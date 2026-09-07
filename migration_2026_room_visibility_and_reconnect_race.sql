-- ============================================================================
-- migration_2026_room_visibility_and_reconnect_race.sql
--
-- Three independently-confirmed root causes, found by tracing the actual
-- live PGRST116 crash log against the live RLS policies (verified via the
-- SQL Editor, not assumed from any file), against the actual timing of
-- recover_owner_room vs. the presence-heartbeat write, and against the
-- live create_game_session overloads (also verified via the SQL Editor).
--
-- Applies AFTER migration_2026_lifecycle_final.sql (already confirmed live
-- and correct — this file only adds to it, does not re-touch anything it
-- already fixed correctly). Idempotent: DROP POLICY IF EXISTS + CREATE
-- POLICY, CREATE OR REPLACE FUNCTION throughout. Safe to run twice.
-- ============================================================================


-- ============================================================================
-- ROOT CAUSE 1 (PGRST116) — "rooms: read" RLS requires is_room_member(),
-- which requires room_members.left_at IS NULL. For a PRIVATE room, a
-- returning player whose row was genuinely evicted by the disconnect
-- grace-period timeout (left_at correctly set, per the deliberate
-- "defer to rejoin-approval instead of silently reviving membership"
-- design in RoomProvider.initialize()'s skipAutoJoin gate) loses ALL
-- visibility of the rooms row itself — not just game/session data, the
-- room row. getRoomWithDetails' `.single()` call on rooms returns exactly
-- 0 rows, PostgREST raises PGRST116, and this app's ErrorHandler
-- unconditionally maps PGRST116 to NotFoundFailure with the comment
-- "exactly 0 rows" == "the room is gone" — which is exactly the false
-- inference the room genuinely being gone is the ONLY interpretation
-- warns against. The room was never gone; this specific player just
-- couldn't see it under RLS. RoomProvider._handleRoomNoLongerExists then
-- fires a fallback 'roomClosed' event purely from this client's own
-- inability to see the room — never broadcast to anyone else, but it
-- reliably explains "the expected reconnect/rejoin behavior is not
-- working" and "players remain stuck on the loading screen and then get
-- returned to the lobby in a loop" (initialize() fails outright with
-- NotFoundFailure before the lobby/rejoin-banner UI can even render, and
-- retrying does nothing because left_at is never cleared by this path —
-- clearing it is exactly what skipAutoJoin was built to defer until
-- explicit admin approval).
--
-- Fix: grant read visibility on rooms, in addition to the existing
-- is_room_member/public/invite branches, to anyone who is a participant
-- (auth.uid() = ANY(player_ids)) of the room's CURRENT active/paused
-- session — regardless of their room_members.left_at. This is the exact
-- same eligibility concept request_game_rejoin already enforces
-- server-side before actually filing a request (see schema.sql's
-- request_game_rejoin), and the exact same predicate game_sessions' own
-- "game_sessions: room member read" RLS policy already uses
-- (auth.uid() = ANY(player_ids)) — not a new concept, just extending an
-- already-blessed one to the one table that was missing it. A stranger
-- who was never in the session, or whose session has fully ended, gains
-- nothing from this branch. Wrapped in a SECURITY DEFINER STABLE helper
-- (matching is_room_member's own pattern) so this EXISTS check never
-- re-triggers RLS-on-RLS recursion.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."is_current_session_participant"("p_room_id" "uuid", "p_user_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET search_path = public
    AS $$
  select exists (
    select 1 from public.game_sessions
    where room_id = p_room_id
      and status in ('active', 'paused')
      and p_user_id = any(player_ids)
  );
$$;

ALTER FUNCTION "public"."is_current_session_participant"("p_room_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";

DROP POLICY IF EXISTS "rooms: read" ON "public"."rooms";
CREATE POLICY "rooms: read" ON "public"."rooms" FOR SELECT USING (
  (("auth"."role"() = 'authenticated'::"text") AND ("deleted_at" IS NULL) AND (
    ("visibility" = 'public'::"public"."room_visibility_enum")
    OR "public"."is_room_member"("id", "auth"."uid"())
    OR (EXISTS ( SELECT 1
       FROM "public"."room_invites"
      WHERE (("room_invites"."room_id" = "rooms"."id") AND ("room_invites"."invited_user" = "auth"."uid"()) AND ("room_invites"."accepted_at" IS NULL) AND ("room_invites"."declined_at" IS NULL) AND ("room_invites"."expires_at" > "now"()))))
    OR "public"."is_current_session_participant"("id", "auth"."uid"())
  ))
);


-- ============================================================================
-- ROOT CAUSE 2 — a race between an owner's successful reconnect and their
-- OWN presence heartbeat refresh.
--
--   RoomProvider.initialize() calls recover_owner_room() very early (before
--   getRoomApprovalInfo, before joinRoom, before getRoomWithDetails) — but
--   only calls _trackOwnPresence() (which stamps room_members.last_seen_at
--   via touch_room_presence) much later, after several more awaited
--   round-trips. In between, the owner's OWN last_seen_at is still the
--   STALE, pre-disconnect value.
--
--   force_end_game_if_owner_absent treats BOTH 'in_game' and 'paused' as
--   valid targets to abort (by design — a designated-closer's timer could
--   legitimately fire while still 'paused'). Its own safety check
--   (v_owner_last_seen > now() - interval '25 seconds' => reject) is
--   supposed to be the single authoritative guard against ending a game
--   the owner already resumed — but it reads the SAME stale last_seen_at
--   recover_owner_room hasn't refreshed yet. If a designated-closer
--   bystander's independently-running local timer fires inside this
--   window — after the owner's recover_owner_room call has already
--   resumed the session (rooms.status back to 'in_game'), but before that
--   owner's own _trackOwnPresence() call several awaits later has landed —
--   force_end_game_if_owner_absent's staleness check incorrectly still
--   passes, and it aborts the session that was already legitimately
--   resumed. This is exactly "sometimes the game ends before the expected
--   60-second timeout" (non-deterministic: depends on which of the two
--   independent async chains — the owner's own remaining initialize()
--   awaits, or a bystander's local timer — happens to land first) and
--   directly explains "the admin enters the room lobby and the other
--   players get kicked out to the lobby" (the resume the admin's own
--   client just applied gets undone moments later, and every client's
--   next 5s reconciliation tick correctly, but confusingly, converges on
--   the now-actually-aborted state).
--
--   Fix: recover_owner_room stamps the owner's OWN last_seen_at, in the
--   SAME transaction, the moment it confirms auth.uid() is genuinely the
--   room's owner — closing the race at its source instead of trying to
--   make the client-side timing race "less likely". A successful,
--   authenticated call to this function IS proof of presence; there is no
--   reason to wait for a separate, later heartbeat call to establish that.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET search_path = public
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
  v_row_count integer;
  v_state text;
BEGIN
  SELECT created_by, owner_id, status INTO v_created_by, v_owner_id, v_status
  FROM public.rooms
  WHERE id = p_room_id AND deleted_at IS NULL
  FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RETURN jsonb_build_object('reclaimed', false, 'game_terminated', false, 'resumed', false, 'state', 'room_not_found');
  END IF;

  IF v_created_by IS NOT NULL AND auth.uid() = v_created_by AND v_owner_id <> v_created_by THEN
    UPDATE public.rooms
    SET owner_id = v_created_by, owner_transferred_at = now()
    WHERE id = p_room_id;
    v_owner_id := v_created_by;
    v_reclaimed := true;
  END IF;

  IF auth.uid() <> v_owner_id THEN
    RETURN jsonb_build_object(
      'reclaimed', v_reclaimed, 'game_terminated', false, 'resumed', false,
      'state', CASE WHEN v_status = 'paused'::public.room_status_enum THEN 'not_owner' ELSE 'no_op' END
    );
  END IF;

  -- Root cause 2 fix: a successful call past this point is definitive
  -- proof the real owner is back, independent of whether their own
  -- separate heartbeat call has landed yet. Stamped unconditionally here
  -- (not only in the resume branch below) so it also protects the
  -- ordinary "reconnect while merely in_game, nothing to resume" path,
  -- and the designated-closer race window is closed the instant this
  -- function returns, not several client-side awaits later.
  UPDATE public.room_members
  SET last_seen_at = now()
  WHERE room_id = p_room_id AND user_id = v_owner_id;

  IF v_status <> 'paused'::public.room_status_enum THEN
    v_state := CASE v_status
      WHEN 'in_game'::public.room_status_enum THEN 'already_in_game'
      WHEN 'waiting'::public.room_status_enum THEN 'already_waiting'
      ELSE 'no_op'
    END;
    RETURN jsonb_build_object('reclaimed', v_reclaimed, 'game_terminated', false, 'resumed', false, 'state', v_state);
  END IF;

  SELECT id, paused_at INTO v_session_id, v_paused_at
  FROM public.game_sessions
  WHERE room_id = p_room_id AND status IN ('active', 'paused')
  ORDER BY started_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_session_id IS NOT NULL
     AND v_paused_at IS NOT NULL
     AND v_paused_at > now() - interval '90 seconds' THEN
    UPDATE public.rooms
    SET status = 'in_game'::public.room_status_enum, last_active_at = now(), updated_at = now()
    WHERE id = p_room_id;
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    IF v_row_count <> 1 THEN
      RAISE EXCEPTION 'recover_owner_room: resume expected 1 room row updated, got % (room_id=%)', v_row_count, p_room_id;
    END IF;

    UPDATE public.game_sessions
    SET paused_at = NULL,
        total_pause_ms = total_pause_ms + GREATEST(0, EXTRACT(EPOCH FROM (now() - v_paused_at)) * 1000)::bigint,
        updated_at = now()
    WHERE id = v_session_id;
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    IF v_row_count <> 1 THEN
      RAISE EXCEPTION 'recover_owner_room: resume expected 1 session row updated, got % (session_id=%)', v_row_count, v_session_id;
    END IF;

    v_resumed := true;
    v_state := 'resumed';
  ELSE
    IF v_session_id IS NOT NULL THEN
      UPDATE public.game_sessions
      SET status = 'aborted', lifecycle_state = 'ended', paused_at = NULL, ended_at = now(), updated_at = now()
      WHERE id = v_session_id;
    END IF;

    UPDATE public.rooms
    SET status = 'waiting'::public.room_status_enum, last_active_at = now(), updated_at = now(), pack_id = NULL
    WHERE id = p_room_id;
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    IF v_row_count <> 1 THEN
      RAISE EXCEPTION 'recover_owner_room: terminate expected 1 room row updated, got % (room_id=%)', v_row_count, p_room_id;
    END IF;

    UPDATE public.room_members
    SET is_ready = false
    WHERE room_id = p_room_id AND left_at IS NULL;

    v_terminated := true;
    v_state := 'ended';
  END IF;

  RETURN jsonb_build_object(
    'reclaimed', v_reclaimed, 'game_terminated', v_terminated, 'resumed', v_resumed,
    'state', v_state, 'session_id', v_session_id
  );
END;
$$;

ALTER FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") TO "service_role";


-- ============================================================================
-- ROOT CAUSE 3 — ToD calls a DIFFERENT, NOT race-safe overload of
-- create_game_session than NHIE/Meme.
--
--   Confirmed live: two overloads of create_game_session exist —
--     (..., p_state_snapshot jsonb DEFAULT)                     -- 9-param
--     (..., p_state_snapshot jsonb DEFAULT, p_config jsonb DEFAULT) -- 10-param
--   Only the 9-param overload has the unique_violation exception handler
--   (added by migration_2026_lifecycle_final.sql / migration_2026_one_
--   active_session_per_room.sql) protecting against
--   idx_game_sessions_one_active_per_room. NHIE and Meme's Dart call sites
--   pass exactly the 9-param overload's parameter names, so they
--   unambiguously resolve to the safe one.
--
--   TodRepository.createSession (tod_repository.dart) passes 'p_config',
--   which is not a parameter of the 9-param overload at all — a named
--   argument that doesn't match any parameter of a candidate function
--   disqualifies that candidate from PostgreSQL's overload resolution, so
--   ToD's call can ONLY ever resolve to the 10-param overload, which has
--   no such protection: a genuine race (double-tap Start Game, a retried
--   request) would raise a raw, unhandled unique_violation instead of
--   transparently joining the session that won — for ToD only, violating
--   the "at most one active/paused session per room, enforced by the
--   application too, not just the index" requirement specifically for
--   this game.
--
--   Fix: give the 10-param overload the exact same protection, rather
--   than removing p_config from ToD's call — the `config` column is what
--   ToD's own findActiveSession/findLatestSession restore full game
--   config from on reconnect (a real, working feature; NHIE/Meme don't
--   use it and don't need to be touched).
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb" DEFAULT '{}'::"jsonb", "p_config" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET search_path = public
    AS $$
DECLARE
  v_id uuid;
  v_min_players smallint;
  v_eligible_count integer;
BEGIN
  IF NOT public.is_room_owner(p_room_id, auth.uid()) THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;

  IF p_pack_id IS NOT NULL THEN
    SELECT min_players INTO v_min_players FROM public.packs WHERE id = p_pack_id;
    IF v_min_players IS NOT NULL THEN
      SELECT count(*) INTO v_eligible_count FROM public.room_members
      WHERE room_id = p_room_id AND left_at IS NULL
        AND role <> 'spectator'::public.room_member_role_enum
        AND last_seen_at > now() - interval '25 seconds';
      IF v_eligible_count < v_min_players THEN
        RAISE EXCEPTION 'not_enough_players';
      END IF;
    END IF;
  END IF;

  BEGIN
    INSERT INTO public.game_sessions (
      room_id, pack_id, game_type, owner_id, player_ids, state_snapshot,
      max_rounds, turn_timer_secs, allow_skip, allow_spicy, config, status,
      lifecycle_state
    ) VALUES (
      p_room_id, p_pack_id, p_game_type::public.game_type_enum, auth.uid(), p_player_ids, p_state_snapshot,
      p_max_rounds, p_turn_timer_secs, p_allow_skip, p_allow_spicy, p_config, 'active',
      'starting'
    )
    RETURNING id INTO v_id;
  EXCEPTION
    WHEN unique_violation THEN
      -- Lost the race against a concurrent create_game_session call (either
      -- overload — both write the same room_id/status columns the unique
      -- index covers) for this same room — join the session that actually
      -- won instead of erroring the caller out.
      SELECT id INTO v_id FROM public.game_sessions
      WHERE room_id = p_room_id AND status IN ('active', 'paused')
      ORDER BY started_at DESC
      LIMIT 1;
  END;

  IF v_id IS NULL THEN
    RAISE EXCEPTION 'create_game_session: no session id resolved for room %', p_room_id;
  END IF;

  RETURN v_id;
END;
$$;

ALTER FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb", "p_config" "jsonb") OWNER TO "postgres";
