-- ============================================================================
-- Root-cause fix for the "buyer charged, creator never credited" bug class:
-- the pack-purchase flow used to be several separate REST/RPC round-trips
-- from Node (insert purchase row -> debit buyer -> credit creator ->
-- log commission), so a failure on any later step could leave an earlier
-- step's effect permanently applied with no way to reverse it. This moves
-- the whole flow into one SECURITY DEFINER function — a single Postgres
-- transaction, genuinely all-or-nothing.
--
-- SECURITY: only ever granted to service_role. It trusts p_user_id as
-- given (there is no auth.uid() context when called via the service_role
-- key) — must NEVER be granted to anon/authenticated, or any authenticated
-- user could purchase a pack "as" an arbitrary other user.
-- Safe to re-run.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.purchase_pack(p_user_id uuid, p_pack_id uuid, p_idempotency_key text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_existing public.pack_purchases;
  v_pack public.packs;
  v_price integer;
  v_wallet_id uuid;
  v_wallet_balance integer;
  v_wallet_frozen boolean;
  v_purchase public.pack_purchases;
  v_platform_cut integer;
  v_creator_share integer;
  v_creator_wallet_id uuid;
BEGIN
  IF p_idempotency_key IS NOT NULL THEN
    SELECT * INTO v_existing FROM public.pack_purchases WHERE idempotency_key = p_idempotency_key;
    IF FOUND THEN
      RETURN jsonb_build_object('purchase', to_jsonb(v_existing), 'alreadyPurchased', true);
    END IF;
  END IF;

  SELECT * INTO v_pack FROM public.packs WHERE id = p_pack_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'pack_not_found';
  END IF;
  IF v_pack.status NOT IN ('approved', 'draft') THEN
    RAISE EXCEPTION 'pack_unavailable';
  END IF;

  v_price := coalesce(v_pack.price_mru, 0);

  IF v_price > 0 THEN
    SELECT id, balance_mru, is_frozen INTO v_wallet_id, v_wallet_balance, v_wallet_frozen
    FROM public.wallets WHERE user_id = p_user_id ORDER BY created_at ASC LIMIT 1;
    IF v_wallet_id IS NULL THEN
      RAISE EXCEPTION 'wallet_not_found';
    END IF;
    IF v_wallet_frozen THEN
      RAISE EXCEPTION 'wallet_frozen';
    END IF;
    IF v_wallet_balance < v_price THEN
      RAISE EXCEPTION 'insufficient_funds';
    END IF;
  END IF;

  BEGIN
    INSERT INTO public.pack_purchases (pack_id, buyer_id, price_paid_mru, status, idempotency_key)
    VALUES (p_pack_id, p_user_id, v_price, 'completed', p_idempotency_key)
    RETURNING * INTO v_purchase;
  EXCEPTION WHEN unique_violation THEN
    SELECT * INTO v_purchase FROM public.pack_purchases WHERE pack_id = p_pack_id AND buyer_id = p_user_id;
    RETURN jsonb_build_object('purchase', to_jsonb(v_purchase), 'alreadyPurchased', true);
  END;

  IF v_price = 0 THEN
    RETURN jsonb_build_object('purchase', to_jsonb(v_purchase), 'alreadyPurchased', false);
  END IF;

  PERFORM public.apply_wallet_transaction(
    v_wallet_id, 'purchase', -v_price, v_purchase.id,
    'Pack purchase: ' || p_pack_id::text,
    'pack_purchase_debit:' || v_purchase.id::text, 'wallet'
  );

  v_platform_cut  := round(v_price * 0.15);
  v_creator_share := v_price - v_platform_cut;
  IF v_creator_share > 0 AND v_pack.creator_id IS NOT NULL THEN
    SELECT id INTO v_creator_wallet_id FROM public.wallets
    WHERE user_id = v_pack.creator_id ORDER BY created_at ASC LIMIT 1;

    IF v_creator_wallet_id IS NOT NULL THEN
      PERFORM public.apply_wallet_transaction(
        v_creator_wallet_id, 'commission', v_creator_share, v_purchase.id,
        'Pack sale commission: ' || p_pack_id::text,
        'pack_purchase_commission:' || v_purchase.id::text, 'earnings'
      );

      INSERT INTO public.commissions (
        purchase_id, creator_id, gross_amount_mru, commission_rate,
        commission_amount_mru, creator_payout_mru
      ) VALUES (
        v_purchase.id, v_pack.creator_id, v_price, 0.15, v_platform_cut, v_creator_share
      );
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'purchase', to_jsonb(v_purchase),
    'alreadyPurchased', false,
    'creatorId', v_pack.creator_id,
    'creatorShare', v_creator_share
  );
END;
$$;

ALTER FUNCTION public.purchase_pack(uuid, uuid, text) OWNER TO postgres;

REVOKE ALL ON FUNCTION public.purchase_pack(uuid, uuid, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.purchase_pack(uuid, uuid, text) TO service_role;
