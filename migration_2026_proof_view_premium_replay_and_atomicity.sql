-- Item 2: premium image-proof replay (initial + 2 replays = 3 total for
-- 'once'/'timed' image proof; free viewers unchanged at 1) + atomic/
-- idempotent view recording so two rapid/concurrent replay requests from
-- the same viewer can never both pass the count check and jointly exceed
-- the maximum (the previous SELECT-count-then-INSERT was a classic
-- check-then-act race under concurrent calls).
--
-- pg_advisory_xact_lock (transaction-scoped, auto-released at COMMIT, no
-- manual unlock needed) serializes concurrent record_proof_view calls for
-- the SAME (session, turn, viewer) key — exactly the "one viewer
-- double-tapping Replay" scenario — without introducing a new table or
-- locking unrelated rows for other viewers/turns.
--
-- replayOnce's own existing formula (2, +1 for premium) is untouched —
-- not part of this change.

BEGIN;

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
  -- Serializes this function's check-then-insert for this exact
  -- (session, turn, viewer) triple only — a concurrent call for a
  -- DIFFERENT viewer, turn, or session is never blocked by this.
  PERFORM pg_advisory_xact_lock(
    hashtextextended(
      p_session_id::text || ':' || p_turn_started_at::text || ':' || auth.uid()::text,
      0
    )
  );

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

  -- Item 2: 'once'/'timed' image proof now grants Premium viewers the
  -- initial view + 2 replays (3 total) — previously capped at 1 view
  -- regardless of premium for these two modes. Free viewers unchanged.
  v_max_views := CASE
    WHEN v_replay_mode = 'replay_once' THEN 2 + (CASE WHEN v_is_premium THEN 1 ELSE 0 END)
    ELSE 1 + (CASE WHEN v_is_premium THEN 2 ELSE 0 END)
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
