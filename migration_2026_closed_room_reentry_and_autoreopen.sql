-- Closed-room re-entry fix + admin-alone auto-reopen
--
-- Batch D's keep-game close (rooms.closed_at) correctly hides a room from
-- Browse and refuses brand-new joiners, but its re-entry gate
-- (room_members_block_reactivation_when_closed) was too narrow: it only
-- ever let the OWNER or an active/paused game_sessions participant back in.
-- That wrongly blocked two legitimate cases:
--   1. A plain existing member (already in room_members before the room was
--      closed — e.g. still in the lobby, or between games) who disconnects
--      and reconnects.
--   2. A freshly invited user accepting a real invite while the room is
--      closed — accept_room_invite() never itself checks closed_at, it was
--      only ever the trigger silently rejecting the resulting upsert.
-- Kicked / banned / permanently-left users must still be rejected, so the
-- new exceptions are gated behind NEW.kicked_at IS NULL, NOT NEW.left_definitively,
-- and an explicit room_bans lookup, exactly like the existing join paths.
--
-- Also adds: when a closed room's membership drops to just the owner (the
-- last other member left/was removed/kicked), the room auto-reopens so the
-- owner isn't stuck alone in a room nobody else can (re)join.

BEGIN;

-- 1. Widen the closed-room re-entry gate --------------------------------
CREATE OR REPLACE FUNCTION "public"."room_members_block_reactivation_when_closed"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF NEW.left_at IS NULL
     AND (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.left_at IS NOT NULL)) THEN
    IF EXISTS (SELECT 1 FROM public.rooms r
               WHERE r.id = NEW.room_id AND r.closed_at IS NOT NULL) THEN
      IF NOT EXISTS (SELECT 1 FROM public.rooms r
                     WHERE r.id = NEW.room_id AND r.owner_id = NEW.user_id)
         AND NOT (
           NEW.kicked_at IS NULL
           AND NOT NEW.left_definitively
           AND NOT EXISTS (
             SELECT 1 FROM public.room_bans b
             WHERE b.room_id = NEW.room_id AND b.user_id = NEW.user_id
               AND b.lifted_at IS NULL
               AND (b.banned_until IS NULL OR b.banned_until > now())
           )
           AND (
             -- (a) genuine active/paused game-session participant
             -- reconnecting (unchanged from before).
             EXISTS (
               SELECT 1 FROM public.game_sessions gs
               WHERE gs.room_id = NEW.room_id
                 AND gs.status IN ('active', 'paused')
                 AND NEW.user_id = ANY(gs.player_ids)
             )
             -- (b) a row that already existed before this reactivation
             -- (TG_OP = 'UPDATE' only reaches here when OLD.left_at WAS
             -- set, per the outer IF) — a legitimate existing member
             -- simply reconnecting, not a brand-new joiner.
             OR TG_OP = 'UPDATE'
             -- (c) a still-valid (not declined, not expired) invitation —
             -- an admin inviting someone into a closed room must work.
             OR EXISTS (
               SELECT 1 FROM public.room_invites ri
               WHERE ri.room_id = NEW.room_id
                 AND ri.invited_user = NEW.user_id
                 AND ri.declined_at IS NULL
                 AND ri.expires_at > now()
             )
           )
         )
      THEN
        RAISE EXCEPTION 'room_closed';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."room_members_block_reactivation_when_closed"() OWNER TO "postgres";

-- 2. Auto-reopen when the owner is left alone in a closed room -----------
CREATE OR REPLACE FUNCTION "public"."rooms_auto_reopen_when_owner_alone"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_owner_id uuid;
  v_active_count integer;
  v_owner_still_active boolean;
BEGIN
  -- Fires only on the transition into "just left" (see trigger's WHEN
  -- clause); a room that isn't currently keep-game-closed has nothing to
  -- reopen.
  SELECT owner_id INTO v_owner_id FROM public.rooms
  WHERE id = NEW.room_id AND closed_at IS NOT NULL AND deleted_at IS NULL;
  IF v_owner_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT count(*) INTO v_active_count
  FROM public.room_members
  WHERE room_id = NEW.room_id AND left_at IS NULL;

  IF v_active_count = 1 THEN
    SELECT EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_id = NEW.room_id AND left_at IS NULL AND user_id = v_owner_id
    ) INTO v_owner_still_active;

    IF v_owner_still_active THEN
      UPDATE public.rooms
      SET closed_at = NULL, updated_at = now()
      WHERE id = NEW.room_id AND closed_at IS NOT NULL;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."rooms_auto_reopen_when_owner_alone"() OWNER TO "postgres";

CREATE OR REPLACE TRIGGER "trg_room_members_auto_reopen_when_owner_alone"
  AFTER UPDATE ON "public"."room_members"
  FOR EACH ROW
  WHEN (NEW.left_at IS NOT NULL AND OLD.left_at IS NULL)
  EXECUTE FUNCTION "public"."rooms_auto_reopen_when_owner_alone"();

COMMIT;
