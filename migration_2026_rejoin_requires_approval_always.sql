-- ============================================================================
-- "Never automatically re-enter a normal player" (hard requirement):
--
--   request_game_rejoin previously raised 'already_in_room' and refused to
--   file a request whenever the caller's room_members row was still intact
--   — the existing design's own rule was "an intact row reconnects
--   instantly, only a genuinely evicted row needs host approval". That
--   rule is deliberately overridden now: EVERY non-owner reconnecting to a
--   room whose game is already in_game/paused must go through explicit
--   admin/mod approval, with no exception for "the row just happened to
--   still be there" (a weak disconnect presence never caught, an app
--   backgrounded briefly, etc.) — only the room owner's own separate
--   host-reconnect-pause mechanism is exempt, and that path never calls
--   this RPC at all.
--
--   The Flutter side (RoomProvider.arrivedMidGame) now routes every
--   non-owner who connects while the game is already running through this
--   RPC unconditionally, regardless of row intactness — this migration is
--   what stops the RPC itself from rejecting that call. decide_game_rejoin
--   _request's own approval logic already handles "row still exists" as a
--   plain UPDATE (idempotent — resets left_at/kicked_at/left_definitively/
--   is_away, all already-correct values for an intact row), so no change
--   needed there.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.request_game_rejoin(p_room_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_room_status public.room_status_enum;
  v_owner_id uuid;
  v_max_players smallint;
  v_session_id uuid;
  v_active_count integer;
  v_request_id uuid;
BEGIN
  SELECT status, max_players, owner_id INTO v_room_status, v_max_players, v_owner_id
  FROM public.rooms
  WHERE id = p_room_id AND deleted_at IS NULL
  FOR UPDATE;
  IF v_room_status IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;
  IF v_room_status NOT IN ('in_game', 'paused') THEN
    RAISE EXCEPTION 'game_finished';
  END IF;

  -- The owner has a separate, dedicated host-reconnect mechanism
  -- (recover_owner_room) and never legitimately needs this RPC — reject
  -- defensively rather than silently filing a request for them.
  IF auth.uid() = v_owner_id THEN
    RAISE EXCEPTION 'is_owner';
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

  -- 'already_in_room' removed — an intact room_members row is no longer a
  -- reason to skip approval (see migration header). decide_game_rejoin_
  -- request's own approval branch already tolerates an existing row.

  IF EXISTS (
    SELECT 1 FROM public.game_rejoin_requests
    WHERE room_id = p_room_id AND user_id = auth.uid() AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'already_pending';
  END IF;

  SELECT count(*) INTO v_active_count FROM public.room_members
  WHERE room_id = p_room_id AND left_at IS NULL
    AND role <> 'spectator'::public.room_member_role_enum
    AND user_id <> auth.uid();
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
