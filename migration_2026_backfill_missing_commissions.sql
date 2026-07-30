-- ============================================================================
-- ONE-OFF DATA BACKFILL: credit the 9 pack-sale commissions that were never
-- paid out due to the .catch()-on-Supabase-builder bug in packRoutes.js
-- (fixed separately in code). Buyers were already charged correctly in
-- every case; only the creator's 85% share was never credited.
--
-- Safety:
--   - The entire backfill runs inside ONE DO block = one Postgres
--     transaction. If any purchase/pack/wallet lookup fails partway, the
--     RAISE EXCEPTION aborts the whole block and every change made so far
--     in this block is rolled back automatically — no partial credits.
--   - Each purchase is explicitly checked for an existing commissions row
--     and an existing commission-type wallet_transactions row before
--     crediting anything; either one already present skips that purchase.
--   - apply_wallet_transaction() — the exact same function real purchases
--     use — is also itself idempotent by idempotency_key (returns the
--     existing row instead of re-crediting if that key was already used),
--     so this script is safe to re-run.
-- ============================================================================

DO $$
DECLARE
  v_purchase_ids uuid[] := ARRAY[
    '2aa9fb9c-557a-4a9b-bb85-527a1e4417ab',
    '5852902e-bb01-4d02-81ee-7b641aa05c76',
    '9fc566e5-9d7d-4d08-8760-0455540dea75',
    '763544d3-b4a5-4abb-a81d-b2965a7ecf7a',
    '5b0f079c-392d-40f6-be40-a985f2cec482',
    '9cb7e1a7-d12f-4289-8bdc-44eca59e6906',
    '8ebe0b42-ef25-4404-976b-e7cf690a5518',
    '9c4eb8d7-5b6e-48a3-af89-e678165ba060',
    '14c62e7f-d7b8-4be3-a982-73a17ff968b4'
  ];
  v_id uuid;
  v_purchase public.pack_purchases;
  v_pack public.packs;
  v_creator_wallet_id uuid;
  v_platform_cut integer;
  v_creator_share numeric;
  v_tx public.wallet_transactions;
  v_idem text;
BEGIN
  FOREACH v_id IN ARRAY v_purchase_ids LOOP

    SELECT * INTO v_purchase FROM public.pack_purchases WHERE id = v_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Aborting backfill: purchase % not found', v_id;
    END IF;
    IF v_purchase.status <> 'completed'::public.purchase_status_enum OR v_purchase.price_paid_mru <= 0 THEN
      RAISE EXCEPTION 'Aborting backfill: purchase % is not a completed paid purchase (status=%, price=%)',
        v_id, v_purchase.status, v_purchase.price_paid_mru;
    END IF;

    -- Verify not already backfilled (requirement: check before inserting).
    IF EXISTS (SELECT 1 FROM public.commissions WHERE purchase_id = v_id) THEN
      RAISE NOTICE 'SKIP % — a commissions row already exists', v_id;
      CONTINUE;
    END IF;
    IF EXISTS (
      SELECT 1 FROM public.wallet_transactions
      WHERE reference_id = v_id AND type = 'commission'::public.transaction_type_enum
    ) THEN
      RAISE NOTICE 'SKIP % — a commission wallet_transaction already exists', v_id;
      CONTINUE;
    END IF;

    SELECT * INTO v_pack FROM public.packs WHERE id = v_purchase.pack_id;
    IF NOT FOUND OR v_pack.creator_id IS NULL THEN
      RAISE EXCEPTION 'Aborting backfill: pack % not found or has no creator', v_purchase.pack_id;
    END IF;

    SELECT id INTO v_creator_wallet_id FROM public.wallets
    WHERE user_id = v_pack.creator_id ORDER BY created_at ASC LIMIT 1;
    IF v_creator_wallet_id IS NULL THEN
      RAISE EXCEPTION 'Aborting backfill: no wallet found for creator % (pack %)', v_pack.creator_id, v_purchase.pack_id;
    END IF;

    v_platform_cut  := round(v_purchase.price_paid_mru * 0.15);
    v_creator_share := v_purchase.price_paid_mru - v_platform_cut;
    v_idem := 'pack_purchase_commission:' || v_id::text;

    -- The exact same function real, live purchases use for the credit.
    v_tx := public.apply_wallet_transaction(
      v_creator_wallet_id, 'commission', v_creator_share::integer, v_id,
      'Pack sale commission (backfill): ' || v_purchase.pack_id::text,
      v_idem, 'earnings'
    );

    INSERT INTO public.commissions (
      purchase_id, creator_id, gross_amount_mru, commission_rate,
      commission_amount_mru, creator_payout_mru
    ) VALUES (
      v_id, v_pack.creator_id, v_purchase.price_paid_mru, 0.15,
      v_platform_cut, v_creator_share::integer
    );

    RAISE NOTICE 'BACKFILLED % — credited % MRU to wallet % (wallet_transactions.id=%)',
      v_id, v_creator_share, v_creator_wallet_id, v_tx.id;

  END LOOP;
END $$;


-- ── Verification: any remaining completed paid purchase with no commission?
-- Should return zero rows once the block above has run successfully.
SELECT pp.id AS purchase_id, pp.pack_id, pp.price_paid_mru, pp.purchased_at
FROM public.pack_purchases pp
WHERE pp.status = 'completed'::public.purchase_status_enum
  AND pp.price_paid_mru > 0
  AND NOT EXISTS (SELECT 1 FROM public.commissions c WHERE c.purchase_id = pp.id);
