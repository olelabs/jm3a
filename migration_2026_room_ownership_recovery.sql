-- ============================================================================
-- Room ownership recovery after app restart:
--   1. rooms.created_by — new, immutable "original creator" identity,
--      distinct from the mutable owner_id used everywhere for CURRENT host
--      permissions. Lets a returning creator deterministically reclaim
--      ownership even after an automatic failover already reassigned it.
--   2. create_room now sets created_by alongside owner_id.
--   3. claim_room_ownership's staleness re-check lengthened from 25s to 3
--      minutes — a briefly force-quit owner must never lose the room to
--      the emergency failover; a genuinely abandoned room still recovers,
--      just after a longer wait.
--   4. recover_owner_room — new RPC, called by RoomProvider.initialize()
--      before any other room-state gate. Reclaims ownership for the
--      original creator if needed, and gracefully terminates a stale
--      mid-game session (aborts the dangling game_sessions row, resets
--      rooms.status to 'waiting', resets room_members.is_ready) so a
--      returning owner lands on a normal lobby instead of silently
--      resuming a partially-running game. pack_id/room_settings/
--      moderators are intentionally untouched.
-- ============================================================================


-- ── 1. rooms.created_by ─────────────────────────────────────────────────────

ALTER TABLE public.rooms ADD COLUMN IF NOT EXISTS created_by uuid;

-- Best-effort backfill for existing rooms — no creation-history is tracked
-- today, so the current owner is the closest available approximation.
UPDATE public.rooms SET created_by = owner_id WHERE created_by IS NULL;


-- ── 2. create_room — set created_by ─────────────────────────────────────────

CREATE OR REPLACE FUNCTION "public"."create_room"(
    "p_name" "text",
    "p_visibility" "text" DEFAULT 'public',
    "p_max_players" smallint DEFAULT NULL,
    "p_language" "text" DEFAULT 'en',
    "p_cover_emoji" "text" DEFAULT '🎮'
) RETURNS "public"."rooms"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_tier text;
  v_cap smallint;
  v_requested smallint;
  v_room public.rooms;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext(auth.uid()::text));

  IF EXISTS (
    SELECT 1 FROM public.rooms
    WHERE owner_id = auth.uid()
      AND status IN ('waiting', 'in_game', 'paused')
      AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'already_has_open_room';
  END IF;

  SELECT premium_tier INTO v_tier
  FROM public.profiles
  WHERE id = auth.uid() AND is_premium = true AND deleted_at IS NULL;

  v_cap := CASE v_tier
    WHEN 'premium_plus' THEN 12
    WHEN 'premium' THEN 8
    ELSE 3
  END;

  v_requested := COALESCE(p_max_players, v_cap);
  IF v_requested > v_cap THEN
    RAISE EXCEPTION 'max_players_exceeds_tier_cap';
  END IF;
  IF v_requested < 2 THEN
    v_requested := 2;
  END IF;

  INSERT INTO public.rooms (owner_id, created_by, name, visibility, max_players, language, cover_emoji, status)
  VALUES (
    auth.uid(), auth.uid(), p_name, p_visibility::public.room_visibility_enum,
    v_requested, p_language, p_cover_emoji, 'waiting'
  )
  RETURNING * INTO v_room;

  INSERT INTO public.room_members (room_id, user_id, seat_order, role)
  VALUES (v_room.id, auth.uid(), 0, 'player'::public.room_member_role_enum)
  ON CONFLICT (room_id, user_id) DO NOTHING;

  RETURN v_room;
END;
$$;


-- ── 3. claim_room_ownership — lengthen staleness threshold to 3 minutes ────

CREATE OR REPLACE FUNCTION "public"."claim_room_ownership"("p_room_id" "uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
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

  IF v_owner_left_at IS NULL
     AND v_owner_last_seen IS NOT NULL
     AND v_owner_last_seen > now() - interval '3 minutes' THEN
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


-- ── 4. recover_owner_room — new RPC ─────────────────────────────────────────

CREATE OR REPLACE FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_created_by uuid;
  v_owner_id uuid;
  v_status public.room_status_enum;
  v_reclaimed boolean := false;
  v_terminated boolean := false;
  v_session_id uuid;
BEGIN
  SELECT created_by, owner_id, status INTO v_created_by, v_owner_id, v_status
  FROM public.rooms
  WHERE id = p_room_id AND deleted_at IS NULL
  FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RETURN jsonb_build_object('reclaimed', false, 'game_terminated', false);
  END IF;

  IF v_created_by IS NOT NULL AND auth.uid() = v_created_by AND v_owner_id <> v_created_by THEN
    UPDATE public.rooms
    SET owner_id = v_created_by, owner_transferred_at = now()
    WHERE id = p_room_id;
    v_owner_id := v_created_by;
    v_reclaimed := true;
  END IF;

  IF auth.uid() = v_owner_id AND v_status IN ('in_game', 'paused') THEN
    SELECT id INTO v_session_id FROM public.game_sessions
    WHERE room_id = p_room_id AND status IN ('active', 'paused')
    ORDER BY started_at DESC
    LIMIT 1;

    IF v_session_id IS NOT NULL THEN
      UPDATE public.game_sessions
      SET status = 'aborted', ended_at = now(), updated_at = now()
      WHERE id = v_session_id;
    END IF;

    UPDATE public.rooms
    SET status = 'waiting', last_active_at = now(), updated_at = now()
    WHERE id = p_room_id;

    UPDATE public.room_members
    SET is_ready = false
    WHERE room_id = p_room_id AND left_at IS NULL;

    v_terminated := true;
  END IF;

  RETURN jsonb_build_object('reclaimed', v_reclaimed, 'game_terminated', v_terminated);
END;
$$;

ALTER FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") OWNER TO "postgres";
