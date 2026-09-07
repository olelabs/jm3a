-- Migration: authoritative, atomic invitation acceptance that reconciles a
-- pending join request for the SAME user_id.
--
-- Bug fixed: in an approval-required room, a user who already filed a pending
-- join request and then enters via a direct admin invitation ended up with a
-- membership AND a still-pending join request. The membership itself was never
-- duplicated (room_members has UNIQUE(room_id, user_id) and the client upserts
-- on that key), but the orphaned pending request made the same user_id appear
-- as both a member and a pending requester — effectively two room identities.
--
-- Previously invitation acceptance was client-orchestrated (markInviteAccepted
-- then joinRoom's upsert) and nothing ever resolved the pending request. This
-- RPC makes the whole thing ONE atomic, server-authoritative operation keyed
-- exclusively on auth.uid(), so no device race can leave a lingering request or
-- a second membership.
--
-- This repo has no supabase CLI / migration tooling — apply this by hand
-- against the live Supabase project (SQL editor or `psql`). schema.sql has been
-- updated to reflect this as the target end-state for fresh installs; this
-- script brings an already-provisioned database up to the same state. Safe to
-- run multiple times (CREATE OR REPLACE + idempotent DML).
--
-- Invariant enforced:
--   (room_id, user_id) identifies exactly one logical room membership. A join
--   request, invitation, notification, reconnect, or device is never a separate
--   member identity. Successful room entry reconciles all pending access
--   mechanisms for that same user and room.

CREATE OR REPLACE FUNCTION public.accept_room_invite(p_room_id uuid)
    RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_has_invite boolean;
  v_status text;
  v_max_players smallint;
  v_active_players integer;
  v_seat_order integer;
  v_membership_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- 1. Validate the invitation belongs to THIS caller and is still usable.
  --    Keyed on invited_user = auth.uid(): an invitation can only ever
  --    authorize the invited user_id, never whoever holds the invite id.
  --    accepted_at is intentionally NOT required to be null — re-accepting an
  --    already-consumed invite must resolve idempotently to the existing
  --    membership (duplicate-invitation / old-notification protection), not
  --    error out or create a second identity.
  SELECT EXISTS (
    SELECT 1 FROM public.room_invites
    WHERE room_id = p_room_id
      AND invited_user = v_uid
      AND declined_at IS NULL
      AND expires_at > now()
  ) INTO v_has_invite;
  IF NOT v_has_invite THEN
    RAISE EXCEPTION 'no_valid_invite';
  END IF;

  -- 2. Room must exist and be open.
  SELECT status, max_players INTO v_status, v_max_players
  FROM public.rooms WHERE id = p_room_id;
  IF v_status IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;
  IF v_status = 'closed' THEN
    RAISE EXCEPTION 'room_closed';
  END IF;

  -- 3. An invitation never overrides a ban (security: a banned user must not be
  --    able to walk back in through an invite).
  IF EXISTS (
    SELECT 1 FROM public.room_bans
    WHERE room_id = p_room_id
      AND user_id = v_uid
      AND lifted_at IS NULL
      AND (banned_until IS NULL OR banned_until > now())
  ) THEN
    RAISE EXCEPTION 'banned';
  END IF;

  -- 4. Capacity — only meaningful when this user is NOT already an active
  --    player (reusing an existing membership never consumes a new seat).
  --    Mirrors decide_join_request's capacity gate exactly.
  IF NOT EXISTS (
    SELECT 1 FROM public.room_members
    WHERE room_id = p_room_id AND user_id = v_uid
      AND left_at IS NULL AND role <> 'spectator'::public.room_member_role_enum
  ) THEN
    SELECT count(*) INTO v_active_players FROM public.room_members
    WHERE room_id = p_room_id AND left_at IS NULL
      AND role <> 'spectator'::public.room_member_role_enum
      AND user_id <> v_uid;
    IF v_active_players >= v_max_players THEN
      RAISE EXCEPTION 'room_full';
    END IF;
  END IF;

  -- 5. Reuse-or-create exactly one membership. ON CONFLICT on the
  --    (room_id, user_id) unique key makes this race-safe: two simultaneous
  --    invite/request flows for the same user can never produce two rows — the
  --    second collapses into an UPDATE of the same single row.
  SELECT count(*) INTO v_seat_order FROM public.room_members
  WHERE room_id = p_room_id AND left_at IS NULL;

  INSERT INTO public.room_members
    (room_id, user_id, seat_order, role, is_hidden_spectator, is_ready, left_at, joined_at)
  VALUES
    (p_room_id, v_uid, v_seat_order, 'player', false, false, NULL, now())
  ON CONFLICT (room_id, user_id) DO UPDATE
    SET left_at = NULL,
        kicked_at = NULL,
        left_definitively = false,
        is_away = false
  RETURNING id INTO v_membership_id;

  -- 6. Reconcile the pending join request for the SAME user_id. The invitation
  --    is itself the admin's explicit authorization to enter, so the request is
  --    fulfilled (approved), never left pending and never creating a second
  --    approval state. Server-authoritative: once this is 'approved', a stale
  --    realtime event or another device cannot revive it as pending (a later
  --    requestToJoin upsert would create a fresh row, but the user is already a
  --    member, so no duplicate identity results).
  UPDATE public.room_join_requests
  SET status = 'approved', resolved_at = now()
  WHERE room_id = p_room_id AND user_id = v_uid AND status = 'pending';

  -- 7. Mark the invitation consumed.
  UPDATE public.room_invites
  SET accepted_at = now()
  WHERE room_id = p_room_id AND invited_user = v_uid AND accepted_at IS NULL;

  RETURN v_membership_id;
END;
$$;

ALTER FUNCTION public.accept_room_invite(uuid) OWNER TO postgres;

GRANT ALL ON FUNCTION public.accept_room_invite(uuid) TO anon;
GRANT ALL ON FUNCTION public.accept_room_invite(uuid) TO authenticated;
GRANT ALL ON FUNCTION public.accept_room_invite(uuid) TO service_role;
