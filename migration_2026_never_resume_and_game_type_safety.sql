-- ============================================================================
-- migration_2026_never_resume_and_game_type_safety.sql
--
-- Applies AFTER migration_2026_lifecycle_final.sql and
-- migration_2026_room_visibility_and_reconnect_race.sql (both already
-- live/applied). Two independent, deliberately minimal changes:
--
--   1. recover_owner_room: the resume-on-reconnect behavior is REMOVED by
--      product decision (not a bug fix) — an owner reconnecting to a
--      paused room now always terminates the existing session cleanly,
--      never resumes it. Everything else about this function (reclaim,
--      lock ordering, row-count verification, the owner's own last_seen_at
--      stamp) is untouched.
--
--   2. create_game_session (both overloads): the unique_violation fallback
--      — reached when a concurrent/retried call collides with
--      idx_game_sessions_one_active_per_room — previously returned
--      whatever active/paused session existed for the room regardless of
--      its game_type. If that colliding session belongs to a DIFFERENT
--      game type (e.g. a still-active Truth or Dare session from before,
--      while starting NHIE), the caller was silently hijacked onto the
--      wrong session — the actual, confirmed root cause of "starting game
--      #2 gets stuck loading, then bounces to lobby". The fallback now
--      only returns a same-game_type collision (preserving the existing,
--      correct "transparently join the session that already won" behavior
--      for a genuine double-tap/retry of the SAME game); a different-
--      game_type collision now raises a distinct, deterministic exception
--      instead of ever handing back the wrong session id.
--
-- idx_game_sessions_one_active_per_room itself is NOT touched — the
-- one-active-session invariant is unchanged, only which row a same-room
-- collision is allowed to resolve to. No data is deleted or modified;
-- CREATE OR REPLACE FUNCTION only, both signatures byte-identical to their
-- live counterparts so existing grants are preserved. Idempotent — safe to
-- run twice.
-- ============================================================================


-- ============================================================================
-- PART 1 — recover_owner_room: never resume, always terminate cleanly.
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
  v_session_id uuid;
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

  -- A successful call past this point is definitive proof the real owner
  -- is back — kept from the presence-race fix even though resume no
  -- longer exists, since this also protects the ordinary
  -- "reconnect while merely in_game" path from a stale-presence force-end.
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

  -- Product decision: an owner reconnecting to a paused room ALWAYS
  -- terminates the existing session cleanly — resume is intentionally no
  -- longer offered, regardless of paused_at/how long the pause has run.
  -- No path in this function ever creates a new game_sessions row.
  SELECT id INTO v_session_id
  FROM public.game_sessions
  WHERE room_id = p_room_id AND status IN ('active', 'paused')
  ORDER BY started_at DESC
  LIMIT 1
  FOR UPDATE;

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

  RETURN jsonb_build_object(
    'reclaimed', v_reclaimed, 'game_terminated', v_terminated, 'resumed', false,
    'state', v_state, 'session_id', v_session_id
  );
END;
$$;

ALTER FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") TO "service_role";


-- ============================================================================
-- PART 2 — create_game_session (9-param overload): game_type-aware
-- unique_violation fallback.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET search_path = public
    AS $$
DECLARE
  v_id uuid;
  v_min_players smallint;
  v_eligible_count integer;
  v_existing_game_type public.game_type_enum;
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
      max_rounds, turn_timer_secs, allow_skip, allow_spicy, status
    ) VALUES (
      p_room_id, p_pack_id, p_game_type::public.game_type_enum, auth.uid(), p_player_ids, p_state_snapshot,
      p_max_rounds, p_turn_timer_secs, p_allow_skip, p_allow_spicy, 'active'
    )
    RETURNING id INTO v_id;
  EXCEPTION
    WHEN unique_violation THEN
      -- Only ever transparently join a colliding session of the SAME game
      -- type (a genuine double-tap/retry of this same start) — a
      -- different game_type means a stale session from an earlier,
      -- unrelated game is still active/paused for this room, which must
      -- never be silently handed back as if it were the requested game.
      SELECT id, game_type INTO v_id, v_existing_game_type
      FROM public.game_sessions
      WHERE room_id = p_room_id AND status IN ('active', 'paused')
      ORDER BY started_at DESC
      LIMIT 1;

      IF v_existing_game_type IS DISTINCT FROM p_game_type::public.game_type_enum THEN
        RAISE EXCEPTION 'different_game_type_active'
          USING DETAIL = format('An active/paused %s session already exists for this room.', v_existing_game_type),
                HINT = 'The previous game must fully end before a different game type can start.';
      END IF;
  END;

  IF v_id IS NULL THEN
    RAISE EXCEPTION 'create_game_session: no session id resolved for room %', p_room_id;
  END IF;

  RETURN v_id;
END;
$$;

ALTER FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb") OWNER TO "postgres";


-- ============================================================================
-- PART 3 — create_game_session (10-param overload, adds p_config): same
-- game_type-aware fallback. Used by ToD (TodRepository.createSession).
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb" DEFAULT '{}'::"jsonb", "p_config" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET search_path = public
    AS $$
DECLARE
  v_id uuid;
  v_min_players smallint;
  v_eligible_count integer;
  v_existing_game_type public.game_type_enum;
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
      SELECT id, game_type INTO v_id, v_existing_game_type
      FROM public.game_sessions
      WHERE room_id = p_room_id AND status IN ('active', 'paused')
      ORDER BY started_at DESC
      LIMIT 1;

      IF v_existing_game_type IS DISTINCT FROM p_game_type::public.game_type_enum THEN
        RAISE EXCEPTION 'different_game_type_active'
          USING DETAIL = format('An active/paused %s session already exists for this room.', v_existing_game_type),
                HINT = 'The previous game must fully end before a different game type can start.';
      END IF;
  END;

  IF v_id IS NULL THEN
    RAISE EXCEPTION 'create_game_session: no session id resolved for room %', p_room_id;
  END IF;

  RETURN v_id;
END;
$$;

ALTER FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb", "p_config" "jsonb") OWNER TO "postgres";
