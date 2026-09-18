-- Jma3a Store — Phase 2A foundation, part 4: admin_grant_premium()
-- idempotency for Store-driven grants.
--
-- CORRECTION vs. an earlier draft of this file: that draft framed this
-- migration as fixing a privilege vulnerability (admin_grant_premium
-- callable by anon/authenticated). VERIFIED AGAINST LIVE PRODUCTION
-- (via Supabase SQL Editor): admin_grant_premium(uuid,integer,text,text)
-- currently has EXECUTE only for service_role and postgres — that
-- privilege restriction is ALREADY CORRECT in production today. This is
-- NOT a new finding and NOT something this migration needs to fix; the
-- stale jma3a/schema.sql dump the earlier draft was reading (which
-- showed GRANT ALL to anon/authenticated) does not reflect production.
--
-- The ONLY thing actually needed here is adding Store-specific
-- idempotency (an optional p_idempotency_key parameter) — nothing about
-- authorization, renewal semantics, or any other existing behavior.
--
-- Mechanical note on WHY a DROP is still required even though this is
-- no longer a privilege fix: PostgreSQL identifies a function by its
-- full argument-type signature. A plain CREATE OR REPLACE that appends
-- a new parameter does NOT replace the existing 4-argument function —
-- it creates a second, additional 5-argument overload, leaving both
-- callable side by side (and ambiguous for a caller that omits the new
-- parameter, since both signatures would match). This migration
-- therefore still DROPs the old 4-argument signature first, purely to
-- avoid that overload ambiguity — confirmed safe because this session
-- (and the prior one) found zero existing callers anywhere in
-- jma3a-api or the Flutter app. If a caller is later found that this
-- session missed, drop the DROP FUNCTION statement below and keep both
-- signatures instead.
--
-- Consequence of using DROP + CREATE instead of a same-signature
-- REPLACE: PostgreSQL does NOT carry privileges over from a dropped
-- function to a newly created one (they are different objects as far
-- as GRANT/REVOKE bookkeeping is concerned) — a fresh CREATE FUNCTION
-- starts with NO grants to anyone but the owner. The GRANT at the
-- bottom of this file is therefore a functional NECESSITY (without it,
-- even the trusted service_role caller could not call the new 5-arg
-- function at all), not a security fix — it simply RESTATES the
-- already-correct, already-verified production posture (EXECUTE for
-- service_role only) on the new function object.
--
-- Idempotent (the DROP+CREATE pair is safe to re-run — the second run's
-- DROP IF EXISTS on the 4-arg signature is simply a no-op once it's
-- already gone). NOT applied automatically — for manual application
-- only. Not executed against production this session — validated
-- instead against a disposable local Postgres instance built to match
-- the verified facts above (see the final report).

DROP FUNCTION IF EXISTS public.admin_grant_premium(uuid, integer, text, text);

-- ─────────────────────────────────────────────────────────────────────────
-- admin_grant_premium(p_user_id, p_days, p_tier, p_source,
-- p_idempotency_key)
--
-- Body is otherwise UNCHANGED from the original (still a plain insert
-- into subscriptions — this migration deliberately does not touch
-- renewal/extension semantics, per the task's explicit instruction not
-- to unnecessarily change existing subscription behavior) except for
-- the added idempotency handling.
--
-- Idempotency, following the existing convention (a nullable
-- idempotency-bearing column + a real UNIQUE constraint) rather than
-- inventing a new one: subscriptions already has exactly this shape,
-- VERIFIED live — UNIQUE (user_id, store_transaction_id) — used today
-- by walletService.purchaseSubscription's own idempotency check for the
-- 'wallet' purchase_source. This reuses that SAME column/constraint:
-- p_idempotency_key, when given, is stored as store_transaction_id.
--
-- Carefully considered: does reusing store_transaction_id risk
-- colliding with real App Store/Google Play transaction ids (the
-- 'ios'/'android' purchase_source rows already stored in this same
-- column)? No — the unique constraint is composite, UNIQUE(user_id,
-- store_transaction_id), so a collision requires the SAME user to have
-- two DIFFERENT purchase_source rows whose store_transaction_id string
-- happens to be byte-identical. Apple/Google's own transaction
-- identifiers and this Store's own idempotency keys (the intended
-- caller convention is 'store_order:<store_orders.id>', a uuid-derived
-- string) are drawn from entirely independent, non-overlapping id
-- formats/namespaces, so an accidental collision is not a realistic
-- concern — and even in the astronomically unlikely event of one, the
-- effect is only a false idempotency short-circuit for that one
-- (user, key) pair, not data corruption or a cross-user leak. No schema
-- change, no new column, no new constraint — this migration only adds
-- application logic around a column/constraint that already exists and
-- is already safely shared across purchase sources.
--
-- A pre-check short-circuits an exact retry; the INSERT is additionally
-- wrapped to catch unique_violation for a race between two concurrent
-- calls carrying the same key.
--
-- IMPORTANT for the later jma3a-api Store-bridge phase:
-- subscriptions_purchase_source_check only allows
-- ('ios','android','admin','promo','web','wallet') — VERIFIED live —
-- a Store-driven call MUST pass p_source='web' (the value this
-- constraint already anticipates for exactly this purpose), not
-- 'store'.
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.admin_grant_premium(
    p_user_id uuid,
    p_days integer DEFAULT 30,
    p_tier text DEFAULT 'premium'::text,
    p_source text DEFAULT 'admin'::text,
    p_idempotency_key text DEFAULT NULL::text
) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_existing public.subscriptions;
BEGIN
  IF p_idempotency_key IS NOT NULL THEN
    SELECT * INTO v_existing FROM public.subscriptions
    WHERE user_id = p_user_id AND store_transaction_id = p_idempotency_key;
    IF FOUND THEN
      RETURN;
    END IF;
  END IF;

  BEGIN
    INSERT INTO public.subscriptions (
      user_id, tier, status, purchase_source, store_transaction_id,
      started_at, expires_at, auto_renew
    ) VALUES (
      p_user_id, p_tier, 'active', p_source, p_idempotency_key,
      now(), now() + (p_days || ' days')::interval, false
    );
  EXCEPTION WHEN unique_violation THEN
    -- Same (user_id, idempotency key) retried concurrently — the row
    -- already exists (or is being committed by the other call), nothing
    -- further to do here.
    NULL;
  END;
END;
$$;

ALTER FUNCTION public.admin_grant_premium(uuid, integer, text, text, text) OWNER TO postgres;

-- NOT a security fix (see header) — restates the already-verified,
-- already-correct production posture (EXECUTE for service_role only)
-- on the newly (re)created function object, since DROP + CREATE does
-- not carry privileges over. REVOKE lines are belt-and-suspenders
-- documentation of intent, not a change from any known-insecure state.
REVOKE ALL ON FUNCTION public.admin_grant_premium(uuid, integer, text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_grant_premium(uuid, integer, text, text, text) TO service_role;
