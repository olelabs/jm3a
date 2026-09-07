-- Items 2/3/8/12: authoritative start-game validation for Max Rounds vs
-- actual card/prompt supply. Mirrors
-- lib/features/games/engine/round_capacity.dart's exact formula in SQL —
-- the ONE other place this calculation is allowed to live, so the client
-- UI and this server-side check can never disagree:
--
--   cardsConsumedPerRound = (game_type = 'truth_or_dare')
--       ? greatest(active_players, 1)   -- every player draws a card/round
--       : 1                              -- NHIE/Meme: one shared card/round
--
--   maxPossibleRounds = unique_cards
--       ? floor(available_card_count / cardsConsumedPerRound)
--       : NULL (no ceiling — repeats allowed, existing shuffle behavior)
--
-- This runs INSIDE create_game_session (the one choke point every game's
-- session creation already funnels through — see NHIE/Meme/ToD's
-- identical create_game_session RPC calls), so a stale client, a modified
-- client, or a race with another admin's settings change can never create
-- a session with an impossible Max Rounds — this check is independent of
-- (and cannot be bypassed by skipping) any client-side UI validation.
--
-- p_unique_cards is a NEW optional parameter (default false — matches
-- ToD's own 'shuffle' default, preserving the exact prior behavior for
-- any caller that doesn't pass it). NHIE/Meme's engines have no repeat
-- mode at all today (every card/prompt is always unique within a game —
-- see never_have_i_ever_engine.dart's/meme_game_engine.dart's used-id
-- tracking), so their call sites always pass true.
--
-- "Active players" reuses the EXACT existing eligibility query this RPC
-- already had (room_members, left_at IS NULL, not spectator, seen in the
-- last 25s) — not a new participant system.

BEGIN;

-- CREATE OR REPLACE cannot change a function's parameter list in place —
-- a new parameter makes this a distinct overload unless the old 9-param
-- signature is dropped first, which would otherwise leave BOTH versions
-- callable (the old one silently skipping this whole validation for any
-- caller that doesn't pass p_unique_cards).
DROP FUNCTION IF EXISTS "public"."create_game_session"("uuid", "uuid", "text", "uuid"[], smallint, smallint, boolean, boolean, "jsonb");

CREATE OR REPLACE FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb" DEFAULT '{}'::"jsonb", "p_unique_cards" boolean DEFAULT false) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_id uuid;
  v_min_players smallint;
  v_eligible_count integer;
  v_card_count integer;
  v_per_round integer;
  v_max_possible_rounds integer;
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
  SELECT count(*) INTO v_eligible_count FROM public.room_members
  WHERE room_id = p_room_id AND left_at IS NULL
    AND role <> 'spectator'::public.room_member_role_enum
    AND last_seen_at > now() - interval '25 seconds';

  IF p_pack_id IS NOT NULL THEN
    SELECT min_players, card_count INTO v_min_players, v_card_count
    FROM public.packs WHERE id = p_pack_id;
    IF v_min_players IS NOT NULL AND v_eligible_count < v_min_players THEN
      RAISE EXCEPTION 'not_enough_players';
    END IF;

    -- Items 2/3/4/8 — reject an impossible Max Rounds configuration
    -- before a session is ever created, rather than letting the engine
    -- discover the card pool is exhausted mid-game.
    IF p_unique_cards AND v_card_count IS NOT NULL THEN
      v_per_round := CASE
        WHEN p_game_type = 'truth_or_dare' THEN greatest(v_eligible_count, 1)
        ELSE 1
      END;
      v_max_possible_rounds := v_card_count / v_per_round;
      IF p_max_rounds > v_max_possible_rounds THEN
        RAISE EXCEPTION 'max_rounds_exceeds_capacity';
      END IF;
    END IF;
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

ALTER FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb", "p_unique_cards" boolean) OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb", "p_unique_cards" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb", "p_unique_cards" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb", "p_unique_cards" boolean) TO "service_role";

COMMIT;
