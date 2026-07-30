-- Migration: game rejoin system, ownership-transfer per-user+premium
-- restriction, two-balance wallet split, closed-rooms archive.
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

-- ── 1. Ownership transfer — per-user (not per-room) + Premium-gated ────────
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS last_ownership_transfer_at timestamptz;

CREATE OR REPLACE FUNCTION public.transfer_room_ownership(p_room_id uuid, p_new_owner_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_owner_id uuid;
  v_is_premium boolean;
  v_last_transfer timestamptz;
  v_target_role public.room_member_role_enum;
BEGIN
  SELECT owner_id INTO v_owner_id
  FROM public.rooms WHERE id = p_room_id FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;
  IF v_owner_id <> auth.uid() THEN
    RAISE EXCEPTION 'not_owner';
  END IF;

  SELECT is_premium, last_ownership_transfer_at
    INTO v_is_premium, v_last_transfer
  FROM public.profiles WHERE id = auth.uid() FOR UPDATE;

  IF v_is_premium IS NOT TRUE THEN
    RAISE EXCEPTION 'premium_required';
  END IF;
  IF v_last_transfer IS NOT NULL
     AND (v_last_transfer AT TIME ZONE 'utc')::date >= (now() AT TIME ZONE 'utc')::date THEN
    RAISE EXCEPTION 'transfer_limit_reached';
  END IF;

  SELECT role INTO v_target_role
  FROM public.room_members
  WHERE room_id = p_room_id AND user_id = p_new_owner_id AND left_at IS NULL;

  IF v_target_role IS NULL THEN
    RAISE EXCEPTION 'target_not_member';
  END IF;
  IF v_target_role = 'spectator' THEN
    RAISE EXCEPTION 'target_is_spectator';
  END IF;

  UPDATE public.rooms
  SET owner_id = p_new_owner_id, owner_transferred_at = now()
  WHERE id = p_room_id;

  UPDATE public.profiles
  SET last_ownership_transfer_at = now()
  WHERE id = auth.uid();
END;
$$;

GRANT ALL ON FUNCTION public.transfer_room_ownership(uuid, uuid) TO anon;
GRANT ALL ON FUNCTION public.transfer_room_ownership(uuid, uuid) TO authenticated;
GRANT ALL ON FUNCTION public.transfer_room_ownership(uuid, uuid) TO service_role;

-- ── 2. Game rejoin system ───────────────────────────────────────────────────
-- Mirrors the existing room_join_requests/spectator_requests shape and the
-- has_room_permission()-gated decide_* RPC pattern.

CREATE TABLE IF NOT EXISTS public.game_rejoin_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    room_id uuid NOT NULL,
    session_id uuid,
    user_id uuid NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    resolved_at timestamp with time zone,
    CONSTRAINT game_rejoin_requests_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text])))
);

ALTER TABLE public.game_rejoin_requests OWNER TO postgres;

ALTER TABLE ONLY public.game_rejoin_requests
    DROP CONSTRAINT IF EXISTS game_rejoin_requests_pkey;
ALTER TABLE ONLY public.game_rejoin_requests
    ADD CONSTRAINT game_rejoin_requests_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.game_rejoin_requests
    DROP CONSTRAINT IF EXISTS game_rejoin_requests_room_id_user_id_key;
ALTER TABLE ONLY public.game_rejoin_requests
    ADD CONSTRAINT game_rejoin_requests_room_id_user_id_key UNIQUE (room_id, user_id);

ALTER TABLE ONLY public.game_rejoin_requests
    DROP CONSTRAINT IF EXISTS game_rejoin_requests_room_id_fkey;
ALTER TABLE ONLY public.game_rejoin_requests
    ADD CONSTRAINT game_rejoin_requests_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.game_rejoin_requests
    DROP CONSTRAINT IF EXISTS game_rejoin_requests_session_id_fkey;
ALTER TABLE ONLY public.game_rejoin_requests
    ADD CONSTRAINT game_rejoin_requests_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.game_sessions(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.game_rejoin_requests
    DROP CONSTRAINT IF EXISTS game_rejoin_requests_user_id_fkey;
ALTER TABLE ONLY public.game_rejoin_requests
    ADD CONSTRAINT game_rejoin_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_game_rejoin_requests_room ON public.game_rejoin_requests USING btree (room_id, status);

ALTER TABLE public.game_rejoin_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "game_rejoin_requests: own or room member" ON public.game_rejoin_requests;
CREATE POLICY "game_rejoin_requests: own or room member" ON public.game_rejoin_requests FOR SELECT USING (((user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.room_members rm
  WHERE ((rm.room_id = game_rejoin_requests.room_id) AND (rm.user_id = auth.uid()) AND (rm.left_at IS NULL))))));

DROP POLICY IF EXISTS "game_rejoin_requests: self insert" ON public.game_rejoin_requests;
CREATE POLICY "game_rejoin_requests: self insert" ON public.game_rejoin_requests FOR INSERT WITH CHECK ((user_id = auth.uid()));

GRANT ALL ON TABLE public.game_rejoin_requests TO anon;
GRANT ALL ON TABLE public.game_rejoin_requests TO authenticated;
GRANT ALL ON TABLE public.game_rejoin_requests TO service_role;

COMMENT ON COLUMN public.room_moderators.permissions IS 'Granular moderator permission keys: accept_joins, accept_spectators, accept_rejoins, advance_turn, skip_turn, kick_players, mute_chat, manage_settings, end_game. Owner always has every permission implicitly (see has_room_permission()).';

CREATE OR REPLACE FUNCTION public.request_game_rejoin(p_room_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_room_status public.room_status_enum;
  v_max_players smallint;
  v_session_id uuid;
  v_active_count integer;
  v_request_id uuid;
BEGIN
  SELECT status, max_players INTO v_room_status, v_max_players
  FROM public.rooms
  WHERE id = p_room_id AND deleted_at IS NULL
  FOR UPDATE;
  IF v_room_status IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;
  IF v_room_status NOT IN ('in_game', 'paused') THEN
    RAISE EXCEPTION 'game_finished';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.room_members
    WHERE room_id = p_room_id AND user_id = auth.uid() AND kicked_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'not_eligible';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.room_bans
    WHERE room_id = p_room_id AND user_id = auth.uid() AND lifted_at IS NULL
      AND (banned_until IS NULL OR banned_until > now())
  ) THEN
    RAISE EXCEPTION 'not_eligible';
  END IF;

  SELECT id INTO v_session_id FROM public.game_sessions
  WHERE room_id = p_room_id AND status IN ('active', 'paused')
  ORDER BY started_at DESC
  LIMIT 1;
  IF v_session_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.game_sessions
    WHERE id = v_session_id AND auth.uid() = ANY(player_ids)
  ) THEN
    RAISE EXCEPTION 'not_eligible';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.room_members
    WHERE room_id = p_room_id AND user_id = auth.uid() AND left_at IS NULL
  ) THEN
    RAISE EXCEPTION 'already_in_room';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.game_rejoin_requests
    WHERE room_id = p_room_id AND user_id = auth.uid() AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'already_pending';
  END IF;

  SELECT count(*) INTO v_active_count FROM public.room_members
  WHERE room_id = p_room_id AND left_at IS NULL
    AND role <> 'spectator'::public.room_member_role_enum;
  IF v_active_count >= v_max_players THEN
    RAISE EXCEPTION 'room_full';
  END IF;

  INSERT INTO public.game_rejoin_requests (room_id, session_id, user_id, status)
  VALUES (p_room_id, v_session_id, auth.uid(), 'pending')
  ON CONFLICT (room_id, user_id) DO UPDATE
    SET status = 'pending', session_id = excluded.session_id,
        created_at = now(), resolved_at = NULL
  RETURNING id INTO v_request_id;

  RETURN v_request_id;
END;
$$;

GRANT ALL ON FUNCTION public.request_game_rejoin(uuid) TO anon;
GRANT ALL ON FUNCTION public.request_game_rejoin(uuid) TO authenticated;
GRANT ALL ON FUNCTION public.request_game_rejoin(uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.decide_game_rejoin_request(p_request_id uuid, p_approve boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_room_id uuid;
  v_user_id uuid;
  v_row_exists boolean;
BEGIN
  SELECT room_id, user_id INTO v_room_id, v_user_id
  FROM public.game_rejoin_requests
  WHERE id = p_request_id AND status = 'pending';
  IF v_room_id IS NULL THEN
    RAISE EXCEPTION 'request_not_found';
  END IF;
  IF NOT public.has_room_permission(v_room_id, auth.uid(), 'accept_rejoins') THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;

  UPDATE public.game_rejoin_requests
  SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
      resolved_at = now()
  WHERE id = p_request_id;

  IF p_approve THEN
    SELECT EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_id = v_room_id AND user_id = v_user_id
    ) INTO v_row_exists;

    IF v_row_exists THEN
      UPDATE public.room_members
      SET left_at = NULL, kicked_at = NULL, left_definitively = false, is_away = false
      WHERE room_id = v_room_id AND user_id = v_user_id;
    ELSE
      INSERT INTO public.room_members (room_id, user_id, role, seat_order)
      VALUES (v_room_id, v_user_id, 'player', 0);
    END IF;
  END IF;
END;
$$;

GRANT ALL ON FUNCTION public.decide_game_rejoin_request(uuid, boolean) TO anon;
GRANT ALL ON FUNCTION public.decide_game_rejoin_request(uuid, boolean) TO authenticated;
GRANT ALL ON FUNCTION public.decide_game_rejoin_request(uuid, boolean) TO service_role;

-- ── 3. Wallet split — independent Wallet Balance / Earnings Balance ────────
-- Root cause: wallets had exactly one balance column, so deposits, pack-
-- purchase debits, creator commissions, and withdrawals all read/wrote the
-- same number. This splits it in two and fixes every write path.

ALTER TABLE public.wallets
  ADD COLUMN IF NOT EXISTS earnings_balance_mru integer DEFAULT 0 NOT NULL;
ALTER TABLE public.wallets
  DROP CONSTRAINT IF EXISTS wallets_earnings_balance_mru_check;
ALTER TABLE public.wallets
  ADD CONSTRAINT wallets_earnings_balance_mru_check CHECK (earnings_balance_mru >= 0);

COMMENT ON COLUMN public.wallets.balance_mru IS 'Spendable balance — deposits + manually transferred earnings. The ONLY balance used for buying packs, creating rooms, Premium, or any in-app payment.';
COMMENT ON COLUMN public.wallets.earnings_balance_mru IS 'Creator earnings, commissions, rewards. Withdrawals draw ONLY from here (verified creator + balance >= 500 MRU). Never auto-transferred to balance_mru — the user must explicitly transfer.';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'transfer'
      AND enumtypid = 'public.transaction_type_enum'::regtype
  ) THEN
    ALTER TYPE public.transaction_type_enum ADD VALUE 'transfer';
  END IF;
END $$;

ALTER TABLE public.wallet_transactions
  ADD COLUMN IF NOT EXISTS balance_type text DEFAULT 'wallet' NOT NULL;
ALTER TABLE public.wallet_transactions
  DROP CONSTRAINT IF EXISTS wallet_transactions_balance_type_check;
ALTER TABLE public.wallet_transactions
  ADD CONSTRAINT wallet_transactions_balance_type_check
  CHECK (balance_type = ANY (ARRAY['wallet'::text, 'earnings'::text]));

-- p_balance_type selects which of the two balances this transaction
-- reads/locks/writes. Existing 6-arg callers keep working unchanged —
-- the new param defaults to 'wallet' (today's only balance).
CREATE OR REPLACE FUNCTION public.apply_wallet_transaction(
  p_wallet_id uuid,
  p_type public.transaction_type_enum,
  p_amount_mru integer,
  p_reference_id uuid DEFAULT NULL::uuid,
  p_description text DEFAULT NULL::text,
  p_idempotency_key text DEFAULT NULL::text,
  p_balance_type text DEFAULT 'wallet'::text
) RETURNS public.wallet_transactions
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_balance_before integer;
  v_balance_after  integer;
  v_tx             public.wallet_transactions;
begin
  if p_balance_type not in ('wallet', 'earnings') then
    raise exception 'invalid_balance_type';
  end if;

  if p_idempotency_key is not null then
    select * into v_tx
    from public.wallet_transactions
    where idempotency_key = p_idempotency_key;
    if found then
      return v_tx;
    end if;
  end if;

  if p_balance_type = 'wallet' then
    select balance_mru into v_balance_before
    from public.wallets
    where id = p_wallet_id
    for update;
  else
    select earnings_balance_mru into v_balance_before
    from public.wallets
    where id = p_wallet_id
    for update;
  end if;

  if not found then
    raise exception 'Wallet % not found', p_wallet_id;
  end if;

  v_balance_after := v_balance_before + p_amount_mru;

  if v_balance_after < 0 then
    raise exception 'Insufficient balance: have %, need %',
      v_balance_before, abs(p_amount_mru)
      using errcode = 'P0001';
  end if;

  if p_balance_type = 'wallet' then
    update public.wallets
    set balance_mru = v_balance_after,
        updated_at  = now()
    where id = p_wallet_id;
  else
    update public.wallets
    set earnings_balance_mru = v_balance_after,
        updated_at  = now()
    where id = p_wallet_id;
  end if;

  insert into public.wallet_transactions (
    wallet_id, type, amount_mru, balance_before,
    balance_after, balance_type, reference_id, description,
    idempotency_key, status
  )
  values (
    p_wallet_id, p_type, p_amount_mru, v_balance_before,
    v_balance_after, p_balance_type, p_reference_id, p_description,
    p_idempotency_key, 'completed'
  )
  returning * into v_tx;

  return v_tx;
end;
$$;

GRANT ALL ON FUNCTION public.apply_wallet_transaction(uuid, public.transaction_type_enum, integer, uuid, text, text, text) TO anon;
GRANT ALL ON FUNCTION public.apply_wallet_transaction(uuid, public.transaction_type_enum, integer, uuid, text, text, text) TO authenticated;
GRANT ALL ON FUNCTION public.apply_wallet_transaction(uuid, public.transaction_type_enum, integer, uuid, text, text, text) TO service_role;

CREATE OR REPLACE FUNCTION public.transfer_earnings_to_wallet(p_wallet_id uuid, p_amount_mru integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_ref uuid := gen_random_uuid();
BEGIN
  IF p_amount_mru <= 0 THEN
    RAISE EXCEPTION 'invalid_amount';
  END IF;

  PERFORM public.apply_wallet_transaction(
    p_wallet_id, 'transfer', -p_amount_mru, v_ref,
    'Transfer to wallet balance', NULL, 'earnings'
  );
  PERFORM public.apply_wallet_transaction(
    p_wallet_id, 'transfer', p_amount_mru, v_ref,
    'Transfer from earnings balance', NULL, 'wallet'
  );
END;
$$;

GRANT ALL ON FUNCTION public.transfer_earnings_to_wallet(uuid, integer) TO anon;
GRANT ALL ON FUNCTION public.transfer_earnings_to_wallet(uuid, integer) TO authenticated;
GRANT ALL ON FUNCTION public.transfer_earnings_to_wallet(uuid, integer) TO service_role;

-- Dead + broken duplicates removed rather than left as landmines — neither
-- is called from any client/backend code; both reference the non-existent
-- 'pack_sale_credit' transaction_type_enum value and non-existent
-- commissions.total_amount_mru/platform_rate/platform_cut_mru columns, so
-- either would fail outright if ever invoked.
DROP FUNCTION IF EXISTS public.apply_purchase_commission(uuid);
DROP FUNCTION IF EXISTS public.distribute_pack_sale(uuid);

-- ── 4. Closed rooms archive (Premium, read-only, 5-day window) ─────────────
-- "rooms: read" RLS has no owner exception once deleted_at IS NOT NULL —
-- these RPCs are a narrow read-only carve-out instead of loosening that
-- policy. Nothing is ever deleted; the 5-day window is just a query filter.

CREATE OR REPLACE FUNCTION public.get_my_closed_rooms() RETURNS TABLE(room_id uuid, name text, cover_emoji text, game_type public.game_type_enum, closed_at timestamptz, max_players smallint, created_at timestamptz)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF NOT COALESCE((SELECT is_premium FROM public.profiles WHERE id = auth.uid()), false) THEN
    RAISE EXCEPTION 'premium_required';
  END IF;

  RETURN QUERY
  SELECT r.id, r.name, r.cover_emoji, r.game_type, r.deleted_at, r.max_players, r.created_at
  FROM public.rooms r
  WHERE r.owner_id = auth.uid()
    AND r.status = 'closed'::public.room_status_enum
    AND r.deleted_at IS NOT NULL
    AND r.deleted_at >= now() - interval '5 days'
  ORDER BY r.deleted_at DESC;
END;
$$;

GRANT ALL ON FUNCTION public.get_my_closed_rooms() TO anon;
GRANT ALL ON FUNCTION public.get_my_closed_rooms() TO authenticated;
GRANT ALL ON FUNCTION public.get_my_closed_rooms() TO service_role;

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
      SELECT jsonb_agg(jsonb_build_object('pack_id', rpp.pack_id, 'played_at', rpp.played_at))
      FROM public.room_played_packs rpp WHERE rpp.room_id = p_room_id
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
