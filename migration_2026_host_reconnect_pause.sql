-- ============================================================================
-- SUPERSEDED — do not apply this file separately. Its lifecycle_state
-- column default was wrong ('active' instead of 'starting') and its
-- recover_owner_room used rooms.last_active_at instead of the dedicated
-- game_sessions.paused_at. See migration_2026_lifecycle_final.sql, which
-- fully replaces everything in this file and is safe to apply regardless
-- of whether this file was ever run.
-- ============================================================================

-- ============================================================================
-- Replace mid-game ownership transfer with pause + host-reconnect:
--
--   Previously, a stale owner mid-game (in_game/paused) was still eligible
--   for claim_room_ownership's emergency failover after 3 minutes, exactly
--   like a stale owner in the lobby — silently handing the game to another
--   player. The Flutter client now gates claim_room_ownership to the lobby
--   only (see RoomProvider._confirmAndRemoveMember) and instead pauses the
--   game, shows every client a 60s "waiting for host" countdown, and either
--   resumes (host back in time) or ends the game (host_disconnected timeout)
--   — driven client-side via the existing 'pause'/'resume'/game_ended
--   broadcast plumbing (already scaffolded in RoomProvider._handleModeration,
--   previously unused).
--
--   recover_owner_room previously terminated ANY mid-game session
--   unconditionally the moment its rightful owner reconnected — including a
--   host who was only gone a few seconds, which fought directly against
--   "resume if the host reconnects within 60 seconds". It now only
--   terminates a 'paused' session if the pause has already run longer than
--   the client-side 60s countdown (+ a safety margin, checked via
--   rooms.last_active_at, which updateStatus() already stamps on every
--   status change including the pause itself) — a fast reconnect resumes in
--   place instead. A room merely 'in_game' (nobody ever noticed the gap, or
--   it was never long enough for a bystander to pause it) is left
--   completely alone now — there is nothing to reconcile.
-- ============================================================================

-- Safety net: game_sessions.lifecycle_state is written by this function
-- (and by force_end_game_if_owner_absent, and read pervasively throughout
-- the Flutter game providers/screens for all 3 games) but no migration in
-- this repo ever creates the column, and it is absent from the last known
-- schema dump (schema.sql, 2026-07-30). If it was added directly against
-- the live database out of band, this is a no-op; if not, every write
-- below would otherwise fail with "column does not exist" and roll back
-- the entire recovery function silently (caught client-side and only
-- logged as a warning, never surfaced to the user).
ALTER TABLE public.game_sessions
  ADD COLUMN IF NOT EXISTS lifecycle_state text DEFAULT 'active';

CREATE OR REPLACE FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_created_by uuid;
  v_owner_id uuid;
  v_status public.room_status_enum;
  v_last_active timestamptz;
  v_reclaimed boolean := false;
  v_terminated boolean := false;
  v_resumed boolean := false;
  v_session_id uuid;
BEGIN
  SELECT created_by, owner_id, status, last_active_at
    INTO v_created_by, v_owner_id, v_status, v_last_active
  FROM public.rooms
  WHERE id = p_room_id AND deleted_at IS NULL
  FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RETURN jsonb_build_object('reclaimed', false, 'game_terminated', false, 'resumed', false);
  END IF;

  IF v_created_by IS NOT NULL AND auth.uid() = v_created_by AND v_owner_id <> v_created_by THEN
    UPDATE public.rooms
    SET owner_id = v_created_by, owner_transferred_at = now()
    WHERE id = p_room_id;
    v_owner_id := v_created_by;
    v_reclaimed := true;
  END IF;

  IF auth.uid() = v_owner_id AND v_status = 'paused'::public.room_status_enum THEN
    -- 90s = the client's 60s countdown + a safety margin, so a client that
    -- already decided to end the game wins the race instead of having this
    -- resurrect the session out from under it.
    IF v_last_active IS NOT NULL AND v_last_active > now() - interval '90 seconds' THEN
      UPDATE public.rooms
      SET status = 'in_game'::public.room_status_enum, last_active_at = now(), updated_at = now()
      WHERE id = p_room_id;
      v_resumed := true;
    ELSE
      SELECT id INTO v_session_id FROM public.game_sessions
      WHERE room_id = p_room_id AND status IN ('active', 'paused')
      ORDER BY started_at DESC
      LIMIT 1;

      IF v_session_id IS NOT NULL THEN
        UPDATE public.game_sessions
        SET status = 'aborted', lifecycle_state = 'ended', ended_at = now(), updated_at = now()
        WHERE id = v_session_id;
      END IF;

      UPDATE public.rooms
      SET status = 'waiting'::public.room_status_enum, last_active_at = now(), updated_at = now()
      WHERE id = p_room_id;

      UPDATE public.room_members
      SET is_ready = false
      WHERE room_id = p_room_id AND left_at IS NULL;

      v_terminated := true;
    END IF;
  END IF;
  -- status = 'in_game' (never paused, or the pause never got this far):
  -- intentionally left untouched — nothing to reconcile, the owner just
  -- resumes as a normal client from here.

  RETURN jsonb_build_object('reclaimed', v_reclaimed, 'game_terminated', v_terminated, 'resumed', v_resumed);
END;
$$;

ALTER FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") OWNER TO "postgres";

-- CREATE OR REPLACE preserves this function's existing ACL (same OID, same
-- signature) — these are defensive/redundant given that, matching the
-- explicit-GRANT pattern already used by every sibling RPC in this
-- lifecycle (pause_game_if_owner_absent, force_end_game_if_owner_absent,
-- request_game_rejoin), so this doesn't silently rely on
-- ALTER DEFAULT PRIVILEGES alone.
GRANT ALL ON FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") TO "service_role";
