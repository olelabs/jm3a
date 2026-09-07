-- ============================================================================
-- Fixes the actual root cause of "the pause overlay disappears by itself
-- even though the host never returned":
--
--   rooms: FOR UPDATE USING (auth.uid() = owner_id)   -- schema.sql:6520
--
--   RoomProvider._pauseGameForHostDisconnect is, by definition, always
--   triggered by a BYSTANDER (a client other than the owner — the owner
--   obviously can't detect their own absence) calling
--   RoomRepository.updateStatus(room.id, RoomStatus.paused). That's a
--   plain `rooms.update()`, which RLS silently limits to 0 affected rows
--   for anyone but the current owner — no exception is raised, so the
--   call "succeeds" from the client's point of view while never actually
--   writing anything. The room only ever *looked* paused via the
--   ephemeral 'pause' broadcast each client applied to its own local
--   state (Realtime Broadcast has no delivery guarantee or replay) — the
--   underlying rooms.status never left 'in_game'. The next full refetch
--   on ANY client (the 5s reconcile poll, a reconnect, a missed broadcast
--   catching up) would read the true, never-actually-changed 'in_game'
--   value and silently revert the overlay — exactly the reported
--   "disappears by itself" symptom, and also why it was inconsistent
--   whether anyone even saw it in the first place (purely down to whether
--   their client happened to receive the one-shot broadcast).
--
--   Same pattern as force_end_game_if_owner_absent
--   (migration_2026_designated_closer_force_end.sql): a SECURITY DEFINER
--   RPC is the only way a non-owner can legitimately perform this write,
--   gated on re-deriving the owner's own absence server-side rather than
--   trusting the caller.
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

  -- Idempotent no-op: already paused (another bystander's call already
  -- won), or the game already ended/isn't running — nothing to pause.
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

  -- 20s = 2x the client heartbeat interval (touch_room_presence every
  -- 10s) — the same "more than one missed heartbeat" tolerance used
  -- everywhere else this project checks staleness, so a single slow
  -- write is never mistaken for a real disconnect.
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
END;
$$;

ALTER FUNCTION "public"."pause_game_if_owner_absent"("p_room_id" "uuid") OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."pause_game_if_owner_absent"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."pause_game_if_owner_absent"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pause_game_if_owner_absent"("p_room_id" "uuid") TO "service_role";
