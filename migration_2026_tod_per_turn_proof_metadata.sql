-- Server-authoritative per-turn proof visibility + viewing rules.
--
-- Root cause: proof visibility became a per-submission choice (chosen by
-- the player right before pressing Done on a Dare), but record_proof_view
-- only ever checked room_settings.proof_visibility_policy — a room-wide
-- DEFAULT, never updated per turn. A viewer's authorization therefore
-- never actually reflected the submitting player's own per-turn choice,
-- and the shared broadcast game state (where the per-turn choice DOES
-- live) is only ever durably persisted every ~10s
-- (TodRepository.saveSnapshot) — far too stale to safely gate access.
--
-- Adds a small, synchronously-written table for exactly this turn's proof
-- metadata (visibility + viewing mode/duration), and makes
-- record_proof_view prefer it — falling back to the OLD room_settings
-- read verbatim when no per-turn row exists (an older client, or any
-- session that predates this), so existing behavior is fully preserved
-- for anything that doesn't use the new path.

BEGIN;

CREATE TABLE IF NOT EXISTS "public"."tod_turn_proofs" (
    "session_id" "uuid" NOT NULL,
    "turn_started_at" bigint NOT NULL,
    "visibility" "text" DEFAULT 'everyone'::"text" NOT NULL,
    "visible_to_ids" "uuid"[] DEFAULT '{}'::"uuid"[] NOT NULL,
    "view_mode" "text" DEFAULT 'once'::"text" NOT NULL,
    "view_seconds" integer DEFAULT 5 NOT NULL,
    "submitted_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "tod_turn_proofs_pkey" PRIMARY KEY ("session_id", "turn_started_at"),
    CONSTRAINT "tod_turn_proofs_visibility_check" CHECK (("visibility" = ANY (ARRAY['everyone'::"text", 'players_only'::"text", 'spectators_only'::"text", 'selected'::"text"]))),
    CONSTRAINT "tod_turn_proofs_view_mode_check" CHECK (("view_mode" = ANY (ARRAY['once'::"text", 'timed'::"text", 'replay_once'::"text"]))),
    CONSTRAINT "tod_turn_proofs_view_seconds_check" CHECK (("view_seconds" >= 0))
);

ALTER TABLE "public"."tod_turn_proofs" OWNER TO "postgres";

ALTER TABLE ONLY "public"."tod_turn_proofs"
    ADD CONSTRAINT "tod_turn_proofs_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."game_sessions"("id") ON DELETE CASCADE;

-- No general-access policies — every read/write goes exclusively through
-- the two SECURITY DEFINER RPCs below (record_proof_view already reads
-- this table; save_tod_proof_metadata is the only writer), so RLS stays
-- enabled with a default-deny for direct table access.
ALTER TABLE "public"."tod_turn_proofs" ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE "public"."tod_turn_proofs" TO "anon";
GRANT ALL ON TABLE "public"."tod_turn_proofs" TO "authenticated";
GRANT ALL ON TABLE "public"."tod_turn_proofs" TO "service_role";


CREATE OR REPLACE FUNCTION "public"."save_tod_proof_metadata"(
    "p_session_id" "uuid",
    "p_turn_started_at" bigint,
    "p_visibility" "text",
    "p_visible_to_ids" "uuid"[],
    "p_view_mode" "text",
    "p_view_seconds" integer
) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_room_id uuid;
BEGIN
  SELECT room_id INTO v_room_id FROM public.game_sessions WHERE id = p_session_id;
  IF v_room_id IS NULL THEN
    RAISE EXCEPTION 'session_not_found';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.room_members
    WHERE room_id = v_room_id AND user_id = auth.uid() AND left_at IS NULL
  ) THEN
    RAISE EXCEPTION 'not_a_member';
  END IF;

  IF p_visibility NOT IN ('everyone', 'players_only', 'spectators_only', 'selected') THEN
    RAISE EXCEPTION 'invalid_visibility';
  END IF;
  IF p_view_mode NOT IN ('once', 'timed', 'replay_once') THEN
    RAISE EXCEPTION 'invalid_view_mode';
  END IF;

  INSERT INTO public.tod_turn_proofs
    (session_id, turn_started_at, visibility, visible_to_ids, view_mode, view_seconds, submitted_by)
  VALUES
    (p_session_id, p_turn_started_at, p_visibility, COALESCE(p_visible_to_ids, '{}'),
     p_view_mode, GREATEST(p_view_seconds, 0), auth.uid())
  ON CONFLICT (session_id, turn_started_at) DO UPDATE
    SET visibility = EXCLUDED.visibility,
        visible_to_ids = EXCLUDED.visible_to_ids,
        view_mode = EXCLUDED.view_mode,
        view_seconds = EXCLUDED.view_seconds;
END;
$$;

ALTER FUNCTION "public"."save_tod_proof_metadata"("p_session_id" "uuid", "p_turn_started_at" bigint, "p_visibility" "text", "p_visible_to_ids" "uuid"[], "p_view_mode" "text", "p_view_seconds" integer) OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."save_tod_proof_metadata"("p_session_id" "uuid", "p_turn_started_at" bigint, "p_visibility" "text", "p_visible_to_ids" "uuid"[], "p_view_mode" "text", "p_view_seconds" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."save_tod_proof_metadata"("p_session_id" "uuid", "p_turn_started_at" bigint, "p_visibility" "text", "p_visible_to_ids" "uuid"[], "p_view_mode" "text", "p_view_seconds" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."save_tod_proof_metadata"("p_session_id" "uuid", "p_turn_started_at" bigint, "p_visibility" "text", "p_visible_to_ids" "uuid"[], "p_view_mode" "text", "p_view_seconds" integer) TO "service_role";


-- record_proof_view: prefer the per-turn row; fall back to the existing
-- room_settings read verbatim when absent.
CREATE OR REPLACE FUNCTION "public"."record_proof_view"("p_session_id" "uuid", "p_turn_started_at" bigint) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_room_id uuid;
  v_role public.room_member_role_enum;
  v_policy text;
  v_replay_mode text;
  v_selected_ids uuid[];
  v_is_premium boolean;
  v_existing_count integer;
  v_max_views integer;
  v_view_number integer;
  v_has_turn_proof boolean := false;
BEGIN
  SELECT room_id INTO v_room_id FROM public.game_sessions WHERE id = p_session_id;
  IF v_room_id IS NULL THEN
    RAISE EXCEPTION 'session_not_found';
  END IF;

  SELECT role INTO v_role FROM public.room_members
  WHERE room_id = v_room_id AND user_id = auth.uid() AND left_at IS NULL;
  IF v_role IS NULL THEN
    RAISE EXCEPTION 'not_a_member';
  END IF;

  SELECT true, visibility, view_mode, visible_to_ids
    INTO v_has_turn_proof, v_policy, v_replay_mode, v_selected_ids
  FROM public.tod_turn_proofs
  WHERE session_id = p_session_id AND turn_started_at = p_turn_started_at;

  IF NOT COALESCE(v_has_turn_proof, false) THEN
    SELECT proof_visibility_policy, proof_replay_mode, proof_visibility_selected_user_ids
      INTO v_policy, v_replay_mode, v_selected_ids
    FROM public.room_settings WHERE room_id = v_room_id;
  END IF;

  IF v_policy = 'players_only' AND v_role = 'spectator'::public.room_member_role_enum THEN
    RAISE EXCEPTION 'not_permitted';
  END IF;
  IF v_policy = 'spectators_only' AND v_role <> 'spectator'::public.room_member_role_enum THEN
    RAISE EXCEPTION 'not_permitted';
  END IF;
  IF v_policy = 'selected' AND NOT (auth.uid() = ANY(v_selected_ids)) THEN
    RAISE EXCEPTION 'not_permitted';
  END IF;

  SELECT is_premium INTO v_is_premium FROM public.profiles WHERE id = auth.uid();

  v_max_views := CASE
    WHEN v_replay_mode = 'replay_once' THEN 2 + (CASE WHEN v_is_premium THEN 1 ELSE 0 END)
    ELSE 1 -- 'once' or 'timed' — a single view, no replay
  END;

  SELECT count(*) INTO v_existing_count FROM public.tod_proof_views
  WHERE session_id = p_session_id AND turn_started_at = p_turn_started_at AND viewer_id = auth.uid();

  IF v_existing_count >= v_max_views THEN
    RAISE EXCEPTION 'view_limit_exceeded';
  END IF;

  v_view_number := v_existing_count + 1;

  INSERT INTO public.tod_proof_views (session_id, turn_started_at, viewer_id, view_number)
  VALUES (p_session_id, p_turn_started_at, auth.uid(), v_view_number);

  RETURN jsonb_build_object(
    'allowed', true,
    'viewNumber', v_view_number,
    'maxViews', v_max_views,
    'viewsRemaining', v_max_views - v_view_number
  );
END;
$$;

COMMIT;
