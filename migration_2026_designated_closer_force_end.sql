-- ============================================================================
-- "Designated closer" support for host-reconnect timeout / <2-players
-- auto-end when the owner themselves is the one who's absent:
--
--   rooms: FOR UPDATE USING (auth.uid() = owner_id)   -- schema.sql:6520
--   game_sessions: FOR UPDATE USING (auth.uid() = owner_id)  -- schema.sql:5905
--
--   Both tables restrict UPDATE to the CURRENT owner. RoomProvider's
--   deterministic "designated closer" (a non-owner client that ends the
--   game when the owner never returns within the 60s pause window, or
--   when active players drop below 2 while the owner is disconnected) can
--   never satisfy that check directly — its own plain .update() calls
--   would silently affect 0 rows under RLS, leaving the room stuck
--   'paused'/'in_game' forever even though every client had already moved
--   on. This RPC is the one path a non-owner may use to perform that
--   specific, narrow write, gated on re-deriving the owner's own absence
--   server-side (same 25s heartbeat staleness pattern claim_room_ownership
--   already uses for its own emergency failover) — never trusting the
--   caller's own claim that the owner is gone.
-- ============================================================================

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

  -- Idempotent no-op: someone else (the owner reconnecting, or another
  -- designated-closer attempt that won the race) already resolved this.
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
  WHERE room_id = p_room_id AND status = 'active'
  LIMIT 1;

  IF v_session_id IS NOT NULL THEN
    UPDATE public.game_sessions
    SET status = 'aborted', lifecycle_state = 'ended', ended_at = now(), updated_at = now()
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
