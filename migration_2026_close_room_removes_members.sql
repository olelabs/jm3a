-- close_room(): actually remove members on a destructive room close
--
-- Root cause of "ghost members after the admin closes the room": close_room
-- marks the ROOM itself closed+deleted and aborts any live game_sessions,
-- but never touched room_members at all — unlike every sibling departure
-- path (kick_room_member, ban_room_member, and the plain leaveRoom update)
-- which all explicitly set left_at. Every other player/spectator's
-- room_members row was left with left_at IS NULL forever, even though the
-- room itself was gone — a real, persisted ghost membership, independent of
-- whether their client happened to receive the 'owner_left' realtime
-- broadcast that already drives their own immediate navigation-away.
--
-- Sets left_at only (not kicked_at) — this is not a kick/ban, so
-- kick_room_member/ban_room_member's own semantics and the closed-room
-- reactivation gate (which keys off kicked_at) are untouched.

BEGIN;

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
  SET status = 'aborted', ended_at = now(), updated_at = now()
  WHERE room_id = p_room_id AND status IN ('active', 'paused');

  UPDATE public.room_members
  SET left_at = now()
  WHERE room_id = p_room_id AND left_at IS NULL;
END;
$$;

ALTER FUNCTION "public"."close_room"("p_room_id" "uuid") OWNER TO "postgres";

COMMIT;
