-- ============================================================================
-- Pack system updates:
--   1. Pack creation extra-submission fee — DB-configurable (was hardcoded
--      300 in submit_pack_for_review), read from app_settings, mirroring
--      the existing physical_pack_price_mru convention.
--   2. Multi-language pack name/description — no schema change needed,
--      packs.title/description are already jsonb translation maps; this
--      item is Dart/client-only (PackDraft + create_pack_screen.dart).
--   3. Pack audience restrictions (age range, gender).
--   4. Truth-or-Dare pack-authored punishments (>=10 if the creator adds
--      any), plus a room-owner-selectable punishment source.
--   5. Physical pack request icon relocation — Dart/client-only, no schema
--      change.
--   6. Physical pack request form reshape — replace address/country with
--      city/zone/quantity.
-- ============================================================================


-- ── 1. Pack creation extra-submission fee ───────────────────────────────────

INSERT INTO public.app_settings (key, value)
VALUES ('pack_extra_creation_price_mru', '300')
ON CONFLICT (key) DO NOTHING;

-- Replaces the hardcoded `v_fee_mru CONSTANT integer := 300` with a lookup
-- against app_settings, mirroring request_physical_pack's existing pattern
-- (including the price_not_configured safety exception). Quota logic,
-- atomicity, and pack_submissions history are all unchanged — they were
-- already correct.
CREATE OR REPLACE FUNCTION "public"."submit_pack_for_review"("p_pack_id" "uuid", "p_pay_fee" boolean DEFAULT false) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_status public.pack_status_enum;
  v_month_count integer;
  v_last_submitted timestamptz;
  v_needs_fee boolean;
  v_fee_mru integer;
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
    SELECT (value #>> '{}')::integer INTO v_fee_mru
    FROM public.app_settings WHERE key = 'pack_extra_creation_price_mru';
    IF v_fee_mru IS NULL THEN
      RAISE EXCEPTION 'price_not_configured';
    END IF;

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


-- ── 3. Pack audience restrictions ───────────────────────────────────────────

ALTER TABLE public.packs
  ADD COLUMN IF NOT EXISTS min_age smallint,
  ADD COLUMN IF NOT EXISTS max_age smallint,
  ADD COLUMN IF NOT EXISTS gender_restriction text NOT NULL DEFAULT 'everyone';

ALTER TABLE public.packs DROP CONSTRAINT IF EXISTS packs_min_age_check;
ALTER TABLE public.packs ADD CONSTRAINT packs_min_age_check
  CHECK (min_age IS NULL OR (min_age BETWEEN 13 AND 100));

ALTER TABLE public.packs DROP CONSTRAINT IF EXISTS packs_max_age_check;
ALTER TABLE public.packs ADD CONSTRAINT packs_max_age_check
  CHECK (max_age IS NULL OR (max_age BETWEEN 13 AND 100));

ALTER TABLE public.packs DROP CONSTRAINT IF EXISTS packs_age_range_check;
ALTER TABLE public.packs ADD CONSTRAINT packs_age_range_check
  CHECK (max_age IS NULL OR min_age IS NULL OR max_age >= min_age);

ALTER TABLE public.packs DROP CONSTRAINT IF EXISTS packs_gender_restriction_check;
ALTER TABLE public.packs ADD CONSTRAINT packs_gender_restriction_check
  CHECK (gender_restriction = ANY (ARRAY['everyone'::text, 'male'::text, 'female'::text]));

-- No enforcement yet (deferred to future game-join work per product
-- decision) — these columns are storage-only for now, writable by the
-- creator via the existing "packs: creator insert"/"packs: creator update"
-- RLS policies (not column-restricted, no new policy needed).


-- ── 4. Truth-or-Dare pack-authored punishments ──────────────────────────────

ALTER TABLE public.packs
  ADD COLUMN IF NOT EXISTS suggested_punishments text[];

-- Optional overall (NULL/empty allowed), but if the creator adds any, at
-- least 10 are required. Named suggested_punishments (not "punishments")
-- to stay unambiguous against the existing, unrelated
-- room_settings.enable_punishments boolean and the runtime TodPunishment
-- peer-vote model — this column is pack-authored content, that system is
-- live in-game player interaction. They're wired together at the room
-- level via GameConfig.punishment_source (see room_settings below), not by
-- sharing a name.
ALTER TABLE public.packs DROP CONSTRAINT IF EXISTS packs_suggested_punishments_check;
ALTER TABLE public.packs ADD CONSTRAINT packs_suggested_punishments_check
  CHECK (suggested_punishments IS NULL OR array_length(suggested_punishments, 1) >= 10);

-- Room-owner-selectable punishment source: 'players' (existing live
-- peer-vote flow, default — preserves current behavior for every existing
-- room) or 'pack' (skip resolves directly from the selected pack's
-- suggested_punishments instead of the peer-proposal phase).
ALTER TABLE public.room_settings
  ADD COLUMN IF NOT EXISTS punishment_source text NOT NULL DEFAULT 'players';

ALTER TABLE public.room_settings DROP CONSTRAINT IF EXISTS room_settings_punishment_source_check;
ALTER TABLE public.room_settings ADD CONSTRAINT room_settings_punishment_source_check
  CHECK (punishment_source = ANY (ARRAY['players'::text, 'pack'::text]));


-- ── 6. Physical pack request — city/zone/quantity, drop address/country ────

ALTER TABLE public.physical_pack_requests
  ALTER COLUMN address_line1 DROP NOT NULL,
  ALTER COLUMN country DROP NOT NULL;

ALTER TABLE public.physical_pack_requests
  ADD COLUMN IF NOT EXISTS zone text,
  ADD COLUMN IF NOT EXISTS quantity integer NOT NULL DEFAULT 1;

ALTER TABLE public.physical_pack_requests DROP CONSTRAINT IF EXISTS physical_pack_requests_quantity_check;
ALTER TABLE public.physical_pack_requests ADD CONSTRAINT physical_pack_requests_quantity_check
  CHECK (quantity >= 1);

-- New signature: p_city/p_zone/p_quantity are the new required client
-- inputs; p_address_line1/p_address_line2/p_country become optional
-- (nullable, unused by the new form, kept only so the function doesn't
-- disappear out from under anything else that might reference it). Price
-- becomes unit price (from app_settings, unchanged) * quantity.
DROP FUNCTION IF EXISTS public.request_physical_pack(uuid, text, text, text, text, text, text, text);

CREATE OR REPLACE FUNCTION "public"."request_physical_pack"(
    "p_pack_id" "uuid",
    "p_recipient_name" "text",
    "p_phone_number" "text",
    "p_city" "text",
    "p_zone" "text",
    "p_quantity" integer DEFAULT 1,
    "p_notes" "text" DEFAULT NULL::"text",
    "p_address_line1" "text" DEFAULT NULL::"text",
    "p_address_line2" "text" DEFAULT NULL::"text",
    "p_country" "text" DEFAULT NULL::"text"
) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_unit_price_mru integer;
  v_total_price_mru integer;
  v_wallet_id uuid;
  v_tx public.wallet_transactions;
  v_request_id uuid;
BEGIN
  IF p_quantity IS NULL OR p_quantity < 1 THEN
    RAISE EXCEPTION 'invalid_quantity';
  END IF;

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

  SELECT (value #>> '{}')::integer INTO v_unit_price_mru
  FROM public.app_settings WHERE key = 'physical_pack_price_mru';
  IF v_unit_price_mru IS NULL THEN
    RAISE EXCEPTION 'price_not_configured';
  END IF;
  v_total_price_mru := v_unit_price_mru * p_quantity;

  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = auth.uid();
  IF v_wallet_id IS NULL THEN
    RAISE EXCEPTION 'wallet_not_found';
  END IF;

  v_tx := public.apply_wallet_transaction(
    v_wallet_id, 'purchase', -v_total_price_mru, NULL,
    'Physical pack request: ' || p_pack_id, NULL, 'wallet'
  );

  -- Payment is debited atomically above, in the same call — there's no
  -- separate async payment step in this model, so "Payment Confirmed" is
  -- satisfied automatically at submission rather than needing an admin to
  -- manually advance it later.
  INSERT INTO public.physical_pack_requests (
    user_id, pack_id, price_mru, recipient_name, phone_number,
    address_line1, address_line2, city, zone, country, quantity, notes, tx_id,
    payment_confirmed_at
  ) VALUES (
    auth.uid(), p_pack_id, v_total_price_mru, p_recipient_name, p_phone_number,
    p_address_line1, p_address_line2, p_city, p_zone, p_country, p_quantity, p_notes, v_tx.id,
    now()
  )
  RETURNING id INTO v_request_id;

  RETURN v_request_id;
END;
$$;

ALTER FUNCTION "public"."request_physical_pack"(
  "p_pack_id" "uuid", "p_recipient_name" "text", "p_phone_number" "text",
  "p_city" "text", "p_zone" "text", "p_quantity" integer, "p_notes" "text",
  "p_address_line1" "text", "p_address_line2" "text", "p_country" "text"
) OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."request_physical_pack"(
  "p_pack_id" "uuid", "p_recipient_name" "text", "p_phone_number" "text",
  "p_city" "text", "p_zone" "text", "p_quantity" integer, "p_notes" "text",
  "p_address_line1" "text", "p_address_line2" "text", "p_country" "text"
) TO "anon";
GRANT ALL ON FUNCTION "public"."request_physical_pack"(
  "p_pack_id" "uuid", "p_recipient_name" "text", "p_phone_number" "text",
  "p_city" "text", "p_zone" "text", "p_quantity" integer, "p_notes" "text",
  "p_address_line1" "text", "p_address_line2" "text", "p_country" "text"
) TO "authenticated";
GRANT ALL ON FUNCTION "public"."request_physical_pack"(
  "p_pack_id" "uuid", "p_recipient_name" "text", "p_phone_number" "text",
  "p_city" "text", "p_zone" "text", "p_quantity" integer, "p_notes" "text",
  "p_address_line1" "text", "p_address_line2" "text", "p_country" "text"
) TO "service_role";
