-- Jma3a Store — financial accounting for Store order approval.
--
-- Adds ONE new function, admin_record_store_revenue(). Does not modify
-- purchase_pack(), record_platform_earning(), apply_wallet_transaction(),
-- admin_grant_pack(), admin_grant_premium(), any Finance/Earnings
-- reporting RPC, or any existing table's schema. Purely additive.
--
-- WHY a new function instead of extending an existing one: purchase_pack()
-- always debits the buyer's wallet (wrong here — the Store customer never
-- had a wallet balance to charge, per the existing admin_grant_pack()
-- design it must stay consistent with) and has no "100% platform, no
-- creator split" branch at all (official packs bought in-app today still
-- go through the ordinary 85/15 split to the official account's own
-- wallet — confirmed by reading its live body; that is NOT what these
-- business rules want for Store official-pack sales). record_platform_
-- earning() is a single-purpose ledger-insert primitive with no branching
-- logic and, per this task's own instruction, must not be modified.
--
-- SCHEMA FACTS THIS FUNCTION IS BUILT ON — verified against LIVE
-- PRODUCTION this session (via PostgREST's own schema introspection and
-- read-only, non-mutating calls; the checked-in schema.sql is known
-- stale for this area and was not relied on):
--   * commissions(id, purchase_id NOT NULL FK->pack_purchases.id,
--     creator_id NOT NULL, gross_amount_mru, commission_rate default
--     0.15, commission_amount_mru, creator_payout_mru, created_at) — all
--     8 columns NOT NULL. No UNIQUE constraint on purchase_id could be
--     confirmed (PostgREST's schema introspection does not expose
--     non-PK constraints, and no direct SQL/catalog access is available
--     in this environment) — this function therefore does NOT rely on
--     one and explicitly checks for an existing row itself (see below).
--   * platform_earnings(id, source NOT NULL, reference_id NULLABLE,
--     user_id NULLABLE FK->profiles.id, amount_mru NOT NULL, currency
--     NOT NULL default 'MRU', description NULLABLE, created_at) — same
--     caveat: no uniqueness on (source, reference_id) could be confirmed,
--     so this function does not assume record_platform_earning() is
--     itself idempotent (per this task's explicit instruction) and
--     explicitly checks first.
--   * record_platform_earning(p_source text, p_reference_id uuid,
--     p_user_id uuid, p_amount_mru integer, p_currency text DEFAULT,
--     p_description text DEFAULT) — p_source/p_reference_id/p_user_id/
--     p_amount_mru are all REQUIRED (no default) — confirmed via live
--     signature introspection. Its return type could not be confirmed
--     (PostgREST's OpenAPI output does not expose RPC return shapes),
--     so it is called with PERFORM, never `SELECT * INTO ...`, which
--     works correctly regardless of what it actually returns.
--   * admin_grant_premium(...) RETURNS void (confirmed — this session's
--     own migration_2026_store_admin_grant_premium_hardening.sql) — it
--     never gives the caller a subscription id. Its idempotency key is
--     stored verbatim in subscriptions.store_transaction_id (same file),
--     so the subscription row it created/found is recovered here via
--     (user_id, store_transaction_id = p_idempotency_key) — the exact
--     same pair subscriptions_user_id_store_transaction_id_key already
--     uniquely indexes — rather than adding any new column or touching
--     admin_grant_premium() itself.
--
-- Idempotent (CREATE OR REPLACE), safe to re-run. NOT applied
-- automatically — for manual application only, per this task's explicit
-- instruction. Not executed against production this session.

-- ─────────────────────────────────────────────────────────────────────────
-- admin_record_store_revenue(p_idempotency_key, p_product_type, p_user_id,
--   p_amount_mru, p_pack_id, p_pack_purchase_id)
--
-- Called by jma3a-api's storeOrdersService.approveOrder() immediately
-- after the entitlement grant (admin_grant_pack/admin_grant_premium)
-- succeeds, inside the SAME try/catch — a failure here is handled
-- identically to a grant failure (order -> grant_failed, retryable).
--
-- p_idempotency_key is the SAME 'store_order:<orderId>' string already
-- passed to admin_grant_pack/admin_grant_premium — the external
-- accounting identity this whole task specifies. p_user_id is always the
-- resolved Store CUSTOMER's Jma3a uuid (never an admin, official-account,
-- or creator id) — required for every branch, including the official-
-- pack and subscription cases, per this task's explicit instruction.
--
-- p_product_type: 'pack' | 'premium' | 'premium_plus' (mirrors
-- store_orders.product_snapshot.product_type, already trusted for this
-- exact purpose by the existing grant step immediately before this
-- call — not a new trust boundary).
--
-- For 'pack': p_pack_id (Jma3a packs.id) and p_pack_purchase_id (the
-- pack_purchases.id admin_grant_pack already created/found, returned in
-- its own jsonb result) are both required. Officialness is re-derived
-- HERE, from packs.creator_id -> profiles.is_official_account — NEVER
-- from the Store's own product_snapshot/creator_display_name, per this
-- task's explicit instruction (the Store schema doesn't even capture
-- officialness at all — confirmed this session).
--
-- Idempotency (explicit, not assumed): the row this call's accounting is
-- "about" is locked FOR UPDATE first (pack_purchases row for a pack,
-- subscriptions row for a subscription) — this serializes two concurrent
-- calls for the same purchase/subscription so the existence check right
-- after can never race. Then:
--   * creator-split pack: checks for an existing commissions row with
--     this purchase_id BEFORE any wallet credit or insert. Found ->
--     returns immediately, nothing written (never a second 85% credit).
--   * platform-only pack / subscription: checks for an existing
--     platform_earnings row with this exact (source, reference_id)
--     BEFORE calling record_platform_earning(). Found -> returns
--     immediately.
-- Every write this function makes (the wallet credit, the commissions
-- insert, the platform_earnings insert) happens inside this ONE
-- function call, i.e. one Postgres transaction — an error anywhere
-- rolls back everything this call did, so a genuinely PARTIAL write
-- (e.g. creator credited but no commissions row) cannot occur from a
-- single invocation. The only "missing accounting" a retry can ever
-- find is "this call was never reached, or never completed, on a prior
-- attempt" — exactly what the existence checks above detect.
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.admin_record_store_revenue(
    p_idempotency_key text,
    p_product_type text,
    p_user_id uuid,
    p_amount_mru integer,
    p_pack_id uuid DEFAULT NULL,
    p_pack_purchase_id uuid DEFAULT NULL
) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_pack public.packs;
  v_is_official boolean;
  v_platform_cut integer;
  v_creator_share integer;
  v_creator_wallet_id uuid;
  v_commission public.commissions;
  v_subscription_id uuid;
BEGIN
  IF p_idempotency_key IS NULL OR p_user_id IS NULL OR p_amount_mru IS NULL THEN
    RAISE EXCEPTION 'missing_required_argument';
  END IF;

  IF p_product_type = 'pack' THEN
    IF p_pack_id IS NULL OR p_pack_purchase_id IS NULL THEN
      RAISE EXCEPTION 'missing_pack_arguments';
    END IF;

    -- Serializes any concurrent/duplicate accounting attempt for this
    -- SAME purchase — the existence checks below can never race once
    -- this lock is held.
    PERFORM 1 FROM public.pack_purchases WHERE id = p_pack_purchase_id FOR UPDATE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'pack_purchase_not_found';
    END IF;

    -- Never trust Store-side officialness/creator info (the Store
    -- schema doesn't even capture it) — re-derive from Jma3a's own
    -- authoritative data, exactly as instructed.
    SELECT * INTO v_pack FROM public.packs WHERE id = p_pack_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'pack_not_found';
    END IF;

    SELECT is_official_account INTO v_is_official
    FROM public.profiles WHERE id = v_pack.creator_id;
    v_is_official := COALESCE(v_is_official, false);

    IF v_is_official THEN
      -- Official / platform-managed pack: 100% platform, no creator
      -- payout, no commissions row.
      IF EXISTS (
        SELECT 1 FROM public.platform_earnings
        WHERE source = 'pack_sale_commission' AND reference_id = p_pack_purchase_id
      ) THEN
        RETURN jsonb_build_object('alreadyAccounted', true, 'mode', 'platform_only');
      END IF;

      PERFORM public.record_platform_earning(
        'pack_sale_commission', p_pack_purchase_id, p_user_id, p_amount_mru,
        'MRU', 'Store pack sale (official pack): ' || p_pack_purchase_id::text
      );

      RETURN jsonb_build_object('alreadyAccounted', false, 'mode', 'platform_only');
    ELSE
      -- Normal creator pack: same 15%/85% split purchase_pack() already
      -- uses, unchanged rate, same rounding.
      IF EXISTS (SELECT 1 FROM public.commissions WHERE purchase_id = p_pack_purchase_id) THEN
        RETURN jsonb_build_object('alreadyAccounted', true, 'mode', 'creator_split');
      END IF;

      v_platform_cut  := round(p_amount_mru * 0.15);
      v_creator_share := p_amount_mru - v_platform_cut;

      SELECT id INTO v_creator_wallet_id FROM public.wallets
      WHERE user_id = v_pack.creator_id ORDER BY created_at ASC LIMIT 1;
      IF v_creator_wallet_id IS NULL THEN
        RAISE EXCEPTION 'creator_wallet_not_found';
      END IF;

      PERFORM public.apply_wallet_transaction(
        v_creator_wallet_id, 'commission', v_creator_share, p_pack_purchase_id,
        'Store pack sale commission: ' || p_pack_purchase_id::text,
        p_idempotency_key || ':creator_commission', 'earnings'
      );

      INSERT INTO public.commissions (
        purchase_id, creator_id, gross_amount_mru, commission_rate,
        commission_amount_mru, creator_payout_mru
      ) VALUES (
        p_pack_purchase_id, v_pack.creator_id, p_amount_mru, 0.15, v_platform_cut, v_creator_share
      ) RETURNING * INTO v_commission;

      PERFORM public.record_platform_earning(
        'pack_sale_commission', p_pack_purchase_id, p_user_id, v_platform_cut,
        'MRU', 'Store pack sale commission (platform share): ' || p_pack_purchase_id::text
      );

      RETURN jsonb_build_object('alreadyAccounted', false, 'mode', 'creator_split', 'commissionId', v_commission.id);
    END IF;

  ELSIF p_product_type IN ('premium', 'premium_plus') THEN
    -- admin_grant_premium() returns void — recover the subscription row
    -- IT created/found via the exact (user_id, store_transaction_id)
    -- pair its own idempotency already keys on, rather than adding any
    -- new column or touching that function.
    SELECT id INTO v_subscription_id FROM public.subscriptions
    WHERE user_id = p_user_id AND store_transaction_id = p_idempotency_key
    FOR UPDATE;
    IF v_subscription_id IS NULL THEN
      RAISE EXCEPTION 'subscription_not_found';
    END IF;

    IF EXISTS (
      SELECT 1 FROM public.platform_earnings
      WHERE source = 'subscription' AND reference_id = v_subscription_id
    ) THEN
      RETURN jsonb_build_object('alreadyAccounted', true, 'mode', 'platform_only');
    END IF;

    PERFORM public.record_platform_earning(
      'subscription', v_subscription_id, p_user_id, p_amount_mru,
      'MRU', 'Store subscription purchase: ' || v_subscription_id::text
    );

    RETURN jsonb_build_object('alreadyAccounted', false, 'mode', 'platform_only');
  ELSE
    RAISE EXCEPTION 'unsupported_product_type';
  END IF;
END;
$$;

ALTER FUNCTION public.admin_record_store_revenue(text, text, uuid, integer, uuid, uuid) OWNER TO postgres;

REVOKE ALL ON FUNCTION public.admin_record_store_revenue(text, text, uuid, integer, uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_record_store_revenue(text, text, uuid, integer, uuid, uuid) TO service_role;
