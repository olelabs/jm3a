-- migration_2026_sync_presence_proof.sql
--
-- Sync architecture overhaul: follower staleness reconciliation, server-
-- verified presence heartbeat + automatic ownership failover, and real
-- backend enforcement of Truth-or-Dare proof visibility/replay limits.
-- Mirrors schema.sql exactly. Safe to run multiple times (IF NOT EXISTS /
-- DROP-then-CREATE guarded throughout, matching every prior migration in
-- this project).
--
-- Apply by hand in the Supabase SQL editor (this environment has no direct
-- Postgres connection / CLI access).

-- ── 1. Presence heartbeat (room_members.last_seen_at) ─────────────────────
-- Root cause: Supabase Presence is client-side diffing with no server
-- record — any two unrelated presence events could race-arm a false
-- eviction for a player with only a momentary connection blip. This column
-- gives eviction logic a real, tamper-resistant "last confirmed active"
-- timestamp to double-check against before permanently writing left_at.

ALTER TABLE public.room_members
  ADD COLUMN IF NOT EXISTS last_seen_at timestamp with time zone DEFAULT now() NOT NULL;

CREATE OR REPLACE FUNCTION public.touch_room_presence(p_room_id uuid) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    AS $$
  update public.room_members
  set last_seen_at = now()
  where room_id = p_room_id and user_id = auth.uid() and left_at is null;
$$;

GRANT ALL ON FUNCTION public.touch_room_presence(uuid) TO anon;
GRANT ALL ON FUNCTION public.touch_room_presence(uuid) TO authenticated;
GRANT ALL ON FUNCTION public.touch_room_presence(uuid) TO service_role;

-- ── 2. Emergency ownership failover ────────────────────────────────────────
-- Deliberately separate from transfer_room_ownership (manual, Premium-
-- gated, once-per-day): this exists purely to recover a game when the
-- current owner has gone genuinely unreachable, so it isn't rate-limited.
-- The staleness check re-reads the CURRENT owner's own last_seen_at
-- (updated only by touch_room_presence, callable only by that owner's own
-- authenticated session) rather than trusting anything the caller asserts.

CREATE OR REPLACE FUNCTION public.claim_room_ownership(p_room_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_current_owner_id uuid;
  v_owner_last_seen timestamptz;
  v_owner_left_at timestamptz;
  v_new_owner_id uuid;
  v_caller_is_member boolean;
BEGIN
  SELECT owner_id INTO v_current_owner_id
  FROM public.rooms WHERE id = p_room_id FOR UPDATE;
  IF v_current_owner_id IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.room_members
    WHERE room_id = p_room_id AND user_id = auth.uid() AND left_at IS NULL
  ) INTO v_caller_is_member;
  IF NOT v_caller_is_member THEN
    RAISE EXCEPTION 'not_a_member';
  END IF;

  SELECT last_seen_at, left_at INTO v_owner_last_seen, v_owner_left_at
  FROM public.room_members
  WHERE room_id = p_room_id AND user_id = v_current_owner_id;

  -- Eligible to claim only if the owner has actually left, or their own
  -- heartbeat hasn't landed in well over the client-side grace period —
  -- never based on the caller's own claim about the owner's state.
  IF v_owner_left_at IS NULL
     AND v_owner_last_seen IS NOT NULL
     AND v_owner_last_seen > now() - interval '25 seconds' THEN
    RAISE EXCEPTION 'owner_still_active';
  END IF;

  SELECT rm.user_id INTO v_new_owner_id
  FROM public.room_members rm
  WHERE rm.room_id = p_room_id
    AND rm.left_at IS NULL
    AND rm.role <> 'spectator'::public.room_member_role_enum
    AND rm.user_id <> v_current_owner_id
  ORDER BY (EXISTS (
    SELECT 1 FROM public.room_moderators mod
    WHERE mod.room_id = p_room_id AND mod.user_id = rm.user_id
  )) DESC, rm.seat_order ASC
  LIMIT 1;

  IF v_new_owner_id IS NULL THEN
    RAISE EXCEPTION 'no_eligible_member';
  END IF;

  UPDATE public.rooms
  SET owner_id = v_new_owner_id, owner_transferred_at = now()
  WHERE id = p_room_id;

  UPDATE public.game_sessions
  SET owner_id = v_new_owner_id
  WHERE room_id = p_room_id AND status = 'active';

  RETURN v_new_owner_id;
END;
$$;

GRANT ALL ON FUNCTION public.claim_room_ownership(uuid) TO anon;
GRANT ALL ON FUNCTION public.claim_room_ownership(uuid) TO authenticated;
GRANT ALL ON FUNCTION public.claim_room_ownership(uuid) TO service_role;

-- Pre-existing bug fix, folded in here since it touches the same function:
-- a manual transfer_room_ownership call never updated the active game
-- session's own owner_id, which gates the "game_sessions: owner update"
-- RLS policy — a manual mid-game transfer left the new owner unable to
-- save/broadcast state at all.
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

  UPDATE public.game_sessions
  SET owner_id = p_new_owner_id
  WHERE room_id = p_room_id AND status = 'active';

  UPDATE public.profiles
  SET last_ownership_transfer_at = now()
  WHERE id = auth.uid();
END;
$$;

GRANT ALL ON FUNCTION public.transfer_room_ownership(uuid, uuid) TO anon;
GRANT ALL ON FUNCTION public.transfer_room_ownership(uuid, uuid) TO authenticated;
GRANT ALL ON FUNCTION public.transfer_room_ownership(uuid, uuid) TO service_role;

-- ── 3. Truth-or-Dare proof-view ledger + enforcement ───────────────────────
-- Root cause: visibility policy and replay counting previously lived only
-- in the shared game-state broadcast (state.turnProofViewedBy), trusted
-- from whichever client currently runs as room owner — nothing in
-- Postgres validated who was allowed to view or how many times.

CREATE TABLE IF NOT EXISTS public.tod_proof_views (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    session_id uuid NOT NULL,
    turn_started_at bigint NOT NULL,
    viewer_id uuid NOT NULL,
    viewed_at timestamp with time zone DEFAULT now() NOT NULL,
    view_number integer NOT NULL
);

ALTER TABLE public.tod_proof_views OWNER TO postgres;

ALTER TABLE ONLY public.tod_proof_views
    DROP CONSTRAINT IF EXISTS tod_proof_views_pkey;
ALTER TABLE ONLY public.tod_proof_views
    ADD CONSTRAINT tod_proof_views_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.tod_proof_views
    DROP CONSTRAINT IF EXISTS tod_proof_views_session_id_fkey;
ALTER TABLE ONLY public.tod_proof_views
    ADD CONSTRAINT tod_proof_views_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.game_sessions(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.tod_proof_views
    DROP CONSTRAINT IF EXISTS tod_proof_views_viewer_id_fkey;
ALTER TABLE ONLY public.tod_proof_views
    ADD CONSTRAINT tod_proof_views_viewer_id_fkey FOREIGN KEY (viewer_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.tod_proof_views ENABLE ROW LEVEL SECURITY;

-- Self-referential-RLS-recursion sweep (this project's standing check,
-- previously caught a bug on room_members): none of these three policies
-- reference tod_proof_views itself in a subquery — "no client insert"/
-- "no client update" are constant (false), and "own read" is a direct
-- column comparison against auth.uid(). No recursion risk.
DROP POLICY IF EXISTS "tod_proof_views: no client insert" ON public.tod_proof_views;
CREATE POLICY "tod_proof_views: no client insert" ON public.tod_proof_views FOR INSERT WITH CHECK (false);

DROP POLICY IF EXISTS "tod_proof_views: no client update" ON public.tod_proof_views;
CREATE POLICY "tod_proof_views: no client update" ON public.tod_proof_views FOR UPDATE USING (false);

DROP POLICY IF EXISTS "tod_proof_views: own read" ON public.tod_proof_views;
CREATE POLICY "tod_proof_views: own read" ON public.tod_proof_views FOR SELECT USING ((auth.uid() = viewer_id));

GRANT ALL ON TABLE public.tod_proof_views TO anon;
GRANT ALL ON TABLE public.tod_proof_views TO authenticated;
GRANT ALL ON TABLE public.tod_proof_views TO service_role;

-- Custom visibility selection (specific players/spectators) and the
-- 'timed' replay mode were both fully modeled in the Dart client already
-- (TodProofVisibility.selectedPlayers / TodProofViewMode.timed) but had no
-- reachable DB value — this makes them selectable end-to-end.
ALTER TABLE public.room_settings
  ADD COLUMN IF NOT EXISTS proof_visibility_selected_user_ids uuid[] DEFAULT ARRAY[]::uuid[] NOT NULL;

ALTER TABLE public.room_settings
  DROP CONSTRAINT IF EXISTS room_settings_proof_visibility_policy_check;
ALTER TABLE public.room_settings
  ADD CONSTRAINT room_settings_proof_visibility_policy_check
    CHECK ((proof_visibility_policy = ANY (ARRAY['everyone'::text, 'players_only'::text, 'spectators_only'::text, 'selected'::text])));

ALTER TABLE public.room_settings
  DROP CONSTRAINT IF EXISTS room_settings_proof_replay_mode_check;
ALTER TABLE public.room_settings
  ADD CONSTRAINT room_settings_proof_replay_mode_check
    CHECK ((proof_replay_mode = ANY (ARRAY['once'::text, 'replay_once'::text, 'timed'::text])));

-- 0 is the new "unlimited until next round" sentinel (previously the
-- column only accepted a 2-30s finite duration).
ALTER TABLE public.room_settings
  DROP CONSTRAINT IF EXISTS room_settings_proof_view_seconds_check;
ALTER TABLE public.room_settings
  ADD CONSTRAINT room_settings_proof_view_seconds_check
    CHECK (((proof_view_seconds = 0) OR ((proof_view_seconds >= 2) AND (proof_view_seconds <= 30))));

-- record_proof_view: verifies membership + role-based visibility policy
-- (including the new 'selected' picker) before allowing a view, enforces
-- the replay cap server-side ('once'/'timed' → 1 view, 'replay_once' → 2,
-- +1 more for Premium viewers), and logs every actual view for a
-- tamper-proof count instead of trusting a client-reported flag.
CREATE OR REPLACE FUNCTION public.record_proof_view(p_session_id uuid, p_turn_started_at bigint) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_room_id uuid;
  v_role public.room_member_role_enum;
  v_policy text;
  v_replay_mode text;
  v_selected_ids uuid[];
  v_is_premium boolean;
  v_existing_count integer;
  v_max_views integer;
  v_view_number integer;
BEGIN
  SELECT room_id INTO v_room_id FROM public.game_sessions WHERE id = p_session_id;
  IF v_room_id IS NULL THEN
    RAISE EXCEPTION 'session_not_found';
  END IF;

  SELECT role INTO v_role FROM public.room_members
  WHERE room_id = v_room_id AND user_id = auth.uid() AND left_at IS NULL;
  IF v_role IS NULL THEN
    RAISE EXCEPTION 'not_a_member';
  END IF;

  SELECT proof_visibility_policy, proof_replay_mode, proof_visibility_selected_user_ids
    INTO v_policy, v_replay_mode, v_selected_ids
  FROM public.room_settings WHERE room_id = v_room_id;

  IF v_policy = 'players_only' AND v_role = 'spectator'::public.room_member_role_enum THEN
    RAISE EXCEPTION 'not_permitted';
  END IF;
  IF v_policy = 'spectators_only' AND v_role <> 'spectator'::public.room_member_role_enum THEN
    RAISE EXCEPTION 'not_permitted';
  END IF;
  IF v_policy = 'selected' AND NOT (auth.uid() = ANY(v_selected_ids)) THEN
    RAISE EXCEPTION 'not_permitted';
  END IF;

  SELECT is_premium INTO v_is_premium FROM public.profiles WHERE id = auth.uid();

  v_max_views := CASE
    WHEN v_replay_mode = 'replay_once' THEN 2 + (CASE WHEN v_is_premium THEN 1 ELSE 0 END)
    ELSE 1 -- 'once' or 'timed' — a single view, no replay
  END;

  SELECT count(*) INTO v_existing_count FROM public.tod_proof_views
  WHERE session_id = p_session_id AND turn_started_at = p_turn_started_at AND viewer_id = auth.uid();

  IF v_existing_count >= v_max_views THEN
    RAISE EXCEPTION 'view_limit_exceeded';
  END IF;

  v_view_number := v_existing_count + 1;

  INSERT INTO public.tod_proof_views (session_id, turn_started_at, viewer_id, view_number)
  VALUES (p_session_id, p_turn_started_at, auth.uid(), v_view_number);

  RETURN jsonb_build_object(
    'allowed', true,
    'viewNumber', v_view_number,
    'maxViews', v_max_views,
    'viewsRemaining', v_max_views - v_view_number
  );
END;
$$;

GRANT ALL ON FUNCTION public.record_proof_view(uuid, bigint) TO anon;
GRANT ALL ON FUNCTION public.record_proof_view(uuid, bigint) TO authenticated;
GRANT ALL ON FUNCTION public.record_proof_view(uuid, bigint) TO service_role;
