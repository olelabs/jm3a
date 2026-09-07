-- ============================================================================
-- SUPERSEDED — do not apply this file separately. Fully re-embedded,
-- unchanged in intent, in migration_2026_lifecycle_final.sql, which is
-- safe to apply regardless of whether this file was ever run.
-- ============================================================================

-- ============================================================================
-- Root cause for "admin sees the game refresh / multiple lifecycle
-- instances" and "exactly ONE active game session per room" not actually
-- being guaranteed:
--
--   create_game_session (schema.sql:2327) does an unconditional INSERT with
--   no existing-session check at all — every "resume the existing session
--   instead of creating a new one" check (e.g. NhieGameProvider's
--   `if (existing != null) resume else create_game_session(...)`) is
--   client-side only, reading the current active session via a plain
--   SELECT immediately beforehand. Two calls close enough together (a
--   double-tap on Start Game, an owner reconnecting from two tabs/devices,
--   a retried request after a slow response) can both observe "no active
--   session yet" and both proceed to create one — nothing at the database
--   level stops it. A stale comment in room_repository.dart even refers to
--   an index called idx_game_sessions_one_active_per_room enforcing this,
--   but no such index has ever existed in this schema — only
--   idx_game_sessions_status, a plain non-unique performance index.
--
--   Fix: an actual partial unique index makes "at most one active/paused
--   session per room" a real database guarantee instead of a best-effort
--   client-side check, and create_game_session now catches the resulting
--   unique_violation and returns the winning session's id instead of
--   raising an opaque constraint error — so a losing racer transparently
--   joins the session that already won, exactly like the pre-existing
--   "resume, don't recreate" intent, but now actually enforced.
-- ============================================================================

-- Pre-flight cleanup: CREATE UNIQUE INDEX fails outright if any room
-- currently already has more than one active/paused game_sessions row —
-- entirely possible, since that duplicate-session race is exactly the bug
-- this migration closes. Keep only the most-recently-started row per room
-- as the live one; abort the rest (status only — never deletes any row,
-- so nothing referencing them, e.g. game_states/game_rounds/proof views,
-- is orphaned). No-op if no duplicates exist.
WITH ranked AS (
  SELECT id, room_id,
         row_number() OVER (
           PARTITION BY room_id ORDER BY started_at DESC, id DESC
         ) AS rn
  FROM public.game_sessions
  WHERE status IN ('active', 'paused')
)
UPDATE public.game_sessions gs
SET status = 'aborted', ended_at = now(), updated_at = now()
FROM ranked
WHERE gs.id = ranked.id AND ranked.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS "idx_game_sessions_one_active_per_room"
  ON "public"."game_sessions" ("room_id")
  WHERE ("status" IN ('active'::"public"."game_session_status_enum", 'paused'::"public"."game_session_status_enum"));

CREATE OR REPLACE FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_id uuid;
  v_min_players smallint;
  v_eligible_count integer;
BEGIN
  -- Starting a game is owner-only — never delegable to a moderator, even
  -- via a granted permission (previously start_game could be granted,
  -- letting a moderator start the game through this same RPC).
  IF NOT public.is_room_owner(p_room_id, auth.uid()) THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;

  -- Defense-in-depth for the pack's minimum-player requirement and the
  -- "no reconnecting players" rule: the room already flips to in_game
  -- before this RPC runs (lobby_screen.dart's _onStartGame broadcasts and
  -- flips status first), matching the pre-existing pack_already_played
  -- precedent below — this can't be a true pre-flight block without
  -- restructuring that sequence, but it does stop the session (and thus
  -- the actual game) from ever being created.
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

  RETURN v_id;
END;
$$;

ALTER FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb") OWNER TO "postgres";
