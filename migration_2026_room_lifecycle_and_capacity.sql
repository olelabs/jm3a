-- migration_2026_room_lifecycle_and_capacity.sql
--
-- Room lifecycle + subscription-tier player limits + duplicate-room
-- prevention. Root causes fixed:
--
-- 1. Closing a room was a plain client-side rooms.update() — it never
--    marked an in-progress game_sessions row as ended (nothing else does
--    either, until a hard-delete 5 days later), and room_members' own
--    INSERT policy never checked the room's status, so a closed room
--    could still be joined at the DB level via a direct call.
-- 2. There was no create_room RPC at all — a raw client insert took a
--    free max_players int with zero subscription-tier validation, and did
--    a non-atomic, racy "do I already own an open room" pre-check that
--    also missed the 'paused' status.
--
-- Safe to run multiple times. Apply by hand in the Supabase SQL editor.

-- ── 1. Widen the player-count cap (Basic=3/Premium=8/Premium Plus=12) ──────

ALTER TABLE public.rooms DROP CONSTRAINT IF EXISTS rooms_max_players_check;
ALTER TABLE public.rooms
  ADD CONSTRAINT rooms_max_players_check CHECK ((max_players >= 2 AND max_players <= 12));

-- ── 2. Atomic room-close RPCs ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.close_room(p_room_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
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
END;
$$;

GRANT ALL ON FUNCTION public.close_room(uuid) TO anon;
GRANT ALL ON FUNCTION public.close_room(uuid) TO authenticated;
GRANT ALL ON FUNCTION public.close_room(uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.close_abandoned_room(p_room_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_owner_id uuid;
BEGIN
  SELECT owner_id INTO v_owner_id FROM public.rooms
  WHERE id = p_room_id AND deleted_at IS NULL;
  IF v_owner_id IS NULL THEN
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.room_members
    WHERE room_id = p_room_id AND user_id = v_owner_id AND left_at IS NULL
  ) THEN
    RAISE EXCEPTION 'owner_still_present';
  END IF;

  UPDATE public.rooms
  SET status = 'closed', deleted_at = now(), updated_at = now()
  WHERE id = p_room_id AND deleted_at IS NULL;

  UPDATE public.game_sessions
  SET status = 'aborted', ended_at = now(), updated_at = now()
  WHERE room_id = p_room_id AND status IN ('active', 'paused');
END;
$$;

GRANT ALL ON FUNCTION public.close_abandoned_room(uuid) TO anon;
GRANT ALL ON FUNCTION public.close_abandoned_room(uuid) TO authenticated;
GRANT ALL ON FUNCTION public.close_abandoned_room(uuid) TO service_role;

-- ── 3. room_members insert now also checks the room isn't closed ──────────

DROP POLICY IF EXISTS "room_members: self insert" ON public.room_members;
CREATE POLICY "room_members: self insert" ON public.room_members
  FOR INSERT WITH CHECK (
    (auth.uid() = user_id)
    AND NOT EXISTS (
      SELECT 1 FROM public.room_bans
      WHERE room_bans.room_id = room_members.room_id
        AND room_bans.user_id = auth.uid()
        AND room_bans.lifted_at IS NULL
        AND (room_bans.banned_until IS NULL OR room_bans.banned_until > now())
    )
    AND EXISTS (
      SELECT 1 FROM public.rooms
      WHERE rooms.id = room_members.room_id
        AND rooms.deleted_at IS NULL
        AND rooms.status <> 'closed'::public.room_status_enum
    )
  );

-- ── 4. Invite-code lookup excludes closed rooms too ────────────────────────

CREATE OR REPLACE FUNCTION public.get_room_by_invite_code(p_code text)
RETURNS TABLE(id uuid, name text, visibility text, status text, game_type text,
              current_players smallint, max_players smallint, owner_id uuid,
              pack_id uuid, language text, allow_spicy boolean, invite_code text,
              cover_emoji text, last_active_at timestamp with time zone,
              created_at timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
  select
    id, name, visibility::text, status::text, game_type::text,
    current_players, max_players, owner_id, pack_id, language,
    allow_spicy, invite_code, cover_emoji, last_active_at, created_at
  from public.rooms
  where upper(invite_code) = upper(p_code)
    and deleted_at is null
    and status <> 'closed'::public.room_status_enum
  limit 1;
$$;

-- ── 5. create_room RPC — subscription-tier cap + duplicate-room guard ─────

CREATE OR REPLACE FUNCTION public.create_room(
    p_name text,
    p_visibility text DEFAULT 'public',
    p_max_players smallint DEFAULT NULL,
    p_language text DEFAULT 'en',
    p_cover_emoji text DEFAULT '🎮'
) RETURNS public.rooms
    LANGUAGE plpgsql SECURITY DEFINER
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

  INSERT INTO public.rooms (owner_id, name, visibility, max_players, language, cover_emoji, status)
  VALUES (
    auth.uid(), p_name, p_visibility::public.room_visibility_enum,
    v_requested, p_language, p_cover_emoji, 'waiting'
  )
  RETURNING * INTO v_room;

  INSERT INTO public.room_members (room_id, user_id, seat_order, role)
  VALUES (v_room.id, auth.uid(), 0, 'player'::public.room_member_role_enum)
  ON CONFLICT (room_id, user_id) DO NOTHING;

  RETURN v_room;
END;
$$;

GRANT ALL ON FUNCTION public.create_room(text, text, smallint, text, text) TO anon;
GRANT ALL ON FUNCTION public.create_room(text, text, smallint, text, text) TO authenticated;
GRANT ALL ON FUNCTION public.create_room(text, text, smallint, text, text) TO service_role;

-- ── 6. decide_game_rejoin_request — missing capacity check on approval ────

CREATE OR REPLACE FUNCTION public.decide_game_rejoin_request(p_request_id uuid, p_approve boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_room_id uuid;
  v_user_id uuid;
  v_row_exists boolean;
  v_max_players smallint;
  v_active_count integer;
BEGIN
  SELECT room_id, user_id INTO v_room_id, v_user_id
  FROM public.game_rejoin_requests
  WHERE id = p_request_id AND status = 'pending';
  IF v_room_id IS NULL THEN
    RAISE EXCEPTION 'request_not_found';
  END IF;
  IF NOT public.has_room_permission(v_room_id, auth.uid(), 'accept_rejoins') THEN
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

  UPDATE public.game_rejoin_requests
  SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
      resolved_at = now()
  WHERE id = p_request_id;

  IF p_approve THEN
    SELECT EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_id = v_room_id AND user_id = v_user_id
    ) INTO v_row_exists;

    IF v_row_exists THEN
      UPDATE public.room_members
      SET left_at = NULL, kicked_at = NULL, left_definitively = false, is_away = false
      WHERE room_id = v_room_id AND user_id = v_user_id;
    ELSE
      INSERT INTO public.room_members (room_id, user_id, role, seat_order)
      VALUES (v_room_id, v_user_id, 'player', 0);
    END IF;
  END IF;
END;
$$;
