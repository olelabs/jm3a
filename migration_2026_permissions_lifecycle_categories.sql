-- ============================================================================
-- Fifth audit pass: ToD start-game permission crash, kick/ready durability,
-- pack submission limits, custom category suggestions, physical pack
-- timeline. Every statement below is safe to re-run.
-- ============================================================================


-- ── 1. Truth or Dare "You don't have permission to do that" crash ──────────
-- Root cause: game_sessions has no permissive INSERT policy at all (a prior
-- session's RLS-enable sweep turned this dormant restriction on for the
-- first time) — session creation must go through this SECURITY DEFINER RPC
-- instead of a raw client insert. Gated by has_room_permission(...,
-- 'start_game') — true for the owner unconditionally, true for a moderator
-- only if explicitly granted.
CREATE OR REPLACE FUNCTION public.create_game_session(p_room_id uuid, p_pack_id uuid, p_game_type text, p_player_ids uuid[], p_max_rounds smallint, p_turn_timer_secs smallint, p_allow_skip boolean, p_allow_spicy boolean, p_state_snapshot jsonb DEFAULT '{}'::jsonb) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.has_room_permission(p_room_id, auth.uid(), 'start_game') THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;

  INSERT INTO public.game_sessions (
    room_id, pack_id, game_type, owner_id, player_ids, state_snapshot,
    max_rounds, turn_timer_secs, allow_skip, allow_spicy, status
  ) VALUES (
    p_room_id, p_pack_id, p_game_type::public.game_type_enum, auth.uid(), p_player_ids, p_state_snapshot,
    p_max_rounds, p_turn_timer_secs, p_allow_skip, p_allow_spicy, 'active'
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

GRANT ALL ON FUNCTION public.create_game_session(uuid, uuid, text, uuid[], smallint, smallint, boolean, boolean, jsonb) TO anon;
GRANT ALL ON FUNCTION public.create_game_session(uuid, uuid, text, uuid[], smallint, smallint, boolean, boolean, jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.create_game_session(uuid, uuid, text, uuid[], smallint, smallint, boolean, boolean, jsonb) TO service_role;


-- ── 2. Kick-from-game durability ────────────────────────────────────────────
-- Previously "kicked from this game" (as opposed to kicked from the room
-- entirely) was only ever a client-side broadcast + local in-memory flag —
-- any client that reconnected, briefly dropped, or joined after that one-
-- shot broadcast never learned the target was away, letting them keep
-- stalling turn order and ready checks. This persists it to the already-
-- existing room_members.is_away column so every client's normal
-- getRoomWithDetails fetch / realtime room_members subscription picks it up.
CREATE OR REPLACE FUNCTION public.mark_room_member_away(p_room_id uuid, p_target_user_id uuid, p_away boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF NOT public.has_room_permission(p_room_id, auth.uid(), 'kick_players') THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;
  UPDATE public.room_members
  SET is_away = p_away
  WHERE room_id = p_room_id AND user_id = p_target_user_id AND left_at IS NULL;
END;
$$;

GRANT ALL ON FUNCTION public.mark_room_member_away(uuid, uuid, boolean) TO anon;
GRANT ALL ON FUNCTION public.mark_room_member_away(uuid, uuid, boolean) TO authenticated;
GRANT ALL ON FUNCTION public.mark_room_member_away(uuid, uuid, boolean) TO service_role;


-- ── 3. Pack submission limits (2/month, 15-day gap, 300 MRU fee) ───────────
CREATE TABLE IF NOT EXISTS public.pack_submissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    pack_id uuid NOT NULL,
    creator_id uuid NOT NULL,
    submitted_at timestamp with time zone DEFAULT now() NOT NULL,
    fee_paid boolean DEFAULT false NOT NULL,
    fee_tx_id uuid
);

ALTER TABLE public.pack_submissions DROP CONSTRAINT IF EXISTS pack_submissions_pkey;
ALTER TABLE ONLY public.pack_submissions ADD CONSTRAINT pack_submissions_pkey PRIMARY KEY (id);

ALTER TABLE public.pack_submissions DROP CONSTRAINT IF EXISTS pack_submissions_creator_id_fkey;
ALTER TABLE ONLY public.pack_submissions ADD CONSTRAINT pack_submissions_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.pack_submissions DROP CONSTRAINT IF EXISTS pack_submissions_pack_id_fkey;
ALTER TABLE ONLY public.pack_submissions ADD CONSTRAINT pack_submissions_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES public.packs(id) ON DELETE CASCADE;

ALTER TABLE public.pack_submissions DROP CONSTRAINT IF EXISTS pack_submissions_fee_tx_id_fkey;
ALTER TABLE ONLY public.pack_submissions ADD CONSTRAINT pack_submissions_fee_tx_id_fkey FOREIGN KEY (fee_tx_id) REFERENCES public.wallet_transactions(id) ON DELETE SET NULL;

ALTER TABLE public.pack_submissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pack_submissions: no client insert" ON public.pack_submissions;
CREATE POLICY "pack_submissions: no client insert" ON public.pack_submissions FOR INSERT WITH CHECK (false);

DROP POLICY IF EXISTS "pack_submissions: no client update" ON public.pack_submissions;
CREATE POLICY "pack_submissions: no client update" ON public.pack_submissions FOR UPDATE USING (false);

DROP POLICY IF EXISTS "pack_submissions: own read" ON public.pack_submissions;
CREATE POLICY "pack_submissions: own read" ON public.pack_submissions FOR SELECT USING ((auth.uid() = creator_id));

GRANT ALL ON TABLE public.pack_submissions TO anon;
GRANT ALL ON TABLE public.pack_submissions TO authenticated;
GRANT ALL ON TABLE public.pack_submissions TO service_role;

CREATE OR REPLACE FUNCTION public.submit_pack_for_review(p_pack_id uuid, p_pay_fee boolean DEFAULT false) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_status public.pack_status_enum;
  v_month_count integer;
  v_last_submitted timestamptz;
  v_needs_fee boolean;
  v_fee_mru CONSTANT integer := 300;
  v_wallet_id uuid;
  v_tx public.wallet_transactions;
  v_fee_tx_id uuid;
BEGIN
  SELECT status INTO v_status FROM public.packs
  WHERE id = p_pack_id AND creator_id = auth.uid();
  IF v_status IS NULL THEN
    RAISE EXCEPTION 'pack_not_found';
  END IF;
  IF v_status NOT IN ('draft', 'rejected') THEN
    RAISE EXCEPTION 'pack_not_editable';
  END IF;

  SELECT count(*) INTO v_month_count FROM public.pack_submissions
  WHERE creator_id = auth.uid()
    AND submitted_at >= date_trunc('month', now());
  SELECT max(submitted_at) INTO v_last_submitted FROM public.pack_submissions
  WHERE creator_id = auth.uid();

  v_needs_fee := v_month_count >= 2
    OR (v_last_submitted IS NOT NULL AND now() - v_last_submitted < interval '15 days');

  IF v_needs_fee AND NOT p_pay_fee THEN
    RAISE EXCEPTION 'fee_required';
  END IF;

  IF v_needs_fee THEN
    SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = auth.uid();
    IF v_wallet_id IS NULL THEN
      RAISE EXCEPTION 'wallet_not_found';
    END IF;
    v_tx := public.apply_wallet_transaction(
      v_wallet_id, 'purchase', -v_fee_mru, NULL,
      'Additional pack submission fee: ' || p_pack_id, NULL, 'wallet'
    );
    v_fee_tx_id := v_tx.id;
  END IF;

  INSERT INTO public.pack_submissions (pack_id, creator_id, fee_paid, fee_tx_id)
  VALUES (p_pack_id, auth.uid(), v_needs_fee, v_fee_tx_id);

  UPDATE public.packs
  SET status = 'pending_review', rejection_reason = NULL
  WHERE id = p_pack_id;

  RETURN jsonb_build_object('fee_charged', v_needs_fee, 'fee_mru', CASE WHEN v_needs_fee THEN v_fee_mru ELSE 0 END);
END;
$$;

GRANT ALL ON FUNCTION public.submit_pack_for_review(uuid, boolean) TO anon;
GRANT ALL ON FUNCTION public.submit_pack_for_review(uuid, boolean) TO authenticated;
GRANT ALL ON FUNCTION public.submit_pack_for_review(uuid, boolean) TO service_role;


-- ── 4. User-created pack category suggestions ───────────────────────────────
DO $$
BEGIN
  CREATE TYPE public.category_suggestion_status_enum AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.pack_category_suggestions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    suggested_name text NOT NULL,
    suggested_by uuid NOT NULL,
    status public.category_suggestion_status_enum DEFAULT 'pending'::public.category_suggestion_status_enum NOT NULL,
    rejection_reason text,
    reviewed_by uuid,
    reviewed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pack_category_suggestions_suggested_name_check CHECK ((char_length(suggested_name) >= 2) AND (char_length(suggested_name) <= 60))
);

ALTER TABLE public.pack_category_suggestions DROP CONSTRAINT IF EXISTS pack_category_suggestions_pkey;
ALTER TABLE ONLY public.pack_category_suggestions ADD CONSTRAINT pack_category_suggestions_pkey PRIMARY KEY (id);

ALTER TABLE public.pack_category_suggestions DROP CONSTRAINT IF EXISTS pack_category_suggestions_suggested_by_fkey;
ALTER TABLE ONLY public.pack_category_suggestions ADD CONSTRAINT pack_category_suggestions_suggested_by_fkey FOREIGN KEY (suggested_by) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.pack_category_suggestions DROP CONSTRAINT IF EXISTS pack_category_suggestions_reviewed_by_fkey;
ALTER TABLE ONLY public.pack_category_suggestions ADD CONSTRAINT pack_category_suggestions_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.pack_category_suggestions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pack_category_suggestions: no client update" ON public.pack_category_suggestions;
CREATE POLICY "pack_category_suggestions: no client update" ON public.pack_category_suggestions FOR UPDATE USING (false);

DROP POLICY IF EXISTS "pack_category_suggestions: own insert" ON public.pack_category_suggestions;
CREATE POLICY "pack_category_suggestions: own insert" ON public.pack_category_suggestions FOR INSERT WITH CHECK ((auth.uid() = suggested_by));

DROP POLICY IF EXISTS "pack_category_suggestions: own read" ON public.pack_category_suggestions;
CREATE POLICY "pack_category_suggestions: own read" ON public.pack_category_suggestions FOR SELECT USING ((auth.uid() = suggested_by));

GRANT ALL ON TABLE public.pack_category_suggestions TO anon;
GRANT ALL ON TABLE public.pack_category_suggestions TO authenticated;
GRANT ALL ON TABLE public.pack_category_suggestions TO service_role;

ALTER TABLE public.packs ADD COLUMN IF NOT EXISTS pending_category_suggestion_id uuid;

ALTER TABLE public.packs DROP CONSTRAINT IF EXISTS packs_pending_category_suggestion_id_fkey;
ALTER TABLE ONLY public.packs ADD CONSTRAINT packs_pending_category_suggestion_id_fkey FOREIGN KEY (pending_category_suggestion_id) REFERENCES public.pack_category_suggestions(id) ON DELETE SET NULL;

ALTER TABLE public.packs DROP CONSTRAINT IF EXISTS packs_no_approve_with_pending_category;
ALTER TABLE ONLY public.packs ADD CONSTRAINT packs_no_approve_with_pending_category CHECK ((NOT (status = 'approved'::public.pack_status_enum AND pending_category_suggestion_id IS NOT NULL)));

-- Mirrors apply_verification_decision: an admin (service role) applies the
-- decision by updating status; this trigger does the real work atomically.
-- On rejection, pending_category_suggestion_id is deliberately left set so
-- the creator's UI can show the rejection_reason and let them pick another
-- category or submit a fresh suggestion.
CREATE OR REPLACE FUNCTION public.apply_category_suggestion_decision() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_category_id uuid;
  v_slug text;
BEGIN
  IF new.status <> old.status AND new.status = 'approved' THEN
    v_slug := trim(both '-' from regexp_replace(lower(new.suggested_name), '[^a-z0-9]+', '-', 'g'));
    INSERT INTO public.pack_categories (name_json, slug)
    VALUES (jsonb_build_object('en', new.suggested_name), v_slug)
    RETURNING id INTO v_category_id;

    UPDATE public.packs
    SET category_id = v_category_id,
        pending_category_suggestion_id = NULL
    WHERE pending_category_suggestion_id = new.id;
  END IF;
  RETURN new;
END;
$$;

GRANT ALL ON FUNCTION public.apply_category_suggestion_decision() TO anon;
GRANT ALL ON FUNCTION public.apply_category_suggestion_decision() TO authenticated;
GRANT ALL ON FUNCTION public.apply_category_suggestion_decision() TO service_role;

DROP TRIGGER IF EXISTS trg_apply_category_suggestion ON public.pack_category_suggestions;
CREATE TRIGGER trg_apply_category_suggestion AFTER UPDATE OF status ON public.pack_category_suggestions FOR EACH ROW EXECUTE FUNCTION public.apply_category_suggestion_decision();


-- ── 5/6. Pack + Room Settings language sourcing — Dart-only, no schema change.


-- ── 7. Wallet transaction detail sheet — Dart-only (balance_type column
-- already existed), no schema change.


-- ── 8. Physical pack request timeline ───────────────────────────────────────
-- Additive-only enum growth — 'processing'/'shipped' are kept even though
-- superseded by the more granular stages below, since removing an enum
-- value would require recreating the type and remapping any existing rows.
ALTER TYPE public.physical_pack_request_status_enum ADD VALUE IF NOT EXISTS 'payment_confirmed';
ALTER TYPE public.physical_pack_request_status_enum ADD VALUE IF NOT EXISTS 'under_review';
ALTER TYPE public.physical_pack_request_status_enum ADD VALUE IF NOT EXISTS 'printing';
ALTER TYPE public.physical_pack_request_status_enum ADD VALUE IF NOT EXISTS 'packaging';
ALTER TYPE public.physical_pack_request_status_enum ADD VALUE IF NOT EXISTS 'out_for_delivery';
ALTER TYPE public.physical_pack_request_status_enum ADD VALUE IF NOT EXISTS 'completed';

ALTER TABLE public.physical_pack_requests ADD COLUMN IF NOT EXISTS payment_confirmed_at timestamp with time zone;
ALTER TABLE public.physical_pack_requests ADD COLUMN IF NOT EXISTS under_review_at timestamp with time zone;
ALTER TABLE public.physical_pack_requests ADD COLUMN IF NOT EXISTS printing_at timestamp with time zone;
ALTER TABLE public.physical_pack_requests ADD COLUMN IF NOT EXISTS packaging_at timestamp with time zone;
ALTER TABLE public.physical_pack_requests ADD COLUMN IF NOT EXISTS out_for_delivery_at timestamp with time zone;
ALTER TABLE public.physical_pack_requests ADD COLUMN IF NOT EXISTS completed_at timestamp with time zone;

-- Payment is debited atomically at request-creation time in this model (no
-- separate async payment step exists), so "Payment Confirmed" is satisfied
-- automatically at submission rather than needing an admin to advance it.
CREATE OR REPLACE FUNCTION public.request_physical_pack(p_pack_id uuid, p_recipient_name text, p_phone_number text, p_address_line1 text, p_address_line2 text, p_city text, p_country text, p_notes text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_price_mru integer;
  v_wallet_id uuid;
  v_tx public.wallet_transactions;
  v_request_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.pack_purchases
    WHERE pack_id = p_pack_id AND buyer_id = auth.uid() AND status = 'completed'::public.purchase_status_enum
  ) THEN
    RAISE EXCEPTION 'pack_not_owned';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.physical_pack_requests
    WHERE pack_id = p_pack_id AND user_id = auth.uid()
      AND status IN ('pending', 'processing', 'shipped')
  ) THEN
    RAISE EXCEPTION 'already_requested';
  END IF;

  SELECT (value #>> '{}')::integer INTO v_price_mru
  FROM public.app_settings WHERE key = 'physical_pack_price_mru';
  IF v_price_mru IS NULL THEN
    RAISE EXCEPTION 'price_not_configured';
  END IF;

  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = auth.uid();
  IF v_wallet_id IS NULL THEN
    RAISE EXCEPTION 'wallet_not_found';
  END IF;

  v_tx := public.apply_wallet_transaction(
    v_wallet_id, 'purchase', -v_price_mru, NULL,
    'Physical pack request: ' || p_pack_id, NULL, 'wallet'
  );

  INSERT INTO public.physical_pack_requests (
    user_id, pack_id, price_mru, recipient_name, phone_number,
    address_line1, address_line2, city, country, notes, tx_id,
    payment_confirmed_at
  ) VALUES (
    auth.uid(), p_pack_id, v_price_mru, p_recipient_name, p_phone_number,
    p_address_line1, p_address_line2, p_city, p_country, p_notes, v_tx.id,
    now()
  )
  RETURNING id INTO v_request_id;

  RETURN v_request_id;
END;
$$;
