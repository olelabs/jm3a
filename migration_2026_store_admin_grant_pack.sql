-- Jma3a Store — Phase 2A foundation, part 2: admin_grant_pack(), the
-- free/no-wallet pack entitlement grant the Store approval workflow
-- will call. purchase_pack() cannot be reused as-is for this: whenever
-- packs.price_mru > 0 it requires the target user to have a wallet with
-- sufficient balance and DEBITS it via apply_wallet_transaction, plus
-- credits the pack creator a 15%-platform-cut commission — both wrong
-- for a Store order, where payment already happened entirely outside
-- Jma3a's wallet system.
--
-- This function is deliberately modeled directly on purchase_pack()'s
-- own structure (same idempotency shape, same pack-status guard, same
-- SECURITY DEFINER + service_role-only grant) with ONLY the
-- wallet-debit and commission block removed — not a rewrite, a
-- subtraction, per the task's own instruction not to "copy and remove
-- random lines" — every remaining line has a direct counterpart in
-- purchase_pack's real body.
--
-- VERIFIED AGAINST LIVE PRODUCTION (via Supabase SQL Editor, not the
-- stale jma3a/schema.sql dump): pack_purchases has UNIQUE
-- (pack_id, buyer_id) and a separate UNIQUE idempotency_key, and
-- price_paid_mru >= 0 explicitly permits a zero-price row — this
-- function's idempotency and zero-price design (below) rests entirely
-- on these confirmed, already-existing constraints, not on any
-- assumption.
--
-- Idempotent (CREATE OR REPLACE), safe to re-run. NOT applied
-- automatically — for manual application only. Not executed against
-- production this session — validated instead against a disposable
-- local Postgres instance built to match the verified facts above (see
-- the final report).

-- ─────────────────────────────────────────────────────────────────────────
-- admin_grant_pack(p_user_id, p_pack_id, p_source, p_idempotency_key)
--
-- Grants a pack to a user with NO wallet transaction and NO creator
-- commission — this is the entire, intentional difference from
-- purchase_pack(). Records price_paid_mru = 0 (accurate: nothing was
-- actually charged through Jma3a's wallet; the real payment happened in
-- the separate Store system) rather than the pack's real price_mru,
-- which would misrepresent an internal transaction that never occurred.
--
-- Idempotency: identical two-layer protection to purchase_pack() — (1)
-- an explicit pre-check against pack_purchases.idempotency_key (the
-- verified, already-existing UNIQUE idempotency_key constraint)
-- short-circuits a retry with the same key before attempting any
-- insert; (2) the INSERT is additionally wrapped to catch
-- unique_violation, which the verified, already-existing
-- UNIQUE (pack_id, buyer_id) constraint makes structurally impossible
-- to violate twice for the same user+pack even if two calls race with
-- different idempotency keys (e.g. a caller that forgot to pass one).
-- No new table, no new uniqueness mechanism — pack_purchases' own
-- existing, verified constraints are what make this safe, exactly as
-- instructed.
--
-- Security: SECURITY DEFINER, REVOKEd from PUBLIC/anon/authenticated,
-- GRANTed to service_role only — byte-for-byte the same posture as
-- purchase_pack(). p_user_id is trusted the same way purchase_pack()
-- already trusts it (a plain parameter, no auth.uid() self-check) —
-- this is safe ONLY because the function is unreachable by anyone but
-- the trusted server-side service_role caller, never by an end user's
-- own session.
--
-- Considered and rejected: adding a `source` column to pack_purchases
-- to persist p_source. pack_purchases has no such column today (unlike
-- subscriptions.purchase_source) and the task calls for the smallest
-- change grounded in the real schema — p_source is accepted and
-- returned in the result jsonb (useful to the caller/for logging) but
-- not persisted onto the row, avoiding an unrequested schema addition.
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.admin_grant_pack(
    p_user_id uuid,
    p_pack_id uuid,
    p_source text DEFAULT 'admin',
    p_idempotency_key text DEFAULT NULL
) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_existing public.pack_purchases;
  v_pack public.packs;
  v_purchase public.pack_purchases;
BEGIN
  IF p_idempotency_key IS NOT NULL THEN
    SELECT * INTO v_existing FROM public.pack_purchases WHERE idempotency_key = p_idempotency_key;
    IF FOUND THEN
      RETURN jsonb_build_object('purchase', to_jsonb(v_existing), 'alreadyGranted', true);
    END IF;
  END IF;

  SELECT * INTO v_pack FROM public.packs WHERE id = p_pack_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'pack_not_found';
  END IF;
  IF v_pack.status NOT IN ('approved', 'draft') THEN
    RAISE EXCEPTION 'pack_unavailable';
  END IF;

  BEGIN
    INSERT INTO public.pack_purchases (pack_id, buyer_id, price_paid_mru, status, idempotency_key)
    VALUES (p_pack_id, p_user_id, 0, 'completed', p_idempotency_key)
    RETURNING * INTO v_purchase;
  EXCEPTION WHEN unique_violation THEN
    SELECT * INTO v_purchase FROM public.pack_purchases WHERE pack_id = p_pack_id AND buyer_id = p_user_id;
    RETURN jsonb_build_object('purchase', to_jsonb(v_purchase), 'alreadyGranted', true);
  END;

  RETURN jsonb_build_object(
    'purchase', to_jsonb(v_purchase),
    'alreadyGranted', false,
    'source', p_source
  );
END;
$$;

ALTER FUNCTION public.admin_grant_pack(uuid, uuid, text, text) OWNER TO postgres;

-- EXECUTE (not ALL) matches the verified live privilege style already
-- used on admin_grant_premium (EXECUTE only for service_role/postgres)
-- — EXECUTE is the only privilege type meaningful on a function, so
-- this is stylistically consistent with, not different in effect from,
-- ALL.
REVOKE ALL ON FUNCTION public.admin_grant_pack(uuid, uuid, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_grant_pack(uuid, uuid, text, text) TO service_role;
