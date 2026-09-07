-- ============================================================================
-- SUPERSEDED — do not apply this file separately. Its lifecycle_state
-- default and recover_owner_room timing basis had the same defects as
-- migration_2026_host_reconnect_pause.sql (see that file's own superseded
-- notice). Fully replaced by migration_2026_lifecycle_final.sql.
-- ============================================================================

-- ============================================================================
-- Lifecycle rebuild, applied after migration_2026_host_reconnect_pause.sql,
-- migration_2026_one_active_session_per_room.sql and
-- migration_2026_rejoin_requires_approval_always.sql.
--
-- Two independently-confirmed root causes, found by tracing actual RPC
-- calls against what the database actually defines (not assuming a call
-- "works" just because the client doesn't crash):
--
-- ============================================================================
-- ROOT CAUSE 1 — activate_game_session and confirm_game_session_ready do
-- not exist anywhere in this schema, and never have.
--
--   All 3 game providers/screens call `Supabase.rpc('activate_game_session',
--   ...)` the instant the ready barrier passes, and
--   `Supabase.rpc('confirm_game_session_ready', ...)` when a player readies
--   up. Neither function is defined by schema.sql or any migration file in
--   this repo. Every call has always been failing with a Postgrest
--   "function not found" error — silently: confirm_game_session_ready's
--   failure is caught and only logged; activate_game_session's failure is
--   caught by a `.then((_) {}, onError: (e) {})` that does nothing at all,
--   not even a log line.
--
--   Consequence: game_sessions.lifecycle_state is NEVER actually written
--   to 'active' by any mechanism — it only ever changes locally, in each
--   client's own in-memory `_lifecycleState` variable. Any client that has
--   to fall back to polling the database for `lifecycle_state = 'active'`
--   because it missed the live broadcast (NhieProvider._pollForSessionActive
--   and the equivalent in the other two games — this is the ONLY fallback
--   a reconnecting/late-arriving non-owner player has) polls 10 times over
--   30 seconds and then gives up with "Could not confirm the game started.
--   Please rejoin." This is the direct, previously-undiscovered mechanism
--   behind "players stuck loading, eventually kicked to browse rooms."
--
--   Fix: create both RPCs for real. activate_game_session is also the
--   correct, single hook for Root Cause 2 below, since it is the one
--   moment, on the owner's client only, when the ready barrier has
--   genuinely passed and the game has genuinely gone active.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."activate_game_session"("p_session_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_owner_id uuid;
  v_room_id uuid;
  v_pack_id uuid;
BEGIN
  SELECT owner_id, room_id, pack_id INTO v_owner_id, v_room_id, v_pack_id
  FROM public.game_sessions
  WHERE id = p_session_id
  FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'session_not_found';
  END IF;
  IF auth.uid() <> v_owner_id THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;

  UPDATE public.game_sessions
  SET lifecycle_state = 'active', updated_at = now()
  WHERE id = p_session_id;

  -- Root cause 2 (see migration header below): the pack is only ever
  -- committed as "played in this room" here — the one point in the whole
  -- lifecycle that's actually reached if and only if the ready barrier
  -- passed and the game genuinely went active.
  IF v_pack_id IS NOT NULL THEN
    INSERT INTO public.room_played_packs (room_id, pack_id)
    VALUES (v_room_id, v_pack_id)
    ON CONFLICT (room_id, pack_id) DO NOTHING;
  END IF;
END;
$$;

ALTER FUNCTION "public"."activate_game_session"("p_session_id" "uuid") OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."activate_game_session"("p_session_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."activate_game_session"("p_session_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."activate_game_session"("p_session_id" "uuid") TO "service_role";

-- confirm_game_session_ready: the actual ready-barrier bookkeeping already
-- happens client-side via broadcast (session_ready) plus the owner's own
-- in-memory tally — this RPC's only real job is to give every "confirm
-- ready" tap a genuine, non-silently-failing database round trip (a real
-- liveness/participation proof for the caller, on their own session row
-- only) instead of calling a function that has never existed.
CREATE OR REPLACE FUNCTION "public"."confirm_game_session_ready"("p_session_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_player_ids uuid[];
BEGIN
  SELECT player_ids INTO v_player_ids
  FROM public.game_sessions
  WHERE id = p_session_id AND status IN ('active', 'paused');

  IF v_player_ids IS NULL THEN
    RAISE EXCEPTION 'session_not_found';
  END IF;
  IF NOT (auth.uid() = ANY(v_player_ids)) THEN
    RAISE EXCEPTION 'not_a_participant';
  END IF;

  UPDATE public.game_sessions
  SET updated_at = now()
  WHERE id = p_session_id;
END;
$$;

ALTER FUNCTION "public"."confirm_game_session_ready"("p_session_id" "uuid") OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."confirm_game_session_ready"("p_session_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."confirm_game_session_ready"("p_session_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."confirm_game_session_ready"("p_session_id" "uuid") TO "service_role";


-- ============================================================================
-- ROOT CAUSE 2 — pack consumption is committed at Start-Game-button-press
-- time, fully decoupled from whether the game ever actually goes active.
--
--   start_game_session_checks (schema.sql:2292) INSERTs into
--   room_played_packs the moment "Start Game" is pressed and the pack
--   isn't already marked played — before create_game_session even runs,
--   before any game_sessions row exists, before the ready barrier, before
--   the game screen has even mounted. Any later failure (session creation,
--   navigation, ready-barrier timeout, host disconnect before active)
--   leaves the pack permanently unusable in that room with no rollback
--   path anywhere.
--
--   Fix: start_game_session_checks becomes a pure availability check —
--   the INSERT moves into activate_game_session above, the one point
--   that's only ever reached once the game genuinely went active.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."start_game_session_checks"("p_user_id" "uuid", "p_room_id" "uuid", "p_pack_id" "uuid", "p_is_premium" boolean) RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Pack-per-room check only — no longer records anything. See
  -- activate_game_session for where "played" is actually committed now.
  IF EXISTS (
    SELECT 1 FROM public.room_played_packs
    WHERE room_id = p_room_id AND pack_id = p_pack_id
  ) THEN
    RETURN 'pack_already_played';
  END IF;

  RETURN NULL; -- success
END;
$$;

ALTER FUNCTION "public"."start_game_session_checks"("p_user_id" "uuid", "p_room_id" "uuid", "p_pack_id" "uuid", "p_is_premium" boolean) OWNER TO "postgres";


-- ============================================================================
-- ROOT CAUSE 3 — the pause/resume window is anchored to rooms.last_active_at,
-- a general-purpose timestamp stamped by nearly every room write (any
-- updateStatus call, any moderation action), not a dedicated pause marker.
-- game_sessions already has paused_at and total_pause_ms columns for
-- exactly this purpose; they have never been written by anything. Move the
-- resume-vs-terminate decision onto them instead — a precise, single-
-- purpose signal tied to the actual paused session, not the room's most
-- recent unrelated write.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."pause_game_if_owner_absent"("p_room_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_owner_id uuid;
  v_owner_last_seen timestamptz;
  v_owner_left_at timestamptz;
  v_status public.room_status_enum;
  v_caller_is_member boolean;
BEGIN
  SELECT owner_id, status INTO v_owner_id, v_status
  FROM public.rooms WHERE id = p_room_id FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;

  IF v_status <> 'in_game'::public.room_status_enum THEN
    RETURN;
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
  WHERE room_id = p_room_id AND user_id = v_owner_id;

  IF v_owner_left_at IS NULL
     AND v_owner_last_seen IS NOT NULL
     AND v_owner_last_seen > now() - interval '20 seconds' THEN
    RAISE EXCEPTION 'owner_still_active';
  END IF;

  UPDATE public.rooms
  SET status = 'paused'::public.room_status_enum,
      last_active_at = now(),
      updated_at = now()
  WHERE id = p_room_id;

  -- The dedicated pause marker: the actual game state (round, scores,
  -- used cards, config) is untouched — only this timestamp records that a
  -- pause started, for recover_owner_room to measure precisely.
  UPDATE public.game_sessions
  SET paused_at = now()
  WHERE room_id = p_room_id AND status = 'active';
END;
$$;

ALTER FUNCTION "public"."pause_game_if_owner_absent"("p_room_id" "uuid") OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."pause_game_if_owner_absent"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."pause_game_if_owner_absent"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pause_game_if_owner_absent"("p_room_id" "uuid") TO "service_role";


CREATE OR REPLACE FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_created_by uuid;
  v_owner_id uuid;
  v_status public.room_status_enum;
  v_reclaimed boolean := false;
  v_terminated boolean := false;
  v_resumed boolean := false;
  v_session_id uuid;
  v_paused_at timestamptz;
BEGIN
  SELECT created_by, owner_id, status INTO v_created_by, v_owner_id, v_status
  FROM public.rooms
  WHERE id = p_room_id AND deleted_at IS NULL
  FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RETURN jsonb_build_object('reclaimed', false, 'game_terminated', false, 'resumed', false);
  END IF;

  IF v_created_by IS NOT NULL AND auth.uid() = v_created_by AND v_owner_id <> v_created_by THEN
    UPDATE public.rooms
    SET owner_id = v_created_by, owner_transferred_at = now()
    WHERE id = p_room_id;
    v_owner_id := v_created_by;
    v_reclaimed := true;
  END IF;

  IF auth.uid() = v_owner_id AND v_status = 'paused'::public.room_status_enum THEN
    SELECT id, paused_at INTO v_session_id, v_paused_at
    FROM public.game_sessions
    WHERE room_id = p_room_id AND status IN ('active', 'paused')
    ORDER BY started_at DESC
    LIMIT 1;

    -- 90s = the client's 60s countdown + a safety margin, so a client that
    -- already decided to end the game wins the race instead of having this
    -- resurrect the session out from under it. Anchored to the session's
    -- own paused_at (stamped once, precisely, by pause_game_if_owner_absent)
    -- rather than rooms.last_active_at, which is touched by unrelated
    -- writes and was never a reliable "when did the pause start" signal.
    -- A NULL paused_at (session row somehow missing, or paused via an
    -- older code path) falls through to the terminate branch rather than
    -- silently resuming with no basis for the decision.
    IF v_session_id IS NOT NULL
       AND v_paused_at IS NOT NULL
       AND v_paused_at > now() - interval '90 seconds' THEN
      UPDATE public.rooms
      SET status = 'in_game'::public.room_status_enum, last_active_at = now(), updated_at = now()
      WHERE id = p_room_id;

      UPDATE public.game_sessions
      SET paused_at = NULL,
          total_pause_ms = total_pause_ms + GREATEST(0, EXTRACT(EPOCH FROM (now() - v_paused_at)) * 1000)::bigint,
          updated_at = now()
      WHERE id = v_session_id;

      v_resumed := true;
    ELSE
      IF v_session_id IS NOT NULL THEN
        UPDATE public.game_sessions
        SET status = 'aborted', lifecycle_state = 'ended', paused_at = NULL, ended_at = now(), updated_at = now()
        WHERE id = v_session_id;
      END IF;

      UPDATE public.rooms
      SET status = 'waiting'::public.room_status_enum, last_active_at = now(), updated_at = now()
      WHERE id = p_room_id;

      UPDATE public.room_members
      SET is_ready = false
      WHERE room_id = p_room_id AND left_at IS NULL;

      v_terminated := true;
    END IF;
  END IF;
  -- status = 'in_game' (never paused, or the pause never got this far):
  -- intentionally left untouched — nothing to reconcile, the owner just
  -- resumes as a normal client from here.

  RETURN jsonb_build_object('reclaimed', v_reclaimed, 'game_terminated', v_terminated, 'resumed', v_resumed);
END;
$$;

ALTER FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") TO "service_role";


-- Consistency: every OTHER path that terminates a session now also clears
-- paused_at (nothing reads it once the session is terminal, but leaving a
-- stale non-null value around is exactly the kind of ambiguous state this
-- whole migration is trying to get rid of).

CREATE OR REPLACE FUNCTION "public"."force_end_game_if_owner_absent"("p_room_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_owner_id uuid;
  v_owner_last_seen timestamptz;
  v_owner_left_at timestamptz;
  v_status public.room_status_enum;
  v_caller_is_member boolean;
  v_session_id uuid;
BEGIN
  SELECT owner_id, status INTO v_owner_id, v_status
  FROM public.rooms WHERE id = p_room_id FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;

  IF v_status NOT IN ('in_game'::public.room_status_enum, 'paused'::public.room_status_enum) THEN
    RETURN;
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
  WHERE room_id = p_room_id AND user_id = v_owner_id;

  IF v_owner_left_at IS NULL
     AND v_owner_last_seen IS NOT NULL
     AND v_owner_last_seen > now() - interval '25 seconds' THEN
    RAISE EXCEPTION 'owner_still_active';
  END IF;

  SELECT id INTO v_session_id FROM public.game_sessions
  WHERE room_id = p_room_id AND status IN ('active', 'paused')
  LIMIT 1;

  IF v_session_id IS NOT NULL THEN
    UPDATE public.game_sessions
    SET status = 'aborted', lifecycle_state = 'ended', paused_at = NULL, ended_at = now(), updated_at = now()
    WHERE id = v_session_id;
  END IF;

  UPDATE public.rooms
  SET status = 'waiting'::public.room_status_enum,
      last_active_at = now(),
      updated_at = now(),
      pack_id = NULL
  WHERE id = p_room_id;

  UPDATE public.room_members
  SET is_ready = false
  WHERE room_id = p_room_id AND left_at IS NULL;
END;
$$;

ALTER FUNCTION "public"."force_end_game_if_owner_absent"("p_room_id" "uuid") OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."force_end_game_if_owner_absent"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."force_end_game_if_owner_absent"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."force_end_game_if_owner_absent"("p_room_id" "uuid") TO "service_role";


-- close_room is deliberately left permission-scoped to the real owner only
-- (auth.uid() = owner_id) and NOT additionally gated on the pause window —
-- the actual race this migration cares about (a bystander's stray
-- 'leave'/'player_left' broadcast reaction closing the room out from under
-- a resumable pause) can only ever be attempted by a bystander, who was
-- already going to fail this permission check regardless; gating on the
-- pause window here as well would also block a genuine, deliberate
-- "Leave Room" tap by the real owner during a still-resumable pause, which
-- is a real decision they're entitled to make. The actual fix for the
-- bystander race is client-side (RoomProvider._removeMember — it must
-- never even attempt this call on behalf of a bystander mid-pause). This
-- redefinition only adds the same state-consistency cleanup used
-- everywhere else a session is terminated.
CREATE OR REPLACE FUNCTION "public"."close_room"("p_room_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.rooms
    WHERE id = p_room_id AND owner_id = auth.uid() AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;

  UPDATE public.rooms
  SET status = 'closed', deleted_at = now(), updated_at = now()
  WHERE id = p_room_id AND deleted_at IS NULL;

  UPDATE public.game_sessions
  SET status = 'aborted', lifecycle_state = 'ended', paused_at = NULL, ended_at = now(), updated_at = now()
  WHERE room_id = p_room_id AND status IN ('active', 'paused');
END;
$$;

ALTER FUNCTION "public"."close_room"("p_room_id" "uuid") OWNER TO "postgres";
