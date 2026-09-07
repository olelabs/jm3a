-- ============================================================================
-- migration_2026_lifecycle_final.sql
--
-- SUPERSEDES (do not apply separately — this file is fully self-contained
-- and safe to run regardless of whether any of the three below were ever
-- applied to the live database; every statement here is idempotent):
--   - migration_2026_host_reconnect_pause.sql
--   - migration_2026_one_active_session_per_room.sql
--   - migration_2026_lifecycle_rebuild.sql
--
-- Still required, SEPARATE, and NOT superseded by this file (touches a
-- different function, request_game_rejoin, deliberately left alone here):
--   - migration_2026_rejoin_requires_approval_always.sql
--
-- We cannot verify the live database's current definitions from this repo
-- (schema.sql predates every one of the four files above, and file
-- existence proves nothing about what has actually been executed against
-- the live database — see verify_live_db_state.sql, run that first). Every
-- statement below is therefore written to converge to the SAME correct
-- final state no matter what the starting state is:
--   - CREATE OR REPLACE FUNCTION for every function (safe to redefine an
--     already-correct function; harmless).
--   - ADD COLUMN IF NOT EXISTS / ALTER COLUMN SET DEFAULT for columns.
--   - CREATE UNIQUE INDEX IF NOT EXISTS for the one-active-session guard,
--     preceded by a dedup pass so it cannot fail against dirty data.
-- Re-running this entire file a second time is a guaranteed no-op.
-- ============================================================================


-- ============================================================================
-- PART 0 — game_sessions.lifecycle_state: create it if missing, and fix its
-- default regardless.
--
--   Root cause found in a prior audit of this exact file family: an earlier
--   attempt (migration_2026_host_reconnect_pause.sql) added this column
--   with DEFAULT 'active' — meaning every freshly created session already
--   reads 'active' in the database from the instant of INSERT, before the
--   ready barrier has even started. Since create_game_session's INSERT
--   never lists lifecycle_state, every new row silently inherits whatever
--   the column default says. All three games gate their ready-barrier
--   loading screen on `_lifecycleState == 'starting'`, and the ONLY way a
--   client's local _lifecycleState is ever set from a DB read is
--   `_pollForSessionActive()`'s fallback (`row?['lifecycle_state'] ==
--   'active'`) — used specifically when a reconnecting/late-arriving
--   non-owner missed the live broadcast. With the wrong default, that poll
--   returns a false positive on its very first attempt, regardless of
--   whether the ready barrier has actually completed. ADD COLUMN IF NOT
--   EXISTS alone cannot fix an already-existing column's default, so this
--   uses an unconditional ALTER COLUMN SET DEFAULT as well.
-- ============================================================================

ALTER TABLE public.game_sessions
  ADD COLUMN IF NOT EXISTS lifecycle_state text DEFAULT 'starting';

ALTER TABLE public.game_sessions
  ALTER COLUMN lifecycle_state SET DEFAULT 'starting';

-- Not a full backfill (see migration notes in the accompanying report for
-- why a blind backfill of existing active/paused rows would be unsafe —
-- there's no way to tell "wrongly defaulted to active" apart from
-- "genuinely already activated" for pre-existing rows). completed/aborted
-- rows are terminal either way and don't matter.


-- ============================================================================
-- PART 1 — at most one active/paused game_sessions row per room, as a real
-- database constraint instead of a best-effort client-side check.
-- ============================================================================

-- Pre-flight cleanup: CREATE UNIQUE INDEX fails outright if any room
-- currently already has more than one active/paused game_sessions row.
-- Keep only the most-recently-started row per room as the live one; abort
-- the rest (status only — never deletes any row). No-op if no duplicates
-- exist.
WITH ranked AS (
  SELECT id, room_id,
         row_number() OVER (
           PARTITION BY room_id ORDER BY started_at DESC, id DESC
         ) AS rn
  FROM public.game_sessions
  WHERE status IN ('active', 'paused')
)
UPDATE public.game_sessions gs
SET status = 'aborted', lifecycle_state = 'ended', paused_at = NULL, ended_at = now(), updated_at = now()
FROM ranked
WHERE gs.id = ranked.id AND ranked.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS "idx_game_sessions_one_active_per_room"
  ON "public"."game_sessions" ("room_id")
  WHERE ("status" IN ('active'::"public"."game_session_status_enum", 'paused'::"public"."game_session_status_enum"));


-- ============================================================================
-- PART 2 — create_game_session: race-safe against the new unique index.
--   Unchanged in intent from migration_2026_one_active_session_per_room.sql
--   — re-embedded here so this file is fully self-contained. Signature is
--   byte-identical to the live/original definition, so CREATE OR REPLACE
--   preserves the existing ACL.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET search_path = public
    AS $$
DECLARE
  v_id uuid;
  v_min_players smallint;
  v_eligible_count integer;
BEGIN
  IF NOT public.is_room_owner(p_room_id, auth.uid()) THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;

  IF p_pack_id IS NOT NULL THEN
    SELECT min_players INTO v_min_players FROM public.packs WHERE id = p_pack_id;
    IF v_min_players IS NOT NULL THEN
      SELECT count(*) INTO v_eligible_count FROM public.room_members
      WHERE room_id = p_room_id AND left_at IS NULL
        AND role <> 'spectator'::public.room_member_role_enum
        AND last_seen_at > now() - interval '25 seconds';
      IF v_eligible_count < v_min_players THEN
        RAISE EXCEPTION 'not_enough_players';
      END IF;
    END IF;
  END IF;

  BEGIN
    INSERT INTO public.game_sessions (
      room_id, pack_id, game_type, owner_id, player_ids, state_snapshot,
      max_rounds, turn_timer_secs, allow_skip, allow_spicy, status
    ) VALUES (
      p_room_id, p_pack_id, p_game_type::public.game_type_enum, auth.uid(), p_player_ids, p_state_snapshot,
      p_max_rounds, p_turn_timer_secs, p_allow_skip, p_allow_spicy, 'active'
    )
    RETURNING id INTO v_id;
  EXCEPTION
    WHEN unique_violation THEN
      -- Lost the race against a concurrent create_game_session call for
      -- this same room (idx_game_sessions_one_active_per_room) — join the
      -- session that actually won instead of erroring the caller out.
      SELECT id INTO v_id FROM public.game_sessions
      WHERE room_id = p_room_id AND status IN ('active', 'paused')
      ORDER BY started_at DESC
      LIMIT 1;
  END;

  IF v_id IS NULL THEN
    RAISE EXCEPTION 'create_game_session: no session id resolved for room %', p_room_id;
  END IF;

  RETURN v_id;
END;
$$;

ALTER FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb") OWNER TO "postgres";


-- ============================================================================
-- PART 3 — activate_game_session / confirm_game_session_ready: these do not
-- exist anywhere in this schema (verified by grepping every *.sql file in
-- this repo — zero CREATE FUNCTION for either name), yet all three game
-- providers call both via .rpc(). Every call has always failed with a
-- Postgrest "function not found" error, silently: confirm_game_session_
-- ready's failure is caught and only logged; activate_game_session's is
-- swallowed by a `.then((_) {}, onError: (e) {})` that does nothing at all.
--
-- activate_game_session is also the single correct hook for Bug 5 (pack
-- consumption): the one point, on the owner's client only, reached if and
-- only if the ready barrier has genuinely passed.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."activate_game_session"("p_session_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET search_path = public
    AS $$
DECLARE
  v_owner_id uuid;
  v_room_id uuid;
  v_pack_id uuid;
  v_row_count integer;
BEGIN
  SELECT owner_id, room_id, pack_id INTO v_owner_id, v_room_id, v_pack_id
  FROM public.game_sessions
  WHERE id = p_session_id
  FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'session_not_found';
  END IF;
  IF auth.uid() <> v_owner_id THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;

  UPDATE public.game_sessions
  SET lifecycle_state = 'active', updated_at = now()
  WHERE id = p_session_id;
  GET DIAGNOSTICS v_row_count = ROW_COUNT;
  IF v_row_count <> 1 THEN
    RAISE EXCEPTION 'activate_game_session: expected 1 row updated, got % (session_id=%)', v_row_count, p_session_id;
  END IF;

  -- Bug 5: the ONLY place a pack is committed as "played in this room" —
  -- see PART 6, where start_game_session_checks' old premature INSERT is
  -- removed.
  IF v_pack_id IS NOT NULL THEN
    INSERT INTO public.room_played_packs (room_id, pack_id)
    VALUES (v_room_id, v_pack_id)
    ON CONFLICT (room_id, pack_id) DO NOTHING;
  END IF;
END;
$$;

ALTER FUNCTION "public"."activate_game_session"("p_session_id" "uuid") OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."activate_game_session"("p_session_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."activate_game_session"("p_session_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."activate_game_session"("p_session_id" "uuid") TO "service_role";

CREATE OR REPLACE FUNCTION "public"."confirm_game_session_ready"("p_session_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET search_path = public
    AS $$
DECLARE
  v_player_ids uuid[];
BEGIN
  SELECT player_ids INTO v_player_ids
  FROM public.game_sessions
  WHERE id = p_session_id AND status IN ('active', 'paused');

  IF v_player_ids IS NULL THEN
    RAISE EXCEPTION 'session_not_found';
  END IF;
  IF NOT (auth.uid() = ANY(v_player_ids)) THEN
    RAISE EXCEPTION 'not_a_participant';
  END IF;

  UPDATE public.game_sessions
  SET updated_at = now()
  WHERE id = p_session_id;
END;
$$;

ALTER FUNCTION "public"."confirm_game_session_ready"("p_session_id" "uuid") OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."confirm_game_session_ready"("p_session_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."confirm_game_session_ready"("p_session_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."confirm_game_session_ready"("p_session_id" "uuid") TO "service_role";


-- ============================================================================
-- PART 4 — pause_game_if_owner_absent: stamps game_sessions.paused_at
-- exactly once per pause (the pre-existing `IF v_status <> 'in_game' THEN
-- RETURN` idempotency guard, combined with the FOR UPDATE lock on rooms,
-- already serializes concurrent bystander calls so only the FIRST one to
-- win the status transition ever reaches the paused_at UPDATE — a second
-- bystander's call re-reads the now-'paused' status and no-ops before ever
-- touching game_sessions again, so the countdown can never be silently
-- extended by a second detector).
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."pause_game_if_owner_absent"("p_room_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET search_path = public
    AS $$
DECLARE
  v_owner_id uuid;
  v_owner_last_seen timestamptz;
  v_owner_left_at timestamptz;
  v_status public.room_status_enum;
  v_caller_is_member boolean;
  v_row_count integer;
BEGIN
  SELECT owner_id, status INTO v_owner_id, v_status
  FROM public.rooms WHERE id = p_room_id FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;

  -- Idempotent no-op: already paused (another bystander's call already
  -- won this exact race), or the game already ended/isn't running.
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
  GET DIAGNOSTICS v_row_count = ROW_COUNT;
  IF v_row_count <> 1 THEN
    RAISE EXCEPTION 'pause_game_if_owner_absent: expected 1 room row updated, got % (room_id=%)', v_row_count, p_room_id;
  END IF;

  -- The dedicated, single-purpose pause marker — stamped exactly once per
  -- pause, thanks to the idempotency guard above. game_sessions.status/
  -- state_snapshot/player_ids/round data are all left completely untouched.
  UPDATE public.game_sessions
  SET paused_at = now()
  WHERE room_id = p_room_id AND status = 'active';
END;
$$;

ALTER FUNCTION "public"."pause_game_if_owner_absent"("p_room_id" "uuid") OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."pause_game_if_owner_absent"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."pause_game_if_owner_absent"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pause_game_if_owner_absent"("p_room_id" "uuid") TO "service_role";


-- ============================================================================
-- PART 5 — recover_owner_room: the authoritative host-reconnect decision.
--
--   Rebuilt per the required design:
--   1. FOR UPDATE lock on the room row first — this is what makes a
--      double-call (retry, two devices) idempotent: the second call blocks
--      until the first commits, then re-reads the ALREADY-UPDATED status
--      and takes the "no-op, already resolved" branch instead of redoing
--      or undoing the first call's decision. No new flag/column needed for
--      idempotency — the lock IS the idempotency mechanism.
--   2. Not paused -> untouched, no session created, matches prior behavior.
--   3. Paused -> locate the (at most one, enforced by
--      idx_game_sessions_one_active_per_room) active/paused session, and
--      decide resume vs. terminate using THAT session's own paused_at —
--      never rooms.last_active_at, which is stamped by many unrelated
--      writes and was never a reliable "when did this pause start" signal.
--   4. Resume: only rooms.status changes + paused_at/total_pause_ms
--      bookkeeping on the SAME session row. No INSERT INTO game_sessions
--      anywhere in this function, ever.
--   5. Terminate: session aborted, room reset to waiting, pack_id cleared
--      (previously only force_end_game_if_owner_absent cleared it —
--      recover_owner_room's own terminate branch left it set, letting an
--      admin who lands back in a normal 'waiting' lobby press Start Game
--      again without realizing a new, unrelated session would be created
--      under their still-selected pack).
--   6. Every UPDATE that must affect exactly one row is verified via
--      GET DIAGNOSTICS — no silent 0-row success.
--   7. Returns a 'state' string (resumed / ended / already_in_game /
--      already_waiting / not_owner / no_op / room_not_found) in addition
--      to the pre-existing boolean fields the current Dart code already
--      reads, so a client can distinguish every case without guessing.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET search_path = public
    AS $$
DECLARE
  v_created_by uuid;
  v_owner_id uuid;
  v_status public.room_status_enum;
  v_reclaimed boolean := false;
  v_terminated boolean := false;
  v_resumed boolean := false;
  v_session_id uuid;
  v_paused_at timestamptz;
  v_row_count integer;
  v_state text;
BEGIN
  SELECT created_by, owner_id, status INTO v_created_by, v_owner_id, v_status
  FROM public.rooms
  WHERE id = p_room_id AND deleted_at IS NULL
  FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RETURN jsonb_build_object('reclaimed', false, 'game_terminated', false, 'resumed', false, 'state', 'room_not_found');
  END IF;

  -- Original creator reclaiming ownership after an automatic failover —
  -- unrelated to pause/resume, preserved exactly as before.
  IF v_created_by IS NOT NULL AND auth.uid() = v_created_by AND v_owner_id <> v_created_by THEN
    UPDATE public.rooms
    SET owner_id = v_created_by, owner_transferred_at = now()
    WHERE id = p_room_id;
    v_owner_id := v_created_by;
    v_reclaimed := true;
  END IF;

  -- Only the room's actual (possibly just-reclaimed) owner reconnecting
  -- triggers a resume/terminate decision. A non-owner calling this (should
  -- never happen from the current Dart call sites, which only call it on
  -- their own initialize()) gets a harmless no-op read of current state.
  IF auth.uid() <> v_owner_id THEN
    RETURN jsonb_build_object(
      'reclaimed', v_reclaimed, 'game_terminated', false, 'resumed', false,
      'state', CASE WHEN v_status = 'paused'::public.room_status_enum THEN 'not_owner' ELSE 'no_op' END
    );
  END IF;

  IF v_status <> 'paused'::public.room_status_enum THEN
    -- Not paused: preserve existing behavior exactly, no session created,
    -- nothing to reconcile.
    v_state := CASE v_status
      WHEN 'in_game'::public.room_status_enum THEN 'already_in_game'
      WHEN 'waiting'::public.room_status_enum THEN 'already_waiting'
      ELSE 'no_op'
    END;
    RETURN jsonb_build_object('reclaimed', v_reclaimed, 'game_terminated', false, 'resumed', false, 'state', v_state);
  END IF;

  -- Room IS paused and caller IS the real owner. Locate the (at most one)
  -- active/paused session for this room, lock it too — nothing else should
  -- be racing to modify it, but this makes the guarantee explicit.
  SELECT id, paused_at INTO v_session_id, v_paused_at
  FROM public.game_sessions
  WHERE room_id = p_room_id AND status IN ('active', 'paused')
  ORDER BY started_at DESC
  LIMIT 1
  FOR UPDATE;

  -- 90s = the client's 60s countdown + a safety margin, so a client that
  -- already decided to end the game (force_end_game_if_owner_absent) wins
  -- the race instead of having this resurrect the session out from under
  -- it. A NULL paused_at (no session found, or paused via some other path)
  -- falls through to terminate rather than resuming with no basis for the
  -- decision.
  IF v_session_id IS NOT NULL
     AND v_paused_at IS NOT NULL
     AND v_paused_at > now() - interval '90 seconds' THEN
    UPDATE public.rooms
    SET status = 'in_game'::public.room_status_enum, last_active_at = now(), updated_at = now()
    WHERE id = p_room_id;
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    IF v_row_count <> 1 THEN
      RAISE EXCEPTION 'recover_owner_room: resume expected 1 room row updated, got % (room_id=%)', v_row_count, p_room_id;
    END IF;

    UPDATE public.game_sessions
    SET paused_at = NULL,
        total_pause_ms = total_pause_ms + GREATEST(0, EXTRACT(EPOCH FROM (now() - v_paused_at)) * 1000)::bigint,
        updated_at = now()
    WHERE id = v_session_id;
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    IF v_row_count <> 1 THEN
      RAISE EXCEPTION 'recover_owner_room: resume expected 1 session row updated, got % (session_id=%)', v_row_count, v_session_id;
    END IF;

    v_resumed := true;
    v_state := 'resumed';
  ELSE
    IF v_session_id IS NOT NULL THEN
      UPDATE public.game_sessions
      SET status = 'aborted', lifecycle_state = 'ended', paused_at = NULL, ended_at = now(), updated_at = now()
      WHERE id = v_session_id;
    END IF;

    UPDATE public.rooms
    SET status = 'waiting'::public.room_status_enum, last_active_at = now(), updated_at = now(), pack_id = NULL
    WHERE id = p_room_id;
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    IF v_row_count <> 1 THEN
      RAISE EXCEPTION 'recover_owner_room: terminate expected 1 room row updated, got % (room_id=%)', v_row_count, p_room_id;
    END IF;

    UPDATE public.room_members
    SET is_ready = false
    WHERE room_id = p_room_id AND left_at IS NULL;

    v_terminated := true;
    v_state := 'ended';
  END IF;

  RETURN jsonb_build_object(
    'reclaimed', v_reclaimed, 'game_terminated', v_terminated, 'resumed', v_resumed,
    'state', v_state, 'session_id', v_session_id
  );
END;
$$;

ALTER FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") TO "service_role";


-- ============================================================================
-- PART 6 — force_end_game_if_owner_absent: timeout-expiry path, called by a
-- deterministically-designated bystander when the owner never returns.
-- Same state-consistency additions as everywhere else a session ends.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."force_end_game_if_owner_absent"("p_room_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET search_path = public
    AS $$
DECLARE
  v_owner_id uuid;
  v_owner_last_seen timestamptz;
  v_owner_left_at timestamptz;
  v_status public.room_status_enum;
  v_caller_is_member boolean;
  v_session_id uuid;
  v_row_count integer;
BEGIN
  SELECT owner_id, status INTO v_owner_id, v_status
  FROM public.rooms WHERE id = p_room_id FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;

  -- Idempotent no-op: the owner already reconnected (recover_owner_room
  -- already resolved this one way or another), or another designated-closer
  -- attempt already won the race.
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
  WHERE room_id = p_room_id AND status IN ('active', 'paused')
  ORDER BY started_at DESC
  LIMIT 1;

  IF v_session_id IS NOT NULL THEN
    UPDATE public.game_sessions
    SET status = 'aborted', lifecycle_state = 'ended', paused_at = NULL, ended_at = now(), updated_at = now()
    WHERE id = v_session_id;
  END IF;

  UPDATE public.rooms
  SET status = 'waiting'::public.room_status_enum,
      last_active_at = now(),
      updated_at = now(),
      pack_id = NULL
  WHERE id = p_room_id;
  GET DIAGNOSTICS v_row_count = ROW_COUNT;
  IF v_row_count <> 1 THEN
    RAISE EXCEPTION 'force_end_game_if_owner_absent: expected 1 room row updated, got % (room_id=%)', v_row_count, p_room_id;
  END IF;

  UPDATE public.room_members
  SET is_ready = false
  WHERE room_id = p_room_id AND left_at IS NULL;
END;
$$;

ALTER FUNCTION "public"."force_end_game_if_owner_absent"("p_room_id" "uuid") OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."force_end_game_if_owner_absent"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."force_end_game_if_owner_absent"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."force_end_game_if_owner_absent"("p_room_id" "uuid") TO "service_role";


-- ============================================================================
-- PART 7 — start_game_session_checks: Bug 5. Pure availability check only —
-- the pack-played commit now happens exclusively in activate_game_session
-- (PART 3), the one point only ever reached once the game genuinely went
-- active. This function no longer writes anything at all.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."start_game_session_checks"("p_user_id" "uuid", "p_room_id" "uuid", "p_pack_id" "uuid", "p_is_premium" boolean) RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET search_path = public
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.room_played_packs
    WHERE room_id = p_room_id AND pack_id = p_pack_id
  ) THEN
    RETURN 'pack_already_played';
  END IF;

  RETURN NULL; -- success — nothing recorded here anymore
END;
$$;

ALTER FUNCTION "public"."start_game_session_checks"("p_user_id" "uuid", "p_room_id" "uuid", "p_pack_id" "uuid", "p_is_premium" boolean) OWNER TO "postgres";


-- ============================================================================
-- PART 8 — close_room: same state-consistency additions. Deliberately NOT
-- gated on the pause window (see design note inline) — a genuine, direct
-- "Leave Room" tap by the real owner during a still-resumable pause is a
-- decision they're entitled to make; the actual bystander-race concern this
-- would otherwise guard against is fixed client-side in RoomProvider.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."close_room"("p_room_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET search_path = public
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
  SET status = 'aborted', lifecycle_state = 'ended', paused_at = NULL, ended_at = now(), updated_at = now()
  WHERE room_id = p_room_id AND status IN ('active', 'paused');
END;
$$;

ALTER FUNCTION "public"."close_room"("p_room_id" "uuid") OWNER TO "postgres";
