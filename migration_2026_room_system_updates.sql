-- ============================================================================
-- Room system / lobby / game-start updates:
--   1. Min-players gate on Start Game — server-side defense-in-depth inside
--      create_game_session (client-side gate is Dart-only, lobby_screen.dart).
--   2. Pack gender-restriction indicator — Dart/client-only, no schema change.
--   3. Disable Start Game while players are reconnecting — same
--      create_game_session check as (1), reusing the same freshness predicate.
--   4. Join-request system for ongoing games:
--        a. decide_join_request / decide_spectator_request now perform the
--           room_members admission themselves (mirroring
--           decide_game_rejoin_request) instead of depending on a
--           follow-up client-side joinRoom() call, which ran under the
--           MODERATOR's own session and was rejected by RLS for any
--           brand-new target user — a real, previously-unnoticed bug this
--           also fixes.
--        b. "room_members: self insert" RLS narrowed so a brand-new
--           stranger can no longer self-insert into an in_game room,
--           closing the client bypass now that every legitimate admission
--           path runs through a SECURITY DEFINER function.
--   5. Pre-flight duplicate-room check — Dart/client-only (already mostly
--      implemented), no schema change.
-- ============================================================================


-- ── 4a. decide_join_request — atomic room_members admission on approval ────

CREATE OR REPLACE FUNCTION "public"."decide_join_request"("p_request_id" "uuid", "p_approve" boolean) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_room_id uuid;
  v_user_id uuid;
  v_row_exists boolean;
  v_max_players smallint;
  v_active_count integer;
  v_seat_order integer;
BEGIN
  SELECT room_id, user_id INTO v_room_id, v_user_id
  FROM public.room_join_requests WHERE id = p_request_id AND status = 'pending';
  IF v_room_id IS NULL THEN
    RAISE EXCEPTION 'request_not_found';
  END IF;
  IF NOT public.has_room_permission(v_room_id, auth.uid(), 'accept_joins') THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;

  IF p_approve THEN
    SELECT max_players INTO v_max_players FROM public.rooms WHERE id = v_room_id;
    SELECT count(*) INTO v_active_count FROM public.room_members
    WHERE room_id = v_room_id AND left_at IS NULL
      AND role <> 'spectator'::public.room_member_role_enum
      AND user_id <> v_user_id;
    IF v_active_count >= v_max_players THEN
      RAISE EXCEPTION 'room_full';
    END IF;
  END IF;

  UPDATE public.room_join_requests
  SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
      resolved_at = now()
  WHERE id = p_request_id;

  IF p_approve THEN
    SELECT EXISTS (
      SELECT 1 FROM public.room_members WHERE room_id = v_room_id AND user_id = v_user_id
    ) INTO v_row_exists;

    IF v_row_exists THEN
      UPDATE public.room_members
      SET left_at = NULL, kicked_at = NULL, left_definitively = false, is_away = false
      WHERE room_id = v_room_id AND user_id = v_user_id;
    ELSE
      SELECT count(*) INTO v_seat_order FROM public.room_members
      WHERE room_id = v_room_id AND left_at IS NULL;

      INSERT INTO public.room_members
        (room_id, user_id, seat_order, role, is_hidden_spectator, is_ready, left_at, joined_at)
      VALUES
        (v_room_id, v_user_id, v_seat_order, 'player', false, false, NULL, now());
    END IF;
  END IF;
END;
$$;


-- ── 4a. decide_spectator_request — same rationale as decide_join_request ───

CREATE OR REPLACE FUNCTION "public"."decide_spectator_request"("p_request_id" "uuid", "p_approve" boolean) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_room_id uuid;
  v_user_id uuid;
  v_row_exists boolean;
  v_seat_order integer;
BEGIN
  SELECT room_id, user_id INTO v_room_id, v_user_id
  FROM public.spectator_requests WHERE id = p_request_id AND status = 'pending';
  IF v_room_id IS NULL THEN
    RAISE EXCEPTION 'request_not_found';
  END IF;
  IF NOT public.has_room_permission(v_room_id, auth.uid(), 'accept_spectators') THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;

  UPDATE public.spectator_requests
  SET status = CASE WHEN p_approve THEN 'approved' ELSE 'denied' END,
      decided_by = auth.uid(),
      decided_at = now()
  WHERE id = p_request_id;

  IF p_approve THEN
    SELECT EXISTS (
      SELECT 1 FROM public.room_members WHERE room_id = v_room_id AND user_id = v_user_id
    ) INTO v_row_exists;

    IF v_row_exists THEN
      UPDATE public.room_members
      SET left_at = NULL, kicked_at = NULL, left_definitively = false, is_away = false,
          role = 'spectator'
      WHERE room_id = v_room_id AND user_id = v_user_id;
    ELSE
      SELECT count(*) INTO v_seat_order FROM public.room_members
      WHERE room_id = v_room_id AND left_at IS NULL;

      INSERT INTO public.room_members
        (room_id, user_id, seat_order, role, is_hidden_spectator, is_ready, left_at, joined_at)
      VALUES
        (v_room_id, v_user_id, v_seat_order, 'spectator', false, false, NULL, now());
    END IF;
  END IF;
END;
$$;


-- ── 1/3. create_game_session — min-players + no-reconnecting server check ──
-- Defense-in-depth: the room already flips to in_game before this RPC runs
-- (lobby_screen.dart's _onStartGame broadcasts and flips status first, then
-- the game screen calls this), matching the pre-existing pack_already_played
-- precedent — this stops the session (and thus the actual game) from being
-- created, but isn't a true pre-flight block without restructuring that
-- call sequence.

CREATE OR REPLACE FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
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


-- ── 4b. Narrow room_members self-insert RLS for in_game rooms ──────────────
-- Every legitimate admission path for an in_game room now runs inside a
-- SECURITY DEFINER function (decide_join_request, decide_spectator_request,
-- decide_game_rejoin_request), which bypasses RLS entirely, so nothing
-- currently-working depends on this policy allowing a brand-new self-insert
-- into an in_game room.

DROP POLICY IF EXISTS "room_members: self insert" ON "public"."room_members";

CREATE POLICY "room_members: self insert" ON "public"."room_members" FOR INSERT WITH CHECK ((("auth"."uid"() = "user_id") AND (NOT (EXISTS ( SELECT 1
   FROM "public"."room_bans"
  WHERE (("room_bans"."room_id" = "room_members"."room_id") AND ("room_bans"."user_id" = "auth"."uid"()) AND ("room_bans"."lifted_at" IS NULL) AND (("room_bans"."banned_until" IS NULL) OR ("room_bans"."banned_until" > "now"())))))) AND (EXISTS ( SELECT 1
   FROM "public"."rooms"
  WHERE (("rooms"."id" = "room_members"."room_id") AND ("rooms"."deleted_at" IS NULL) AND ("rooms"."status" <> 'closed'::"public"."room_status_enum") AND (("rooms"."status" <> 'in_game'::"public"."room_status_enum") OR ("rooms"."owner_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
           FROM "public"."room_members" "rm2"
          WHERE (("rm2"."room_id" = "rooms"."id") AND ("rm2"."user_id" = "auth"."uid"()))))))))));
