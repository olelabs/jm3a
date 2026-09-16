-- Trial Packs — hotfix for a live production bug in
-- public.try_consume_trial_card(uuid).
--
-- Confirmed production error (PostgrestException, code 42702):
--   column reference "cards_played" is ambiguous
--
-- Root cause: the function is declared RETURNS TABLE(..., cards_played
-- integer, ...), which implicitly creates a PL/pgSQL variable named
-- cards_played in scope for the whole function body. Its UPDATE
-- statement referenced the bare (unqualified) column name
-- cards_played/trial_completed_at, which PostgreSQL cannot resolve
-- between that OUT parameter and the public.pack_trial_usage column of
-- the same name — every call failed with 42702, so no trial card was
-- ever actually consumed (start_pack_trial succeeded, incrementing
-- never did), silently disabling trial enforcement in production
-- because the exception was caught client-side and treated as "not a
-- trial pack this session."
--
-- Fix: alias the target table in the UPDATE and qualify every column
-- reference against that alias, exactly as recommended. No other
-- behavior changes — same signature, same SECURITY DEFINER/search_path,
-- same auth/pack/ownership/trial-state checks, same FOR UPDATE lock,
-- same reason strings, same return shape and values.
--
-- Idempotent (CREATE OR REPLACE), safe to run multiple times, matching
-- this repo's existing migration_2026_*.sql convention. NOT applied
-- automatically — for manual application only.

CREATE OR REPLACE FUNCTION public.try_consume_trial_card(p_pack_id uuid)
RETURNS TABLE (
  allowed boolean,
  reason text,
  cards_played integer,
  trial_card_count integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_pack public.packs;
  v_row public.pack_trial_usage;
  v_new_cards_played integer;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT * INTO v_pack FROM public.packs WHERE id = p_pack_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'pack_not_found' USING ERRCODE = 'P0002';
  END IF;

  IF NOT v_pack.trial_enabled THEN
    RETURN QUERY SELECT true, 'not_trial_pack'::text, 0, 0;
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.pack_purchases
    WHERE pack_id = p_pack_id AND buyer_id = v_uid AND status = 'completed'
      AND (expires_at IS NULL OR expires_at > now())
  ) THEN
    RETURN QUERY SELECT true, 'owned'::text, 0, v_pack.trial_card_count;
    RETURN;
  END IF;

  -- Row lock: a concurrent call for the same user+pack blocks here until
  -- the other transaction commits/rolls back, so the two never both read
  -- the same pre-increment cards_played value.
  SELECT * INTO v_row FROM public.pack_trial_usage
  WHERE user_id = v_uid AND pack_id = p_pack_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'no_active_trial'::text, 0, v_pack.trial_card_count;
    RETURN;
  END IF;

  IF v_row.cards_played >= v_pack.trial_card_count THEN
    RETURN QUERY SELECT false, 'trial_exhausted'::text,
      v_row.cards_played, v_pack.trial_card_count;
    RETURN;
  END IF;

  -- Fix: table alias (ptu) + fully-qualified column references. The
  -- previous unqualified cards_played/trial_completed_at referenced
  -- here were ambiguous against this function's own cards_played OUT
  -- parameter (RETURNS TABLE), causing every call to fail with 42702.
  UPDATE public.pack_trial_usage AS ptu
  SET
    cards_played = ptu.cards_played + 1,
    updated_at = now(),
    trial_completed_at = CASE
      WHEN ptu.cards_played + 1 >= v_pack.trial_card_count THEN now()
      ELSE ptu.trial_completed_at
    END
  WHERE ptu.id = v_row.id
  RETURNING ptu.cards_played INTO v_new_cards_played;

  RETURN QUERY SELECT true, 'trial'::text, v_new_cards_played, v_pack.trial_card_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.try_consume_trial_card(uuid) TO authenticated;
