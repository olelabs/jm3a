-- migration_2026_moderator_scope_and_ban_guard.sql
--
-- Starting/ending a game becomes hard owner-only (previously a moderator
-- granted 'start_game' could actually start a game via real server
-- enforcement; 'end_game' was only ever enforced client-side for Truth or
-- Dare, and not at all for Never Have I Ever / Meme). Also closes a real
-- gap in banning: there was no ban_room_member RPC at all — banning was a
-- raw, unguarded room_bans upsert followed by a call to kick_room_member,
-- which meant the ban row (potentially targeting the room's own owner)
-- was already persisted before kick's owner-protection ever ran.
--
-- Safe to run multiple times. Apply by hand in the Supabase SQL editor.

-- ── 1. Starting a game is owner-only, never delegable ──────────────────────

CREATE OR REPLACE FUNCTION public.create_game_session(
    p_room_id uuid, p_pack_id uuid, p_game_type text, p_player_ids uuid[],
    p_max_rounds smallint, p_turn_timer_secs smallint, p_allow_skip boolean,
    p_allow_spicy boolean, p_state_snapshot jsonb DEFAULT '{}'::jsonb
) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.is_room_owner(p_room_id, auth.uid()) THEN
    RAISE EXCEPTION 'permission_denied';
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

-- ── 2. One-time cleanup: strip any already-granted start_game/end_game ────

COMMENT ON COLUMN public.room_moderators.permissions IS 'Granular moderator permission keys: accept_joins, accept_spectators, accept_rejoins, advance_turn, skip_turn, kick_players, mute_chat, manage_settings. start_game and end_game are owner-only and no longer grantable. Owner always has every permission implicitly (see has_room_permission()).';

UPDATE public.room_moderators
SET permissions = array_remove(array_remove(permissions, 'start_game'), 'end_game')
WHERE 'start_game' = ANY(permissions) OR 'end_game' = ANY(permissions);

-- ── 3. ban_room_member — atomic, owner-only, protects the room owner ──────

CREATE OR REPLACE FUNCTION public.ban_room_member(
    p_room_id uuid,
    p_target_user_id uuid,
    p_reason text DEFAULT NULL,
    p_duration_secs integer DEFAULT NULL
) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF NOT public.is_room_owner(p_room_id, auth.uid()) THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;
  IF p_target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'cannot_target_self';
  END IF;
  IF EXISTS (SELECT 1 FROM public.rooms WHERE id = p_room_id AND owner_id = p_target_user_id) THEN
    RAISE EXCEPTION 'cannot_target_owner';
  END IF;

  INSERT INTO public.room_bans (room_id, user_id, banned_by, reason, banned_until)
  VALUES (
    p_room_id, p_target_user_id, auth.uid(), p_reason,
    CASE WHEN p_duration_secs IS NULL THEN NULL
         ELSE now() + make_interval(secs => p_duration_secs) END
  )
  ON CONFLICT (room_id, user_id) DO UPDATE
    SET banned_by = excluded.banned_by, reason = excluded.reason,
        banned_until = excluded.banned_until, lifted_at = NULL;

  UPDATE public.room_members
  SET left_at = now(), kicked_at = now()
  WHERE room_id = p_room_id AND user_id = p_target_user_id AND left_at IS NULL;
END;
$$;

GRANT ALL ON FUNCTION public.ban_room_member(uuid, uuid, text, integer) TO anon;
GRANT ALL ON FUNCTION public.ban_room_member(uuid, uuid, text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.ban_room_member(uuid, uuid, text, integer) TO service_role;
