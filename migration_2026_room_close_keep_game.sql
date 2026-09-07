-- Batch D — Close Room Without Ending the Active Game
--
-- Adds an orthogonal "closed for new entrants" state that is completely
-- separate from the existing terminal teardown (close_room, which sets
-- status='closed' + deleted_at + aborts the session). A keep-game close:
--   * sets rooms.closed_at = now()
--   * leaves status unchanged (e.g. 'in_game')
--   * leaves deleted_at NULL
--   * never touches game_sessions
-- so the active session keeps running and its player_ids keep playing,
-- while the room vanishes from Browse and refuses all new entrants.
--
-- The existing destructive close_room / close_abandoned_room are left
-- exactly as-is for owner-leave / terminal teardown.

BEGIN;

-- 1. Orthogonal closed marker ------------------------------------------------
ALTER TABLE "public"."rooms"
  ADD COLUMN IF NOT EXISTS "closed_at" timestamp with time zone;

COMMENT ON COLUMN "public"."rooms"."closed_at" IS
  'Keep-game close marker: room refuses new entrants and hides from Browse, '
  'but the current game_sessions row keeps running and status is unchanged. '
  'Distinct from the terminal status=''closed''+deleted_at teardown.';

-- Browse and the join RLS both filter on this a lot; a partial index keeps
-- the "open, joinable" scan cheap (mirrors idx_rooms_status' shape).
CREATE INDEX IF NOT EXISTS "idx_rooms_open"
  ON "public"."rooms" USING "btree" ("status", "visibility", "last_active_at" DESC)
  WHERE (("deleted_at" IS NULL) AND ("closed_at" IS NULL));

-- 2. Keep-game close RPC -----------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."close_room_keep_game"("p_room_id" "uuid")
  RETURNS "void"
  LANGUAGE "plpgsql" SECURITY DEFINER
  AS $$
DECLARE
  v_owner_id uuid;
  v_closed_at timestamptz;
  v_relevant integer;
BEGIN
  SELECT owner_id, closed_at INTO v_owner_id, v_closed_at
  FROM public.rooms
  WHERE id = p_room_id AND deleted_at IS NULL
  FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;
  IF v_owner_id <> auth.uid() THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;
  IF v_closed_at IS NOT NULL THEN
    RAISE EXCEPTION 'already_closed';
  END IF;

  -- Admin-alone protection: at least one OTHER relevant member must be
  -- present. Relevant = currently in the room (not left, not kicked). The
  -- owner is one such row, so the room needs strictly more than one.
  SELECT count(*) INTO v_relevant
  FROM public.room_members
  WHERE room_id = p_room_id AND left_at IS NULL AND kicked_at IS NULL;
  IF v_relevant <= 1 THEN
    RAISE EXCEPTION 'not_enough_members';
  END IF;

  -- The ONLY mutation: mark closed. status, deleted_at, and game_sessions
  -- are deliberately untouched so the live game continues.
  UPDATE public.rooms
  SET closed_at = now(), updated_at = now()
  WHERE id = p_room_id AND closed_at IS NULL;
END;
$$;

ALTER FUNCTION "public"."close_room_keep_game"("p_room_id" "uuid") OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."close_room_keep_game"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."close_room_keep_game"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."close_room_keep_game"("p_room_id" "uuid") TO "service_role";

-- 2b. Reopen RPC (reverse of close_room_keep_game) ---------------------------
-- Clears closed_at so the room accepts new entrants and reappears in Browse
-- again, per its normal room rules. Deliberately touches ONLY closed_at:
-- never deletes, never creates a room/session, never resets game data or
-- settings. Owner-only, server-authoritative.
CREATE OR REPLACE FUNCTION "public"."reopen_room_keep_game"("p_room_id" "uuid")
  RETURNS "void"
  LANGUAGE "plpgsql" SECURITY DEFINER
  AS $$
DECLARE
  v_owner_id uuid;
  v_closed_at timestamptz;
BEGIN
  SELECT owner_id, closed_at INTO v_owner_id, v_closed_at
  FROM public.rooms
  WHERE id = p_room_id AND deleted_at IS NULL
  FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;
  IF v_owner_id <> auth.uid() THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;
  IF v_closed_at IS NULL THEN
    RAISE EXCEPTION 'not_closed';
  END IF;

  UPDATE public.rooms
  SET closed_at = NULL, updated_at = now()
  WHERE id = p_room_id AND closed_at IS NOT NULL AND deleted_at IS NULL;
END;
$$;

ALTER FUNCTION "public"."reopen_room_keep_game"("p_room_id" "uuid") OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."reopen_room_keep_game"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."reopen_room_keep_game"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."reopen_room_keep_game"("p_room_id" "uuid") TO "service_role";

-- 3. Join RLS: reject new memberships in a keep-game-closed room -------------
-- A keep-game-closed room keeps status='in_game', so the old status<>'closed'
-- guard no longer covers it — add closed_at IS NULL to the INSERT check.
DROP POLICY IF EXISTS "room_members: self insert" ON "public"."room_members";
CREATE POLICY "room_members: self insert" ON "public"."room_members"
  FOR INSERT WITH CHECK (
    (("auth"."uid"() = "user_id")
     AND (NOT (EXISTS ( SELECT 1
        FROM "public"."room_bans"
       WHERE (("room_bans"."room_id" = "room_members"."room_id")
         AND ("room_bans"."user_id" = "auth"."uid"())
         AND ("room_bans"."lifted_at" IS NULL)
         AND (("room_bans"."banned_until" IS NULL) OR ("room_bans"."banned_until" > "now"()))))))
     AND (EXISTS ( SELECT 1
        FROM "public"."rooms"
       WHERE (("rooms"."id" = "room_members"."room_id")
         AND ("rooms"."deleted_at" IS NULL)
         AND ("rooms"."closed_at" IS NULL)
         AND ("rooms"."status" <> 'closed'::"public"."room_status_enum")
         AND (("rooms"."status" <> 'in_game'::"public"."room_status_enum")
              OR ("rooms"."owner_id" = "auth"."uid"())
              OR (EXISTS ( SELECT 1
                 FROM "public"."room_members" "rm2"
                WHERE (("rm2"."room_id" = "rooms"."id")
                  AND ("rm2"."user_id" = "auth"."uid"())))))))))
  );

-- 4. Reactivation backstop -------------------------------------------------
-- RLS WITH CHECK on UPDATE can only see the NEW row, so it cannot tell a
-- reactivation (left_at NOT NULL -> NULL) apart from an ordinary self-update
-- (ready/heartbeat, where left_at stays NULL). A trigger sees OLD and NEW and
-- fires on every path (plain INSERT, upsert's DO UPDATE, direct UPDATE), so a
-- kicked/left player can never resurrect their row into a closed room via the
-- joinRoom upsert. Present members (spectators, lobby, active players) whose
-- left_at is already NULL are untouched — this only guards the activation edge.
CREATE OR REPLACE FUNCTION "public"."room_members_block_reactivation_when_closed"()
  RETURNS "trigger"
  LANGUAGE "plpgsql" SECURITY DEFINER
  AS $$
BEGIN
  -- Only an activation/reactivation matters (row is becoming/entering active).
  IF NEW.left_at IS NULL
     AND (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.left_at IS NOT NULL)) THEN
    IF EXISTS (SELECT 1 FROM public.rooms r
               WHERE r.id = NEW.room_id AND r.closed_at IS NOT NULL) THEN
      -- Allowed only for the owner, or a genuine active-session participant
      -- (in game_sessions.player_ids and not kicked) reconnecting.
      IF NOT EXISTS (SELECT 1 FROM public.rooms r
                     WHERE r.id = NEW.room_id AND r.owner_id = NEW.user_id)
         AND NOT (NEW.kicked_at IS NULL AND EXISTS (
                   SELECT 1 FROM public.game_sessions gs
                   WHERE gs.room_id = NEW.room_id
                     AND gs.status IN ('active','paused')
                     AND NEW.user_id = ANY(gs.player_ids)))
      THEN
        RAISE EXCEPTION 'room_closed';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."room_members_block_reactivation_when_closed"() OWNER TO "postgres";

DROP TRIGGER IF EXISTS "trg_room_members_block_reactivation_when_closed" ON "public"."room_members";
CREATE TRIGGER "trg_room_members_block_reactivation_when_closed"
  BEFORE INSERT OR UPDATE ON "public"."room_members"
  FOR EACH ROW EXECUTE FUNCTION "public"."room_members_block_reactivation_when_closed"();

-- 5. Batch C rejoin must respect the closed state ---------------------------
-- A closed room rejects rejoin requests server-side (before any 'pending' row
-- is written), so the returning player never gets a "waiting for acceptance"
-- state. Non-closed rooms behave exactly as before.
CREATE OR REPLACE FUNCTION "public"."request_game_rejoin"("p_room_id" "uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_room_status public.room_status_enum;
  v_max_players smallint;
  v_closed_at timestamptz;
  v_session_id uuid;
  v_active_count integer;
  v_request_id uuid;
BEGIN
  SELECT status, max_players, closed_at
    INTO v_room_status, v_max_players, v_closed_at
  FROM public.rooms
  WHERE id = p_room_id AND deleted_at IS NULL
  FOR UPDATE;
  IF v_room_status IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;
  -- Keep-game-closed rooms accept no new entrants, rejoiners included.
  IF v_closed_at IS NOT NULL THEN
    RAISE EXCEPTION 'room_closed';
  END IF;
  IF v_room_status NOT IN ('in_game', 'paused') THEN
    RAISE EXCEPTION 'game_finished';
  END IF;

  -- Kicked or currently banned players are never rejoin-eligible.
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

  -- Proves real prior participation, not just prior room membership.
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

  IF EXISTS (
    SELECT 1 FROM public.room_members
    WHERE room_id = p_room_id AND user_id = auth.uid() AND left_at IS NULL
  ) THEN
    RAISE EXCEPTION 'already_in_room';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.game_rejoin_requests
    WHERE room_id = p_room_id AND user_id = auth.uid() AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'already_pending';
  END IF;

  SELECT count(*) INTO v_active_count FROM public.room_members
  WHERE room_id = p_room_id AND left_at IS NULL
    AND role <> 'spectator'::public.room_member_role_enum;
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

-- 6. Admin "my closed rooms" recognizes the new marker too ------------------
-- Terminal (deleted_at) history is preserved; keep-game-closed rooms
-- (closed_at set, deleted_at NULL) also surface, timestamped by closed_at.
CREATE OR REPLACE FUNCTION "public"."get_my_closed_rooms"()
  RETURNS TABLE("room_id" "uuid", "name" "text", "cover_emoji" "text",
                "game_type" "public"."game_type_enum",
                "closed_at" timestamp with time zone,
                "max_players" smallint,
                "created_at" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF NOT COALESCE((SELECT is_premium FROM public.profiles WHERE id = auth.uid()), false) THEN
    RAISE EXCEPTION 'premium_required';
  END IF;

  RETURN QUERY
  SELECT r.id, r.name, r.cover_emoji, r.game_type,
         COALESCE(r.closed_at, r.deleted_at) AS closed_at,
         r.max_players, r.created_at
  FROM public.rooms r
  WHERE r.owner_id = auth.uid()
    AND (
      (r.status = 'closed'::public.room_status_enum AND r.deleted_at IS NOT NULL)
      OR r.closed_at IS NOT NULL
    )
    AND COALESCE(r.closed_at, r.deleted_at) >= now() - interval '5 days'
  ORDER BY COALESCE(r.closed_at, r.deleted_at) DESC;
END;
$$;

COMMIT;
