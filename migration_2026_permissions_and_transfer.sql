-- Migration: calendar-day ownership transfer limit (server-enforced),
-- granular moderator permissions, and related RLS fixes.
--
-- This repo has no supabase CLI / migration tooling — apply this by hand
-- against the live Supabase project (SQL editor or `psql`). schema.sql has
-- already been updated to reflect this as the target end-state for future
-- fresh installs; this script brings an existing, already-provisioned
-- database up to the same state. Safe to run multiple times.
--
-- Requires the previous session's migration_2026_ownership_notifications.sql
-- to have been applied already (adds rooms.owner_transferred_at).

-- ── 1. Ownership transfer — calendar-day limit, server-enforced ────────────
CREATE OR REPLACE FUNCTION public.transfer_room_ownership(p_room_id uuid, p_new_owner_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_owner_id uuid;
  v_last_transfer timestamptz;
  v_target_role public.room_member_role_enum;
BEGIN
  SELECT owner_id, owner_transferred_at INTO v_owner_id, v_last_transfer
  FROM public.rooms WHERE id = p_room_id FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;
  IF v_owner_id <> auth.uid() THEN
    RAISE EXCEPTION 'not_owner';
  END IF;
  IF v_last_transfer IS NOT NULL
     AND (v_last_transfer AT TIME ZONE 'utc')::date >= (now() AT TIME ZONE 'utc')::date THEN
    RAISE EXCEPTION 'transfer_limit_reached';
  END IF;

  SELECT role INTO v_target_role
  FROM public.room_members
  WHERE room_id = p_room_id AND user_id = p_new_owner_id AND left_at IS NULL;

  IF v_target_role IS NULL THEN
    RAISE EXCEPTION 'target_not_member';
  END IF;
  IF v_target_role = 'spectator' THEN
    RAISE EXCEPTION 'target_is_spectator';
  END IF;

  UPDATE public.rooms
  SET owner_id = p_new_owner_id, owner_transferred_at = now()
  WHERE id = p_room_id;
END;
$$;

GRANT ALL ON FUNCTION public.transfer_room_ownership(uuid, uuid) TO anon;
GRANT ALL ON FUNCTION public.transfer_room_ownership(uuid, uuid) TO authenticated;
GRANT ALL ON FUNCTION public.transfer_room_ownership(uuid, uuid) TO service_role;


-- ── 2. Granular moderator permissions ───────────────────────────────────────
ALTER TABLE public.room_moderators
  ADD COLUMN IF NOT EXISTS permissions text[] NOT NULL DEFAULT '{}';

COMMENT ON COLUMN public.room_moderators.permissions IS
  'Granular moderator permission keys: accept_joins, accept_spectators, advance_turn, skip_turn, kick_players, mute_chat, manage_settings, end_game. Owner always has every permission implicitly (see has_room_permission()).';

-- One-time backfill so existing moderators keep exactly the capabilities
-- they already had before this migration (kick/mute/accept-joins/accept-
-- spectators were unconditionally granted to every moderator; advance/skip
-- turn, manage settings, and end game were owner-only and stay opt-in).
-- Safe to re-run, but only meaningfully affects rows still at the default
-- empty array — an owner who deliberately strips a moderator back to no
-- permissions after this migration runs will have that undone if this
-- script is re-run; run once in normal operation.
UPDATE public.room_moderators
SET permissions = ARRAY['accept_joins','accept_spectators','kick_players','mute_chat']
WHERE permissions = '{}'::text[];

CREATE OR REPLACE FUNCTION public.has_room_permission(p_room_id uuid, p_user_id uuid, p_permission text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
  select
    public.is_room_owner(p_room_id, p_user_id)
    or exists (
      select 1 from public.room_moderators
      where room_id = p_room_id and user_id = p_user_id
        and p_permission = any(permissions)
    );
$$;

GRANT ALL ON FUNCTION public.has_room_permission(uuid, uuid, text) TO anon;
GRANT ALL ON FUNCTION public.has_room_permission(uuid, uuid, text) TO authenticated;
GRANT ALL ON FUNCTION public.has_room_permission(uuid, uuid, text) TO service_role;

CREATE OR REPLACE FUNCTION public.kick_room_member(p_room_id uuid, p_target_user_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF NOT public.has_room_permission(p_room_id, auth.uid(), 'kick_players') THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;
  IF p_target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'cannot_target_self';
  END IF;
  IF EXISTS (SELECT 1 FROM public.rooms WHERE id = p_room_id AND owner_id = p_target_user_id) THEN
    RAISE EXCEPTION 'cannot_target_owner';
  END IF;
  UPDATE public.room_members
  SET left_at = now(), kicked_at = now()
  WHERE room_id = p_room_id AND user_id = p_target_user_id AND left_at IS NULL;
END;
$$;

GRANT ALL ON FUNCTION public.kick_room_member(uuid, uuid) TO anon;
GRANT ALL ON FUNCTION public.kick_room_member(uuid, uuid) TO authenticated;
GRANT ALL ON FUNCTION public.kick_room_member(uuid, uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.mute_room_member(p_room_id uuid, p_target_user_id uuid, p_muted boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF NOT public.has_room_permission(p_room_id, auth.uid(), 'mute_chat') THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;
  UPDATE public.room_members
  SET is_muted = p_muted
  WHERE room_id = p_room_id AND user_id = p_target_user_id;
END;
$$;

GRANT ALL ON FUNCTION public.mute_room_member(uuid, uuid, boolean) TO anon;
GRANT ALL ON FUNCTION public.mute_room_member(uuid, uuid, boolean) TO authenticated;
GRANT ALL ON FUNCTION public.mute_room_member(uuid, uuid, boolean) TO service_role;

CREATE OR REPLACE FUNCTION public.decide_join_request(p_request_id uuid, p_approve boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_room_id uuid;
BEGIN
  SELECT room_id INTO v_room_id FROM public.room_join_requests WHERE id = p_request_id;
  IF v_room_id IS NULL THEN
    RAISE EXCEPTION 'request_not_found';
  END IF;
  IF NOT public.has_room_permission(v_room_id, auth.uid(), 'accept_joins') THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;
  UPDATE public.room_join_requests
  SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
      resolved_at = now()
  WHERE id = p_request_id;
END;
$$;

GRANT ALL ON FUNCTION public.decide_join_request(uuid, boolean) TO anon;
GRANT ALL ON FUNCTION public.decide_join_request(uuid, boolean) TO authenticated;
GRANT ALL ON FUNCTION public.decide_join_request(uuid, boolean) TO service_role;

CREATE OR REPLACE FUNCTION public.decide_spectator_request(p_request_id uuid, p_approve boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_room_id uuid;
BEGIN
  SELECT room_id INTO v_room_id FROM public.spectator_requests WHERE id = p_request_id;
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
END;
$$;

GRANT ALL ON FUNCTION public.decide_spectator_request(uuid, boolean) TO anon;
GRANT ALL ON FUNCTION public.decide_spectator_request(uuid, boolean) TO authenticated;
GRANT ALL ON FUNCTION public.decide_spectator_request(uuid, boolean) TO service_role;

-- room_moderators had no UPDATE policy at all (only owner-gated INSERT/
-- DELETE) — needed now so an owner can edit an existing moderator's
-- permissions array without revoking and re-granting.
DROP POLICY IF EXISTS "room_moderators: owner can update" ON public.room_moderators;
CREATE POLICY "room_moderators: owner can update" ON public.room_moderators FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.rooms "r"
  WHERE (("r"."id" = "room_moderators"."room_id") AND ("r"."owner_id" = auth.uid())))));

-- room_bans had NO working insert/update policy at all — the existing
-- "no client insert/update" (WITH CHECK false) policies left ban/unban
-- non-functional at the DB layer for everyone, including the owner.
-- Unrelated to the new permission system (ban stays owner-only, per the
-- app's existing behavior) but discovered while working in this area and
-- worth fixing since "remove/moderate players" must actually work.
DROP POLICY IF EXISTS "room_bans: owner can insert" ON public.room_bans;
CREATE POLICY "room_bans: owner can insert" ON public.room_bans FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM public.rooms
  WHERE (("rooms"."id" = "room_bans"."room_id") AND ("rooms"."owner_id" = auth.uid())))));

DROP POLICY IF EXISTS "room_bans: owner can update" ON public.room_bans;
CREATE POLICY "room_bans: owner can update" ON public.room_bans FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.rooms
  WHERE (("rooms"."id" = "room_bans"."room_id") AND ("rooms"."owner_id" = auth.uid())))));
