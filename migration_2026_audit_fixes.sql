-- Migration: 20-item audit & fix pass — notification config, RLS gap
-- closure, wallet filter/transfer fixes, room cleanup, closed-room detail
-- enrichment, pack languages, physical pack requests, and more.
--
-- This repo has no supabase CLI / migration tooling — apply this by hand
-- against the live Supabase project (SQL editor or `psql`). schema.sql has
-- already been updated to reflect this as the target end-state; this
-- script brings an existing, already-provisioned database up to the same
-- state. Safe to run multiple times (IF NOT EXISTS / guarded ADD VALUE).
--
-- Requires prior sessions' migrations already applied:
--   migration_2026_ownership_notifications.sql
--   migration_2026_permissions_and_transfer.sql
--   migration_2026_rejoin_presence_wallet.sql
--
-- ── 0. SEVERITY NOTE ─────────────────────────────────────────────────────
-- Section 1 below (RLS gap closure) is a critical security fix: 19 tables,
-- including wallets, wallet_transactions, room_members, and rooms, had
-- fully-authored RLS policies that were never actually enforced because
-- ALTER TABLE ... ENABLE ROW LEVEL SECURITY was missing, combined with
-- GRANT ALL to anon/authenticated on every one of them. Any authenticated
-- (or even anonymous) client could read or write every user's wallet
-- balance, every room's members, chat, and bans directly via the Supabase
-- REST API, completely bypassing app logic. Apply this section FIRST and
-- as soon as possible, independent of anything else in this file.

-- ── 1. Close the RLS enforcement gap (19 tables) ────────────────────────────
-- Every one of these tables already has a correct, complete policy set
-- (explicit "no client write/update" (false) policies for backend-only
-- tables, correctly scoped reads for client-direct tables) — this was a
-- pure enable-flag omission, not a policy design problem.
ALTER TABLE public.deposits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pack_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pack_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pack_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pack_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pack_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pack_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promoted_packs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_bans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_creation_quotas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

-- ── 2. Automatic room cleanup — hard-purge closed rooms after 5 days ───────
-- game_sessions' FK to rooms was ON DELETE RESTRICT, which would make any
-- purge of a room with game history fail outright — fixed to CASCADE so
-- the whole room (and everything about it) actually disappears together,
-- at the same 5-day boundary the closed-rooms Premium archive already uses
-- as its own visibility window.
ALTER TABLE public.game_sessions DROP CONSTRAINT IF EXISTS game_sessions_room_id_fkey;
ALTER TABLE public.game_sessions
  ADD CONSTRAINT game_sessions_room_id_fkey FOREIGN KEY (room_id)
  REFERENCES public.rooms(id) ON DELETE CASCADE;

CREATE OR REPLACE FUNCTION public.cleanup_purge_closed_rooms() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_count integer;
begin
  delete from public.rooms
  where status = 'closed'::public.room_status_enum
    and deleted_at is not null
    and deleted_at < now() - interval '5 days';
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

GRANT ALL ON FUNCTION public.cleanup_purge_closed_rooms() TO anon;
GRANT ALL ON FUNCTION public.cleanup_purge_closed_rooms() TO authenticated;
GRANT ALL ON FUNCTION public.cleanup_purge_closed_rooms() TO service_role;

-- ── 3. Closed-room detail: join played-pack titles ─────────────────────────
-- get_closed_room_details() previously returned only pack_id for played
-- packs — CREATE OR REPLACE is idempotent, safe to reapply the whole
-- function even if migration_2026_rejoin_presence_wallet.sql already ran.
CREATE OR REPLACE FUNCTION public.get_closed_room_details(p_room_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_room public.rooms%rowtype;
  v_result jsonb;
BEGIN
  IF NOT COALESCE((SELECT is_premium FROM public.profiles WHERE id = auth.uid()), false) THEN
    RAISE EXCEPTION 'premium_required';
  END IF;

  SELECT * INTO v_room FROM public.rooms
  WHERE id = p_room_id AND owner_id = auth.uid()
    AND status = 'closed'::public.room_status_enum
    AND deleted_at IS NOT NULL
    AND deleted_at >= now() - interval '5 days';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;

  v_result := jsonb_build_object(
    'room', jsonb_build_object(
      'id', v_room.id, 'name', v_room.name, 'cover_emoji', v_room.cover_emoji,
      'game_type', v_room.game_type, 'max_players', v_room.max_players,
      'created_at', v_room.created_at, 'closed_at', v_room.deleted_at,
      'game_started_at', v_room.game_started_at, 'game_ended_at', v_room.game_ended_at
    ),
    'sessions', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', gs.id, 'pack_id', gs.pack_id, 'game_type', gs.game_type,
        'status', gs.status, 'player_ids', gs.player_ids,
        'state_snapshot', gs.state_snapshot,
        'started_at', gs.started_at, 'ended_at', gs.ended_at
      ) ORDER BY gs.started_at)
      FROM public.game_sessions gs WHERE gs.room_id = p_room_id
    ), '[]'::jsonb),
    'played_packs', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'pack_id', rpp.pack_id, 'played_at', rpp.played_at,
        'title', pk.title, 'cover_image_url', pk.cover_image_url
      ))
      FROM public.room_played_packs rpp
      LEFT JOIN public.packs pk ON pk.id = rpp.pack_id
      WHERE rpp.room_id = p_room_id
    ), '[]'::jsonb),
    'participants', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'user_id', rm.user_id, 'role', rm.role, 'seat_order', rm.seat_order,
        'joined_at', rm.joined_at, 'left_at', rm.left_at,
        'display_name', p.display_name, 'username', p.username, 'avatar_url', p.avatar_url
      ))
      FROM public.room_members rm
      LEFT JOIN public.profiles p ON p.id = rm.user_id
      WHERE rm.room_id = p_room_id
    ), '[]'::jsonb)
  );

  RETURN v_result;
END;
$$;

GRANT ALL ON FUNCTION public.get_closed_room_details(uuid) TO anon;
GRANT ALL ON FUNCTION public.get_closed_room_details(uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_closed_room_details(uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.run_all_cleanup() RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_result jsonb;
begin
  v_result := jsonb_build_object(
    'stale_rooms',          public.cleanup_stale_rooms(),
    'expired_bans',         public.cleanup_expired_bans(),
    'platform_bans',        public.cleanup_expired_platform_bans(),
    'notifications',        public.cleanup_expired_notifications(),
    'invites',              public.cleanup_expired_invites(),
    'purchases',            public.cleanup_expired_purchases(),
    'online_status',        public.cleanup_stale_online_status(),
    'otp_audit',            public.cleanup_otp_audit_log(),
    'purged_closed_rooms',  public.cleanup_purge_closed_rooms(),
    'ran_at',               now()
  );
  return v_result;
end;
$$;

-- ── 4. Room settings: punishment toggle + Truth or Dare proof policy ───────
-- enable_punishments existed on GameConfig but was never a real room
-- setting — hardcoded true at every game-start call site with no owner
-- control. Proof visibility/view-duration/replay already existed at the
-- engine level but were never exposed as configurable either.
ALTER TABLE public.room_settings
  ADD COLUMN IF NOT EXISTS enable_punishments boolean DEFAULT false NOT NULL;
ALTER TABLE public.room_settings
  ADD COLUMN IF NOT EXISTS proof_visibility_policy text DEFAULT 'everyone' NOT NULL;
ALTER TABLE public.room_settings
  ADD COLUMN IF NOT EXISTS proof_view_seconds smallint DEFAULT 5 NOT NULL;
ALTER TABLE public.room_settings
  ADD COLUMN IF NOT EXISTS proof_replay_mode text DEFAULT 'once' NOT NULL;

ALTER TABLE public.room_settings DROP CONSTRAINT IF EXISTS room_settings_proof_visibility_policy_check;
ALTER TABLE public.room_settings
  ADD CONSTRAINT room_settings_proof_visibility_policy_check
  CHECK (proof_visibility_policy = ANY (ARRAY['everyone', 'players_only', 'spectators_only']));

ALTER TABLE public.room_settings DROP CONSTRAINT IF EXISTS room_settings_proof_replay_mode_check;
ALTER TABLE public.room_settings
  ADD CONSTRAINT room_settings_proof_replay_mode_check
  CHECK (proof_replay_mode = ANY (ARRAY['once', 'replay_once']));

ALTER TABLE public.room_settings DROP CONSTRAINT IF EXISTS room_settings_proof_view_seconds_check;
ALTER TABLE public.room_settings
  ADD CONSTRAINT room_settings_proof_view_seconds_check
  CHECK (proof_view_seconds >= 2 AND proof_view_seconds <= 30);

-- ── 5. Physical Card Pack Requests (new feature) ────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'physical_pack_request_status_enum') THEN
    CREATE TYPE public.physical_pack_request_status_enum AS ENUM
      ('pending', 'processing', 'shipped', 'delivered', 'cancelled');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.app_settings (
    key text NOT NULL,
    value jsonb NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT app_settings_pkey PRIMARY KEY (key)
);
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "app_settings: no client write" ON public.app_settings;
CREATE POLICY "app_settings: no client write" ON public.app_settings FOR INSERT WITH CHECK (false);
DROP POLICY IF EXISTS "app_settings: no client update" ON public.app_settings;
CREATE POLICY "app_settings: no client update" ON public.app_settings FOR UPDATE USING (false);
DROP POLICY IF EXISTS "app_settings: public read" ON public.app_settings;
CREATE POLICY "app_settings: public read" ON public.app_settings FOR SELECT USING (true);

GRANT ALL ON TABLE public.app_settings TO anon;
GRANT ALL ON TABLE public.app_settings TO authenticated;
GRANT ALL ON TABLE public.app_settings TO service_role;

-- Seed the default price — admins can update it directly via SQL editor
-- afterward (service_role bypasses the "no client write" RLS policies).
INSERT INTO public.app_settings (key, value)
VALUES ('physical_pack_price_mru', '1500')
ON CONFLICT (key) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.physical_pack_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    pack_id uuid NOT NULL,
    status public.physical_pack_request_status_enum DEFAULT 'pending' NOT NULL,
    price_mru integer NOT NULL,
    recipient_name text NOT NULL,
    phone_number text NOT NULL,
    address_line1 text NOT NULL,
    address_line2 text,
    city text NOT NULL,
    country text NOT NULL,
    notes text,
    tx_id uuid,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    processing_at timestamptz,
    shipped_at timestamptz,
    delivered_at timestamptz,
    cancelled_at timestamptz,
    CONSTRAINT physical_pack_requests_pkey PRIMARY KEY (id),
    CONSTRAINT physical_pack_requests_price_mru_check CHECK (price_mru >= 0)
);

ALTER TABLE public.physical_pack_requests DROP CONSTRAINT IF EXISTS physical_pack_requests_user_id_fkey;
ALTER TABLE public.physical_pack_requests
  ADD CONSTRAINT physical_pack_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE RESTRICT;

ALTER TABLE public.physical_pack_requests DROP CONSTRAINT IF EXISTS physical_pack_requests_pack_id_fkey;
ALTER TABLE public.physical_pack_requests
  ADD CONSTRAINT physical_pack_requests_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES public.packs(id) ON DELETE RESTRICT;

ALTER TABLE public.physical_pack_requests DROP CONSTRAINT IF EXISTS physical_pack_requests_tx_id_fkey;
ALTER TABLE public.physical_pack_requests
  ADD CONSTRAINT physical_pack_requests_tx_id_fkey FOREIGN KEY (tx_id) REFERENCES public.wallet_transactions(id) ON DELETE SET NULL;

ALTER TABLE public.physical_pack_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "physical_pack_requests: no client insert" ON public.physical_pack_requests;
CREATE POLICY "physical_pack_requests: no client insert" ON public.physical_pack_requests FOR INSERT WITH CHECK (false);
DROP POLICY IF EXISTS "physical_pack_requests: no client update" ON public.physical_pack_requests;
CREATE POLICY "physical_pack_requests: no client update" ON public.physical_pack_requests FOR UPDATE USING (false);
DROP POLICY IF EXISTS "physical_pack_requests: own read" ON public.physical_pack_requests;
CREATE POLICY "physical_pack_requests: own read" ON public.physical_pack_requests FOR SELECT USING (auth.uid() = user_id);

GRANT ALL ON TABLE public.physical_pack_requests TO anon;
GRANT ALL ON TABLE public.physical_pack_requests TO authenticated;
GRANT ALL ON TABLE public.physical_pack_requests TO service_role;

CREATE OR REPLACE FUNCTION public.request_physical_pack(
  p_pack_id uuid, p_recipient_name text, p_phone_number text,
  p_address_line1 text, p_address_line2 text, p_city text,
  p_country text, p_notes text DEFAULT NULL::text
) RETURNS uuid
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
    address_line1, address_line2, city, country, notes, tx_id
  ) VALUES (
    auth.uid(), p_pack_id, v_price_mru, p_recipient_name, p_phone_number,
    p_address_line1, p_address_line2, p_city, p_country, p_notes, v_tx.id
  )
  RETURNING id INTO v_request_id;

  RETURN v_request_id;
END;
$$;

GRANT ALL ON FUNCTION public.request_physical_pack(uuid, text, text, text, text, text, text, text) TO anon;
GRANT ALL ON FUNCTION public.request_physical_pack(uuid, text, text, text, text, text, text, text) TO authenticated;
GRANT ALL ON FUNCTION public.request_physical_pack(uuid, text, text, text, text, text, text, text) TO service_role;
