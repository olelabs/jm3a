


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE TYPE "public"."card_type_enum" AS ENUM (
    'truth',
    'dare',
    'statement',
    'prompt'
);


ALTER TYPE "public"."card_type_enum" OWNER TO "postgres";


CREATE TYPE "public"."difficulty_enum" AS ENUM (
    'mild',
    'medium',
    'spicy'
);


ALTER TYPE "public"."difficulty_enum" OWNER TO "postgres";


CREATE TYPE "public"."friendship_status_enum" AS ENUM (
    'pending',
    'accepted',
    'rejected',
    'blocked'
);


ALTER TYPE "public"."friendship_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."game_session_status_enum" AS ENUM (
    'active',
    'paused',
    'completed',
    'aborted'
);


ALTER TYPE "public"."game_session_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."game_type_enum" AS ENUM (
    'truth_or_dare',
    'never_have_i_ever',
    'meme_game'
);


ALTER TYPE "public"."game_type_enum" OWNER TO "postgres";


CREATE TYPE "public"."moderation_action_type_enum" AS ENUM (
    'warn',
    'mute',
    'room_ban',
    'platform_ban',
    'content_removed',
    'account_suspended',
    'verification_revoked'
);


ALTER TYPE "public"."moderation_action_type_enum" OWNER TO "postgres";


CREATE TYPE "public"."notification_type_enum" AS ENUM (
    'friend_request',
    'friend_accepted',
    'room_invite',
    'room_started',
    'room_join_request',
    'room_join_approved',
    'room_join_rejected',
    'game_ended',
    'pack_approved',
    'pack_rejected',
    'pack_sale',
    'wallet_credit',
    'wallet_debit',
    'moderation',
    'system',
    'achievement',
    'wallet_deposit_rejected',
    'wallet_withdrawal_rejected'
);


ALTER TYPE "public"."notification_type_enum" OWNER TO "postgres";


CREATE TYPE "public"."online_status_enum" AS ENUM (
    'offline',
    'online',
    'away'
);


ALTER TYPE "public"."online_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."pack_status_enum" AS ENUM (
    'draft',
    'pending_review',
    'approved',
    'rejected',
    'suspended',
    'archived'
);


ALTER TYPE "public"."pack_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."payment_method_type_enum" AS ENUM (
    'bankily',
    'masrivi',
    'sedad',
    'bimbank',
    'cash',
    'other'
);


ALTER TYPE "public"."payment_method_type_enum" OWNER TO "postgres";


CREATE TYPE "public"."purchase_status_enum" AS ENUM (
    'pending',
    'completed',
    'refunded',
    'failed'
);


-- 'processing'/'shipped' kept even though no longer used going forward
-- (superseded by the more granular stages below) — removing an enum value
-- in Postgres requires recreating the type and remapping every existing
-- row, too invasive for a hand-applied migration against a live table that
-- may already have rows in these statuses.
CREATE TYPE "public"."physical_pack_request_status_enum" AS ENUM (
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'payment_confirmed',
    'under_review',
    'printing',
    'packaging',
    'out_for_delivery',
    'completed'
);


ALTER TYPE "public"."purchase_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."report_status_enum" AS ENUM (
    'open',
    'under_review',
    'resolved',
    'dismissed'
);


ALTER TYPE "public"."report_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."report_type_enum" AS ENUM (
    'spam',
    'harassment',
    'inappropriate_content',
    'hate_speech',
    'cheating',
    'impersonation',
    'underage',
    'other'
);


ALTER TYPE "public"."report_type_enum" OWNER TO "postgres";


CREATE TYPE "public"."room_log_action_enum" AS ENUM (
    'created',
    'joined',
    'left',
    'kicked',
    'banned',
    'unbanned',
    'muted',
    'unmuted',
    'game_started',
    'game_ended',
    'game_paused',
    'game_resumed',
    'settings_changed',
    'ownership_transferred',
    'chat_deleted',
    'invite_created',
    'invite_used'
);


ALTER TYPE "public"."room_log_action_enum" OWNER TO "postgres";


CREATE TYPE "public"."room_member_role_enum" AS ENUM (
    'player',
    'moderator',
    'spectator'
);


ALTER TYPE "public"."room_member_role_enum" OWNER TO "postgres";


CREATE TYPE "public"."room_status_enum" AS ENUM (
    'waiting',
    'starting',
    'in_game',
    'paused',
    'ended',
    'closed'
);


ALTER TYPE "public"."room_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."room_visibility_enum" AS ENUM (
    'public',
    'private'
);


ALTER TYPE "public"."room_visibility_enum" OWNER TO "postgres";


CREATE TYPE "public"."transaction_status_enum" AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed',
    'cancelled',
    'reversed'
);


ALTER TYPE "public"."transaction_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."transaction_type_enum" AS ENUM (
    'deposit',
    'withdrawal',
    'purchase',
    'refund',
    'commission',
    'payout',
    'adjustment',
    'bonus',
    'transfer'
);


ALTER TYPE "public"."transaction_type_enum" OWNER TO "postgres";


CREATE TYPE "public"."turn_result_enum" AS ENUM (
    'completed',
    'skipped',
    'timed_out',
    'voted_out'
);


ALTER TYPE "public"."turn_result_enum" OWNER TO "postgres";


CREATE TYPE "public"."category_suggestion_status_enum" AS ENUM (
    'pending',
    'approved',
    'rejected'
);


ALTER TYPE "public"."category_suggestion_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."verification_status_enum" AS ENUM (
    'unverified',
    'pending',
    'verified',
    'rejected'
);


ALTER TYPE "public"."verification_status_enum" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."_trg_sync_premium"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  PERFORM public.sync_premium_status(
    CASE WHEN TG_OP = 'DELETE' THEN OLD.user_id ELSE NEW.user_id END
  );
  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."_trg_sync_premium"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."_trg_update_current_players"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  UPDATE public.rooms
  SET current_players = (
    SELECT COUNT(*)
    FROM public.room_members
    WHERE room_id = COALESCE(NEW.room_id, OLD.room_id)
      AND role = 'player'
      AND left_at IS NULL
  )
  WHERE id = COALESCE(NEW.room_id, OLD.room_id);
  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."_trg_update_current_players"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_updated_at_trigger"("schema_name" "text", "table_name" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
declare
  trigger_name text := 'trg_' || table_name || '_updated_at';
  full_table   text := schema_name || '.' || table_name;
begin
  execute format(
    'drop trigger if exists %I on %s;
     create trigger %I
       before update on %s
       for each row execute procedure public.set_updated_at();',
    trigger_name, full_table,
    trigger_name, full_table
  );
end;
$$;


ALTER FUNCTION "public"."add_updated_at_trigger"("schema_name" "text", "table_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_grant_premium"("p_user_id" "uuid", "p_days" integer DEFAULT 30, "p_tier" "text" DEFAULT 'premium'::"text", "p_source" "text" DEFAULT 'admin'::"text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.subscriptions (
    user_id, tier, status, purchase_source,
    started_at, expires_at, auto_renew
  ) VALUES (
    p_user_id, p_tier, 'active', p_source,
    now(), now() + (p_days || ' days')::interval, false
  );
END;
$$;


ALTER FUNCTION "public"."admin_grant_premium"("p_user_id" "uuid", "p_days" integer, "p_tier" "text", "p_source" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."apply_moderation_to_profile"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  if new.action in ('platform_ban', 'account_suspended') then
    update public.profiles
    set is_banned    = true,
        ban_reason   = new.reason,
        banned_until = new.expires_at,
        updated_at   = now()
    where id = new.target_user_id;
  end if;

  if new.action = 'verification_revoked' then
    update public.profiles
    set verification_status = 'rejected',
        updated_at = now()
    where id = new.target_user_id;
  end if;

  if new.action = 'content_removed' and new.target_pack_id is not null then
    update public.packs
    set status     = 'suspended',
        updated_at = now()
    where id = new.target_pack_id;
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."apply_moderation_to_profile"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."apply_verification_decision"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  if new.status <> old.status then
    update public.profiles
    set verification_status = new.status,
        updated_at = now()
    where id = new.user_id;
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."apply_verification_decision"() OWNER TO "postgres";


-- Mirrors apply_verification_decision's shape: the client can only insert
-- its own pending suggestion row (see RLS below); an admin (service role,
-- same out-of-app-UI convention as pack approval/rejection elsewhere in
-- this schema) applies the actual decision by updating this row's status,
-- and this trigger does the real work atomically. On approval, creates the
-- real category and re-points every pack that was waiting on this
-- suggestion at it; packs.pending_category_suggestion_id is intentionally
-- left untouched on rejection so the creator's UI can still show the
-- rejection_reason via the existing FK and let them pick a different
-- category or submit a fresh suggestion.
CREATE OR REPLACE FUNCTION "public"."apply_category_suggestion_decision"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_category_id uuid;
  v_slug text;
BEGIN
  IF new.status <> old.status AND new.status = 'approved' THEN
    v_slug := trim(both '-' from regexp_replace(lower(new.suggested_name), '[^a-z0-9]+', '-', 'g'));
    INSERT INTO public.pack_categories (name_json, slug)
    VALUES (jsonb_build_object('en', new.suggested_name), v_slug)
    RETURNING id INTO v_category_id;

    UPDATE public.packs
    SET category_id = v_category_id,
        pending_category_suggestion_id = NULL
    WHERE pending_category_suggestion_id = new.id;
  END IF;
  RETURN new;
END;
$$;


ALTER FUNCTION "public"."apply_category_suggestion_decision"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."wallet_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "wallet_id" "uuid" NOT NULL,
    "type" "public"."transaction_type_enum" NOT NULL,
    "status" "public"."transaction_status_enum" DEFAULT 'pending'::"public"."transaction_status_enum" NOT NULL,
    "amount_mru" integer NOT NULL,
    "balance_before" integer NOT NULL,
    "balance_after" integer NOT NULL,
    "balance_type" "text" DEFAULT 'wallet'::"text" NOT NULL,
    "reference_id" "uuid",
    "description" "text",
    "idempotency_key" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "chk_balance_arithmetic" CHECK (("balance_after" = ("balance_before" + "amount_mru"))),
    CONSTRAINT "wallet_transactions_balance_after_check" CHECK (("balance_after" >= 0)),
    CONSTRAINT "wallet_transactions_balance_before_check" CHECK (("balance_before" >= 0)),
    CONSTRAINT "wallet_transactions_balance_type_check" CHECK (("balance_type" = ANY (ARRAY['wallet'::"text", 'earnings'::"text"])))
);


ALTER TABLE "public"."wallet_transactions" OWNER TO "postgres";


-- p_balance_type selects which of the two independent balances this
-- transaction reads/locks/writes: 'wallet' (deposits + manually transferred
-- earnings — the only balance spendable on packs/rooms/premium) or
-- 'earnings' (creator earnings/commissions/rewards — withdrawable only).
-- Keeps one idempotent-ledger function instead of forking into near-
-- duplicates per balance.
CREATE OR REPLACE FUNCTION "public"."apply_wallet_transaction"("p_wallet_id" "uuid", "p_type" "public"."transaction_type_enum", "p_amount_mru" integer, "p_reference_id" "uuid" DEFAULT NULL::"uuid", "p_description" "text" DEFAULT NULL::"text", "p_idempotency_key" "text" DEFAULT NULL::"text", "p_balance_type" "text" DEFAULT 'wallet'::"text") RETURNS "public"."wallet_transactions"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_balance_before integer;
  v_balance_after  integer;
  v_tx             public.wallet_transactions;
begin
  if p_balance_type not in ('wallet', 'earnings') then
    raise exception 'invalid_balance_type';
  end if;

  if p_idempotency_key is not null then
    select * into v_tx
    from public.wallet_transactions
    where idempotency_key = p_idempotency_key;
    if found then
      return v_tx;
    end if;
  end if;

  if p_balance_type = 'wallet' then
    select balance_mru into v_balance_before
    from public.wallets
    where id = p_wallet_id
    for update;
  else
    select earnings_balance_mru into v_balance_before
    from public.wallets
    where id = p_wallet_id
    for update;
  end if;

  if not found then
    raise exception 'Wallet % not found', p_wallet_id;
  end if;

  v_balance_after := v_balance_before + p_amount_mru;

  if v_balance_after < 0 then
    raise exception 'Insufficient balance: have %, need %',
      v_balance_before, abs(p_amount_mru)
      using errcode = 'P0001';
  end if;

  if p_balance_type = 'wallet' then
    update public.wallets
    set balance_mru = v_balance_after,
        updated_at  = now()
    where id = p_wallet_id;
  else
    update public.wallets
    set earnings_balance_mru = v_balance_after,
        updated_at  = now()
    where id = p_wallet_id;
  end if;

  insert into public.wallet_transactions (
    wallet_id, type, amount_mru, balance_before,
    balance_after, balance_type, reference_id, description,
    idempotency_key, status
  )
  values (
    p_wallet_id, p_type, p_amount_mru, v_balance_before,
    v_balance_after, p_balance_type, p_reference_id, p_description,
    p_idempotency_key, 'completed'
  )
  returning * into v_tx;

  return v_tx;
end;
$$;


ALTER FUNCTION "public"."apply_wallet_transaction"("p_wallet_id" "uuid", "p_type" "public"."transaction_type_enum", "p_amount_mru" integer, "p_reference_id" "uuid", "p_description" "text", "p_idempotency_key" "text", "p_balance_type" "text") OWNER TO "postgres";


-- Atomic earnings->wallet transfer — both legs (debit earnings, credit
-- wallet) happen inside one PL/pgSQL function so a mid-flight failure can
-- never leave one side applied without the other, the way two separate
-- apply_wallet_transaction() RPC calls from a client/backend could.
CREATE OR REPLACE FUNCTION "public"."transfer_earnings_to_wallet"("p_wallet_id" "uuid", "p_amount_mru" integer) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_ref uuid := gen_random_uuid();
BEGIN
  IF p_amount_mru <= 0 THEN
    RAISE EXCEPTION 'invalid_amount';
  END IF;

  PERFORM public.apply_wallet_transaction(
    p_wallet_id, 'transfer', -p_amount_mru, v_ref,
    'Transfer to wallet balance', NULL, 'earnings'
  );
  PERFORM public.apply_wallet_transaction(
    p_wallet_id, 'transfer', p_amount_mru, v_ref,
    'Transfer from earnings balance', NULL, 'wallet'
  );
END;
$$;


ALTER FUNCTION "public"."transfer_earnings_to_wallet"("p_wallet_id" "uuid", "p_amount_mru" integer) OWNER TO "postgres";


-- Whole pack-purchase flow (insert the purchase row, debit the buyer,
-- credit the creator's commission, log the commission) in one PL/pgSQL
-- function, so it is genuinely all-or-nothing — a mid-flight failure on
-- any step rolls back every earlier step in this same call, instead of
-- the previous shape (several separate REST/RPC round-trips from Node)
-- which could leave a buyer charged with no creator commission credited
-- if anything after the debit failed.
--
-- SECURITY: this trusts p_user_id as given — it must NEVER be granted to
-- anon/authenticated (no auth.uid() context exists here anyway, since this
-- is only ever called by the Node backend via the service_role key on a
-- user's behalf after its own requireAuth check) — only to service_role.
CREATE OR REPLACE FUNCTION "public"."purchase_pack"("p_user_id" "uuid", "p_pack_id" "uuid", "p_idempotency_key" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
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

  -- Debit buyer — same ledger RPC used everywhere else, still atomic with
  -- everything below since this whole function is one transaction.
  PERFORM public.apply_wallet_transaction(
    v_wallet_id, 'purchase', -v_price, v_purchase.id,
    'Pack purchase: ' || p_pack_id::text,
    'pack_purchase_debit:' || v_purchase.id::text, 'wallet'
  );

  -- Credit creator's commission (85% after 15% platform cut) — into
  -- EARNINGS, never the buyer-facing spendable wallet balance. If this (or
  -- the commissions insert right after) fails, the debit above and the
  -- purchase insert above both roll back too — the buyer is never left
  -- charged with the creator uncredited.
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


ALTER FUNCTION "public"."purchase_pack"("p_user_id" "uuid", "p_pack_id" "uuid", "p_idempotency_key" "text") OWNER TO "postgres";

REVOKE ALL ON FUNCTION "public"."purchase_pack"("p_user_id" "uuid", "p_pack_id" "uuid", "p_idempotency_key" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."purchase_pack"("p_user_id" "uuid", "p_pack_id" "uuid", "p_idempotency_key" "text") TO "service_role";


-- Requests a printed physical copy of a pack the caller already owns
-- (purchased or free — both leave a completed pack_purchases row). Price
-- is entirely app-controlled (app_settings, never the pack creator), and
-- the full amount is platform revenue — debited from the caller's
-- spendable wallet balance via the same ledger RPC digital purchases use,
-- with no creator commission entry at all (unlike a digital sale).
-- New signature: p_city/p_zone/p_quantity are the client-facing inputs;
-- p_address_line1/p_address_line2/p_country are optional (nullable,
-- unused by the current form, kept only so the function signature doesn't
-- disappear out from under anything else that might reference it). Price
-- is unit price (from app_settings, unchanged) * quantity.
CREATE OR REPLACE FUNCTION "public"."request_physical_pack"(
    "p_pack_id" "uuid",
    "p_recipient_name" "text",
    "p_phone_number" "text",
    "p_city" "text",
    "p_zone" "text",
    "p_quantity" integer DEFAULT 1,
    "p_notes" "text" DEFAULT NULL::"text",
    "p_address_line1" "text" DEFAULT NULL::"text",
    "p_address_line2" "text" DEFAULT NULL::"text",
    "p_country" "text" DEFAULT NULL::"text"
) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_unit_price_mru integer;
  v_total_price_mru integer;
  v_wallet_id uuid;
  v_tx public.wallet_transactions;
  v_request_id uuid;
BEGIN
  IF p_quantity IS NULL OR p_quantity < 1 THEN
    RAISE EXCEPTION 'invalid_quantity';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.pack_purchases
    WHERE pack_id = p_pack_id AND buyer_id = auth.uid() AND status = 'completed'::public.purchase_status_enum
  ) THEN
    RAISE EXCEPTION 'pack_not_owned';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.physical_pack_requests
    WHERE pack_id = p_pack_id AND user_id = auth.uid()
      AND status IN ('pending', 'processing', 'shipped')
  ) THEN
    RAISE EXCEPTION 'already_requested';
  END IF;

  SELECT (value #>> '{}')::integer INTO v_unit_price_mru
  FROM public.app_settings WHERE key = 'physical_pack_price_mru';
  IF v_unit_price_mru IS NULL THEN
    RAISE EXCEPTION 'price_not_configured';
  END IF;
  v_total_price_mru := v_unit_price_mru * p_quantity;

  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = auth.uid();
  IF v_wallet_id IS NULL THEN
    RAISE EXCEPTION 'wallet_not_found';
  END IF;

  v_tx := public.apply_wallet_transaction(
    v_wallet_id, 'purchase', -v_total_price_mru, NULL,
    'Physical pack request: ' || p_pack_id, NULL, 'wallet'
  );

  -- Payment is debited atomically above, in the same call — there's no
  -- separate async payment step in this model, so "Payment Confirmed" is
  -- satisfied automatically at submission rather than needing an admin to
  -- manually advance it later.
  INSERT INTO public.physical_pack_requests (
    user_id, pack_id, price_mru, recipient_name, phone_number,
    address_line1, address_line2, city, zone, country, quantity, notes, tx_id,
    payment_confirmed_at
  ) VALUES (
    auth.uid(), p_pack_id, v_total_price_mru, p_recipient_name, p_phone_number,
    p_address_line1, p_address_line2, p_city, p_zone, p_country, p_quantity, p_notes, v_tx.id,
    now()
  )
  RETURNING id INTO v_request_id;

  RETURN v_request_id;
END;
$$;


ALTER FUNCTION "public"."request_physical_pack"(
  "p_pack_id" "uuid", "p_recipient_name" "text", "p_phone_number" "text",
  "p_city" "text", "p_zone" "text", "p_quantity" integer, "p_notes" "text",
  "p_address_line1" "text", "p_address_line2" "text", "p_country" "text"
) OWNER TO "postgres";


-- Pack submission limits: 2 free submissions per calendar month, at least
-- 15 days between submissions; beyond either limit a fee applies, read
-- from app_settings (key 'pack_extra_creation_price_mru') — never
-- hardcoded, admin-configurable without an app update. Logged
-- per-submission-event (not a single column on packs) since a pack can be
-- submitted/rejected/resubmitted multiple times and both the monthly
-- count and the gap-since-last check need full history, not just the
-- latest attempt. SECURITY DEFINER so the quota check, the fee debit, and
-- the status flip all happen atomically — a client can't submit past the
-- limit by racing two calls or skipping the fee.
CREATE OR REPLACE FUNCTION "public"."submit_pack_for_review"("p_pack_id" "uuid", "p_pay_fee" boolean DEFAULT false) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_status public.pack_status_enum;
  v_month_count integer;
  v_last_submitted timestamptz;
  v_needs_fee boolean;
  v_fee_mru integer;
  v_wallet_id uuid;
  v_tx public.wallet_transactions;
  v_fee_tx_id uuid;
BEGIN
  SELECT status INTO v_status FROM public.packs
  WHERE id = p_pack_id AND creator_id = auth.uid();
  IF v_status IS NULL THEN
    RAISE EXCEPTION 'pack_not_found';
  END IF;
  IF v_status NOT IN ('draft', 'rejected') THEN
    RAISE EXCEPTION 'pack_not_editable';
  END IF;

  SELECT count(*) INTO v_month_count FROM public.pack_submissions
  WHERE creator_id = auth.uid()
    AND submitted_at >= date_trunc('month', now());
  SELECT max(submitted_at) INTO v_last_submitted FROM public.pack_submissions
  WHERE creator_id = auth.uid();

  v_needs_fee := v_month_count >= 2
    OR (v_last_submitted IS NOT NULL AND now() - v_last_submitted < interval '15 days');

  IF v_needs_fee AND NOT p_pay_fee THEN
    RAISE EXCEPTION 'fee_required';
  END IF;

  IF v_needs_fee THEN
    SELECT (value #>> '{}')::integer INTO v_fee_mru
    FROM public.app_settings WHERE key = 'pack_extra_creation_price_mru';
    IF v_fee_mru IS NULL THEN
      RAISE EXCEPTION 'price_not_configured';
    END IF;

    SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = auth.uid();
    IF v_wallet_id IS NULL THEN
      RAISE EXCEPTION 'wallet_not_found';
    END IF;
    v_tx := public.apply_wallet_transaction(
      v_wallet_id, 'purchase', -v_fee_mru, NULL,
      'Additional pack submission fee: ' || p_pack_id, NULL, 'wallet'
    );
    v_fee_tx_id := v_tx.id;
  END IF;

  INSERT INTO public.pack_submissions (pack_id, creator_id, fee_paid, fee_tx_id)
  VALUES (p_pack_id, auth.uid(), v_needs_fee, v_fee_tx_id);

  UPDATE public.packs
  SET status = 'pending_review', rejection_reason = NULL
  WHERE id = p_pack_id;

  RETURN jsonb_build_object('fee_charged', v_needs_fee, 'fee_mru', CASE WHEN v_needs_fee THEN v_fee_mru ELSE 0 END);
END;
$$;


ALTER FUNCTION "public"."submit_pack_for_review"("p_pack_id" "uuid", "p_pay_fee" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_wallet_balance"("p_wallet_id" "uuid", "p_amount" integer) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_balance integer;
begin
  select balance_mru into v_balance
  from public.wallets
  where id = p_wallet_id
  for update;
  return v_balance >= p_amount;
end;
$$;


ALTER FUNCTION "public"."check_wallet_balance"("p_wallet_id" "uuid", "p_amount" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_expired_bans"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_count integer;
begin
  with updated as (
    update public.room_bans
    set lifted_at = now()
    where lifted_at is null
      and banned_until is not null
      and banned_until < now()
    returning id
  )
  select count(*) into v_count from updated;
  return v_count;
end;
$$;


ALTER FUNCTION "public"."cleanup_expired_bans"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_expired_invites"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_count integer;
begin
  with deleted as (
    delete from public.room_invites
    where expires_at < now()
      and accepted_at is null
      and declined_at is null
    returning id
  )
  select count(*) into v_count from deleted;
  return v_count;
end;
$$;


ALTER FUNCTION "public"."cleanup_expired_invites"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_expired_notifications"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_count integer;
begin
  with deleted as (
    delete from public.notifications
    where expires_at < now() - interval '7 days'
    returning id
  )
  select count(*) into v_count from deleted;
  return v_count;
end;
$$;


ALTER FUNCTION "public"."cleanup_expired_notifications"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_expired_platform_bans"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_count integer;
begin
  with updated as (
    update public.profiles
    set is_banned    = false,
        ban_reason   = null,
        banned_until = null,
        updated_at   = now()
    where is_banned    = true
      and banned_until is not null
      and banned_until < now()
    returning id
  )
  select count(*) into v_count from updated;
  return v_count;
end;
$$;


ALTER FUNCTION "public"."cleanup_expired_platform_bans"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_expired_purchases"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_count integer;
begin
  with deleted as (
    delete from public.downloaded_packs dp
    using public.pack_purchases pp
    where dp.user_id = pp.buyer_id
      and dp.pack_id = pp.pack_id
      and pp.expires_at < now()
      and pp.status = 'completed'
    returning dp.user_id
  )
  select count(*) into v_count from deleted;
  return v_count;
end;
$$;


ALTER FUNCTION "public"."cleanup_expired_purchases"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_otp_audit_log"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_count integer;
begin
  with deleted as (
    delete from public.otp_audit_log
    where created_at < now() - interval '90 days'
    returning id
  )
  select count(*) into v_count from deleted;
  return v_count;
end;
$$;


ALTER FUNCTION "public"."cleanup_otp_audit_log"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_stale_online_status"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_count integer;
begin
  with updated as (
    update public.profiles
    set online_status  = 'offline',
        in_game_status = false,
        updated_at     = now()
    where online_status <> 'offline'
      and (last_seen_at is null or last_seen_at < now() - interval '5 minutes')
      and deleted_at is null
    returning id
  )
  select count(*) into v_count from updated;
  return v_count;
end;
$$;


ALTER FUNCTION "public"."cleanup_stale_online_status"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_stale_rooms"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_count integer;
begin
  with updated as (
    update public.rooms
    set status     = 'closed',
        deleted_at = now(),
        updated_at = now()
    where status in ('waiting', 'paused')
      and last_active_at < now() - interval '2 hours'
      and deleted_at is null
    returning id
  )
  select count(*) into v_count from updated;
  return v_count;
end;
$$;


ALTER FUNCTION "public"."cleanup_stale_rooms"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_default_notification_preferences"("p_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  insert into public.notification_preferences (user_id, type, in_app, push)
  select p_user_id, unnest(enum_range(null::public.notification_type_enum)), true, true
  on conflict (user_id, type) do nothing;
end;
$$;


ALTER FUNCTION "public"."create_default_notification_preferences"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_user_wallet"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  insert into public.wallets (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;


ALTER FUNCTION "public"."create_user_wallet"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."expire_subscriptions"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  UPDATE public.subscriptions
  SET status     = 'expired',
      updated_at = now()
  WHERE status = 'active'
    AND expires_at IS NOT NULL
    AND expires_at <= now();
END;
$$;


ALTER FUNCTION "public"."expire_subscriptions"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_invite_code"() RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
declare
  chars  text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result text := '';
  i      int;
begin
  for i in 1..6 loop
    result := result || substr(chars, floor(random() * length(chars))::int + 1, 1);
  end loop;
  return result;
end;
$$;


ALTER FUNCTION "public"."generate_invite_code"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_room_by_invite_code"("p_code" "text") RETURNS TABLE("id" "uuid", "name" "text", "visibility" "text", "status" "text", "game_type" "text", "current_players" smallint, "max_players" smallint, "owner_id" "uuid", "pack_id" "uuid", "language" "text", "allow_spicy" boolean, "invite_code" "text", "cover_emoji" "text", "last_active_at" timestamp with time zone, "created_at" timestamp with time zone)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  select
    id, name, visibility::text, status::text, game_type::text,
    current_players, max_players, owner_id, pack_id, language,
    allow_spicy, invite_code, cover_emoji, last_active_at, created_at
  from public.rooms
  where upper(invite_code) = upper(p_code)
    and deleted_at is null
    and status <> 'closed'::public.room_status_enum
  limit 1;
$$;


ALTER FUNCTION "public"."get_room_by_invite_code"("p_code" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_auth_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_auth_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."immutable_to_tsvector"("text") RETURNS "tsvector"
    LANGUAGE "sql" IMMUTABLE
    AS $_$
  select to_tsvector('simple', $1);
$_$;


ALTER FUNCTION "public"."immutable_to_tsvector"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_room_member"("p_room_id" "uuid", "p_user_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  select exists (
    select 1 from public.room_members
    where room_id = p_room_id
      and user_id = p_user_id
      and left_at is null
  );
$$;


ALTER FUNCTION "public"."is_room_member"("p_room_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


-- Server-verified heartbeat: Supabase Realtime Presence alone (client-side
-- diffing, no server record) was the sole signal driving member eviction,
-- and any two unrelated presence events could race-arm a false eviction
-- for someone with only a momentary connection blip. This gives eviction
-- logic a real, tamper-resistant "last confirmed active" timestamp to
-- double-check against before permanently writing left_at.
CREATE OR REPLACE FUNCTION "public"."touch_room_presence"("p_room_id" "uuid") RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  update public.room_members
  set last_seen_at = now()
  where room_id = p_room_id and user_id = auth.uid() and left_at is null;
$$;


ALTER FUNCTION "public"."touch_room_presence"("p_room_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_room_moderator"("p_room_id" "uuid", "p_user_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  select exists (
    select 1 from public.room_moderators
    where room_id = p_room_id and user_id = p_user_id
  )
  or public.is_room_owner(p_room_id, p_user_id);
$$;


ALTER FUNCTION "public"."is_room_moderator"("p_room_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_room_owner"("p_room_id" "uuid", "p_user_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  select exists (
    select 1 from public.rooms
    where id = p_room_id and owner_id = p_user_id
  );
$$;


ALTER FUNCTION "public"."is_room_owner"("p_room_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


-- Used by "room_members: read" to decide whether the caller may see a
-- hidden-spectator row in a room they're active in as a player/moderator/
-- owner. SECURITY DEFINER so this internal room_members lookup bypasses RLS
-- instead of re-entering the calling policy — a raw inline subquery here
-- would recurse infinitely once RLS is enabled on room_members.
CREATE OR REPLACE FUNCTION "public"."can_view_hidden_room_member"("p_room_id" "uuid", "p_user_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  select exists (
    select 1 from public.room_members "mod"
    where "mod"."room_id" = p_room_id
      and "mod"."user_id" = p_user_id
      and (
        "mod"."role" = any (array['player'::public.room_member_role_enum, 'moderator'::public.room_member_role_enum])
        or "mod"."user_id" = (select "rooms"."owner_id" from public.rooms where "rooms"."id" = p_room_id)
      )
      and "mod"."left_at" is null
  );
$$;


ALTER FUNCTION "public"."can_view_hidden_room_member"("p_room_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


-- Granular moderator-permission check: the owner always has every
-- permission; a moderator only has what's explicitly listed in their
-- room_moderators.permissions array. Extensible — a new permission key
-- needs no schema change here, only a new caller checking for it and an
-- entry in the UI's permission list.
CREATE OR REPLACE FUNCTION "public"."has_room_permission"("p_room_id" "uuid", "p_user_id" "uuid", "p_permission" "text") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  select
    public.is_room_owner(p_room_id, p_user_id)
    or exists (
      select 1 from public.room_moderators
      where room_id = p_room_id and user_id = p_user_id
        and p_permission = any(permissions)
    );
$$;


ALTER FUNCTION "public"."has_room_permission"("p_room_id" "uuid", "p_user_id" "uuid", "p_permission" "text") OWNER TO "postgres";


-- Permission-gated moderation actions — SECURITY DEFINER so the check and
-- the mutation happen atomically inside one server-side function, giving
-- real backend enforcement independent of what a client sends.
CREATE OR REPLACE FUNCTION "public"."kick_room_member"("p_room_id" "uuid", "p_target_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF NOT public.has_room_permission(p_room_id, auth.uid(), 'kick_players') THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;
  IF p_target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'cannot_target_self';
  END IF;
  IF EXISTS (SELECT 1 FROM public.rooms WHERE id = p_room_id AND owner_id = p_target_user_id) THEN
    RAISE EXCEPTION 'cannot_target_owner';
  END IF;
  UPDATE public.room_members
  SET left_at = now(), kicked_at = now()
  WHERE room_id = p_room_id AND user_id = p_target_user_id AND left_at IS NULL;
END;
$$;


ALTER FUNCTION "public"."kick_room_member"("p_room_id" "uuid", "p_target_user_id" "uuid") OWNER TO "postgres";


-- Game-level mute: distinct from mute_room_member (which only silences
-- text chat, gated by 'mute_chat'). This gates a target's ability to act
-- in an ongoing game (answer/submit/take a turn) while still letting
-- them watch — enforced client-side at the single per-action chokepoint
-- every game engine already funnels through (mirrors the existing
-- is_away/isDisconnected pattern), with is_game_muted as the durable,
-- backend-synced signal every client derives that from. Mirrors
-- kick_room_member's shape (permission check, self/owner guards) but
-- never removes the member — only toggles the flag.
CREATE OR REPLACE FUNCTION "public"."mute_player_in_game"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_muted" boolean) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF NOT public.has_room_permission(p_room_id, auth.uid(), 'mute_players') THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;
  IF p_target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'cannot_target_self';
  END IF;
  IF EXISTS (SELECT 1 FROM public.rooms WHERE id = p_room_id AND owner_id = p_target_user_id) THEN
    RAISE EXCEPTION 'cannot_target_owner';
  END IF;
  UPDATE public.room_members
  SET is_game_muted = p_muted
  WHERE room_id = p_room_id AND user_id = p_target_user_id AND left_at IS NULL;
END;
$$;


ALTER FUNCTION "public"."mute_player_in_game"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_muted" boolean) OWNER TO "postgres";


-- Replaces the previous two-unguarded-calls flow (RoomRepository.banMember
-- upserting room_bans directly, then calling kickMember) — that left a
-- window where the ban row could be inserted for the room's OWNER before
-- kick_room_member's owner-protection ever ran. Owner-only actor (ban was
-- already RLS-restricted to the owner; this keeps that scope, just makes
-- it atomic and adds the missing target-is-owner rejection kick already had).
CREATE OR REPLACE FUNCTION "public"."ban_room_member"(
    "p_room_id" "uuid",
    "p_target_user_id" "uuid",
    "p_reason" "text" DEFAULT NULL,
    "p_duration_secs" integer DEFAULT NULL
) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF NOT public.is_room_owner(p_room_id, auth.uid()) THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;
  IF p_target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'cannot_target_self';
  END IF;
  IF EXISTS (SELECT 1 FROM public.rooms WHERE id = p_room_id AND owner_id = p_target_user_id) THEN
    RAISE EXCEPTION 'cannot_target_owner';
  END IF;

  INSERT INTO public.room_bans (room_id, user_id, banned_by, reason, banned_until)
  VALUES (
    p_room_id, p_target_user_id, auth.uid(), p_reason,
    CASE WHEN p_duration_secs IS NULL THEN NULL
         ELSE now() + make_interval(secs => p_duration_secs) END
  )
  ON CONFLICT (room_id, user_id) DO UPDATE
    SET banned_by = excluded.banned_by, reason = excluded.reason,
        banned_until = excluded.banned_until, lifted_at = NULL;

  UPDATE public.room_members
  SET left_at = now(), kicked_at = now()
  WHERE room_id = p_room_id AND user_id = p_target_user_id AND left_at IS NULL;
END;
$$;


ALTER FUNCTION "public"."ban_room_member"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_reason" "text", "p_duration_secs" integer) OWNER TO "postgres";


-- Single atomic close path, replacing the previous plain client-side
-- `.update({status:'closed', deleted_at:now()})` — that left any active
-- game_sessions row for the room untouched (nothing else ever marks it
-- ended, since the FK cascade only fires on a hard delete 5 days later),
-- so a closed room's game session could linger 'active' forever. Owner-only.
CREATE OR REPLACE FUNCTION "public"."close_room"("p_room_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.rooms
    WHERE id = p_room_id AND owner_id = auth.uid() AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;

  UPDATE public.rooms
  SET status = 'closed', deleted_at = now(), updated_at = now()
  WHERE id = p_room_id AND deleted_at IS NULL;

  UPDATE public.game_sessions
  SET status = 'aborted', ended_at = now(), updated_at = now()
  WHERE room_id = p_room_id AND status IN ('active', 'paused');
END;
$$;


ALTER FUNCTION "public"."close_room"("p_room_id" "uuid") OWNER TO "postgres";


-- Narrow, non-owner counterpart used only when a JOINING player discovers
-- the room's owner has already left (joinRoom's "owner absent" branch) —
-- re-verifies server-side that the owner genuinely has no active
-- room_members row before closing, so a caller can't claim a room is
-- abandoned when it isn't.
CREATE OR REPLACE FUNCTION "public"."close_abandoned_room"("p_room_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_owner_id uuid;
BEGIN
  SELECT owner_id INTO v_owner_id FROM public.rooms
  WHERE id = p_room_id AND deleted_at IS NULL;
  IF v_owner_id IS NULL THEN
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.room_members
    WHERE room_id = p_room_id AND user_id = v_owner_id AND left_at IS NULL
  ) THEN
    RAISE EXCEPTION 'owner_still_present';
  END IF;

  UPDATE public.rooms
  SET status = 'closed', deleted_at = now(), updated_at = now()
  WHERE id = p_room_id AND deleted_at IS NULL;

  UPDATE public.game_sessions
  SET status = 'aborted', ended_at = now(), updated_at = now()
  WHERE room_id = p_room_id AND status IN ('active', 'paused');
END;
$$;


ALTER FUNCTION "public"."close_abandoned_room"("p_room_id" "uuid") OWNER TO "postgres";


-- Replaces the previous raw client insert (RoomRepository.createRoom),
-- which took a free max_players int with zero tier validation and did a
-- non-atomic select-then-insert duplicate-room check (missing the 'paused'
-- status and racy under concurrent calls). This is now the single,
-- server-verified source of truth for both the subscription-tier player
-- cap (Basic=3, Premium=8, Premium Plus=12) and the "only one open room
-- per owner" rule.
CREATE OR REPLACE FUNCTION "public"."create_room"(
    "p_name" "text",
    "p_visibility" "text" DEFAULT 'public',
    "p_max_players" smallint DEFAULT NULL,
    "p_language" "text" DEFAULT 'en',
    "p_cover_emoji" "text" DEFAULT '🎮'
) RETURNS "public"."rooms"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_tier text;
  v_cap smallint;
  v_requested smallint;
  v_room public.rooms;
BEGIN
  -- Serializes concurrent create_room calls from the SAME owner for the
  -- life of this transaction, closing the race where two calls could both
  -- pass the "no existing open room" check below before either commits —
  -- including the very first room (no row yet exists to lock against).
  PERFORM pg_advisory_xact_lock(hashtext(auth.uid()::text));

  IF EXISTS (
    SELECT 1 FROM public.rooms
    WHERE owner_id = auth.uid()
      AND status IN ('waiting', 'in_game', 'paused')
      AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'already_has_open_room';
  END IF;

  SELECT premium_tier INTO v_tier
  FROM public.profiles
  WHERE id = auth.uid() AND is_premium = true AND deleted_at IS NULL;

  v_cap := CASE v_tier
    WHEN 'premium_plus' THEN 12
    WHEN 'premium' THEN 8
    ELSE 3
  END;

  v_requested := COALESCE(p_max_players, v_cap);
  IF v_requested > v_cap THEN
    RAISE EXCEPTION 'max_players_exceeds_tier_cap';
  END IF;
  IF v_requested < 2 THEN
    v_requested := 2;
  END IF;

  INSERT INTO public.rooms (owner_id, created_by, name, visibility, max_players, language, cover_emoji, status)
  VALUES (
    auth.uid(), auth.uid(), p_name, p_visibility::public.room_visibility_enum,
    v_requested, p_language, p_cover_emoji, 'waiting'
  )
  RETURNING * INTO v_room;

  INSERT INTO public.room_members (room_id, user_id, seat_order, role)
  VALUES (v_room.id, auth.uid(), 0, 'player'::public.room_member_role_enum)
  ON CONFLICT (room_id, user_id) DO NOTHING;

  RETURN v_room;
END;
$$;


ALTER FUNCTION "public"."create_room"("p_name" "text", "p_visibility" "text", "p_max_players" smallint, "p_language" "text", "p_cover_emoji" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mute_room_member"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_muted" boolean) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF NOT public.has_room_permission(p_room_id, auth.uid(), 'mute_chat') THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;
  UPDATE public.room_members
  SET is_muted = p_muted
  WHERE room_id = p_room_id AND user_id = p_target_user_id;
END;
$$;


ALTER FUNCTION "public"."mute_room_member"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_muted" boolean) OWNER TO "postgres";


-- Soft, in-game-only removal: unlike kick_room_member (which sets left_at,
-- removing the row from every "left_at is null" query — the room-members
-- list, seat counts, etc.), this keeps the target a real room member
-- (still visible in the lobby, can still be un-away'd) while durably
-- excluding them from active-game turn rotation and ready calculations for
-- every connected client. Previously this was only ever a client-side
-- broadcast + local in-memory flag — any client that reconnected, briefly
-- dropped, or joined after the broadcast fired never learned the target was
-- away, letting a "kicked from this game" player keep stalling turn order
-- and ready checks as an effectively invisible participant.
CREATE OR REPLACE FUNCTION "public"."mark_room_member_away"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_away" boolean) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF NOT public.has_room_permission(p_room_id, auth.uid(), 'kick_players') THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;
  UPDATE public.room_members
  SET is_away = p_away
  WHERE room_id = p_room_id AND user_id = p_target_user_id AND left_at IS NULL;
END;
$$;


ALTER FUNCTION "public"."mark_room_member_away"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_away" boolean) OWNER TO "postgres";


-- Approves/rejects a pending join request. On approval, this performs the
-- room_members admission itself (mirroring decide_game_rejoin_request)
-- instead of relying on a follow-up client-side joinRoom() upsert — that
-- upsert runs under the MODERATOR's own auth session, which the
-- "room_members: self insert" RLS policy (auth.uid() = user_id) would
-- reject whenever the approved user has no prior row. Doing the write here,
-- inside a SECURITY DEFINER function, bypasses that RLS check entirely and
-- is the only reliable way to admit a brand-new user on approval.
CREATE OR REPLACE FUNCTION "public"."decide_join_request"("p_request_id" "uuid", "p_approve" boolean) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_room_id uuid;
  v_user_id uuid;
  v_row_exists boolean;
  v_max_players smallint;
  v_active_count integer;
  v_seat_order integer;
BEGIN
  SELECT room_id, user_id INTO v_room_id, v_user_id
  FROM public.room_join_requests WHERE id = p_request_id AND status = 'pending';
  IF v_room_id IS NULL THEN
    RAISE EXCEPTION 'request_not_found';
  END IF;
  IF NOT public.has_room_permission(v_room_id, auth.uid(), 'accept_joins') THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;

  IF p_approve THEN
    SELECT max_players INTO v_max_players FROM public.rooms WHERE id = v_room_id;
    SELECT count(*) INTO v_active_count FROM public.room_members
    WHERE room_id = v_room_id AND left_at IS NULL
      AND role <> 'spectator'::public.room_member_role_enum
      AND user_id <> v_user_id;
    IF v_active_count >= v_max_players THEN
      RAISE EXCEPTION 'room_full';
    END IF;
  END IF;

  UPDATE public.room_join_requests
  SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
      resolved_at = now()
  WHERE id = p_request_id;

  IF p_approve THEN
    SELECT EXISTS (
      SELECT 1 FROM public.room_members WHERE room_id = v_room_id AND user_id = v_user_id
    ) INTO v_row_exists;

    IF v_row_exists THEN
      UPDATE public.room_members
      SET left_at = NULL, kicked_at = NULL, left_definitively = false, is_away = false
      WHERE room_id = v_room_id AND user_id = v_user_id;
    ELSE
      SELECT count(*) INTO v_seat_order FROM public.room_members
      WHERE room_id = v_room_id AND left_at IS NULL;

      INSERT INTO public.room_members
        (room_id, user_id, seat_order, role, is_hidden_spectator, is_ready, left_at, joined_at)
      VALUES
        (v_room_id, v_user_id, v_seat_order, 'player', false, false, NULL, now());
    END IF;
  END IF;
END;
$$;


ALTER FUNCTION "public"."decide_join_request"("p_request_id" "uuid", "p_approve" boolean) OWNER TO "postgres";


-- Same rationale as decide_join_request above — performs the room_members
-- admission itself on approval rather than depending on a follow-up
-- client-side joinRoom() call from the moderator's session.
CREATE OR REPLACE FUNCTION "public"."decide_spectator_request"("p_request_id" "uuid", "p_approve" boolean) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_room_id uuid;
  v_user_id uuid;
  v_row_exists boolean;
  v_seat_order integer;
BEGIN
  SELECT room_id, user_id INTO v_room_id, v_user_id
  FROM public.spectator_requests WHERE id = p_request_id AND status = 'pending';
  IF v_room_id IS NULL THEN
    RAISE EXCEPTION 'request_not_found';
  END IF;
  IF NOT public.has_room_permission(v_room_id, auth.uid(), 'accept_spectators') THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;

  UPDATE public.spectator_requests
  SET status = CASE WHEN p_approve THEN 'approved' ELSE 'denied' END,
      decided_by = auth.uid(),
      decided_at = now()
  WHERE id = p_request_id;

  IF p_approve THEN
    SELECT EXISTS (
      SELECT 1 FROM public.room_members WHERE room_id = v_room_id AND user_id = v_user_id
    ) INTO v_row_exists;

    IF v_row_exists THEN
      UPDATE public.room_members
      SET left_at = NULL, kicked_at = NULL, left_definitively = false, is_away = false,
          role = 'spectator'
      WHERE room_id = v_room_id AND user_id = v_user_id;
    ELSE
      SELECT count(*) INTO v_seat_order FROM public.room_members
      WHERE room_id = v_room_id AND left_at IS NULL;

      INSERT INTO public.room_members
        (room_id, user_id, seat_order, role, is_hidden_spectator, is_ready, left_at, joined_at)
      VALUES
        (v_room_id, v_user_id, v_seat_order, 'spectator', false, false, NULL, now());
    END IF;
  END IF;
END;
$$;


ALTER FUNCTION "public"."decide_spectator_request"("p_request_id" "uuid", "p_approve" boolean) OWNER TO "postgres";


-- Requests to rejoin an in-progress game after a real disconnect/leave
-- (the room_members row's left_at is set — an intact row reconnects
-- instantly client-side with no request needed). Eligibility is checked
-- and enforced entirely here, not just in the client UI.
CREATE OR REPLACE FUNCTION "public"."request_game_rejoin"("p_room_id" "uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_room_status public.room_status_enum;
  v_max_players smallint;
  v_session_id uuid;
  v_active_count integer;
  v_request_id uuid;
BEGIN
  SELECT status, max_players INTO v_room_status, v_max_players
  FROM public.rooms
  WHERE id = p_room_id AND deleted_at IS NULL
  FOR UPDATE;
  IF v_room_status IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;
  IF v_room_status NOT IN ('in_game', 'paused') THEN
    RAISE EXCEPTION 'game_finished';
  END IF;

  -- Kicked or currently banned players are never rejoin-eligible.
  IF EXISTS (
    SELECT 1 FROM public.room_members
    WHERE room_id = p_room_id AND user_id = auth.uid() AND kicked_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'not_eligible';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.room_bans
    WHERE room_id = p_room_id AND user_id = auth.uid() AND lifted_at IS NULL
      AND (banned_until IS NULL OR banned_until > now())
  ) THEN
    RAISE EXCEPTION 'not_eligible';
  END IF;

  -- Proves real prior participation, not just prior room membership.
  SELECT id INTO v_session_id FROM public.game_sessions
  WHERE room_id = p_room_id AND status IN ('active', 'paused')
  ORDER BY started_at DESC
  LIMIT 1;
  IF v_session_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.game_sessions
    WHERE id = v_session_id AND auth.uid() = ANY(player_ids)
  ) THEN
    RAISE EXCEPTION 'not_eligible';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.room_members
    WHERE room_id = p_room_id AND user_id = auth.uid() AND left_at IS NULL
  ) THEN
    RAISE EXCEPTION 'already_in_room';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.game_rejoin_requests
    WHERE room_id = p_room_id AND user_id = auth.uid() AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'already_pending';
  END IF;

  SELECT count(*) INTO v_active_count FROM public.room_members
  WHERE room_id = p_room_id AND left_at IS NULL
    AND role <> 'spectator'::public.room_member_role_enum;
  IF v_active_count >= v_max_players THEN
    RAISE EXCEPTION 'room_full';
  END IF;

  INSERT INTO public.game_rejoin_requests (room_id, session_id, user_id, status)
  VALUES (p_room_id, v_session_id, auth.uid(), 'pending')
  ON CONFLICT (room_id, user_id) DO UPDATE
    SET status = 'pending', session_id = excluded.session_id,
        created_at = now(), resolved_at = NULL
  RETURNING id INTO v_request_id;

  RETURN v_request_id;
END;
$$;


ALTER FUNCTION "public"."request_game_rejoin"("p_room_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."decide_game_rejoin_request"("p_request_id" "uuid", "p_approve" boolean) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_room_id uuid;
  v_user_id uuid;
  v_row_exists boolean;
  v_max_players smallint;
  v_active_count integer;
BEGIN
  SELECT room_id, user_id INTO v_room_id, v_user_id
  FROM public.game_rejoin_requests
  WHERE id = p_request_id AND status = 'pending';
  IF v_room_id IS NULL THEN
    RAISE EXCEPTION 'request_not_found';
  END IF;
  IF NOT public.has_room_permission(v_room_id, auth.uid(), 'accept_rejoins') THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;

  -- The request-creation side (request_game_rejoin) already checked
  -- capacity, but the room can fill up in the time between a request being
  -- filed and an owner/moderator actually approving it — re-check here so
  -- approval can't push current_players past max_players.
  IF p_approve THEN
    SELECT max_players INTO v_max_players FROM public.rooms WHERE id = v_room_id;
    SELECT count(*) INTO v_active_count FROM public.room_members
    WHERE room_id = v_room_id AND left_at IS NULL
      AND role <> 'spectator'::public.room_member_role_enum
      AND user_id <> v_user_id;
    IF v_active_count >= v_max_players THEN
      RAISE EXCEPTION 'room_full';
    END IF;
  END IF;

  UPDATE public.game_rejoin_requests
  SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
      resolved_at = now()
  WHERE id = p_request_id;

  IF p_approve THEN
    -- playerOrder is immutable for the life of a session — restoring the
    -- existing seat (never removed, only marked away) is all that's
    -- needed; no game-state mutation happens here.
    SELECT EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_id = v_room_id AND user_id = v_user_id
    ) INTO v_row_exists;

    IF v_row_exists THEN
      UPDATE public.room_members
      SET left_at = NULL, kicked_at = NULL, left_definitively = false, is_away = false
      WHERE room_id = v_room_id AND user_id = v_user_id;
    ELSE
      INSERT INTO public.room_members (room_id, user_id, role, seat_order)
      VALUES (v_room_id, v_user_id, 'player', 0);
    END IF;
  END IF;
END;
$$;


ALTER FUNCTION "public"."decide_game_rejoin_request"("p_request_id" "uuid", "p_approve" boolean) OWNER TO "postgres";


-- Closed-rooms archive (Premium). The blanket "rooms: read" RLS policy
-- requires deleted_at IS NULL with no owner exception, so even the former
-- owner can't re-fetch a closed room directly — these two RPCs are a
-- narrow, read-only carve-out instead of loosening that policy for
-- everyone. Nothing is ever deleted; the 5-day window is just the query
-- filter, so a room past the window still exists, it simply stops
-- appearing here.
CREATE OR REPLACE FUNCTION "public"."get_my_closed_rooms"() RETURNS TABLE("room_id" "uuid", "name" "text", "cover_emoji" "text", "game_type" "public"."game_type_enum", "closed_at" timestamp with time zone, "max_players" smallint, "created_at" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF NOT COALESCE((SELECT is_premium FROM public.profiles WHERE id = auth.uid()), false) THEN
    RAISE EXCEPTION 'premium_required';
  END IF;

  RETURN QUERY
  SELECT r.id, r.name, r.cover_emoji, r.game_type, r.deleted_at, r.max_players, r.created_at
  FROM public.rooms r
  WHERE r.owner_id = auth.uid()
    AND r.status = 'closed'::public.room_status_enum
    AND r.deleted_at IS NOT NULL
    AND r.deleted_at >= now() - interval '5 days'
  ORDER BY r.deleted_at DESC;
END;
$$;


ALTER FUNCTION "public"."get_my_closed_rooms"() OWNER TO "postgres";


-- Strictly read-only archive payload: room info + every game session's
-- state_snapshot (each engine's own scores/history live inside it already,
-- no separate final_scores column needed) + played packs + participants.
-- No mutation path exists through this function by construction.
CREATE OR REPLACE FUNCTION "public"."get_closed_room_details"("p_room_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_room public.rooms%rowtype;
  v_result jsonb;
BEGIN
  IF NOT COALESCE((SELECT is_premium FROM public.profiles WHERE id = auth.uid()), false) THEN
    RAISE EXCEPTION 'premium_required';
  END IF;

  SELECT * INTO v_room FROM public.rooms
  WHERE id = p_room_id AND owner_id = auth.uid()
    AND status = 'closed'::public.room_status_enum
    AND deleted_at IS NOT NULL
    AND deleted_at >= now() - interval '5 days';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;

  v_result := jsonb_build_object(
    'room', jsonb_build_object(
      'id', v_room.id, 'name', v_room.name, 'cover_emoji', v_room.cover_emoji,
      'game_type', v_room.game_type, 'max_players', v_room.max_players,
      'created_at', v_room.created_at, 'closed_at', v_room.deleted_at,
      'game_started_at', v_room.game_started_at, 'game_ended_at', v_room.game_ended_at
    ),
    'sessions', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', gs.id, 'pack_id', gs.pack_id, 'game_type', gs.game_type,
        'status', gs.status, 'player_ids', gs.player_ids,
        'state_snapshot', gs.state_snapshot,
        'started_at', gs.started_at, 'ended_at', gs.ended_at
      ) ORDER BY gs.started_at)
      FROM public.game_sessions gs WHERE gs.room_id = p_room_id
    ), '[]'::jsonb),
    'played_packs', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'pack_id', rpp.pack_id, 'played_at', rpp.played_at,
        'title', pk.title, 'cover_image_url', pk.cover_image_url
      ))
      FROM public.room_played_packs rpp
      LEFT JOIN public.packs pk ON pk.id = rpp.pack_id
      WHERE rpp.room_id = p_room_id
    ), '[]'::jsonb),
    'participants', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'user_id', rm.user_id, 'role', rm.role, 'seat_order', rm.seat_order,
        'joined_at', rm.joined_at, 'left_at', rm.left_at,
        'display_name', p.display_name, 'username', p.username, 'avatar_url', p.avatar_url
      ))
      FROM public.room_members rm
      LEFT JOIN public.profiles p ON p.id = rm.user_id
      WHERE rm.room_id = p_room_id
    ), '[]'::jsonb)
  );

  RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."get_closed_room_details"("p_room_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_room_event"("p_room_id" "uuid", "p_actor_id" "uuid", "p_target_id" "uuid", "p_action" "public"."room_log_action_enum", "p_metadata" "jsonb" DEFAULT NULL::"jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  insert into public.room_logs (room_id, actor_id, target_id, action, metadata)
  values (p_room_id, p_actor_id, p_target_id, p_action, p_metadata);
end;
$$;


ALTER FUNCTION "public"."log_room_event"("p_room_id" "uuid", "p_actor_id" "uuid", "p_target_id" "uuid", "p_action" "public"."room_log_action_enum", "p_metadata" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notifications_set_read_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if new.is_read = true and old.is_read = false then
    new.read_at = now();
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."notifications_set_read_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."refresh_pack_card_count"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  update public.packs
  set card_count = (
        select count(*) from public.pack_cards
        where pack_id = coalesce(new.pack_id, old.pack_id) and is_active = true
      ),
      updated_at = now()
  where id = coalesce(new.pack_id, old.pack_id);
  return coalesce(new, old);
end;
$$;


ALTER FUNCTION "public"."refresh_pack_card_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."refresh_pack_purchase_count"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if new.status = 'completed' and (old.status is null or old.status <> 'completed') then
    update public.packs
    set total_purchases = total_purchases + 1,
        updated_at      = now()
    where id = new.pack_id;
  elsif old.status = 'completed' and new.status = 'refunded' then
    update public.packs
    set total_purchases = greatest(0, total_purchases - 1),
        updated_at      = now()
    where id = new.pack_id;
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."refresh_pack_purchase_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."refresh_pack_rating"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  update public.packs
  set
    avg_rating      = (
      select coalesce(avg(rating)::numeric(3,2), 0)
      from   public.pack_ratings
      where  pack_id = coalesce(new.pack_id, old.pack_id)
    ),
    total_ratings   = (
      select count(*)
      from   public.pack_ratings
      where  pack_id = coalesce(new.pack_id, old.pack_id)
    ),
    updated_at      = now()
  where id = coalesce(new.pack_id, old.pack_id);
  return coalesce(new, old);
end;
$$;


ALTER FUNCTION "public"."refresh_pack_rating"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."refresh_room_player_count"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_room_id uuid;
  v_count   integer;
BEGIN
  v_room_id := COALESCE(NEW.room_id, OLD.room_id);

  SELECT COUNT(*) INTO v_count
  FROM public.room_members
  WHERE room_id = v_room_id
    AND left_at  IS NULL
    AND kicked_at IS NULL
    AND role     = 'player';

  UPDATE public.rooms
  SET current_players = v_count,
      updated_at      = NOW()
  WHERE id = v_room_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION "public"."refresh_room_player_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rooms_create_settings"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  insert into public.room_settings (room_id)
  values (new.id)
  on conflict (room_id) do nothing;
  return new;
end;
$$;


ALTER FUNCTION "public"."rooms_create_settings"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rooms_set_invite_code"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF new.invite_code IS NULL THEN
    LOOP
      new.invite_code := public.generate_invite_code();
      EXIT WHEN NOT EXISTS (
        SELECT 1 FROM public.rooms WHERE invite_code = new.invite_code
      );
    END LOOP;
  END IF;
  RETURN new;
END;
$$;


ALTER FUNCTION "public"."rooms_set_invite_code"() OWNER TO "postgres";


-- Hard-deletes rooms that have been closed for more than 5 days — the same
-- threshold get_my_closed_rooms()/get_closed_room_details() already use as
-- their query window, so a room simply stops being visible in the Premium
-- archive and then, at the same boundary, actually disappears. Every child
-- table (room_members, game_sessions, room_played_packs, room_logs, etc.)
-- cascades via its own FK — nothing orphaned.
CREATE OR REPLACE FUNCTION "public"."cleanup_purge_closed_rooms"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_count integer;
begin
  delete from public.rooms
  where status = 'closed'::public.room_status_enum
    and deleted_at is not null
    and deleted_at < now() - interval '5 days';
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;


ALTER FUNCTION "public"."cleanup_purge_closed_rooms"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."run_all_cleanup"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_result jsonb;
begin
  v_result := jsonb_build_object(
    'stale_rooms',          public.cleanup_stale_rooms(),
    'expired_bans',         public.cleanup_expired_bans(),
    'platform_bans',        public.cleanup_expired_platform_bans(),
    'notifications',        public.cleanup_expired_notifications(),
    'invites',              public.cleanup_expired_invites(),
    'purchases',            public.cleanup_expired_purchases(),
    'online_status',        public.cleanup_stale_online_status(),
    'otp_audit',            public.cleanup_otp_audit_log(),
    'purged_closed_rooms',  public.cleanup_purge_closed_rooms(),
    'ran_at',               now()
  );
  return v_result;
end;
$$;


ALTER FUNCTION "public"."run_all_cleanup"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."send_notification"("p_user_id" "uuid", "p_type" "public"."notification_type_enum", "p_title" "jsonb", "p_body" "jsonb", "p_data" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_pref record;
  v_id   uuid;
begin
  select in_app, push into v_pref
  from public.notification_preferences
  where user_id = p_user_id and type = p_type;

  if not found then
    v_pref := row(true, true);
  end if;

  if v_pref.in_app then
    insert into public.notifications (user_id, type, title, body, data)
    values (p_user_id, p_type, p_title, p_body, p_data)
    returning id into v_id;
  end if;

  return v_id;
end;
$$;


ALTER FUNCTION "public"."send_notification"("p_user_id" "uuid", "p_type" "public"."notification_type_enum", "p_title" "jsonb", "p_body" "jsonb", "p_data" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."soft_delete"("p_table" "text", "p_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $_$
begin
  execute format(
    'update %s set deleted_at = now(), updated_at = now() where id = $1',
    p_table
  ) using p_id;
end;
$_$;


ALTER FUNCTION "public"."soft_delete"("p_table" "text", "p_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."start_game_session_checks"("p_user_id" "uuid", "p_room_id" "uuid", "p_pack_id" "uuid", "p_is_premium" boolean) RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Pack-per-room check only
  IF EXISTS (
    SELECT 1 FROM public.room_played_packs
    WHERE room_id = p_room_id AND pack_id = p_pack_id
  ) THEN
    RETURN 'pack_already_played';
  END IF;

  -- Record the pack as played for this room
  INSERT INTO public.room_played_packs (room_id, pack_id)
  VALUES (p_room_id, p_pack_id)
  ON CONFLICT (room_id, pack_id) DO NOTHING;

  RETURN NULL; -- success
END;
$$;


ALTER FUNCTION "public"."start_game_session_checks"("p_user_id" "uuid", "p_room_id" "uuid", "p_pack_id" "uuid", "p_is_premium" boolean) OWNER TO "postgres";


-- game_sessions has no permissive INSERT policy (INSERT is unconditionally
-- denied — session rows are only ever meant to be created server-side).
-- SECURITY DEFINER so the permission check and the insert happen atomically:
-- the owner always passes has_room_permission, a moderator only if
-- explicitly granted 'start_game'. auth.uid() becomes the session's
-- owner_id (the engine host who may later update it, per the existing
-- "game_sessions: owner update" RLS policy) — this may be a moderator, not
-- necessarily the room's actual owner_id, matching how "isOwner" already
-- means "engine host" throughout the game providers, not literally the room
-- owner.
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


ALTER FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb") OWNER TO "postgres";


-- Real backend enforcement for Truth-or-Dare proof viewing — previously
-- who-can-view and how-many-times were only ever derived from the shared
-- broadcast game state (owner-authoritative, no server validation at all).
-- 'once'/'timed' both cap at exactly 1 view; 'replay_once' caps at 2, +1
-- more for Premium viewers (matches "one replay for basic, two for
-- Premium" — the base view plus 1 or 2 replays respectively).
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

  SELECT proof_visibility_policy, proof_replay_mode, proof_visibility_selected_user_ids
    INTO v_policy, v_replay_mode, v_selected_ids
  FROM public.room_settings WHERE room_id = v_room_id;

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


ALTER FUNCTION "public"."record_proof_view"("p_session_id" "uuid", "p_turn_started_at" bigint) OWNER TO "postgres";


-- Ownership transfer: requires Premium, and at most once per UTC calendar
-- day PER USER (not per room — the gate is profiles.last_ownership_
-- transfer_at, so creating a new room can't reset it). Enforced here, not
-- just client-side, so a modified client/direct API call can't bypass it.
-- FOR UPDATE locks both rows for the duration of the check-then-mutate so
-- two concurrent transfer attempts can't both pass.
CREATE OR REPLACE FUNCTION "public"."transfer_room_ownership"("p_room_id" "uuid", "p_new_owner_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_owner_id uuid;
  v_is_premium boolean;
  v_last_transfer timestamptz;
  v_target_role public.room_member_role_enum;
BEGIN
  SELECT owner_id INTO v_owner_id
  FROM public.rooms WHERE id = p_room_id FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;
  IF v_owner_id <> auth.uid() THEN
    RAISE EXCEPTION 'not_owner';
  END IF;

  SELECT is_premium, last_ownership_transfer_at
    INTO v_is_premium, v_last_transfer
  FROM public.profiles WHERE id = auth.uid() FOR UPDATE;

  IF v_is_premium IS NOT TRUE THEN
    RAISE EXCEPTION 'premium_required';
  END IF;
  IF v_last_transfer IS NOT NULL
     AND (v_last_transfer AT TIME ZONE 'utc')::date >= (now() AT TIME ZONE 'utc')::date THEN
    RAISE EXCEPTION 'transfer_limit_reached';
  END IF;

  SELECT role INTO v_target_role
  FROM public.room_members
  WHERE room_id = p_room_id AND user_id = p_new_owner_id AND left_at IS NULL;

  IF v_target_role IS NULL THEN
    RAISE EXCEPTION 'target_not_member';
  END IF;
  IF v_target_role = 'spectator' THEN
    RAISE EXCEPTION 'target_is_spectator';
  END IF;

  UPDATE public.rooms
  SET owner_id = p_new_owner_id, owner_transferred_at = now()
  WHERE id = p_room_id;

  -- Keep the active game session's own owner_id (which gates
  -- "game_sessions: owner update" RLS — i.e. who may save/broadcast state)
  -- in lockstep with the room's owner_id. Previously missing here: a
  -- manual transfer mid-game left the new room owner unable to persist
  -- any state at all, since RLS still only trusted the old owner_id.
  UPDATE public.game_sessions
  SET owner_id = p_new_owner_id
  WHERE room_id = p_room_id AND status = 'active';

  UPDATE public.profiles
  SET last_ownership_transfer_at = now()
  WHERE id = auth.uid();
END;
$$;


ALTER FUNCTION "public"."transfer_room_ownership"("p_room_id" "uuid", "p_new_owner_id" "uuid") OWNER TO "postgres";


-- Emergency failover — deliberately separate from transfer_room_ownership
-- (which is a manual, Premium-gated, once-per-day feature): this exists
-- purely to recover a game when the current owner has gone genuinely
-- unreachable, so it must not be gated behind Premium/rate-limits or the
-- game would just stay stuck. Safe to call from any remaining client —
-- the outcome (who becomes the new owner) is fully deterministic
-- server-side, so a race between multiple clients noticing the same stale
-- owner and calling this simultaneously is harmless.
--
-- The staleness check is the actual security boundary: it re-reads the
-- CURRENT owner's own last_seen_at (updated only by touch_room_presence,
-- which only the real owner's authenticated session can call for itself)
-- rather than trusting anything the caller asserts — a client cannot claim
-- ownership of a room whose owner is actually still active.
CREATE OR REPLACE FUNCTION "public"."claim_room_ownership"("p_room_id" "uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_current_owner_id uuid;
  v_owner_last_seen timestamptz;
  v_owner_left_at timestamptz;
  v_new_owner_id uuid;
  v_caller_is_member boolean;
BEGIN
  SELECT owner_id INTO v_current_owner_id
  FROM public.rooms WHERE id = p_room_id FOR UPDATE;
  IF v_current_owner_id IS NULL THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.room_members
    WHERE room_id = p_room_id AND user_id = auth.uid() AND left_at IS NULL
  ) INTO v_caller_is_member;
  IF NOT v_caller_is_member THEN
    RAISE EXCEPTION 'not_a_member';
  END IF;

  SELECT last_seen_at, left_at INTO v_owner_last_seen, v_owner_left_at
  FROM public.room_members
  WHERE room_id = p_room_id AND user_id = v_current_owner_id;

  -- Eligible to claim only if the owner has actually left, or their own
  -- heartbeat hasn't landed in well over the client-side grace period —
  -- never based on the caller's own claim about the owner's state.
  -- Deliberately conservative (3 minutes, not the ordinary 25s
  -- member-eviction threshold): an owner briefly force-quitting and
  -- relaunching the app must never lose the room. A genuinely abandoned
  -- room still recovers via this same path, just after a longer wait —
  -- and even then, recover_owner_room lets the original creator reclaim
  -- ownership automatically whenever they do return.
  IF v_owner_left_at IS NULL
     AND v_owner_last_seen IS NOT NULL
     AND v_owner_last_seen > now() - interval '3 minutes' THEN
    RAISE EXCEPTION 'owner_still_active';
  END IF;

  SELECT rm.user_id INTO v_new_owner_id
  FROM public.room_members rm
  WHERE rm.room_id = p_room_id
    AND rm.left_at IS NULL
    AND rm.role <> 'spectator'::public.room_member_role_enum
    AND rm.user_id <> v_current_owner_id
  ORDER BY (EXISTS (
    SELECT 1 FROM public.room_moderators mod
    WHERE mod.room_id = p_room_id AND mod.user_id = rm.user_id
  )) DESC, rm.seat_order ASC
  LIMIT 1;

  IF v_new_owner_id IS NULL THEN
    RAISE EXCEPTION 'no_eligible_member';
  END IF;

  UPDATE public.rooms
  SET owner_id = v_new_owner_id, owner_transferred_at = now()
  WHERE id = p_room_id;

  UPDATE public.game_sessions
  SET owner_id = v_new_owner_id
  WHERE room_id = p_room_id AND status = 'active';

  RETURN v_new_owner_id;
END;
$$;


-- Single authoritative recovery step, called by RoomProvider.initialize()
-- before any other room-state gate runs. Two independent jobs, both
-- no-ops for anyone who isn't the room's original creator or its current
-- owner (safe to call unconditionally on every room entry):
--   1. Reclaim: if the caller is the room's original creator (created_by)
--      but ownership was reassigned to someone else in the meantime (e.g.
--      by claim_room_ownership while the creator was disconnected), it is
--      handed straight back. This is what makes "the room owner must
--      always regain ownership after reconnecting" deterministic
--      regardless of how long they were away.
--   2. Terminate: if the caller is (now) the room's owner and the room is
--      still mid-game from before they disconnected, the stale session is
--      aborted and the room is reset to a normal waiting lobby — pack_id,
--      room_settings, room_members and moderator rows are untouched, only
--      is_ready is cleared so nobody is stuck "ready" for a game that no
--      longer exists.
CREATE OR REPLACE FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_created_by uuid;
  v_owner_id uuid;
  v_status public.room_status_enum;
  v_reclaimed boolean := false;
  v_terminated boolean := false;
  v_session_id uuid;
BEGIN
  SELECT created_by, owner_id, status INTO v_created_by, v_owner_id, v_status
  FROM public.rooms
  WHERE id = p_room_id AND deleted_at IS NULL
  FOR UPDATE;

  IF v_owner_id IS NULL THEN
    RETURN jsonb_build_object('reclaimed', false, 'game_terminated', false);
  END IF;

  IF v_created_by IS NOT NULL AND auth.uid() = v_created_by AND v_owner_id <> v_created_by THEN
    UPDATE public.rooms
    SET owner_id = v_created_by, owner_transferred_at = now()
    WHERE id = p_room_id;
    v_owner_id := v_created_by;
    v_reclaimed := true;
  END IF;

  IF auth.uid() = v_owner_id AND v_status IN ('in_game', 'paused') THEN
    SELECT id INTO v_session_id FROM public.game_sessions
    WHERE room_id = p_room_id AND status IN ('active', 'paused')
    ORDER BY started_at DESC
    LIMIT 1;

    IF v_session_id IS NOT NULL THEN
      UPDATE public.game_sessions
      SET status = 'aborted', ended_at = now(), updated_at = now()
      WHERE id = v_session_id;
    END IF;

    UPDATE public.rooms
    SET status = 'waiting', last_active_at = now(), updated_at = now()
    WHERE id = p_room_id;

    UPDATE public.room_members
    SET is_ready = false
    WHERE room_id = p_room_id AND left_at IS NULL;

    v_terminated := true;
  END IF;

  RETURN jsonb_build_object('reclaimed', v_reclaimed, 'game_terminated', v_terminated);
END;
$$;


ALTER FUNCTION "public"."recover_owner_room"("p_room_id" "uuid") OWNER TO "postgres";


ALTER FUNCTION "public"."claim_room_ownership"("p_room_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_premium_status"("p_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_active_sub subscriptions%ROWTYPE;
BEGIN
  SELECT * INTO v_active_sub
  FROM public.subscriptions
  WHERE user_id = p_user_id
    AND status = 'active'
    AND (expires_at IS NULL OR expires_at > now())
  ORDER BY expires_at DESC NULLS LAST
  LIMIT 1;

  IF FOUND THEN
    UPDATE public.profiles
    SET is_premium         = true,
        premium_tier       = v_active_sub.tier,
        premium_expires_at = v_active_sub.expires_at,
        updated_at         = now()
    WHERE id = p_user_id;
  ELSE
    UPDATE public.profiles
    SET is_premium         = false,
        premium_tier       = null,
        premium_expires_at = null,
        updated_at         = now()
    WHERE id = p_user_id;
  END IF;
END;
$$;


ALTER FUNCTION "public"."sync_premium_status"("p_user_id" "uuid") OWNER TO "postgres";


-- Sets/clears the caller's premium background-color override. NULL always
-- allowed (resetting your own preference isn't a premium-gated action);
-- setting a non-null value requires a LIVE premium check (is_premium AND
-- premium_expires_at still in the future) rather than trusting the raw
-- is_premium column alone — sync_premium_status only fires reactively on
-- writes to the subscriptions table (see trg_sync_premium), there is no
-- cron/scheduled job, so is_premium can stay stale=true well past a
-- subscription's actual expires_at until some other write happens.
CREATE OR REPLACE FUNCTION "public"."set_theme_background_color"("p_hex_color" "text") RETURNS "public"."profiles"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_row public.profiles;
BEGIN
  IF p_hex_color IS NOT NULL THEN
    IF p_hex_color !~ '^#[0-9A-Fa-f]{6}$' THEN
      RAISE EXCEPTION 'invalid_hex_color';
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND is_premium = true
        AND (premium_expires_at IS NULL OR premium_expires_at > now())
    ) THEN
      RAISE EXCEPTION 'premium_required';
    END IF;
  END IF;

  UPDATE public.profiles
  SET theme_background_color = p_hex_color, updated_at = now()
  WHERE id = auth.uid()
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;


ALTER FUNCTION "public"."set_theme_background_color"("p_hex_color" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_requires_approval"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  UPDATE public.rooms
  SET requires_approval = NEW.requires_approval
  WHERE id = NEW.room_id;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."sync_requires_approval"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trim_game_states"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  delete from public.game_states
  where session_id = new.session_id
    and id not in (
      select id from public.game_states
      where session_id = new.session_id
      order by snapshot_at desc
      limit 50
    );
  return new;
end;
$$;


ALTER FUNCTION "public"."trim_game_states"() OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."blocked_users" (
    "blocker_id" "uuid" NOT NULL,
    "blocked_id" "uuid" NOT NULL,
    "reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"(),
    CONSTRAINT "chk_no_self_block" CHECK (("blocker_id" <> "blocked_id"))
);


ALTER TABLE "public"."blocked_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."commissions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "purchase_id" "uuid" NOT NULL,
    "creator_id" "uuid" NOT NULL,
    "gross_amount_mru" integer NOT NULL,
    "commission_rate" numeric(4,3) DEFAULT 0.150 NOT NULL,
    "commission_amount_mru" integer NOT NULL,
    "creator_payout_mru" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "commissions_commission_amount_mru_check" CHECK (("commission_amount_mru" >= 0)),
    CONSTRAINT "commissions_creator_payout_mru_check" CHECK (("creator_payout_mru" >= 0)),
    CONSTRAINT "commissions_gross_amount_mru_check" CHECK (("gross_amount_mru" > 0))
);


ALTER TABLE "public"."commissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."creator_verifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "real_name" "text" NOT NULL,
    "id_document_url" "text",
    "bio" "text",
    "portfolio_url" "text",
    "social_links" "jsonb" DEFAULT '{}'::"jsonb",
    "status" "public"."verification_status_enum" DEFAULT 'pending'::"public"."verification_status_enum" NOT NULL,
    "reviewed_by" "uuid",
    "reviewed_at" timestamp with time zone,
    "rejection_reason" "text",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "creator_verifications_bio_check" CHECK (("char_length"("bio") <= 500)),
    CONSTRAINT "creator_verifications_real_name_check" CHECK ((("char_length"("real_name") >= 2) AND ("char_length"("real_name") <= 100)))
);


ALTER TABLE "public"."creator_verifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."deposits" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "wallet_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "amount_mru" integer NOT NULL,
    "payment_method" "public"."payment_method_type_enum" NOT NULL,
    "payment_reference" "text",
    "status" "public"."transaction_status_enum" DEFAULT 'pending'::"public"."transaction_status_enum" NOT NULL,
    "tx_id" "uuid",
    "submitted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "approved_at" timestamp with time zone,
    "approved_by" "uuid",
    "rejected_at" timestamp with time zone,
    "rejected_reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "payment_method_id" "uuid",
    "phone_number" "text",
    "idempotency_key" "text",
    "notes" "text",
    "rejected_by" "uuid",
    CONSTRAINT "deposits_amount_mru_check" CHECK (("amount_mru" > 0))
);


ALTER TABLE "public"."deposits" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."downloaded_packs" (
    "user_id" "uuid" NOT NULL,
    "pack_id" "uuid" NOT NULL,
    "downloaded_version" integer NOT NULL,
    "synced_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."downloaded_packs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."financial_audit_log" (
    "id" bigint NOT NULL,
    "actor_id" "uuid",
    "action" "text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "ip_address" "inet",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."financial_audit_log" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."financial_audit_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."financial_audit_log_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."financial_audit_log_id_seq" OWNED BY "public"."financial_audit_log"."id";



CREATE TABLE IF NOT EXISTS "public"."follows" (
    "follower_id" "uuid" NOT NULL,
    "followee_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "chk_no_self_follow" CHECK (("follower_id" <> "followee_id"))
);


ALTER TABLE "public"."follows" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."friendships" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "requester_id" "uuid" NOT NULL,
    "addressee_id" "uuid" NOT NULL,
    "status" "public"."friendship_status_enum" DEFAULT 'pending'::"public"."friendship_status_enum" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "chk_no_self_friendship" CHECK (("requester_id" <> "addressee_id"))
);


ALTER TABLE "public"."friendships" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."game_rounds" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "uuid" NOT NULL,
    "round_number" smallint NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "ended_at" timestamp with time zone,
    CONSTRAINT "game_rounds_round_number_check" CHECK (("round_number" >= 1))
);


ALTER TABLE "public"."game_rounds" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."game_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "room_id" "uuid" NOT NULL,
    "pack_id" "uuid",
    "game_type" "public"."game_type_enum" NOT NULL,
    "status" "public"."game_session_status_enum" DEFAULT 'active'::"public"."game_session_status_enum" NOT NULL,
    "player_ids" "uuid"[] DEFAULT '{}'::"uuid"[] NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "state_snapshot" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "snapshot_at" timestamp with time zone,
    "max_rounds" smallint DEFAULT 10 NOT NULL,
    "turn_timer_secs" smallint DEFAULT 60 NOT NULL,
    "allow_skip" boolean DEFAULT true NOT NULL,
    "allow_spicy" boolean DEFAULT false NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "ended_at" timestamp with time zone,
    "paused_at" timestamp with time zone,
    "total_pause_ms" bigint DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE ONLY "public"."game_sessions" REPLICA IDENTITY FULL;


ALTER TABLE "public"."game_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."game_states" (
    "id" bigint NOT NULL,
    "session_id" "uuid" NOT NULL,
    "round_number" smallint,
    "turn_number" smallint,
    "state" "jsonb" NOT NULL,
    "snapshot_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."game_states" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."game_states_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."game_states_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."game_states_id_seq" OWNED BY "public"."game_states"."id";



CREATE TABLE IF NOT EXISTS "public"."game_turns" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "uuid" NOT NULL,
    "round_id" "uuid" NOT NULL,
    "turn_number" smallint NOT NULL,
    "player_id" "uuid" NOT NULL,
    "card_id" "uuid",
    "card_type" "public"."card_type_enum",
    "card_content" "text",
    "result" "public"."turn_result_enum",
    "completed_at" timestamp with time zone,
    "timer_expired" boolean DEFAULT false NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "ended_at" timestamp with time zone,
    CONSTRAINT "game_turns_turn_number_check" CHECK (("turn_number" >= 1))
);


ALTER TABLE "public"."game_turns" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."game_votes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "turn_id" "uuid" NOT NULL,
    "session_id" "uuid" NOT NULL,
    "voter_id" "uuid" NOT NULL,
    "target_id" "uuid",
    "vote_value" smallint,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."game_votes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."gameplay_analytics" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "uuid" NOT NULL,
    "room_id" "uuid",
    "pack_id" "uuid",
    "game_type" "public"."game_type_enum" NOT NULL,
    "player_count" smallint NOT NULL,
    "round_count" smallint NOT NULL,
    "turn_count" smallint NOT NULL,
    "duration_secs" integer NOT NULL,
    "player_stats" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "chat_messages" integer DEFAULT 0 NOT NULL,
    "votes_cast" integer DEFAULT 0 NOT NULL,
    "skips_used" integer DEFAULT 0 NOT NULL,
    "timeouts" integer DEFAULT 0 NOT NULL,
    "started_at" timestamp with time zone NOT NULL,
    "ended_at" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "gameplay_analytics_duration_secs_check" CHECK (("duration_secs" >= 0))
);


ALTER TABLE "public"."gameplay_analytics" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."moderation_actions" (
    "id" bigint NOT NULL,
    "moderator_id" "uuid" NOT NULL,
    "target_user_id" "uuid",
    "target_pack_id" "uuid",
    "report_id" "uuid",
    "action" "public"."moderation_action_type_enum" NOT NULL,
    "reason" "text" NOT NULL,
    "duration_hours" integer,
    "expires_at" timestamp with time zone,
    "reversed_at" timestamp with time zone,
    "reversed_by" "uuid",
    "reversal_reason" "text",
    "metadata" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "moderation_actions_duration_hours_check" CHECK (("duration_hours" > 0)),
    CONSTRAINT "moderation_actions_reason_check" CHECK (("char_length"("reason") >= 5))
);


ALTER TABLE "public"."moderation_actions" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."moderation_actions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."moderation_actions_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."moderation_actions_id_seq" OWNED BY "public"."moderation_actions"."id";



CREATE TABLE IF NOT EXISTS "public"."notification_preferences" (
    "user_id" "uuid" NOT NULL,
    "type" "public"."notification_type_enum" NOT NULL,
    "in_app" boolean DEFAULT true NOT NULL,
    "push" boolean DEFAULT true NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."notification_preferences" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "type" "public"."notification_type_enum" NOT NULL,
    "title" "jsonb" NOT NULL,
    "body" "jsonb" NOT NULL,
    "data" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "is_read" boolean DEFAULT false NOT NULL,
    "read_at" timestamp with time zone,
    "push_sent" boolean DEFAULT false NOT NULL,
    "push_id" "text",
    "idempotency_key" "text",
    "expires_at" timestamp with time zone DEFAULT ("now"() + '30 days'::interval) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone
);

ALTER TABLE ONLY "public"."notifications" REPLICA IDENTITY FULL;


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."otp_audit_log" (
    "id" bigint NOT NULL,
    "email" "text" NOT NULL,
    "action" "text" NOT NULL,
    "ip_address" "inet",
    "user_agent" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "otp_audit_log_action_check" CHECK (("action" = ANY (ARRAY['send'::"text", 'verify_success'::"text", 'verify_fail'::"text", 'expired'::"text", 'max_attempts'::"text"])))
);


ALTER TABLE "public"."otp_audit_log" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."otp_audit_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."otp_audit_log_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."otp_audit_log_id_seq" OWNED BY "public"."otp_audit_log"."id";



CREATE TABLE IF NOT EXISTS "public"."pack_analytics" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pack_id" "uuid" NOT NULL,
    "date" "date" NOT NULL,
    "views" integer DEFAULT 0 NOT NULL,
    "unique_viewers" integer DEFAULT 0 NOT NULL,
    "detail_clicks" integer DEFAULT 0 NOT NULL,
    "purchases" integer DEFAULT 0 NOT NULL,
    "revenue_mru" integer DEFAULT 0 NOT NULL,
    "plays" integer DEFAULT 0 NOT NULL,
    "unique_players" integer DEFAULT 0 NOT NULL,
    "avg_session_mins" numeric(6,2),
    "new_ratings" integer DEFAULT 0 NOT NULL,
    "avg_new_rating" numeric(3,2),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."pack_analytics" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pack_cards" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pack_id" "uuid" NOT NULL,
    "card_type" "public"."card_type_enum" NOT NULL,
    "difficulty" "public"."difficulty_enum" DEFAULT 'mild'::"public"."difficulty_enum" NOT NULL,
    "content" "jsonb" NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."pack_cards" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pack_categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name_json" "jsonb" NOT NULL,
    "slug" "text" NOT NULL,
    "icon" "text" DEFAULT '📦'::"text",
    "sort_order" smallint DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "pack_categories_slug_check" CHECK (("slug" ~ '^[a-z0-9-]+$'::"text"))
);


ALTER TABLE "public"."pack_categories" OWNER TO "postgres";


-- Mirrors creator_verifications: the creator inserts their own pending
-- suggestion row; only an admin (service role) can move it out of
-- 'pending' (see RLS below), and apply_category_suggestion_decision()
-- does the real work of creating the category on approval.
CREATE TABLE IF NOT EXISTS "public"."pack_category_suggestions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "suggested_name" "text" NOT NULL,
    "suggested_by" "uuid" NOT NULL,
    "status" "public"."category_suggestion_status_enum" DEFAULT 'pending'::"public"."category_suggestion_status_enum" NOT NULL,
    "rejection_reason" "text",
    "reviewed_by" "uuid",
    "reviewed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "pack_category_suggestions_suggested_name_check" CHECK ((("char_length"("suggested_name") >= 2) AND ("char_length"("suggested_name") <= 60)))
);


ALTER TABLE "public"."pack_category_suggestions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pack_languages" (
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "native_name" "text" NOT NULL,
    "is_rtl" boolean DEFAULT false NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "sort_order" smallint DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."pack_languages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pack_purchases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pack_id" "uuid" NOT NULL,
    "buyer_id" "uuid" NOT NULL,
    "price_paid_mru" integer NOT NULL,
    "status" "public"."purchase_status_enum" DEFAULT 'pending'::"public"."purchase_status_enum" NOT NULL,
    "purchased_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone DEFAULT ("now"() + '90 days'::interval) NOT NULL,
    "idempotency_key" "text",
    "refunded_at" timestamp with time zone,
    "refund_reason" "text",
    CONSTRAINT "pack_purchases_price_paid_mru_check" CHECK (("price_paid_mru" >= 0))
);


ALTER TABLE "public"."pack_purchases" OWNER TO "postgres";


-- Generic app-wide admin-configurable key/value settings — starts with
-- just the physical-pack price, but deliberately generic (not a single
-- dedicated column somewhere) so future admin-configurable values don't
-- each need their own migration.
CREATE TABLE IF NOT EXISTS "public"."app_settings" (
    "key" "text" NOT NULL,
    "value" "jsonb" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."app_settings" OWNER TO "postgres";


-- Physical printed copy of a pack the user already owns (purchased or
-- free) — price is entirely app-controlled (see app_settings, key
-- 'physical_pack_price_mru'), never set by the pack's creator, and 100%
-- of the charge is platform revenue with no creator commission entry,
-- unlike a normal digital pack sale. Status lifecycle plus shipping
-- address capture give a future fulfillment integration somewhere to
-- plug in without needing another migration.
CREATE TABLE IF NOT EXISTS "public"."physical_pack_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "pack_id" "uuid" NOT NULL,
    "status" "public"."physical_pack_request_status_enum" DEFAULT 'pending'::"public"."physical_pack_request_status_enum" NOT NULL,
    "price_mru" integer NOT NULL,
    "recipient_name" "text" NOT NULL,
    "phone_number" "text" NOT NULL,
    -- address_line1/address_line2/country are nullable, not dropped, to
    -- preserve historical rows from before the form switched to
    -- city/zone/quantity — the current client only ever populates
    -- city/zone now.
    "address_line1" "text",
    "address_line2" "text",
    "city" "text" NOT NULL,
    "zone" "text",
    "country" "text",
    "quantity" integer DEFAULT 1 NOT NULL,
    "notes" "text",
    "tx_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "processing_at" timestamp with time zone,
    "shipped_at" timestamp with time zone,
    "delivered_at" timestamp with time zone,
    "cancelled_at" timestamp with time zone,
    "payment_confirmed_at" timestamp with time zone,
    "under_review_at" timestamp with time zone,
    "printing_at" timestamp with time zone,
    "packaging_at" timestamp with time zone,
    "out_for_delivery_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    CONSTRAINT "physical_pack_requests_price_mru_check" CHECK (("price_mru" >= 0)),
    CONSTRAINT "physical_pack_requests_quantity_check" CHECK (("quantity" >= 1))
);


ALTER TABLE "public"."physical_pack_requests" OWNER TO "postgres";


-- One row per submission EVENT (not a column on packs) — a pack can be
-- submitted, rejected, and resubmitted multiple times, and both "how many
-- submissions this calendar month" and "how long since the last one" need
-- full history, not just the latest attempt. Written only by
-- submit_pack_for_review (SECURITY DEFINER) — see "no client write" below.
CREATE TABLE IF NOT EXISTS "public"."pack_submissions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pack_id" "uuid" NOT NULL,
    "creator_id" "uuid" NOT NULL,
    "submitted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "fee_paid" boolean DEFAULT false NOT NULL,
    "fee_tx_id" "uuid"
);


ALTER TABLE "public"."pack_submissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pack_ratings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pack_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "rating" smallint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "pack_ratings_rating_check" CHECK ((("rating" >= 1) AND ("rating" <= 5)))
);


ALTER TABLE "public"."pack_ratings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pack_reactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pack_id" "uuid" NOT NULL,
    "image_url" "text" NOT NULL,
    "sort_order" smallint DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "chk_max_reactions" CHECK (("sort_order" < 30))
);


ALTER TABLE "public"."pack_reactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pack_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pack_id" "uuid" NOT NULL,
    "reporter_id" "uuid" NOT NULL,
    "reason" "public"."report_type_enum" NOT NULL,
    "details" "text",
    "status" "public"."report_status_enum" DEFAULT 'open'::"public"."report_status_enum" NOT NULL,
    "resolved_by" "uuid",
    "resolved_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "pack_reports_details_check" CHECK (("char_length"("details") <= 1000))
);


ALTER TABLE "public"."pack_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pack_reviews" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pack_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "rating_id" "uuid",
    "content" "text" NOT NULL,
    "is_visible" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "pack_reviews_content_check" CHECK ((("char_length"("content") >= 10) AND ("char_length"("content") <= 500)))
);


ALTER TABLE "public"."pack_reviews" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pack_tags" (
    "pack_id" "uuid" NOT NULL,
    "tag" "text" NOT NULL,
    CONSTRAINT "pack_tags_tag_check" CHECK (("tag" ~ '^[a-z0-9_-]{1,30}$'::"text"))
);


ALTER TABLE "public"."pack_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."packs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "creator_id" "uuid" NOT NULL,
    "category_id" "uuid",
    "title" "jsonb" NOT NULL,
    "description" "jsonb",
    "cover_image_url" "text",
    "game_type" "public"."game_type_enum" NOT NULL,
    "language" "text" DEFAULT 'en'::"text" NOT NULL,
    "is_multilang" boolean DEFAULT false NOT NULL,
    "status" "public"."pack_status_enum" DEFAULT 'draft'::"public"."pack_status_enum" NOT NULL,
    "rejection_reason" "text",
    "reviewed_by" "uuid",
    "reviewed_at" timestamp with time zone,
    "card_count" integer DEFAULT 0 NOT NULL,
    "has_spicy" boolean DEFAULT false NOT NULL,
    "price_mru" integer DEFAULT 0 NOT NULL,
    "avg_rating" numeric(3,2) DEFAULT 0.00 NOT NULL,
    "total_ratings" integer DEFAULT 0 NOT NULL,
    "total_purchases" integer DEFAULT 0 NOT NULL,
    "total_plays" integer DEFAULT 0 NOT NULL,
    "version" integer DEFAULT 1 NOT NULL,
    "download_url" "text",
    "is_featured" boolean DEFAULT false NOT NULL,
    "is_promoted" boolean DEFAULT false NOT NULL,
    "published_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "min_players" smallint DEFAULT 2 NOT NULL,
    "available_languages" "text"[] DEFAULT ARRAY['en'::"text"] NOT NULL,
    "pending_category_suggestion_id" "uuid",
    -- Audience restrictions — storage only, not enforced against a
    -- joining user yet (deferred to future game-join work).
    "min_age" smallint,
    "max_age" smallint,
    "gender_restriction" "text" DEFAULT 'everyone'::"text" NOT NULL,
    -- Creator-authored Truth-or-Dare punishment options, optional overall
    -- but >=10 if the creator adds any. Distinct from
    -- room_settings.enable_punishments / the runtime TodPunishment
    -- peer-vote model — this is pack-authored content, that's live
    -- in-game player interaction; a room's GameConfig.punishment_source
    -- decides which one actually gets used.
    "suggested_punishments" "text"[],
    CONSTRAINT "packs_avg_rating_check" CHECK ((("avg_rating" >= (0)::numeric) AND ("avg_rating" <= (5)::numeric))),
    CONSTRAINT "packs_card_count_check" CHECK (("card_count" >= 0)),
    CONSTRAINT "packs_min_players_check" CHECK ((("min_players" >= 2) AND ("min_players" <= 12))),
    CONSTRAINT "packs_price_mru_check" CHECK (("price_mru" >= 0)),
    CONSTRAINT "packs_total_plays_check" CHECK (("total_plays" >= 0)),
    CONSTRAINT "packs_total_purchases_check" CHECK (("total_purchases" >= 0)),
    CONSTRAINT "packs_total_ratings_check" CHECK (("total_ratings" >= 0)),
    CONSTRAINT "packs_version_check" CHECK (("version" >= 1)),
    CONSTRAINT "packs_no_approve_with_pending_category" CHECK ((NOT (("status" = 'approved'::"public"."pack_status_enum") AND ("pending_category_suggestion_id" IS NOT NULL)))),
    CONSTRAINT "packs_min_age_check" CHECK (("min_age" IS NULL OR ("min_age" BETWEEN 13 AND 100))),
    CONSTRAINT "packs_max_age_check" CHECK (("max_age" IS NULL OR ("max_age" BETWEEN 13 AND 100))),
    CONSTRAINT "packs_age_range_check" CHECK (("max_age" IS NULL OR "min_age" IS NULL OR "max_age" >= "min_age")),
    CONSTRAINT "packs_gender_restriction_check" CHECK (("gender_restriction" = ANY (ARRAY['everyone'::"text", 'male'::"text", 'female'::"text"]))),
    CONSTRAINT "packs_suggested_punishments_check" CHECK (("suggested_punishments" IS NULL OR array_length("suggested_punishments", 1) >= 10))
);


ALTER TABLE "public"."packs" OWNER TO "postgres";


COMMENT ON COLUMN "public"."packs"."min_players" IS 'Minimum number of players recommended for this pack (2–12)';



COMMENT ON COLUMN "public"."packs"."available_languages" IS 'Languages this pack has cards in, e.g. {en,ar} or {en,ar,fr}';



CREATE TABLE IF NOT EXISTS "public"."payment_methods" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "type" "public"."payment_method_type_enum" NOT NULL,
    "label" "text" NOT NULL,
    "details" "jsonb" NOT NULL,
    "is_default" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "payment_methods_label_check" CHECK ((("char_length"("label") >= 2) AND ("char_length"("label") <= 50)))
);


ALTER TABLE "public"."payment_methods" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."payment_methods_config" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "type" "text" NOT NULL,
    "name" "text" NOT NULL,
    "logo_url" "text",
    "account_number" "text",
    "account_name" "text",
    "instructions" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "supports_deposit" boolean DEFAULT true NOT NULL,
    "supports_withdrawal" boolean DEFAULT true NOT NULL,
    "min_amount_mru" integer,
    "max_amount_mru" integer,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."payment_methods_config" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "username" "text",
    "display_name" "text",
    "avatar_url" "text",
    "bio" "text",
    "country_code" character(2),
    "age" smallint,
    "phone_number" "text",
    "preferred_lang" "text" DEFAULT 'en'::"text" NOT NULL,
    "online_status" "public"."online_status_enum" DEFAULT 'offline'::"public"."online_status_enum" NOT NULL,
    "in_game_status" boolean DEFAULT false NOT NULL,
    "last_seen_at" timestamp with time zone,
    "verification_status" "public"."verification_status_enum" DEFAULT 'unverified'::"public"."verification_status_enum" NOT NULL,
    "is_banned" boolean DEFAULT false NOT NULL,
    "ban_reason" "text",
    "banned_until" timestamp with time zone,
    "username_changed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "is_premium" boolean DEFAULT false NOT NULL,
    "premium_tier" "text",
    "premium_expires_at" timestamp with time zone,
    "avatar_config" "jsonb",
    "last_ownership_transfer_at" timestamp with time zone,
    "theme_background_color" "text",
    CONSTRAINT "profiles_age_check" CHECK ((("age" IS NULL) OR (("age" >= 13) AND ("age" <= 100)))),
    CONSTRAINT "profiles_bio_check" CHECK (("char_length"("bio") <= 280)),
    CONSTRAINT "profiles_theme_background_color_check" CHECK ((("theme_background_color" IS NULL) OR ("theme_background_color" ~ '^#[0-9A-Fa-f]{6}$'::"text")))
);

ALTER TABLE ONLY "public"."profiles" REPLICA IDENTITY FULL;


ALTER TABLE "public"."profiles" OWNER TO "postgres";


COMMENT ON COLUMN "public"."profiles"."avatar_config" IS 'Avataaars.io trait selection stored as JSON key-value pairs';


COMMENT ON COLUMN "public"."profiles"."theme_background_color" IS 'Premium/Premium Plus: user-chosen solid background override (hex #RRGGBB) applied on top of the selected theme. NULL = theme default. Locked to writes via set_theme_background_color() RPC — see "profiles: own safe update" RLS policy.';



CREATE TABLE IF NOT EXISTS "public"."room_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "room_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "public"."room_member_role_enum" DEFAULT 'player'::"public"."room_member_role_enum" NOT NULL,
    "seat_order" smallint DEFAULT 0 NOT NULL,
    "is_ready" boolean DEFAULT false NOT NULL,
    "is_muted" boolean DEFAULT false NOT NULL,
    "is_game_muted" boolean DEFAULT false NOT NULL,
    "joined_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "left_at" timestamp with time zone,
    "kicked_at" timestamp with time zone,
    "is_away" boolean DEFAULT false NOT NULL,
    "left_definitively" boolean DEFAULT false NOT NULL,
    "is_hidden_spectator" boolean DEFAULT false NOT NULL,
    "last_seen_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE ONLY "public"."room_members" REPLICA IDENTITY FULL;


ALTER TABLE "public"."room_members" OWNER TO "postgres";


COMMENT ON COLUMN "public"."room_members"."is_away" IS 'Player temporarily left — seat preserved, can rejoin game';



COMMENT ON COLUMN "public"."room_members"."is_game_muted" IS 'Moderator-imposed game mute — cannot act (answer/submit/take a turn) but can still watch, distinct from is_muted which only silences text chat';



COMMENT ON COLUMN "public"."room_members"."left_definitively" IS 'Player left permanently — role downgraded to spectator';



COMMENT ON COLUMN "public"."room_members"."is_hidden_spectator" IS 'Premium: spectator is hidden from player list and spectator count';



CREATE TABLE IF NOT EXISTS "public"."rooms" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "cover_emoji" "text" DEFAULT '🎮'::"text",
    "status" "public"."room_status_enum" DEFAULT 'waiting'::"public"."room_status_enum" NOT NULL,
    "visibility" "public"."room_visibility_enum" DEFAULT 'public'::"public"."room_visibility_enum" NOT NULL,
    "language" "text" DEFAULT 'en'::"text" NOT NULL,
    "max_players" smallint DEFAULT 6 NOT NULL,
    "current_players" smallint DEFAULT 0 NOT NULL,
    "game_type" "public"."game_type_enum",
    "pack_id" "uuid",
    "allow_spicy" boolean DEFAULT false NOT NULL,
    "invite_code" "text",
    "require_invite" boolean DEFAULT false NOT NULL,
    "last_active_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "game_started_at" timestamp with time zone,
    "game_ended_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "requires_approval" boolean DEFAULT false NOT NULL,
    "owner_transferred_at" timestamp with time zone,
    "created_by" "uuid",
    CONSTRAINT "chk_player_count" CHECK (("current_players" <= "max_players")),
    CONSTRAINT "rooms_language_check" CHECK (("language" = ANY (ARRAY['en'::"text", 'ar'::"text", 'fr'::"text"]))),
    CONSTRAINT "rooms_max_players_check" CHECK ((("max_players" >= 2) AND ("max_players" <= 12))),
    CONSTRAINT "rooms_name_check" CHECK ((("char_length"("name") >= 2) AND ("char_length"("name") <= 60)))
);


ALTER TABLE "public"."rooms" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."profiles_public" AS
 SELECT "id",
    "username",
    "display_name",
    "avatar_url",
    "bio",
    "country_code",
    "preferred_lang",
    "online_status",
    "in_game_status",
    "verification_status",
    "created_at",
    (COALESCE(( SELECT "count"(*) AS "count"
           FROM "public"."follows" "f"
          WHERE ("f"."followee_id" = "p"."id")), (0)::bigint))::integer AS "followers_count",
    (COALESCE(( SELECT "count"(*) AS "count"
           FROM "public"."follows" "f"
          WHERE ("f"."follower_id" = "p"."id")), (0)::bigint))::integer AS "following_count",
    (COALESCE(( SELECT "count"(*) AS "count"
           FROM "public"."friendships" "fr"
          WHERE (("fr"."status" = 'accepted'::"public"."friendship_status_enum") AND (("fr"."requester_id" = "p"."id") OR ("fr"."addressee_id" = "p"."id")))), (0)::bigint))::integer AS "friends_count",
    (COALESCE(( SELECT "count"(DISTINCT "rm"."room_id") AS "count"
           FROM ("public"."room_members" "rm"
             JOIN "public"."rooms" "r" ON (("r"."id" = "rm"."room_id")))
          WHERE ((("rm"."user_id" = "p"."id") AND ("r"."status" = ANY (ARRAY['in_game'::"public"."room_status_enum", 'ended'::"public"."room_status_enum"])) AND ("rm"."left_at" IS NULL)) OR ("rm"."left_at" IS NOT NULL))), (0)::bigint))::integer AS "games_played",
    (COALESCE(( SELECT "count"(*) AS "count"
           FROM "public"."packs" "pk"
          WHERE (("pk"."creator_id" = "p"."id") AND ("pk"."status" = 'approved'::"public"."pack_status_enum") AND ("pk"."deleted_at" IS NULL))), (0)::bigint))::integer AS "packs_count"
   FROM "public"."profiles" "p"
  WHERE (("deleted_at" IS NULL) AND ("is_banned" = false));


ALTER VIEW "public"."profiles_public" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."promoted_packs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pack_id" "uuid" NOT NULL,
    "position" smallint NOT NULL,
    "starts_at" timestamp with time zone NOT NULL,
    "ends_at" timestamp with time zone NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "promoted_packs_position_check" CHECK ((("position" >= 1) AND ("position" <= 10)))
);


ALTER TABLE "public"."promoted_packs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "reporter_id" "uuid" NOT NULL,
    "target_type" "text" NOT NULL,
    "target_id" "uuid" NOT NULL,
    "reason" "public"."report_type_enum" NOT NULL,
    "details" "text",
    "status" "public"."report_status_enum" DEFAULT 'open'::"public"."report_status_enum" NOT NULL,
    "priority" smallint DEFAULT 0 NOT NULL,
    "assigned_to" "uuid",
    "resolved_by" "uuid",
    "resolved_at" timestamp with time zone,
    "resolution_note" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "reports_details_check" CHECK (("char_length"("details") <= 1000)),
    CONSTRAINT "reports_priority_check" CHECK ((("priority" >= 0) AND ("priority" <= 3))),
    CONSTRAINT "reports_target_type_check" CHECK (("target_type" = ANY (ARRAY['profile'::"text", 'pack'::"text", 'chat_message'::"text", 'room'::"text"])))
);


ALTER TABLE "public"."reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."room_bans" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "room_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "banned_by" "uuid" NOT NULL,
    "reason" "text",
    "banned_until" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "lifted_at" timestamp with time zone,
    "lifted_by" "uuid"
);


ALTER TABLE "public"."room_bans" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."room_chat_messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "room_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "content" "text" NOT NULL,
    "is_system" boolean DEFAULT false NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "reply_to_id" "uuid",
    "reply_to_content" "text",
    "reply_to_display_name" "text",
    "is_anonymous" boolean DEFAULT false NOT NULL,
    "real_sender_id" "uuid",
    CONSTRAINT "room_chat_messages_content_check" CHECK ((("char_length"("content") >= 1) AND ("char_length"("content") <= 500)))
);


ALTER TABLE "public"."room_chat_messages" OWNER TO "postgres";


COMMENT ON COLUMN "public"."room_chat_messages"."is_anonymous" IS 'Premium feature: sender identity hidden from non-moderators';



COMMENT ON COLUMN "public"."room_chat_messages"."real_sender_id" IS 'Always populated for anonymous messages — visible only to admins/mods via RLS';



CREATE TABLE IF NOT EXISTS "public"."room_creation_quotas" (
    "user_id" "uuid" NOT NULL,
    "quota_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "rooms_today" smallint DEFAULT 0 NOT NULL,
    "is_premium" boolean DEFAULT false NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."room_creation_quotas" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."room_invites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "room_id" "uuid" NOT NULL,
    "invited_by" "uuid" NOT NULL,
    "invited_user" "uuid" NOT NULL,
    "message" "text",
    "expires_at" timestamp with time zone DEFAULT ("now"() + '24:00:00'::interval) NOT NULL,
    "accepted_at" timestamp with time zone,
    "declined_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "chk_no_self_invite" CHECK (("invited_by" <> "invited_user")),
    CONSTRAINT "room_invites_message_check" CHECK (("char_length"("message") <= 200))
);


ALTER TABLE "public"."room_invites" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."room_join_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "room_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "message" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "resolved_at" timestamp with time zone,
    CONSTRAINT "room_join_requests_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'approved'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."room_join_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."game_rejoin_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "room_id" "uuid" NOT NULL,
    "session_id" "uuid",
    "user_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "resolved_at" timestamp with time zone,
    CONSTRAINT "game_rejoin_requests_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'approved'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."game_rejoin_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."room_logs" (
    "id" bigint NOT NULL,
    "room_id" "uuid" NOT NULL,
    "actor_id" "uuid",
    "target_id" "uuid",
    "action" "public"."room_log_action_enum" NOT NULL,
    "metadata" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."room_logs" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."room_logs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."room_logs_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."room_logs_id_seq" OWNED BY "public"."room_logs"."id";



CREATE TABLE IF NOT EXISTS "public"."room_moderators" (
    "room_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "granted_by" "uuid" NOT NULL,
    "granted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "permissions" "text"[] DEFAULT '{}'::"text"[] NOT NULL
);


COMMENT ON COLUMN "public"."room_moderators"."permissions" IS 'Granular moderator permission keys: accept_joins, accept_spectators, accept_rejoins, advance_turn, skip_turn, kick_players, mute_chat, manage_settings. start_game and end_game are owner-only and no longer grantable. Owner always has every permission implicitly (see has_room_permission()).';


-- One-time cleanup: strip any already-granted start_game/end_game values —
-- both are now hard owner-only (see create_game_session and the ToD
-- end-game path), so a stale grant here would be misleading even though
-- has_room_permission()'s callers no longer check for either key.
UPDATE "public"."room_moderators"
SET "permissions" = array_remove(array_remove("permissions", 'start_game'), 'end_game')
WHERE 'start_game' = ANY("permissions") OR 'end_game' = ANY("permissions");


ALTER TABLE "public"."room_moderators" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."room_played_packs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "room_id" "uuid" NOT NULL,
    "pack_id" "uuid" NOT NULL,
    "played_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."room_played_packs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."room_return_timers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "room_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "return_by" timestamp with time zone NOT NULL,
    "is_premium" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "returned_at" timestamp with time zone,
    "expired" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."room_return_timers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."room_settings" (
    "room_id" "uuid" NOT NULL,
    "turn_timer_secs" smallint DEFAULT 60 NOT NULL,
    "max_rounds" smallint DEFAULT 10 NOT NULL,
    "allow_skip" boolean DEFAULT true NOT NULL,
    "chat_enabled" boolean DEFAULT true NOT NULL,
    "allow_spectators" boolean DEFAULT false NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "allow_spicy" boolean DEFAULT false NOT NULL,
    "requires_approval" boolean DEFAULT false NOT NULL,
    "spectator_approval_required" boolean DEFAULT false NOT NULL,
    "allow_anonymous_spectators" boolean DEFAULT true NOT NULL,
    "enable_punishments" boolean DEFAULT false NOT NULL,
    -- 'players' (default, existing peer-vote flow) or 'pack' (resolves
    -- directly from the selected pack's suggested_punishments).
    "punishment_source" "text" DEFAULT 'players'::"text" NOT NULL,
    "proof_visibility_policy" "text" DEFAULT 'everyone'::"text" NOT NULL,
    "proof_view_seconds" smallint DEFAULT 5 NOT NULL,
    "proof_replay_mode" "text" DEFAULT 'once'::"text" NOT NULL,
    "proof_visibility_selected_user_ids" "uuid"[] DEFAULT ARRAY[]::"uuid"[] NOT NULL,
    CONSTRAINT "room_settings_max_rounds_check" CHECK ((("max_rounds" >= 1) AND ("max_rounds" <= 50))),
    CONSTRAINT "room_settings_turn_timer_secs_check" CHECK ((("turn_timer_secs" >= 15) AND ("turn_timer_secs" <= 300))),
    CONSTRAINT "room_settings_proof_visibility_policy_check" CHECK (("proof_visibility_policy" = ANY (ARRAY['everyone'::"text", 'players_only'::"text", 'spectators_only'::"text", 'selected'::"text"]))),
    CONSTRAINT "room_settings_proof_replay_mode_check" CHECK (("proof_replay_mode" = ANY (ARRAY['once'::"text", 'replay_once'::"text", 'timed'::"text"]))),
    CONSTRAINT "room_settings_proof_view_seconds_check" CHECK ((("proof_view_seconds" = 0) OR (("proof_view_seconds" >= 2) AND ("proof_view_seconds" <= 30)))),
    CONSTRAINT "room_settings_punishment_source_check" CHECK (("punishment_source" = ANY (ARRAY['players'::"text", 'pack'::"text"])))
);


ALTER TABLE "public"."room_settings" OWNER TO "postgres";


COMMENT ON COLUMN "public"."room_settings"."allow_anonymous_spectators" IS 'When true, premium users can join as hidden/anonymous spectators';


-- Server-side proof-view ledger — before this, view/replay counting lived
-- only in the shared game-state broadcast (state.turnProofViewedBy),
-- trusted from whichever client currently runs as room owner. Nothing in
-- Postgres validated who was allowed to view or how many times — a
-- modified client (or simply a different current-owner device) had
-- nothing enforcing the room's proof_visibility_policy/proof_replay_mode.
-- One row per actual view; enforcement happens in record_proof_view().
CREATE TABLE IF NOT EXISTS "public"."tod_proof_views" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "uuid" NOT NULL,
    "turn_started_at" bigint NOT NULL,
    "viewer_id" "uuid" NOT NULL,
    "viewed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "view_number" integer NOT NULL
);


ALTER TABLE "public"."tod_proof_views" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."session_custom_cards" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "uuid" NOT NULL,
    "room_id" "uuid" NOT NULL,
    "added_by" "uuid" NOT NULL,
    "card_type" "text" DEFAULT 'truth'::"text" NOT NULL,
    "content" "text" NOT NULL,
    "difficulty" "text" DEFAULT 'mild'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "session_custom_cards_card_type_check" CHECK (("card_type" = ANY (ARRAY['truth'::"text", 'dare'::"text"]))),
    CONSTRAINT "session_custom_cards_content_check" CHECK ((("char_length"("content") >= 5) AND ("char_length"("content") <= 300))),
    CONSTRAINT "session_custom_cards_difficulty_check" CHECK (("difficulty" = ANY (ARRAY['mild'::"text", 'medium'::"text", 'spicy'::"text"])))
);


ALTER TABLE "public"."session_custom_cards" OWNER TO "postgres";


-- Backend-only (service_role) delivery log for Moorsyl SMS sends. Previously
-- "sent successfully" only meant Moorsyl's API returned 2xx — that's true
-- even for the hosted Verify product, which accepted requests but never
-- actually delivered for this account. This records the real provider
-- response and a delivery status independent of the initial HTTP result,
-- so failures are visible instead of silently assumed-success.
CREATE TABLE IF NOT EXISTS "public"."sms_delivery_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "phone" "text" NOT NULL,
    "message_id" "text",
    "idempotency_key" "text",
    "organization_id" "text",
    "provider" "text" DEFAULT 'moorsyl'::"text" NOT NULL,
    "message_type" "text" DEFAULT 'otp'::"text" NOT NULL,
    "status" "text" DEFAULT 'accepted'::"text" NOT NULL,
    "provider_response" "jsonb",
    "error_message" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "sms_delivery_log_status_check" CHECK (("status" = ANY (ARRAY['accepted'::"text", 'pending'::"text", 'processing'::"text", 'sent'::"text", 'failed'::"text", 'error'::"text"]))),
    CONSTRAINT "sms_delivery_log_message_type_check" CHECK (("message_type" = ANY (ARRAY['otp'::"text", 'test'::"text", 'diagnostic'::"text"])))
);


ALTER TABLE "public"."sms_delivery_log" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."spectator_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "room_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "decided_by" "uuid",
    "decided_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "spectator_requests_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'approved'::"text", 'denied'::"text"])))
);


ALTER TABLE "public"."spectator_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "tier" "text" DEFAULT 'premium'::"text" NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "purchase_source" "text" DEFAULT 'admin'::"text" NOT NULL,
    "store_product_id" "text",
    "store_transaction_id" "text",
    "store_original_tx_id" "text",
    "auto_renew" boolean DEFAULT true NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone,
    "cancelled_at" timestamp with time zone,
    "trial_ends_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "subscriptions_purchase_source_check" CHECK (("purchase_source" = ANY (ARRAY['ios'::"text", 'android'::"text", 'admin'::"text", 'promo'::"text", 'web'::"text", 'wallet'::"text"]))),
    CONSTRAINT "subscriptions_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'cancelled'::"text", 'expired'::"text", 'paused'::"text", 'trial'::"text"]))),
    CONSTRAINT "subscriptions_tier_check" CHECK (("tier" = ANY (ARRAY['premium'::"text", 'premium_plus'::"text"])))
);


ALTER TABLE "public"."subscriptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wallets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "balance_mru" integer DEFAULT 0 NOT NULL,
    "earnings_balance_mru" integer DEFAULT 0 NOT NULL,
    "is_frozen" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "wallets_balance_mru_check" CHECK (("balance_mru" >= 0)),
    CONSTRAINT "wallets_earnings_balance_mru_check" CHECK (("earnings_balance_mru" >= 0))
);

ALTER TABLE ONLY "public"."wallets" REPLICA IDENTITY FULL;


ALTER TABLE "public"."wallets" OWNER TO "postgres";


COMMENT ON COLUMN "public"."wallets"."balance_mru" IS 'Spendable balance — deposits + manually transferred earnings. The ONLY balance used for buying packs, creating rooms, Premium, or any in-app payment.';



COMMENT ON COLUMN "public"."wallets"."earnings_balance_mru" IS 'Creator earnings, commissions, rewards. Withdrawals draw ONLY from here (verified creator + balance >= 500 MRU). Never auto-transferred to balance_mru — the user must explicitly transfer.';


CREATE TABLE IF NOT EXISTS "public"."withdrawals" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "wallet_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "amount_mru" integer NOT NULL,
    "payout_method" "public"."payment_method_type_enum" NOT NULL,
    "payout_details" "jsonb" NOT NULL,
    "status" "public"."transaction_status_enum" DEFAULT 'pending'::"public"."transaction_status_enum" NOT NULL,
    "tx_id" "uuid",
    "submitted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "processed_at" timestamp with time zone,
    "processed_by" "uuid",
    "rejected_at" timestamp with time zone,
    "rejected_reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "hold_tx_id" "uuid",
    "payment_method_id" "uuid",
    "idempotency_key" "text",
    "notes" "text",
    "rejected_by" "uuid",
    CONSTRAINT "withdrawals_amount_mru_check" CHECK (("amount_mru" >= 500))
);


ALTER TABLE "public"."withdrawals" OWNER TO "postgres";


ALTER TABLE ONLY "public"."financial_audit_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."financial_audit_log_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."game_states" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."game_states_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."moderation_actions" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."moderation_actions_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."otp_audit_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."otp_audit_log_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."room_logs" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."room_logs_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."blocked_users"
    ADD CONSTRAINT "blocked_users_pkey" PRIMARY KEY ("blocker_id", "blocked_id");



ALTER TABLE ONLY "public"."commissions"
    ADD CONSTRAINT "commissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."commissions"
    ADD CONSTRAINT "commissions_purchase_id_key" UNIQUE ("purchase_id");



ALTER TABLE ONLY "public"."creator_verifications"
    ADD CONSTRAINT "creator_verifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."deposits"
    ADD CONSTRAINT "deposits_idempotency_key_key" UNIQUE ("idempotency_key");



ALTER TABLE ONLY "public"."deposits"
    ADD CONSTRAINT "deposits_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."downloaded_packs"
    ADD CONSTRAINT "downloaded_packs_pkey" PRIMARY KEY ("user_id", "pack_id");



ALTER TABLE ONLY "public"."financial_audit_log"
    ADD CONSTRAINT "financial_audit_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."follows"
    ADD CONSTRAINT "follows_pkey" PRIMARY KEY ("follower_id", "followee_id");



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."game_rounds"
    ADD CONSTRAINT "game_rounds_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."game_sessions"
    ADD CONSTRAINT "game_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."game_states"
    ADD CONSTRAINT "game_states_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."game_turns"
    ADD CONSTRAINT "game_turns_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."game_votes"
    ADD CONSTRAINT "game_votes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."gameplay_analytics"
    ADD CONSTRAINT "gameplay_analytics_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."gameplay_analytics"
    ADD CONSTRAINT "gameplay_analytics_session_id_key" UNIQUE ("session_id");



ALTER TABLE ONLY "public"."moderation_actions"
    ADD CONSTRAINT "moderation_actions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_pkey" PRIMARY KEY ("user_id", "type");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_idempotency_key_key" UNIQUE ("idempotency_key");



ALTER TABLE ONLY "public"."otp_audit_log"
    ADD CONSTRAINT "otp_audit_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pack_analytics"
    ADD CONSTRAINT "pack_analytics_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pack_cards"
    ADD CONSTRAINT "pack_cards_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pack_categories"
    ADD CONSTRAINT "pack_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pack_category_suggestions"
    ADD CONSTRAINT "pack_category_suggestions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pack_categories"
    ADD CONSTRAINT "pack_categories_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."pack_languages"
    ADD CONSTRAINT "pack_languages_pkey" PRIMARY KEY ("code");



ALTER TABLE ONLY "public"."pack_purchases"
    ADD CONSTRAINT "pack_purchases_idempotency_key_key" UNIQUE ("idempotency_key");



ALTER TABLE ONLY "public"."pack_purchases"
    ADD CONSTRAINT "pack_purchases_pack_id_buyer_id_key" UNIQUE ("pack_id", "buyer_id");



ALTER TABLE ONLY "public"."pack_purchases"
    ADD CONSTRAINT "pack_purchases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_settings"
    ADD CONSTRAINT "app_settings_pkey" PRIMARY KEY ("key");



ALTER TABLE ONLY "public"."physical_pack_requests"
    ADD CONSTRAINT "physical_pack_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pack_submissions"
    ADD CONSTRAINT "pack_submissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pack_ratings"
    ADD CONSTRAINT "pack_ratings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pack_reactions"
    ADD CONSTRAINT "pack_reactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pack_reports"
    ADD CONSTRAINT "pack_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pack_reviews"
    ADD CONSTRAINT "pack_reviews_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pack_tags"
    ADD CONSTRAINT "pack_tags_pkey" PRIMARY KEY ("pack_id", "tag");



ALTER TABLE ONLY "public"."packs"
    ADD CONSTRAINT "packs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payment_methods_config"
    ADD CONSTRAINT "payment_methods_config_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payment_methods_config"
    ADD CONSTRAINT "payment_methods_config_type_key" UNIQUE ("type");



ALTER TABLE ONLY "public"."payment_methods"
    ADD CONSTRAINT "payment_methods_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_username_key" UNIQUE ("username");



ALTER TABLE ONLY "public"."promoted_packs"
    ADD CONSTRAINT "promoted_packs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."room_bans"
    ADD CONSTRAINT "room_bans_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."room_bans"
    ADD CONSTRAINT "room_bans_room_id_user_id_key" UNIQUE ("room_id", "user_id");



ALTER TABLE ONLY "public"."room_chat_messages"
    ADD CONSTRAINT "room_chat_messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."room_creation_quotas"
    ADD CONSTRAINT "room_creation_quotas_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."room_invites"
    ADD CONSTRAINT "room_invites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."room_join_requests"
    ADD CONSTRAINT "room_join_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."room_join_requests"
    ADD CONSTRAINT "room_join_requests_room_id_user_id_key" UNIQUE ("room_id", "user_id");



ALTER TABLE ONLY "public"."game_rejoin_requests"
    ADD CONSTRAINT "game_rejoin_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."game_rejoin_requests"
    ADD CONSTRAINT "game_rejoin_requests_room_id_user_id_key" UNIQUE ("room_id", "user_id");



ALTER TABLE ONLY "public"."room_logs"
    ADD CONSTRAINT "room_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."room_members"
    ADD CONSTRAINT "room_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."room_members"
    ADD CONSTRAINT "room_members_room_id_user_id_key" UNIQUE ("room_id", "user_id");



ALTER TABLE ONLY "public"."room_moderators"
    ADD CONSTRAINT "room_moderators_pkey" PRIMARY KEY ("room_id", "user_id");



ALTER TABLE ONLY "public"."room_moderators"
    ADD CONSTRAINT "room_moderators_room_id_user_id_key" UNIQUE ("room_id", "user_id");



ALTER TABLE ONLY "public"."room_played_packs"
    ADD CONSTRAINT "room_played_packs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."room_played_packs"
    ADD CONSTRAINT "room_played_packs_room_id_pack_id_key" UNIQUE ("room_id", "pack_id");



ALTER TABLE ONLY "public"."room_return_timers"
    ADD CONSTRAINT "room_return_timers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."room_return_timers"
    ADD CONSTRAINT "room_return_timers_room_id_user_id_key" UNIQUE ("room_id", "user_id");



ALTER TABLE ONLY "public"."room_settings"
    ADD CONSTRAINT "room_settings_pkey" PRIMARY KEY ("room_id");



ALTER TABLE ONLY "public"."rooms"
    ADD CONSTRAINT "rooms_invite_code_key" UNIQUE ("invite_code");



ALTER TABLE ONLY "public"."rooms"
    ADD CONSTRAINT "rooms_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."session_custom_cards"
    ADD CONSTRAINT "session_custom_cards_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sms_delivery_log"
    ADD CONSTRAINT "sms_delivery_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tod_proof_views"
    ADD CONSTRAINT "tod_proof_views_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."spectator_requests"
    ADD CONSTRAINT "spectator_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."spectator_requests"
    ADD CONSTRAINT "spectator_requests_room_id_user_id_key" UNIQUE ("room_id", "user_id");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_user_id_store_transaction_id_key" UNIQUE ("user_id", "store_transaction_id");



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "uq_friendship_pair" UNIQUE ("requester_id", "addressee_id");



ALTER TABLE ONLY "public"."pack_analytics"
    ADD CONSTRAINT "uq_pack_daily" UNIQUE ("pack_id", "date");



ALTER TABLE ONLY "public"."pack_purchases"
    ADD CONSTRAINT "uq_pack_purchase" UNIQUE ("pack_id", "buyer_id") DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "public"."pack_ratings"
    ADD CONSTRAINT "uq_pack_rating" UNIQUE ("pack_id", "user_id");



ALTER TABLE ONLY "public"."pack_reactions"
    ADD CONSTRAINT "uq_pack_reaction_order" UNIQUE ("pack_id", "sort_order");



ALTER TABLE ONLY "public"."pack_reviews"
    ADD CONSTRAINT "uq_pack_review" UNIQUE ("pack_id", "user_id");



ALTER TABLE ONLY "public"."creator_verifications"
    ADD CONSTRAINT "uq_pending_verification" UNIQUE ("user_id") DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "public"."promoted_packs"
    ADD CONSTRAINT "uq_promoted_position" UNIQUE ("position", "starts_at", "ends_at") DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "uq_report" UNIQUE ("reporter_id", "target_type", "target_id") DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "public"."room_invites"
    ADD CONSTRAINT "uq_room_invite" UNIQUE ("room_id", "invited_user") DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "public"."game_rounds"
    ADD CONSTRAINT "uq_session_round" UNIQUE ("session_id", "round_number");



ALTER TABLE ONLY "public"."game_turns"
    ADD CONSTRAINT "uq_session_turn" UNIQUE ("session_id", "round_id", "turn_number");



ALTER TABLE ONLY "public"."game_votes"
    ADD CONSTRAINT "uq_vote" UNIQUE ("turn_id", "voter_id");



ALTER TABLE ONLY "public"."wallet_transactions"
    ADD CONSTRAINT "wallet_transactions_idempotency_key_key" UNIQUE ("idempotency_key");



ALTER TABLE ONLY "public"."wallet_transactions"
    ADD CONSTRAINT "wallet_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wallets"
    ADD CONSTRAINT "wallets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wallets"
    ADD CONSTRAINT "wallets_user_id_key" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."withdrawals"
    ADD CONSTRAINT "withdrawals_idempotency_key_key" UNIQUE ("idempotency_key");



ALTER TABLE ONLY "public"."withdrawals"
    ADD CONSTRAINT "withdrawals_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_blocked_users_blocked" ON "public"."blocked_users" USING "btree" ("blocked_id");



CREATE INDEX "idx_chat_room_created" ON "public"."room_chat_messages" USING "btree" ("room_id", "created_at" DESC) WHERE ("is_deleted" = false);



CREATE INDEX "idx_commissions_creator" ON "public"."commissions" USING "btree" ("creator_id", "created_at" DESC);



CREATE INDEX "idx_deposits_pending" ON "public"."deposits" USING "btree" ("status", "created_at") WHERE ("status" = 'pending'::"public"."transaction_status_enum");



CREATE INDEX "idx_deposits_user" ON "public"."deposits" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "idx_fin_audit_action" ON "public"."financial_audit_log" USING "btree" ("action", "created_at" DESC);



CREATE INDEX "idx_fin_audit_actor" ON "public"."financial_audit_log" USING "btree" ("actor_id", "created_at" DESC);



CREATE INDEX "idx_follows_followee" ON "public"."follows" USING "btree" ("followee_id");



CREATE INDEX "idx_friendships_accepted" ON "public"."friendships" USING "btree" ("requester_id", "addressee_id") WHERE ("status" = 'accepted'::"public"."friendship_status_enum");



CREATE INDEX "idx_friendships_addressee" ON "public"."friendships" USING "btree" ("addressee_id", "status");



CREATE INDEX "idx_friendships_requester" ON "public"."friendships" USING "btree" ("requester_id", "status");



CREATE INDEX "idx_game_rounds_session" ON "public"."game_rounds" USING "btree" ("session_id", "round_number");



CREATE INDEX "idx_game_sessions_room" ON "public"."game_sessions" USING "btree" ("room_id", "started_at" DESC);



CREATE INDEX "idx_game_sessions_status" ON "public"."game_sessions" USING "btree" ("status") WHERE ("status" = 'active'::"public"."game_session_status_enum");



CREATE INDEX "idx_game_states_session" ON "public"."game_states" USING "btree" ("session_id", "snapshot_at" DESC);



CREATE INDEX "idx_game_turns_player" ON "public"."game_turns" USING "btree" ("player_id", "started_at" DESC);



CREATE INDEX "idx_game_turns_session" ON "public"."game_turns" USING "btree" ("session_id", "turn_number");



CREATE INDEX "idx_game_votes_session" ON "public"."game_votes" USING "btree" ("session_id", "voter_id");



CREATE INDEX "idx_game_votes_turn" ON "public"."game_votes" USING "btree" ("turn_id");



CREATE INDEX "idx_gameplay_analytics_date" ON "public"."gameplay_analytics" USING "btree" (((("started_at" AT TIME ZONE 'UTC'::"text"))::"date"));



CREATE INDEX "idx_gameplay_analytics_game_type" ON "public"."gameplay_analytics" USING "btree" ("game_type", "started_at" DESC);



CREATE INDEX "idx_gameplay_analytics_pack" ON "public"."gameplay_analytics" USING "btree" ("pack_id", "started_at" DESC) WHERE ("pack_id" IS NOT NULL);



CREATE INDEX "idx_join_requests_room_pending" ON "public"."room_join_requests" USING "btree" ("room_id", "status") WHERE ("status" = 'pending'::"text");



CREATE INDEX "idx_moderation_moderator" ON "public"."moderation_actions" USING "btree" ("moderator_id", "created_at" DESC);



CREATE INDEX "idx_moderation_report" ON "public"."moderation_actions" USING "btree" ("report_id") WHERE ("report_id" IS NOT NULL);



CREATE INDEX "idx_moderation_target_user" ON "public"."moderation_actions" USING "btree" ("target_user_id", "created_at" DESC) WHERE ("target_user_id" IS NOT NULL);



CREATE INDEX "idx_notifications_expires" ON "public"."notifications" USING "btree" ("expires_at") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_notifications_user_all" ON "public"."notifications" USING "btree" ("user_id", "created_at" DESC) WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_notifications_user_unread" ON "public"."notifications" USING "btree" ("user_id", "created_at" DESC) WHERE (("is_read" = false) AND ("deleted_at" IS NULL));



CREATE INDEX "idx_otp_audit_date" ON "public"."otp_audit_log" USING "btree" (((("created_at" AT TIME ZONE 'UTC'::"text"))::"date"));



CREATE INDEX "idx_otp_audit_email" ON "public"."otp_audit_log" USING "btree" ("email", "created_at" DESC);



CREATE INDEX "idx_otp_audit_email_time" ON "public"."otp_audit_log" USING "btree" ("email", "created_at" DESC);



CREATE INDEX "idx_pack_analytics_date" ON "public"."pack_analytics" USING "btree" ("date" DESC);



CREATE INDEX "idx_pack_analytics_pack" ON "public"."pack_analytics" USING "btree" ("pack_id", "date" DESC);



CREATE INDEX "idx_pack_cards_pack" ON "public"."pack_cards" USING "btree" ("pack_id", "sort_order", "difficulty") WHERE ("is_active" = true);



CREATE INDEX "idx_pack_ratings_pack" ON "public"."pack_ratings" USING "btree" ("pack_id");



CREATE INDEX "idx_pack_reactions_pack" ON "public"."pack_reactions" USING "btree" ("pack_id", "sort_order");



CREATE INDEX "idx_pack_reports_open" ON "public"."pack_reports" USING "btree" ("status", "created_at") WHERE ("status" = 'open'::"public"."report_status_enum");



CREATE INDEX "idx_pack_reports_pack" ON "public"."pack_reports" USING "btree" ("pack_id", "status");



CREATE INDEX "idx_pack_reviews_pack" ON "public"."pack_reviews" USING "btree" ("pack_id", "created_at" DESC) WHERE ("is_visible" = true);



CREATE INDEX "idx_pack_tags_tag" ON "public"."pack_tags" USING "btree" ("tag");



CREATE INDEX "idx_packs_browse" ON "public"."packs" USING "btree" ("status", "game_type", "avg_rating" DESC, "total_purchases" DESC) WHERE (("deleted_at" IS NULL) AND ("status" = 'approved'::"public"."pack_status_enum"));



CREATE INDEX "idx_packs_category" ON "public"."packs" USING "btree" ("category_id", "avg_rating" DESC) WHERE (("deleted_at" IS NULL) AND ("status" = 'approved'::"public"."pack_status_enum"));



CREATE INDEX "idx_packs_creator" ON "public"."packs" USING "btree" ("creator_id", "status", "created_at" DESC) WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_packs_featured" ON "public"."packs" USING "btree" ("is_featured", "is_promoted") WHERE (("deleted_at" IS NULL) AND ("status" = 'approved'::"public"."pack_status_enum"));



CREATE INDEX "idx_packs_languages" ON "public"."packs" USING "gin" ("available_languages");



CREATE INDEX "idx_packs_search" ON "public"."packs" USING "gin" ("public"."immutable_to_tsvector"(((((COALESCE(("title" ->> 'en'::"text"), ''::"text") || ' '::"text") || COALESCE(("title" ->> 'ar'::"text"), ''::"text")) || ' '::"text") || COALESCE(("title" ->> 'fr'::"text"), ''::"text")))) WHERE (("deleted_at" IS NULL) AND ("status" = 'approved'::"public"."pack_status_enum"));



CREATE INDEX "idx_payment_methods_user" ON "public"."payment_methods" USING "btree" ("user_id", "is_default" DESC);



CREATE INDEX "idx_profiles_email" ON "public"."profiles" USING "btree" ("email");



CREATE INDEX "idx_profiles_is_banned" ON "public"."profiles" USING "btree" ("is_banned") WHERE ("is_banned" = true);



CREATE INDEX "idx_profiles_online_status" ON "public"."profiles" USING "btree" ("online_status") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_profiles_search" ON "public"."profiles" USING "gin" ("public"."immutable_to_tsvector"(((COALESCE("username", ''::"text") || ' '::"text") || COALESCE("display_name", ''::"text")))) WHERE ("deleted_at" IS NULL);



CREATE UNIQUE INDEX "idx_profiles_username_lower" ON "public"."profiles" USING "btree" ("lower"("username")) WHERE (("username" IS NOT NULL) AND ("deleted_at" IS NULL));



CREATE INDEX "idx_promoted_active" ON "public"."promoted_packs" USING "btree" ("position", "starts_at", "ends_at");



CREATE INDEX "idx_purchases_buyer" ON "public"."pack_purchases" USING "btree" ("buyer_id", "pack_id", "expires_at" DESC) WHERE ("status" = 'completed'::"public"."purchase_status_enum");



CREATE INDEX "idx_purchases_pack" ON "public"."pack_purchases" USING "btree" ("pack_id", "purchased_at" DESC) WHERE ("status" = 'completed'::"public"."purchase_status_enum");



CREATE INDEX "idx_reports_open" ON "public"."reports" USING "btree" ("status", "priority" DESC, "created_at") WHERE ("status" = 'open'::"public"."report_status_enum");



CREATE INDEX "idx_reports_reporter" ON "public"."reports" USING "btree" ("reporter_id", "created_at" DESC);



CREATE INDEX "idx_reports_target" ON "public"."reports" USING "btree" ("target_type", "target_id", "status");



CREATE INDEX "idx_room_bans_room" ON "public"."room_bans" USING "btree" ("room_id") WHERE ("lifted_at" IS NULL);



CREATE INDEX "idx_room_bans_user" ON "public"."room_bans" USING "btree" ("user_id") WHERE ("lifted_at" IS NULL);



CREATE INDEX "idx_room_chat_reply_to" ON "public"."room_chat_messages" USING "btree" ("reply_to_id") WHERE ("reply_to_id" IS NOT NULL);



CREATE INDEX "idx_room_invites_invited_user" ON "public"."room_invites" USING "btree" ("invited_user", "expires_at");



CREATE INDEX "idx_room_invites_user" ON "public"."room_invites" USING "btree" ("invited_user", "created_at" DESC) WHERE (("accepted_at" IS NULL) AND ("declined_at" IS NULL));



CREATE INDEX "idx_room_join_requests_room" ON "public"."room_join_requests" USING "btree" ("room_id", "status");



CREATE INDEX "idx_game_rejoin_requests_room" ON "public"."game_rejoin_requests" USING "btree" ("room_id", "status");



CREATE INDEX "idx_room_logs_actor" ON "public"."room_logs" USING "btree" ("actor_id", "created_at" DESC) WHERE ("actor_id" IS NOT NULL);



CREATE INDEX "idx_room_logs_room" ON "public"."room_logs" USING "btree" ("room_id", "created_at" DESC);



CREATE INDEX "idx_room_members_away" ON "public"."room_members" USING "btree" ("room_id", "is_away") WHERE ("is_away" = true);



CREATE INDEX "idx_room_members_room" ON "public"."room_members" USING "btree" ("room_id", "seat_order") WHERE ("left_at" IS NULL);



CREATE INDEX "idx_room_members_user" ON "public"."room_members" USING "btree" ("user_id", "joined_at" DESC) WHERE ("left_at" IS NULL);



CREATE INDEX "idx_room_moderators_room" ON "public"."room_moderators" USING "btree" ("room_id");



CREATE INDEX "idx_room_moderators_user" ON "public"."room_moderators" USING "btree" ("user_id");



CREATE INDEX "idx_room_played_packs_room" ON "public"."room_played_packs" USING "btree" ("room_id");



CREATE INDEX "idx_room_return_timers_room" ON "public"."room_return_timers" USING "btree" ("room_id");



CREATE INDEX "idx_rooms_invite_code" ON "public"."rooms" USING "btree" ("invite_code") WHERE (("invite_code" IS NOT NULL) AND ("deleted_at" IS NULL));



CREATE INDEX "idx_rooms_owner" ON "public"."rooms" USING "btree" ("owner_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_rooms_status" ON "public"."rooms" USING "btree" ("status", "visibility", "last_active_at" DESC) WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_session_custom_cards_session" ON "public"."session_custom_cards" USING "btree" ("session_id");



CREATE INDEX "idx_spectator_requests_room" ON "public"."spectator_requests" USING "btree" ("room_id", "status");



CREATE INDEX "idx_subscriptions_expires_at" ON "public"."subscriptions" USING "btree" ("expires_at") WHERE ("status" = 'active'::"text");



CREATE INDEX "idx_subscriptions_user_id" ON "public"."subscriptions" USING "btree" ("user_id", "status");



CREATE INDEX "idx_verifications_pending" ON "public"."creator_verifications" USING "btree" ("status", "created_at") WHERE ("status" = 'pending'::"public"."verification_status_enum");



CREATE INDEX "idx_wallet_tx_reference" ON "public"."wallet_transactions" USING "btree" ("reference_id") WHERE ("reference_id" IS NOT NULL);



CREATE INDEX "idx_wallet_tx_wallet" ON "public"."wallet_transactions" USING "btree" ("wallet_id", "created_at" DESC);



CREATE INDEX "idx_wallets_user" ON "public"."wallets" USING "btree" ("user_id");



CREATE INDEX "idx_withdrawals_pending" ON "public"."withdrawals" USING "btree" ("status", "created_at") WHERE ("status" = 'pending'::"public"."transaction_status_enum");



CREATE INDEX "idx_withdrawals_user" ON "public"."withdrawals" USING "btree" ("user_id", "created_at" DESC);



CREATE UNIQUE INDEX "uidx_profiles_username" ON "public"."profiles" USING "btree" ("lower"("username")) WHERE (("username" IS NOT NULL) AND ("deleted_at" IS NULL));



CREATE OR REPLACE TRIGGER "trg_apply_moderation" AFTER INSERT ON "public"."moderation_actions" FOR EACH ROW EXECUTE FUNCTION "public"."apply_moderation_to_profile"();



CREATE OR REPLACE TRIGGER "trg_apply_verification" AFTER UPDATE OF "status" ON "public"."creator_verifications" FOR EACH ROW EXECUTE FUNCTION "public"."apply_verification_decision"();



CREATE OR REPLACE TRIGGER "trg_apply_category_suggestion" AFTER UPDATE OF "status" ON "public"."pack_category_suggestions" FOR EACH ROW EXECUTE FUNCTION "public"."apply_category_suggestion_decision"();



CREATE OR REPLACE TRIGGER "trg_create_wallet" AFTER INSERT ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."create_user_wallet"();



CREATE OR REPLACE TRIGGER "trg_creator_verifications_updated_at" BEFORE UPDATE ON "public"."creator_verifications" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_deposits_updated_at" BEFORE UPDATE ON "public"."deposits" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_friendships_updated_at" BEFORE UPDATE ON "public"."friendships" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_game_sessions_updated_at" BEFORE UPDATE ON "public"."game_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_notification_preferences_updated_at" BEFORE UPDATE ON "public"."notification_preferences" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_notifications_read_at" BEFORE UPDATE OF "is_read" ON "public"."notifications" FOR EACH ROW EXECUTE FUNCTION "public"."notifications_set_read_at"();



CREATE OR REPLACE TRIGGER "trg_pack_analytics_updated_at" BEFORE UPDATE ON "public"."pack_analytics" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_pack_cards_count" AFTER INSERT OR DELETE OR UPDATE OF "is_active" ON "public"."pack_cards" FOR EACH ROW EXECUTE FUNCTION "public"."refresh_pack_card_count"();



CREATE OR REPLACE TRIGGER "trg_pack_purchase_count" AFTER INSERT OR UPDATE OF "status" ON "public"."pack_purchases" FOR EACH ROW EXECUTE FUNCTION "public"."refresh_pack_purchase_count"();



CREATE OR REPLACE TRIGGER "trg_pack_rating_refresh" AFTER INSERT OR DELETE OR UPDATE OF "rating" ON "public"."pack_ratings" FOR EACH ROW EXECUTE FUNCTION "public"."refresh_pack_rating"();



CREATE OR REPLACE TRIGGER "trg_pack_ratings_updated_at" BEFORE UPDATE ON "public"."pack_ratings" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_pack_reviews_updated_at" BEFORE UPDATE ON "public"."pack_reviews" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_packs_updated_at" BEFORE UPDATE ON "public"."packs" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_payment_methods_config_updated_at" BEFORE UPDATE ON "public"."payment_methods_config" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_payment_methods_updated_at" BEFORE UPDATE ON "public"."payment_methods" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_profiles_updated_at" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_reports_updated_at" BEFORE UPDATE ON "public"."reports" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_room_members_update_count" AFTER INSERT OR UPDATE OF "left_at" ON "public"."room_members" FOR EACH ROW EXECUTE FUNCTION "public"."refresh_room_player_count"();



CREATE OR REPLACE TRIGGER "trg_room_player_count" AFTER INSERT OR DELETE OR UPDATE ON "public"."room_members" FOR EACH ROW EXECUTE FUNCTION "public"."refresh_room_player_count"();



CREATE OR REPLACE TRIGGER "trg_room_settings_updated_at" BEFORE UPDATE ON "public"."room_settings" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_rooms_create_settings" AFTER INSERT ON "public"."rooms" FOR EACH ROW EXECUTE FUNCTION "public"."rooms_create_settings"();



CREATE OR REPLACE TRIGGER "trg_rooms_invite_code" BEFORE INSERT ON "public"."rooms" FOR EACH ROW EXECUTE FUNCTION "public"."rooms_set_invite_code"();



CREATE OR REPLACE TRIGGER "trg_rooms_updated_at" BEFORE UPDATE ON "public"."rooms" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_sync_premium" AFTER INSERT OR DELETE OR UPDATE ON "public"."subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."_trg_sync_premium"();



CREATE OR REPLACE TRIGGER "trg_sync_requires_approval" AFTER INSERT OR UPDATE OF "requires_approval" ON "public"."room_settings" FOR EACH ROW EXECUTE FUNCTION "public"."sync_requires_approval"();



CREATE OR REPLACE TRIGGER "trg_trim_game_states" AFTER INSERT ON "public"."game_states" FOR EACH ROW EXECUTE FUNCTION "public"."trim_game_states"();



CREATE OR REPLACE TRIGGER "trg_update_current_players" AFTER INSERT OR DELETE OR UPDATE OF "role", "left_at" ON "public"."room_members" FOR EACH ROW EXECUTE FUNCTION "public"."_trg_update_current_players"();



CREATE OR REPLACE TRIGGER "trg_wallets_updated_at" BEFORE UPDATE ON "public"."wallets" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_withdrawals_updated_at" BEFORE UPDATE ON "public"."withdrawals" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



ALTER TABLE ONLY "public"."blocked_users"
    ADD CONSTRAINT "blocked_users_blocked_id_fkey" FOREIGN KEY ("blocked_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."blocked_users"
    ADD CONSTRAINT "blocked_users_blocker_id_fkey" FOREIGN KEY ("blocker_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."commissions"
    ADD CONSTRAINT "commissions_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."commissions"
    ADD CONSTRAINT "commissions_purchase_id_fkey" FOREIGN KEY ("purchase_id") REFERENCES "public"."pack_purchases"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."creator_verifications"
    ADD CONSTRAINT "creator_verifications_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."creator_verifications"
    ADD CONSTRAINT "creator_verifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."deposits"
    ADD CONSTRAINT "deposits_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."deposits"
    ADD CONSTRAINT "deposits_payment_method_id_fkey" FOREIGN KEY ("payment_method_id") REFERENCES "public"."payment_methods_config"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."deposits"
    ADD CONSTRAINT "deposits_rejected_by_fkey" FOREIGN KEY ("rejected_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."deposits"
    ADD CONSTRAINT "deposits_tx_id_fkey" FOREIGN KEY ("tx_id") REFERENCES "public"."wallet_transactions"("id");



ALTER TABLE ONLY "public"."deposits"
    ADD CONSTRAINT "deposits_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."deposits"
    ADD CONSTRAINT "deposits_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "public"."wallets"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."downloaded_packs"
    ADD CONSTRAINT "downloaded_packs_pack_id_fkey" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."downloaded_packs"
    ADD CONSTRAINT "downloaded_packs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."financial_audit_log"
    ADD CONSTRAINT "financial_audit_log_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."game_sessions"
    ADD CONSTRAINT "fk_game_sessions_pack" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE SET NULL NOT VALID;



ALTER TABLE ONLY "public"."game_turns"
    ADD CONSTRAINT "fk_game_turns_card" FOREIGN KEY ("card_id") REFERENCES "public"."pack_cards"("id") ON DELETE SET NULL NOT VALID;



ALTER TABLE ONLY "public"."rooms"
    ADD CONSTRAINT "fk_rooms_pack" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE SET NULL NOT VALID;



ALTER TABLE ONLY "public"."follows"
    ADD CONSTRAINT "follows_followee_id_fkey" FOREIGN KEY ("followee_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."follows"
    ADD CONSTRAINT "follows_follower_id_fkey" FOREIGN KEY ("follower_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_addressee_id_fkey" FOREIGN KEY ("addressee_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_requester_id_fkey" FOREIGN KEY ("requester_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."game_rounds"
    ADD CONSTRAINT "game_rounds_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."game_sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."game_sessions"
    ADD CONSTRAINT "game_sessions_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."game_sessions"
    ADD CONSTRAINT "game_sessions_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."game_states"
    ADD CONSTRAINT "game_states_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."game_sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."game_turns"
    ADD CONSTRAINT "game_turns_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."game_turns"
    ADD CONSTRAINT "game_turns_round_id_fkey" FOREIGN KEY ("round_id") REFERENCES "public"."game_rounds"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."game_turns"
    ADD CONSTRAINT "game_turns_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."game_sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."game_votes"
    ADD CONSTRAINT "game_votes_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."game_sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."game_votes"
    ADD CONSTRAINT "game_votes_target_id_fkey" FOREIGN KEY ("target_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."game_votes"
    ADD CONSTRAINT "game_votes_turn_id_fkey" FOREIGN KEY ("turn_id") REFERENCES "public"."game_turns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."game_votes"
    ADD CONSTRAINT "game_votes_voter_id_fkey" FOREIGN KEY ("voter_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."gameplay_analytics"
    ADD CONSTRAINT "gameplay_analytics_pack_id_fkey" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."gameplay_analytics"
    ADD CONSTRAINT "gameplay_analytics_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."gameplay_analytics"
    ADD CONSTRAINT "gameplay_analytics_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."game_sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."moderation_actions"
    ADD CONSTRAINT "moderation_actions_moderator_id_fkey" FOREIGN KEY ("moderator_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."moderation_actions"
    ADD CONSTRAINT "moderation_actions_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "public"."reports"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."moderation_actions"
    ADD CONSTRAINT "moderation_actions_reversed_by_fkey" FOREIGN KEY ("reversed_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."moderation_actions"
    ADD CONSTRAINT "moderation_actions_target_pack_id_fkey" FOREIGN KEY ("target_pack_id") REFERENCES "public"."packs"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."moderation_actions"
    ADD CONSTRAINT "moderation_actions_target_user_id_fkey" FOREIGN KEY ("target_user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pack_analytics"
    ADD CONSTRAINT "pack_analytics_pack_id_fkey" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pack_cards"
    ADD CONSTRAINT "pack_cards_pack_id_fkey" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pack_purchases"
    ADD CONSTRAINT "pack_purchases_buyer_id_fkey" FOREIGN KEY ("buyer_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."pack_purchases"
    ADD CONSTRAINT "pack_purchases_pack_id_fkey" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."physical_pack_requests"
    ADD CONSTRAINT "physical_pack_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."physical_pack_requests"
    ADD CONSTRAINT "physical_pack_requests_pack_id_fkey" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."physical_pack_requests"
    ADD CONSTRAINT "physical_pack_requests_tx_id_fkey" FOREIGN KEY ("tx_id") REFERENCES "public"."wallet_transactions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."pack_submissions"
    ADD CONSTRAINT "pack_submissions_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pack_submissions"
    ADD CONSTRAINT "pack_submissions_pack_id_fkey" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pack_submissions"
    ADD CONSTRAINT "pack_submissions_fee_tx_id_fkey" FOREIGN KEY ("fee_tx_id") REFERENCES "public"."wallet_transactions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."pack_ratings"
    ADD CONSTRAINT "pack_ratings_pack_id_fkey" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pack_ratings"
    ADD CONSTRAINT "pack_ratings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pack_reactions"
    ADD CONSTRAINT "pack_reactions_pack_id_fkey" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pack_reports"
    ADD CONSTRAINT "pack_reports_pack_id_fkey" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pack_reports"
    ADD CONSTRAINT "pack_reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pack_reports"
    ADD CONSTRAINT "pack_reports_resolved_by_fkey" FOREIGN KEY ("resolved_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."pack_reviews"
    ADD CONSTRAINT "pack_reviews_pack_id_fkey" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pack_reviews"
    ADD CONSTRAINT "pack_reviews_rating_id_fkey" FOREIGN KEY ("rating_id") REFERENCES "public"."pack_ratings"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."pack_reviews"
    ADD CONSTRAINT "pack_reviews_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pack_tags"
    ADD CONSTRAINT "pack_tags_pack_id_fkey" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."packs"
    ADD CONSTRAINT "packs_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."pack_categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."packs"
    ADD CONSTRAINT "packs_pending_category_suggestion_id_fkey" FOREIGN KEY ("pending_category_suggestion_id") REFERENCES "public"."pack_category_suggestions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."pack_category_suggestions"
    ADD CONSTRAINT "pack_category_suggestions_suggested_by_fkey" FOREIGN KEY ("suggested_by") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pack_category_suggestions"
    ADD CONSTRAINT "pack_category_suggestions_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."packs"
    ADD CONSTRAINT "packs_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."packs"
    ADD CONSTRAINT "packs_language_fkey" FOREIGN KEY ("language") REFERENCES "public"."pack_languages"("code");



ALTER TABLE ONLY "public"."packs"
    ADD CONSTRAINT "packs_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."payment_methods"
    ADD CONSTRAINT "payment_methods_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_preferred_lang_fkey" FOREIGN KEY ("preferred_lang") REFERENCES "public"."pack_languages"("code");



ALTER TABLE ONLY "public"."promoted_packs"
    ADD CONSTRAINT "promoted_packs_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."promoted_packs"
    ADD CONSTRAINT "promoted_packs_pack_id_fkey" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "reports_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "reports_resolved_by_fkey" FOREIGN KEY ("resolved_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."room_bans"
    ADD CONSTRAINT "room_bans_banned_by_fkey" FOREIGN KEY ("banned_by") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."room_bans"
    ADD CONSTRAINT "room_bans_lifted_by_fkey" FOREIGN KEY ("lifted_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."room_bans"
    ADD CONSTRAINT "room_bans_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_bans"
    ADD CONSTRAINT "room_bans_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_chat_messages"
    ADD CONSTRAINT "room_chat_messages_deleted_by_fkey" FOREIGN KEY ("deleted_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."room_chat_messages"
    ADD CONSTRAINT "room_chat_messages_real_sender_id_fkey" FOREIGN KEY ("real_sender_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."room_chat_messages"
    ADD CONSTRAINT "room_chat_messages_reply_to_id_fkey" FOREIGN KEY ("reply_to_id") REFERENCES "public"."room_chat_messages"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."room_chat_messages"
    ADD CONSTRAINT "room_chat_messages_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_chat_messages"
    ADD CONSTRAINT "room_chat_messages_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."room_creation_quotas"
    ADD CONSTRAINT "room_creation_quotas_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_invites"
    ADD CONSTRAINT "room_invites_invited_by_fkey" FOREIGN KEY ("invited_by") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_invites"
    ADD CONSTRAINT "room_invites_invited_user_fkey" FOREIGN KEY ("invited_user") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_invites"
    ADD CONSTRAINT "room_invites_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_join_requests"
    ADD CONSTRAINT "room_join_requests_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_join_requests"
    ADD CONSTRAINT "room_join_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."game_rejoin_requests"
    ADD CONSTRAINT "game_rejoin_requests_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."game_rejoin_requests"
    ADD CONSTRAINT "game_rejoin_requests_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."game_sessions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."game_rejoin_requests"
    ADD CONSTRAINT "game_rejoin_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_logs"
    ADD CONSTRAINT "room_logs_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."room_logs"
    ADD CONSTRAINT "room_logs_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_logs"
    ADD CONSTRAINT "room_logs_target_id_fkey" FOREIGN KEY ("target_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."room_members"
    ADD CONSTRAINT "room_members_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_members"
    ADD CONSTRAINT "room_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_moderators"
    ADD CONSTRAINT "room_moderators_granted_by_fkey" FOREIGN KEY ("granted_by") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."room_moderators"
    ADD CONSTRAINT "room_moderators_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_moderators"
    ADD CONSTRAINT "room_moderators_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_played_packs"
    ADD CONSTRAINT "room_played_packs_pack_id_fkey" FOREIGN KEY ("pack_id") REFERENCES "public"."packs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_played_packs"
    ADD CONSTRAINT "room_played_packs_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_return_timers"
    ADD CONSTRAINT "room_return_timers_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_return_timers"
    ADD CONSTRAINT "room_return_timers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_settings"
    ADD CONSTRAINT "room_settings_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."rooms"
    ADD CONSTRAINT "rooms_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."session_custom_cards"
    ADD CONSTRAINT "session_custom_cards_added_by_fkey" FOREIGN KEY ("added_by") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."session_custom_cards"
    ADD CONSTRAINT "session_custom_cards_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."session_custom_cards"
    ADD CONSTRAINT "session_custom_cards_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."game_sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tod_proof_views"
    ADD CONSTRAINT "tod_proof_views_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."game_sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tod_proof_views"
    ADD CONSTRAINT "tod_proof_views_viewer_id_fkey" FOREIGN KEY ("viewer_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."spectator_requests"
    ADD CONSTRAINT "spectator_requests_decided_by_fkey" FOREIGN KEY ("decided_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."spectator_requests"
    ADD CONSTRAINT "spectator_requests_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."spectator_requests"
    ADD CONSTRAINT "spectator_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wallet_transactions"
    ADD CONSTRAINT "wallet_transactions_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "public"."wallets"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."wallets"
    ADD CONSTRAINT "wallets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."withdrawals"
    ADD CONSTRAINT "withdrawals_hold_tx_id_fkey" FOREIGN KEY ("hold_tx_id") REFERENCES "public"."wallet_transactions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."withdrawals"
    ADD CONSTRAINT "withdrawals_payment_method_id_fkey" FOREIGN KEY ("payment_method_id") REFERENCES "public"."payment_methods_config"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."withdrawals"
    ADD CONSTRAINT "withdrawals_processed_by_fkey" FOREIGN KEY ("processed_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."withdrawals"
    ADD CONSTRAINT "withdrawals_rejected_by_fkey" FOREIGN KEY ("rejected_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."withdrawals"
    ADD CONSTRAINT "withdrawals_tx_id_fkey" FOREIGN KEY ("tx_id") REFERENCES "public"."wallet_transactions"("id");



ALTER TABLE ONLY "public"."withdrawals"
    ADD CONSTRAINT "withdrawals_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."withdrawals"
    ADD CONSTRAINT "withdrawals_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "public"."wallets"("id") ON DELETE RESTRICT;



ALTER TABLE "public"."app_settings" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "app_settings: no client write" ON "public"."app_settings" FOR INSERT WITH CHECK (false);



CREATE POLICY "app_settings: no client update" ON "public"."app_settings" FOR UPDATE USING (false);



CREATE POLICY "app_settings: public read" ON "public"."app_settings" FOR SELECT USING (true);



ALTER TABLE "public"."blocked_users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "blocked_users: own delete" ON "public"."blocked_users" FOR DELETE USING (("auth"."uid"() = "blocker_id"));



CREATE POLICY "blocked_users: own insert" ON "public"."blocked_users" FOR INSERT WITH CHECK (("auth"."uid"() = "blocker_id"));



CREATE POLICY "blocked_users: own read" ON "public"."blocked_users" FOR SELECT USING ((("auth"."uid"() = "blocker_id") OR ("auth"."uid"() = "blocked_id")));



ALTER TABLE "public"."commissions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "commissions: creator read" ON "public"."commissions" FOR SELECT USING (("auth"."uid"() = "creator_id"));



CREATE POLICY "commissions: no client write" ON "public"."commissions" FOR INSERT WITH CHECK (false);



ALTER TABLE "public"."creator_verifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "creator_verifications: no client update" ON "public"."creator_verifications" FOR UPDATE USING (false);



CREATE POLICY "creator_verifications: own insert" ON "public"."creator_verifications" FOR INSERT WITH CHECK ((("auth"."uid"() = "user_id") AND (NOT (EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."verification_status" = 'verified'::"public"."verification_status_enum")))))));



CREATE POLICY "creator_verifications: own read" ON "public"."creator_verifications" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."pack_category_suggestions" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "pack_category_suggestions: no client update" ON "public"."pack_category_suggestions" FOR UPDATE USING (false);



CREATE POLICY "pack_category_suggestions: own insert" ON "public"."pack_category_suggestions" FOR INSERT WITH CHECK (("auth"."uid"() = "suggested_by"));



CREATE POLICY "pack_category_suggestions: own read" ON "public"."pack_category_suggestions" FOR SELECT USING (("auth"."uid"() = "suggested_by"));



ALTER TABLE "public"."deposits" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "deposits: no client update" ON "public"."deposits" FOR UPDATE USING (false);



CREATE POLICY "deposits: own insert" ON "public"."deposits" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "deposits: own read" ON "public"."deposits" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."downloaded_packs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "downloaded_packs: own access" ON "public"."downloaded_packs" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."financial_audit_log" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "financial_audit_log: no client access" ON "public"."financial_audit_log" USING (false);



ALTER TABLE "public"."follows" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "follows: own delete" ON "public"."follows" FOR DELETE USING (("auth"."uid"() = "follower_id"));



CREATE POLICY "follows: own insert" ON "public"."follows" FOR INSERT WITH CHECK (("auth"."uid"() = "follower_id"));



CREATE POLICY "follows: public read" ON "public"."follows" FOR SELECT USING (true);



ALTER TABLE "public"."friendships" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "friendships: addressee update" ON "public"."friendships" FOR UPDATE USING ((("auth"."uid"() = "addressee_id") OR ("auth"."uid"() = "requester_id")));



CREATE POLICY "friendships: participant delete" ON "public"."friendships" FOR DELETE USING ((("auth"."uid"() = "requester_id") OR ("auth"."uid"() = "addressee_id")));



CREATE POLICY "friendships: participant read" ON "public"."friendships" FOR SELECT USING ((("auth"."uid"() = "requester_id") OR ("auth"."uid"() = "addressee_id")));



CREATE POLICY "friendships: requester insert" ON "public"."friendships" FOR INSERT WITH CHECK ((("auth"."uid"() = "requester_id") AND (NOT (EXISTS ( SELECT 1
   FROM "public"."blocked_users"
  WHERE (("blocked_users"."blocker_id" = "friendships"."addressee_id") AND ("blocked_users"."blocked_id" = "auth"."uid"())))))));



ALTER TABLE "public"."game_rejoin_requests" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "game_rejoin_requests: own or room member" ON "public"."game_rejoin_requests" FOR SELECT USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."room_members" "rm"
  WHERE (("rm"."room_id" = "game_rejoin_requests"."room_id") AND ("rm"."user_id" = "auth"."uid"()) AND ("rm"."left_at" IS NULL))))));



CREATE POLICY "game_rejoin_requests: self insert" ON "public"."game_rejoin_requests" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."game_rounds" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "game_rounds: session player read" ON "public"."game_rounds" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."game_sessions" "gs"
  WHERE (("gs"."id" = "game_rounds"."session_id") AND ("auth"."uid"() = ANY ("gs"."player_ids"))))));



ALTER TABLE "public"."game_sessions" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "game_sessions: no client write" ON "public"."game_sessions" FOR INSERT WITH CHECK (false);



CREATE POLICY "game_sessions: owner update" ON "public"."game_sessions" FOR UPDATE USING (("auth"."uid"() = "owner_id"));



CREATE POLICY "game_sessions: room member read" ON "public"."game_sessions" FOR SELECT USING (("auth"."uid"() = ANY ("player_ids")));



ALTER TABLE "public"."game_states" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "game_states: no client write" ON "public"."game_states" FOR INSERT WITH CHECK (false);



CREATE POLICY "game_states: session player read" ON "public"."game_states" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."game_sessions" "gs"
  WHERE (("gs"."id" = "game_states"."session_id") AND ("auth"."uid"() = ANY ("gs"."player_ids"))))));



ALTER TABLE "public"."game_turns" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "game_turns: session player read" ON "public"."game_turns" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."game_sessions" "gs"
  WHERE (("gs"."id" = "game_turns"."session_id") AND ("auth"."uid"() = ANY ("gs"."player_ids"))))));



ALTER TABLE "public"."game_votes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "game_votes: own insert" ON "public"."game_votes" FOR INSERT WITH CHECK (("auth"."uid"() = "voter_id"));



CREATE POLICY "game_votes: session player read" ON "public"."game_votes" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."game_sessions" "gs"
  WHERE (("gs"."id" = "game_votes"."session_id") AND ("auth"."uid"() = ANY ("gs"."player_ids"))))));



ALTER TABLE "public"."gameplay_analytics" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "gameplay_analytics: no client access" ON "public"."gameplay_analytics" USING (false);



CREATE POLICY "join_requests_insert_own" ON "public"."room_join_requests" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "join_requests_select" ON "public"."room_join_requests" FOR SELECT USING ((("auth"."uid"() = "user_id") OR (EXISTS ( SELECT 1
   FROM "public"."rooms" "r"
  WHERE (("r"."id" = "room_join_requests"."room_id") AND ("r"."owner_id" = "auth"."uid"())))) OR (EXISTS ( SELECT 1
   FROM "public"."room_members" "rm"
  WHERE (("rm"."room_id" = "room_join_requests"."room_id") AND ("rm"."user_id" = "auth"."uid"()) AND ("rm"."role" = 'moderator'::"public"."room_member_role_enum") AND ("rm"."left_at" IS NULL))))));



CREATE POLICY "join_requests_update_moderator" ON "public"."room_join_requests" FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM "public"."rooms" "r"
  WHERE (("r"."id" = "room_join_requests"."room_id") AND ("r"."owner_id" = "auth"."uid"())))) OR (EXISTS ( SELECT 1
   FROM "public"."room_members" "rm"
  WHERE (("rm"."room_id" = "room_join_requests"."room_id") AND ("rm"."user_id" = "auth"."uid"()) AND ("rm"."role" = 'moderator'::"public"."room_member_role_enum") AND ("rm"."left_at" IS NULL))))));



ALTER TABLE "public"."moderation_actions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "moderation_actions: no client access" ON "public"."moderation_actions" USING (false);



ALTER TABLE "public"."notification_preferences" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notification_preferences: own access" ON "public"."notification_preferences" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notifications: no client insert" ON "public"."notifications" FOR INSERT WITH CHECK (false);



CREATE POLICY "notifications: own read" ON "public"."notifications" FOR SELECT USING ((("auth"."uid"() = "user_id") AND ("deleted_at" IS NULL)));



CREATE POLICY "notifications: own update" ON "public"."notifications" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "otp_audit: no client access" ON "public"."otp_audit_log" USING (false);



ALTER TABLE "public"."otp_audit_log" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "otp_audit_log: no client access" ON "public"."otp_audit_log" USING (false);



ALTER TABLE "public"."pack_analytics" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "pack_analytics: no client access" ON "public"."pack_analytics" USING (false);



ALTER TABLE "public"."pack_cards" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "pack_cards: creator write" ON "public"."pack_cards" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."packs" "p"
  WHERE (("p"."id" = "pack_cards"."pack_id") AND ("p"."creator_id" = "auth"."uid"()) AND ("p"."status" = ANY (ARRAY['draft'::"public"."pack_status_enum", 'rejected'::"public"."pack_status_enum"]))))));



CREATE POLICY "pack_cards: read" ON "public"."pack_cards" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."packs" "p"
  WHERE (("p"."id" = "pack_cards"."pack_id") AND (("p"."status" = 'approved'::"public"."pack_status_enum") OR ("p"."creator_id" = "auth"."uid"()))))));



ALTER TABLE "public"."pack_categories" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "pack_categories: public read" ON "public"."pack_categories" FOR SELECT USING (true);



ALTER TABLE "public"."pack_languages" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "pack_languages: no client write" ON "public"."pack_languages" FOR INSERT WITH CHECK (false);



CREATE POLICY "pack_languages: public read" ON "public"."pack_languages" FOR SELECT USING (("is_active" = true));



ALTER TABLE "public"."pack_purchases" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "pack_purchases: buyer read" ON "public"."pack_purchases" FOR SELECT USING ((("auth"."uid"() = "buyer_id") OR (EXISTS ( SELECT 1
   FROM "public"."packs"
  WHERE (("packs"."id" = "pack_purchases"."pack_id") AND ("packs"."creator_id" = "auth"."uid"()))))));



CREATE POLICY "pack_purchases: no client insert" ON "public"."pack_purchases" FOR INSERT WITH CHECK (false);



ALTER TABLE "public"."pack_ratings" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "pack_ratings: buyer write" ON "public"."pack_ratings" FOR INSERT WITH CHECK ((("auth"."uid"() = "user_id") AND (EXISTS ( SELECT 1
   FROM "public"."pack_purchases"
  WHERE (("pack_purchases"."pack_id" = "pack_ratings"."pack_id") AND ("pack_purchases"."buyer_id" = "auth"."uid"()) AND ("pack_purchases"."status" = 'completed'::"public"."purchase_status_enum") AND ("pack_purchases"."expires_at" > "now"()))))));



CREATE POLICY "pack_ratings: own update" ON "public"."pack_ratings" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "pack_ratings: public read" ON "public"."pack_ratings" FOR SELECT USING (true);



ALTER TABLE "public"."pack_reactions" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "pack_reactions: read" ON "public"."pack_reactions" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."packs" "p"
  WHERE (("p"."id" = "pack_reactions"."pack_id") AND ("p"."deleted_at" IS NULL) AND (("p"."status" = 'approved'::"public"."pack_status_enum") OR ("p"."creator_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
           FROM "public"."pack_purchases" "pp"
          WHERE (("pp"."pack_id" = "p"."id") AND ("pp"."buyer_id" = "auth"."uid"()) AND ("pp"."status" = 'completed'::"public"."purchase_status_enum")))))))));



ALTER TABLE "public"."pack_reports" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "pack_reports: authenticated insert" ON "public"."pack_reports" FOR INSERT WITH CHECK (("auth"."uid"() = "reporter_id"));



CREATE POLICY "pack_reports: own read" ON "public"."pack_reports" FOR SELECT USING (("auth"."uid"() = "reporter_id"));



ALTER TABLE "public"."pack_reviews" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "pack_reviews: buyer insert" ON "public"."pack_reviews" FOR INSERT WITH CHECK ((("auth"."uid"() = "user_id") AND (EXISTS ( SELECT 1
   FROM "public"."pack_purchases"
  WHERE (("pack_purchases"."pack_id" = "pack_reviews"."pack_id") AND ("pack_purchases"."buyer_id" = "auth"."uid"()) AND ("pack_purchases"."status" = 'completed'::"public"."purchase_status_enum"))))));



CREATE POLICY "pack_reviews: own update" ON "public"."pack_reviews" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "pack_reviews: public read" ON "public"."pack_reviews" FOR SELECT USING (("is_visible" = true));



ALTER TABLE "public"."pack_tags" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "pack_tags: creator delete" ON "public"."pack_tags" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."packs"
  WHERE (("packs"."id" = "pack_tags"."pack_id") AND ("packs"."creator_id" = "auth"."uid"())))));



CREATE POLICY "pack_tags: creator write" ON "public"."pack_tags" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."packs"
  WHERE (("packs"."id" = "pack_tags"."pack_id") AND ("packs"."creator_id" = "auth"."uid"())))));



CREATE POLICY "pack_tags: public read" ON "public"."pack_tags" FOR SELECT USING (true);



ALTER TABLE "public"."packs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "packs: creator insert" ON "public"."packs" FOR INSERT WITH CHECK (("auth"."uid"() = "creator_id"));



CREATE POLICY "packs: creator update" ON "public"."packs" FOR UPDATE USING (("auth"."uid"() = "creator_id")) WITH CHECK ((("status" <> 'approved'::"public"."pack_status_enum") OR ("status" = ( SELECT "packs_1"."status"
   FROM "public"."packs" "packs_1"
  WHERE ("packs_1"."id" = "packs_1"."id")))));



CREATE POLICY "packs: no client delete" ON "public"."packs" FOR DELETE USING (false);



CREATE POLICY "packs: public read approved" ON "public"."packs" FOR SELECT USING (((("status" = 'approved'::"public"."pack_status_enum") AND ("deleted_at" IS NULL)) OR ("creator_id" = "auth"."uid"())));



ALTER TABLE "public"."payment_methods" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "payment_methods: own access" ON "public"."payment_methods" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."payment_methods_config" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "payment_methods_config: no client write" ON "public"."payment_methods_config" FOR INSERT WITH CHECK (false);



CREATE POLICY "payment_methods_config: public read" ON "public"."payment_methods_config" FOR SELECT USING (("is_active" = true));



ALTER TABLE "public"."physical_pack_requests" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "physical_pack_requests: no client insert" ON "public"."physical_pack_requests" FOR INSERT WITH CHECK (false);



CREATE POLICY "physical_pack_requests: no client update" ON "public"."physical_pack_requests" FOR UPDATE USING (false);



CREATE POLICY "physical_pack_requests: own read" ON "public"."physical_pack_requests" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."pack_submissions" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "pack_submissions: no client insert" ON "public"."pack_submissions" FOR INSERT WITH CHECK (false);



CREATE POLICY "pack_submissions: no client update" ON "public"."pack_submissions" FOR UPDATE USING (false);



CREATE POLICY "pack_submissions: own read" ON "public"."pack_submissions" FOR SELECT USING (("auth"."uid"() = "creator_id"));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles: no client delete" ON "public"."profiles" FOR DELETE USING (false);



CREATE POLICY "profiles: no client insert" ON "public"."profiles" FOR INSERT WITH CHECK (false);



CREATE POLICY "profiles: own full read" ON "public"."profiles" FOR SELECT USING (("auth"."uid"() = "id"));



CREATE POLICY "profiles: own safe update" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id")) WITH CHECK ((("auth"."uid"() = "id") AND ("is_banned" = ( SELECT "profiles_1"."is_banned"
   FROM "public"."profiles" "profiles_1"
  WHERE ("profiles_1"."id" = "auth"."uid"()))) AND ("verification_status" = ( SELECT "profiles_1"."verification_status"
   FROM "public"."profiles" "profiles_1"
  WHERE ("profiles_1"."id" = "auth"."uid"()))) AND ("email" = ( SELECT "profiles_1"."email"
   FROM "public"."profiles" "profiles_1"
  WHERE ("profiles_1"."id" = "auth"."uid"()))) AND ("theme_background_color" IS NOT DISTINCT FROM ( SELECT "profiles_1"."theme_background_color"
   FROM "public"."profiles" "profiles_1"
  WHERE ("profiles_1"."id" = "auth"."uid"())))));



CREATE POLICY "profiles: public read for auth users" ON "public"."profiles" FOR SELECT USING ((("auth"."role"() = 'authenticated'::"text") AND ("deleted_at" IS NULL) AND ("is_banned" = false)));



CREATE POLICY "profiles: public read for authenticated" ON "public"."profiles" FOR SELECT USING ((("auth"."role"() = 'authenticated'::"text") AND ("deleted_at" IS NULL) AND ("is_banned" = false)));



CREATE POLICY "profiles: service role insert only" ON "public"."profiles" FOR INSERT WITH CHECK (false);



ALTER TABLE "public"."promoted_packs" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "promoted_packs: public read" ON "public"."promoted_packs" FOR SELECT USING ((("starts_at" <= "now"()) AND ("ends_at" >= "now"())));



ALTER TABLE "public"."reports" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "reports: authenticated insert" ON "public"."reports" FOR INSERT WITH CHECK (("auth"."uid"() = "reporter_id"));



CREATE POLICY "reports: own read" ON "public"."reports" FOR SELECT USING (("auth"."uid"() = "reporter_id"));



ALTER TABLE "public"."room_bans" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "room_bans: moderator or own read" ON "public"."room_bans" FOR SELECT USING (("public"."is_room_moderator"("room_id", "auth"."uid"()) OR ("user_id" = "auth"."uid"())));



CREATE POLICY "room_bans: no client insert" ON "public"."room_bans" FOR INSERT WITH CHECK (false);



CREATE POLICY "room_bans: owner can insert" ON "public"."room_bans" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."rooms"
  WHERE (("rooms"."id" = "room_bans"."room_id") AND ("rooms"."owner_id" = "auth"."uid"())))));



CREATE POLICY "room_bans: no client update" ON "public"."room_bans" FOR UPDATE USING (false);



CREATE POLICY "room_bans: owner can update" ON "public"."room_bans" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."rooms"
  WHERE (("rooms"."id" = "room_bans"."room_id") AND ("rooms"."owner_id" = "auth"."uid"())))));



ALTER TABLE "public"."room_chat_messages" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "room_chat: member insert" ON "public"."room_chat_messages" FOR INSERT WITH CHECK ((("auth"."uid"() = "user_id") AND "public"."is_room_member"("room_id", "auth"."uid"()) AND (NOT (EXISTS ( SELECT 1
   FROM "public"."room_members" "rm"
  WHERE (("rm"."room_id" = "room_chat_messages"."room_id") AND ("rm"."user_id" = "auth"."uid"()) AND ("rm"."is_muted" = true) AND ("rm"."left_at" IS NULL)))))));



CREATE POLICY "room_chat: member read" ON "public"."room_chat_messages" FOR SELECT USING (("public"."is_room_member"("room_id", "auth"."uid"()) AND ("is_deleted" = false)));



CREATE POLICY "room_chat: moderator soft delete" ON "public"."room_chat_messages" FOR UPDATE USING ("public"."is_room_moderator"("room_id", "auth"."uid"()));



ALTER TABLE "public"."room_creation_quotas" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "room_creation_quotas: own row" ON "public"."room_creation_quotas" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."room_invites" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "room_invites: member insert" ON "public"."room_invites" FOR INSERT WITH CHECK ((("auth"."uid"() = "invited_by") AND "public"."is_room_member"("room_id", "auth"."uid"())));



CREATE POLICY "room_invites: own or invited" ON "public"."room_invites" USING ((("invited_by" = "auth"."uid"()) OR ("invited_user" = "auth"."uid"())));



CREATE POLICY "room_invites: participant read" ON "public"."room_invites" FOR SELECT USING ((("auth"."uid"() = "invited_by") OR ("auth"."uid"() = "invited_user")));



CREATE POLICY "room_invites: recipient update" ON "public"."room_invites" FOR UPDATE USING (("auth"."uid"() = "invited_user"));



ALTER TABLE "public"."room_join_requests" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "room_join_requests: own or room member" ON "public"."room_join_requests" USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."room_members" "rm"
  WHERE (("rm"."room_id" = "room_join_requests"."room_id") AND ("rm"."user_id" = "auth"."uid"()) AND ("rm"."left_at" IS NULL)))))) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."room_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "room_logs: moderator read" ON "public"."room_logs" FOR SELECT USING ("public"."is_room_moderator"("room_id", "auth"."uid"()));



CREATE POLICY "room_logs: no client write" ON "public"."room_logs" FOR INSERT WITH CHECK (false);



ALTER TABLE "public"."room_members" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "room_members: no delete" ON "public"."room_members" FOR DELETE USING (false);



CREATE POLICY "room_members: read" ON "public"."room_members" FOR SELECT USING ((("user_id" = "auth"."uid"()) OR ("is_hidden_spectator" = false) OR "public"."can_view_hidden_room_member"("room_id", "auth"."uid"())));



CREATE POLICY "room_members: same room read" ON "public"."room_members" FOR SELECT USING ("public"."is_room_member"("room_id", "auth"."uid"()));



-- Brand-new (no prior row) self-inserts into an in_game room are blocked
-- unless the caller is the room owner — closing the client-side bypass for
-- section 4's join-request gate (RoomProvider.initialize). This is safe:
-- every legitimate admission path for an in_game room now runs inside a
-- SECURITY DEFINER function (decide_join_request, decide_spectator_request,
-- decide_game_rejoin_request), which bypasses RLS entirely, so nothing
-- currently-working depends on this policy allowing that case.
CREATE POLICY "room_members: self insert" ON "public"."room_members" FOR INSERT WITH CHECK ((("auth"."uid"() = "user_id") AND (NOT (EXISTS ( SELECT 1
   FROM "public"."room_bans"
  WHERE (("room_bans"."room_id" = "room_members"."room_id") AND ("room_bans"."user_id" = "auth"."uid"()) AND ("room_bans"."lifted_at" IS NULL) AND (("room_bans"."banned_until" IS NULL) OR ("room_bans"."banned_until" > "now"())))))) AND (EXISTS ( SELECT 1
   FROM "public"."rooms"
  WHERE (("rooms"."id" = "room_members"."room_id") AND ("rooms"."deleted_at" IS NULL) AND ("rooms"."status" <> 'closed'::"public"."room_status_enum") AND (("rooms"."status" <> 'in_game'::"public"."room_status_enum") OR ("rooms"."owner_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
           FROM "public"."room_members" "rm2"
          WHERE (("rm2"."room_id" = "rooms"."id") AND ("rm2"."user_id" = "auth"."uid"()))))))))));



CREATE POLICY "room_members: self or moderator update" ON "public"."room_members" FOR UPDATE USING ((("auth"."uid"() = "user_id") OR "public"."is_room_moderator"("room_id", "auth"."uid"())));



CREATE POLICY "room_messages: read for members" ON "public"."room_chat_messages" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."room_members" "rm"
  WHERE (("rm"."room_id" = "room_chat_messages"."room_id") AND ("rm"."user_id" = "auth"."uid"()) AND ("rm"."left_at" IS NULL)))));



ALTER TABLE "public"."room_moderators" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "room_moderators: member read" ON "public"."room_moderators" FOR SELECT USING ("public"."is_room_member"("room_id", "auth"."uid"()));



CREATE POLICY "room_moderators: members can read" ON "public"."room_moderators" FOR SELECT USING (((EXISTS ( SELECT 1
   FROM "public"."room_members" "rm"
  WHERE (("rm"."room_id" = "room_moderators"."room_id") AND ("rm"."user_id" = "auth"."uid"()) AND ("rm"."left_at" IS NULL)))) OR (EXISTS ( SELECT 1
   FROM "public"."rooms" "r"
  WHERE (("r"."id" = "room_moderators"."room_id") AND ("r"."owner_id" = "auth"."uid"()))))));



CREATE POLICY "room_moderators: no client delete" ON "public"."room_moderators" FOR DELETE USING (false);



CREATE POLICY "room_moderators: no client write" ON "public"."room_moderators" FOR INSERT WITH CHECK (false);



CREATE POLICY "room_moderators: owner can delete" ON "public"."room_moderators" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."rooms" "r"
  WHERE (("r"."id" = "room_moderators"."room_id") AND ("r"."owner_id" = "auth"."uid"())))));



CREATE POLICY "room_moderators: owner can insert" ON "public"."room_moderators" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."rooms" "r"
  WHERE (("r"."id" = "room_moderators"."room_id") AND ("r"."owner_id" = "auth"."uid"())))));



CREATE POLICY "room_moderators: owner can update" ON "public"."room_moderators" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."rooms" "r"
  WHERE (("r"."id" = "room_moderators"."room_id") AND ("r"."owner_id" = "auth"."uid"())))));



ALTER TABLE "public"."room_played_packs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "room_played_packs: member insert" ON "public"."room_played_packs" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."room_members" "rm"
  WHERE (("rm"."room_id" = "room_played_packs"."room_id") AND ("rm"."user_id" = "auth"."uid"()) AND ("rm"."left_at" IS NULL)))));



CREATE POLICY "room_played_packs: members read" ON "public"."room_played_packs" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."room_members" "rm"
  WHERE (("rm"."room_id" = "room_played_packs"."room_id") AND ("rm"."user_id" = "auth"."uid"())))));



ALTER TABLE "public"."room_return_timers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "room_return_timers: members can read" ON "public"."room_return_timers" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."room_members" "rm"
  WHERE (("rm"."room_id" = "room_return_timers"."room_id") AND ("rm"."user_id" = "auth"."uid"()) AND ("rm"."left_at" IS NULL)))));



CREATE POLICY "room_return_timers: own row" ON "public"."room_return_timers" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "room_return_timers: room members can read" ON "public"."room_return_timers" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."room_members" "rm"
  WHERE (("rm"."room_id" = "room_return_timers"."room_id") AND ("rm"."user_id" = "auth"."uid"()) AND ("rm"."left_at" IS NULL)))));



ALTER TABLE "public"."room_settings" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "room_settings: member read" ON "public"."room_settings" FOR SELECT USING ("public"."is_room_member"("room_id", "auth"."uid"()));



CREATE POLICY "room_settings: moderator update" ON "public"."room_settings" FOR UPDATE USING ("public"."is_room_moderator"("room_id", "auth"."uid"()));



CREATE POLICY "room_settings: no client insert" ON "public"."room_settings" FOR INSERT WITH CHECK (false);



ALTER TABLE "public"."rooms" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "rooms: insert" ON "public"."rooms" FOR INSERT WITH CHECK ((("auth"."role"() = 'authenticated'::"text") AND ("auth"."uid"() = "owner_id")));



CREATE POLICY "rooms: no client delete" ON "public"."rooms" FOR DELETE USING (false);



CREATE POLICY "rooms: owner update" ON "public"."rooms" FOR UPDATE USING (("auth"."uid"() = "owner_id"));



CREATE POLICY "rooms: read" ON "public"."rooms" FOR SELECT USING ((("auth"."role"() = 'authenticated'::"text") AND ("deleted_at" IS NULL) AND (("visibility" = 'public'::"public"."room_visibility_enum") OR "public"."is_room_member"("id", "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."room_invites"
  WHERE (("room_invites"."room_id" = "rooms"."id") AND ("room_invites"."invited_user" = "auth"."uid"()) AND ("room_invites"."accepted_at" IS NULL) AND ("room_invites"."declined_at" IS NULL) AND ("room_invites"."expires_at" > "now"())))))));



ALTER TABLE "public"."session_custom_cards" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "session_custom_cards: room members" ON "public"."session_custom_cards" USING ((EXISTS ( SELECT 1
   FROM "public"."room_members" "rm"
  WHERE (("rm"."room_id" = "session_custom_cards"."room_id") AND ("rm"."user_id" = "auth"."uid"()) AND ("rm"."left_at" IS NULL))))) WITH CHECK ((("added_by" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."room_members" "rm"
  WHERE (("rm"."room_id" = "session_custom_cards"."room_id") AND ("rm"."user_id" = "auth"."uid"()) AND ("rm"."left_at" IS NULL))))));



ALTER TABLE "public"."sms_delivery_log" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "sms_delivery_log: no client access" ON "public"."sms_delivery_log" USING (false);



ALTER TABLE "public"."tod_proof_views" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "tod_proof_views: no client insert" ON "public"."tod_proof_views" FOR INSERT WITH CHECK (false);



CREATE POLICY "tod_proof_views: no client update" ON "public"."tod_proof_views" FOR UPDATE USING (false);



CREATE POLICY "tod_proof_views: own read" ON "public"."tod_proof_views" FOR SELECT USING (("auth"."uid"() = "viewer_id"));



ALTER TABLE "public"."spectator_requests" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "spectator_requests: member decide" ON "public"."spectator_requests" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."room_members" "rm"
  WHERE (("rm"."room_id" = "spectator_requests"."room_id") AND ("rm"."user_id" = "auth"."uid"()) AND ("rm"."left_at" IS NULL) AND ("rm"."role" = ANY (ARRAY['player'::"public"."room_member_role_enum", 'moderator'::"public"."room_member_role_enum"]))))));



CREATE POLICY "spectator_requests: own or room member" ON "public"."spectator_requests" FOR SELECT USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."room_members" "rm"
  WHERE (("rm"."room_id" = "spectator_requests"."room_id") AND ("rm"."user_id" = "auth"."uid"()) AND ("rm"."left_at" IS NULL))))));



CREATE POLICY "spectator_requests: self insert" ON "public"."spectator_requests" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "subscriptions: owner read" ON "public"."subscriptions" FOR SELECT USING (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."wallet_transactions" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "wallet_transactions: no client write" ON "public"."wallet_transactions" FOR INSERT WITH CHECK (false);



CREATE POLICY "wallet_transactions: own read" ON "public"."wallet_transactions" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."wallets"
  WHERE (("wallets"."id" = "wallet_transactions"."wallet_id") AND ("wallets"."user_id" = "auth"."uid"())))));



ALTER TABLE "public"."wallets" ENABLE ROW LEVEL SECURITY;



CREATE POLICY "wallets: no client update" ON "public"."wallets" FOR UPDATE USING (false);



CREATE POLICY "wallets: no client write" ON "public"."wallets" FOR INSERT WITH CHECK (false);



CREATE POLICY "wallets: own read" ON "public"."wallets" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."withdrawals" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "withdrawals: no client update" ON "public"."withdrawals" FOR UPDATE USING (false);



CREATE POLICY "withdrawals: own insert" ON "public"."withdrawals" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "withdrawals: own read" ON "public"."withdrawals" FOR SELECT USING (("auth"."uid"() = "user_id"));



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."_trg_sync_premium"() TO "anon";
GRANT ALL ON FUNCTION "public"."_trg_sync_premium"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."_trg_sync_premium"() TO "service_role";



GRANT ALL ON FUNCTION "public"."_trg_update_current_players"() TO "anon";
GRANT ALL ON FUNCTION "public"."_trg_update_current_players"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."_trg_update_current_players"() TO "service_role";



GRANT ALL ON FUNCTION "public"."add_updated_at_trigger"("schema_name" "text", "table_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."add_updated_at_trigger"("schema_name" "text", "table_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_updated_at_trigger"("schema_name" "text", "table_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_grant_premium"("p_user_id" "uuid", "p_days" integer, "p_tier" "text", "p_source" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_grant_premium"("p_user_id" "uuid", "p_days" integer, "p_tier" "text", "p_source" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_grant_premium"("p_user_id" "uuid", "p_days" integer, "p_tier" "text", "p_source" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."apply_moderation_to_profile"() TO "anon";
GRANT ALL ON FUNCTION "public"."apply_moderation_to_profile"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."apply_moderation_to_profile"() TO "service_role";



GRANT ALL ON FUNCTION "public"."apply_verification_decision"() TO "anon";
GRANT ALL ON FUNCTION "public"."apply_verification_decision"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."apply_verification_decision"() TO "service_role";



GRANT ALL ON FUNCTION "public"."apply_category_suggestion_decision"() TO "anon";
GRANT ALL ON FUNCTION "public"."apply_category_suggestion_decision"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."apply_category_suggestion_decision"() TO "service_role";



GRANT ALL ON TABLE "public"."wallet_transactions" TO "anon";
GRANT ALL ON TABLE "public"."wallet_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."wallet_transactions" TO "service_role";



GRANT ALL ON FUNCTION "public"."apply_wallet_transaction"("p_wallet_id" "uuid", "p_type" "public"."transaction_type_enum", "p_amount_mru" integer, "p_reference_id" "uuid", "p_description" "text", "p_idempotency_key" "text", "p_balance_type" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."apply_wallet_transaction"("p_wallet_id" "uuid", "p_type" "public"."transaction_type_enum", "p_amount_mru" integer, "p_reference_id" "uuid", "p_description" "text", "p_idempotency_key" "text", "p_balance_type" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."apply_wallet_transaction"("p_wallet_id" "uuid", "p_type" "public"."transaction_type_enum", "p_amount_mru" integer, "p_reference_id" "uuid", "p_description" "text", "p_idempotency_key" "text", "p_balance_type" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."transfer_earnings_to_wallet"("p_wallet_id" "uuid", "p_amount_mru" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."transfer_earnings_to_wallet"("p_wallet_id" "uuid", "p_amount_mru" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."transfer_earnings_to_wallet"("p_wallet_id" "uuid", "p_amount_mru" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."request_physical_pack"(
  "p_pack_id" "uuid", "p_recipient_name" "text", "p_phone_number" "text",
  "p_city" "text", "p_zone" "text", "p_quantity" integer, "p_notes" "text",
  "p_address_line1" "text", "p_address_line2" "text", "p_country" "text"
) TO "anon";
GRANT ALL ON FUNCTION "public"."request_physical_pack"(
  "p_pack_id" "uuid", "p_recipient_name" "text", "p_phone_number" "text",
  "p_city" "text", "p_zone" "text", "p_quantity" integer, "p_notes" "text",
  "p_address_line1" "text", "p_address_line2" "text", "p_country" "text"
) TO "authenticated";
GRANT ALL ON FUNCTION "public"."request_physical_pack"(
  "p_pack_id" "uuid", "p_recipient_name" "text", "p_phone_number" "text",
  "p_city" "text", "p_zone" "text", "p_quantity" integer, "p_notes" "text",
  "p_address_line1" "text", "p_address_line2" "text", "p_country" "text"
) TO "service_role";



GRANT ALL ON FUNCTION "public"."submit_pack_for_review"("p_pack_id" "uuid", "p_pay_fee" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."submit_pack_for_review"("p_pack_id" "uuid", "p_pay_fee" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."submit_pack_for_review"("p_pack_id" "uuid", "p_pay_fee" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."check_wallet_balance"("p_wallet_id" "uuid", "p_amount" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."check_wallet_balance"("p_wallet_id" "uuid", "p_amount" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_wallet_balance"("p_wallet_id" "uuid", "p_amount" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_expired_bans"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_expired_bans"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_expired_bans"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_expired_invites"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_expired_invites"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_expired_invites"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_expired_notifications"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_expired_notifications"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_expired_notifications"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_expired_platform_bans"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_expired_platform_bans"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_expired_platform_bans"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_expired_purchases"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_expired_purchases"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_expired_purchases"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_otp_audit_log"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_otp_audit_log"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_otp_audit_log"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_purge_closed_rooms"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_purge_closed_rooms"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_purge_closed_rooms"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_stale_online_status"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_stale_online_status"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_stale_online_status"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_stale_rooms"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_stale_rooms"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_stale_rooms"() TO "service_role";



GRANT ALL ON FUNCTION "public"."create_default_notification_preferences"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_default_notification_preferences"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_default_notification_preferences"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_user_wallet"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_user_wallet"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_user_wallet"() TO "service_role";



GRANT ALL ON FUNCTION "public"."expire_subscriptions"() TO "anon";
GRANT ALL ON FUNCTION "public"."expire_subscriptions"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."expire_subscriptions"() TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_invite_code"() TO "anon";
GRANT ALL ON FUNCTION "public"."generate_invite_code"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_invite_code"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_closed_room_details"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_closed_room_details"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_closed_room_details"("p_room_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_my_closed_rooms"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_closed_rooms"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_closed_rooms"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_room_by_invite_code"("p_code" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_room_by_invite_code"("p_code" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_room_by_invite_code"("p_code" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."immutable_to_tsvector"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."immutable_to_tsvector"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."immutable_to_tsvector"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_room_member"("p_room_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_room_member"("p_room_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_room_member"("p_room_id" "uuid", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."touch_room_presence"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."touch_room_presence"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."touch_room_presence"("p_room_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_room_moderator"("p_room_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_room_moderator"("p_room_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_room_moderator"("p_room_id" "uuid", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_room_owner"("p_room_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_room_owner"("p_room_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_room_owner"("p_room_id" "uuid", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."log_room_event"("p_room_id" "uuid", "p_actor_id" "uuid", "p_target_id" "uuid", "p_action" "public"."room_log_action_enum", "p_metadata" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."log_room_event"("p_room_id" "uuid", "p_actor_id" "uuid", "p_target_id" "uuid", "p_action" "public"."room_log_action_enum", "p_metadata" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_room_event"("p_room_id" "uuid", "p_actor_id" "uuid", "p_target_id" "uuid", "p_action" "public"."room_log_action_enum", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."notifications_set_read_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."notifications_set_read_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notifications_set_read_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."refresh_pack_card_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."refresh_pack_card_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."refresh_pack_card_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."refresh_pack_purchase_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."refresh_pack_purchase_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."refresh_pack_purchase_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."refresh_pack_rating"() TO "anon";
GRANT ALL ON FUNCTION "public"."refresh_pack_rating"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."refresh_pack_rating"() TO "service_role";



GRANT ALL ON FUNCTION "public"."refresh_room_player_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."refresh_room_player_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."refresh_room_player_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rooms_create_settings"() TO "anon";
GRANT ALL ON FUNCTION "public"."rooms_create_settings"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rooms_create_settings"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rooms_set_invite_code"() TO "anon";
GRANT ALL ON FUNCTION "public"."rooms_set_invite_code"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rooms_set_invite_code"() TO "service_role";



GRANT ALL ON FUNCTION "public"."run_all_cleanup"() TO "anon";
GRANT ALL ON FUNCTION "public"."run_all_cleanup"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."run_all_cleanup"() TO "service_role";



GRANT ALL ON FUNCTION "public"."send_notification"("p_user_id" "uuid", "p_type" "public"."notification_type_enum", "p_title" "jsonb", "p_body" "jsonb", "p_data" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."send_notification"("p_user_id" "uuid", "p_type" "public"."notification_type_enum", "p_title" "jsonb", "p_body" "jsonb", "p_data" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."send_notification"("p_user_id" "uuid", "p_type" "public"."notification_type_enum", "p_title" "jsonb", "p_body" "jsonb", "p_data" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."soft_delete"("p_table" "text", "p_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."soft_delete"("p_table" "text", "p_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."soft_delete"("p_table" "text", "p_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."start_game_session_checks"("p_user_id" "uuid", "p_room_id" "uuid", "p_pack_id" "uuid", "p_is_premium" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."start_game_session_checks"("p_user_id" "uuid", "p_room_id" "uuid", "p_pack_id" "uuid", "p_is_premium" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."start_game_session_checks"("p_user_id" "uuid", "p_room_id" "uuid", "p_pack_id" "uuid", "p_is_premium" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."transfer_room_ownership"("p_room_id" "uuid", "p_new_owner_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."transfer_room_ownership"("p_room_id" "uuid", "p_new_owner_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."transfer_room_ownership"("p_room_id" "uuid", "p_new_owner_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."claim_room_ownership"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."claim_room_ownership"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."claim_room_ownership"("p_room_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."has_room_permission"("p_room_id" "uuid", "p_user_id" "uuid", "p_permission" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."has_room_permission"("p_room_id" "uuid", "p_user_id" "uuid", "p_permission" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_room_permission"("p_room_id" "uuid", "p_user_id" "uuid", "p_permission" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."kick_room_member"("p_room_id" "uuid", "p_target_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."kick_room_member"("p_room_id" "uuid", "p_target_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."kick_room_member"("p_room_id" "uuid", "p_target_user_id" "uuid") TO "service_role";


GRANT ALL ON FUNCTION "public"."ban_room_member"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_reason" "text", "p_duration_secs" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."ban_room_member"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_reason" "text", "p_duration_secs" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."ban_room_member"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_reason" "text", "p_duration_secs" integer) TO "service_role";


GRANT ALL ON FUNCTION "public"."close_room"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."close_room"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."close_room"("p_room_id" "uuid") TO "service_role";


GRANT ALL ON FUNCTION "public"."close_abandoned_room"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."close_abandoned_room"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."close_abandoned_room"("p_room_id" "uuid") TO "service_role";


GRANT ALL ON FUNCTION "public"."create_room"("p_name" "text", "p_visibility" "text", "p_max_players" smallint, "p_language" "text", "p_cover_emoji" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_room"("p_name" "text", "p_visibility" "text", "p_max_players" smallint, "p_language" "text", "p_cover_emoji" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_room"("p_name" "text", "p_visibility" "text", "p_max_players" smallint, "p_language" "text", "p_cover_emoji" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."mark_room_member_away"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_away" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."mark_room_member_away"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_away" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_room_member_away"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_away" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_game_session"("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."record_proof_view"("p_session_id" "uuid", "p_turn_started_at" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."record_proof_view"("p_session_id" "uuid", "p_turn_started_at" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."record_proof_view"("p_session_id" "uuid", "p_turn_started_at" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."mute_room_member"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_muted" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."mute_room_member"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_muted" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."mute_room_member"("p_room_id" "uuid", "p_target_user_id" "uuid", "p_muted" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."decide_join_request"("p_request_id" "uuid", "p_approve" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."decide_join_request"("p_request_id" "uuid", "p_approve" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."decide_join_request"("p_request_id" "uuid", "p_approve" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."decide_spectator_request"("p_request_id" "uuid", "p_approve" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."decide_spectator_request"("p_request_id" "uuid", "p_approve" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."decide_spectator_request"("p_request_id" "uuid", "p_approve" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."request_game_rejoin"("p_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."request_game_rejoin"("p_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."request_game_rejoin"("p_room_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."decide_game_rejoin_request"("p_request_id" "uuid", "p_approve" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."decide_game_rejoin_request"("p_request_id" "uuid", "p_approve" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."decide_game_rejoin_request"("p_request_id" "uuid", "p_approve" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_premium_status"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."sync_premium_status"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_premium_status"("p_user_id" "uuid") TO "service_role";


GRANT ALL ON FUNCTION "public"."set_theme_background_color"("p_hex_color" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."set_theme_background_color"("p_hex_color" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_theme_background_color"("p_hex_color" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_requires_approval"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_requires_approval"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_requires_approval"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trim_game_states"() TO "anon";
GRANT ALL ON FUNCTION "public"."trim_game_states"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trim_game_states"() TO "service_role";



GRANT ALL ON TABLE "public"."blocked_users" TO "anon";
GRANT ALL ON TABLE "public"."blocked_users" TO "authenticated";
GRANT ALL ON TABLE "public"."blocked_users" TO "service_role";



GRANT ALL ON TABLE "public"."commissions" TO "anon";
GRANT ALL ON TABLE "public"."commissions" TO "authenticated";
GRANT ALL ON TABLE "public"."commissions" TO "service_role";



GRANT ALL ON TABLE "public"."creator_verifications" TO "anon";
GRANT ALL ON TABLE "public"."creator_verifications" TO "authenticated";
GRANT ALL ON TABLE "public"."creator_verifications" TO "service_role";



GRANT ALL ON TABLE "public"."deposits" TO "anon";
GRANT ALL ON TABLE "public"."deposits" TO "authenticated";
GRANT ALL ON TABLE "public"."deposits" TO "service_role";



GRANT ALL ON TABLE "public"."downloaded_packs" TO "anon";
GRANT ALL ON TABLE "public"."downloaded_packs" TO "authenticated";
GRANT ALL ON TABLE "public"."downloaded_packs" TO "service_role";



GRANT ALL ON TABLE "public"."financial_audit_log" TO "anon";
GRANT ALL ON TABLE "public"."financial_audit_log" TO "authenticated";
GRANT ALL ON TABLE "public"."financial_audit_log" TO "service_role";



GRANT ALL ON SEQUENCE "public"."financial_audit_log_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."financial_audit_log_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."financial_audit_log_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."follows" TO "anon";
GRANT ALL ON TABLE "public"."follows" TO "authenticated";
GRANT ALL ON TABLE "public"."follows" TO "service_role";



GRANT ALL ON TABLE "public"."friendships" TO "anon";
GRANT ALL ON TABLE "public"."friendships" TO "authenticated";
GRANT ALL ON TABLE "public"."friendships" TO "service_role";



GRANT ALL ON TABLE "public"."game_rounds" TO "anon";
GRANT ALL ON TABLE "public"."game_rounds" TO "authenticated";
GRANT ALL ON TABLE "public"."game_rounds" TO "service_role";



GRANT ALL ON TABLE "public"."game_sessions" TO "anon";
GRANT ALL ON TABLE "public"."game_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."game_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."game_states" TO "anon";
GRANT ALL ON TABLE "public"."game_states" TO "authenticated";
GRANT ALL ON TABLE "public"."game_states" TO "service_role";



GRANT ALL ON SEQUENCE "public"."game_states_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."game_states_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."game_states_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."game_turns" TO "anon";
GRANT ALL ON TABLE "public"."game_turns" TO "authenticated";
GRANT ALL ON TABLE "public"."game_turns" TO "service_role";



GRANT ALL ON TABLE "public"."game_votes" TO "anon";
GRANT ALL ON TABLE "public"."game_votes" TO "authenticated";
GRANT ALL ON TABLE "public"."game_votes" TO "service_role";



GRANT ALL ON TABLE "public"."gameplay_analytics" TO "anon";
GRANT ALL ON TABLE "public"."gameplay_analytics" TO "authenticated";
GRANT ALL ON TABLE "public"."gameplay_analytics" TO "service_role";



GRANT ALL ON TABLE "public"."moderation_actions" TO "anon";
GRANT ALL ON TABLE "public"."moderation_actions" TO "authenticated";
GRANT ALL ON TABLE "public"."moderation_actions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."moderation_actions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."moderation_actions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."moderation_actions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."notification_preferences" TO "anon";
GRANT ALL ON TABLE "public"."notification_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_preferences" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."otp_audit_log" TO "anon";
GRANT ALL ON TABLE "public"."otp_audit_log" TO "authenticated";
GRANT ALL ON TABLE "public"."otp_audit_log" TO "service_role";



GRANT ALL ON SEQUENCE "public"."otp_audit_log_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."otp_audit_log_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."otp_audit_log_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."pack_analytics" TO "anon";
GRANT ALL ON TABLE "public"."pack_analytics" TO "authenticated";
GRANT ALL ON TABLE "public"."pack_analytics" TO "service_role";



GRANT ALL ON TABLE "public"."pack_cards" TO "anon";
GRANT ALL ON TABLE "public"."pack_cards" TO "authenticated";
GRANT ALL ON TABLE "public"."pack_cards" TO "service_role";



GRANT ALL ON TABLE "public"."pack_categories" TO "anon";
GRANT ALL ON TABLE "public"."pack_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."pack_categories" TO "service_role";



GRANT ALL ON TABLE "public"."pack_category_suggestions" TO "anon";
GRANT ALL ON TABLE "public"."pack_category_suggestions" TO "authenticated";
GRANT ALL ON TABLE "public"."pack_category_suggestions" TO "service_role";



GRANT ALL ON TABLE "public"."pack_languages" TO "anon";
GRANT ALL ON TABLE "public"."pack_languages" TO "authenticated";
GRANT ALL ON TABLE "public"."pack_languages" TO "service_role";



GRANT ALL ON TABLE "public"."pack_purchases" TO "anon";
GRANT ALL ON TABLE "public"."pack_purchases" TO "authenticated";
GRANT ALL ON TABLE "public"."pack_purchases" TO "service_role";



GRANT ALL ON TABLE "public"."app_settings" TO "anon";
GRANT ALL ON TABLE "public"."app_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."app_settings" TO "service_role";



GRANT ALL ON TABLE "public"."physical_pack_requests" TO "anon";
GRANT ALL ON TABLE "public"."physical_pack_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."physical_pack_requests" TO "service_role";



GRANT ALL ON TABLE "public"."pack_submissions" TO "anon";
GRANT ALL ON TABLE "public"."pack_submissions" TO "authenticated";
GRANT ALL ON TABLE "public"."pack_submissions" TO "service_role";



GRANT ALL ON TABLE "public"."pack_ratings" TO "anon";
GRANT ALL ON TABLE "public"."pack_ratings" TO "authenticated";
GRANT ALL ON TABLE "public"."pack_ratings" TO "service_role";



GRANT ALL ON TABLE "public"."pack_reactions" TO "anon";
GRANT ALL ON TABLE "public"."pack_reactions" TO "authenticated";
GRANT ALL ON TABLE "public"."pack_reactions" TO "service_role";



GRANT ALL ON TABLE "public"."pack_reports" TO "anon";
GRANT ALL ON TABLE "public"."pack_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."pack_reports" TO "service_role";



GRANT ALL ON TABLE "public"."pack_reviews" TO "anon";
GRANT ALL ON TABLE "public"."pack_reviews" TO "authenticated";
GRANT ALL ON TABLE "public"."pack_reviews" TO "service_role";



GRANT ALL ON TABLE "public"."pack_tags" TO "anon";
GRANT ALL ON TABLE "public"."pack_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."pack_tags" TO "service_role";



GRANT ALL ON TABLE "public"."packs" TO "anon";
GRANT ALL ON TABLE "public"."packs" TO "authenticated";
GRANT ALL ON TABLE "public"."packs" TO "service_role";



GRANT ALL ON TABLE "public"."payment_methods" TO "anon";
GRANT ALL ON TABLE "public"."payment_methods" TO "authenticated";
GRANT ALL ON TABLE "public"."payment_methods" TO "service_role";



GRANT ALL ON TABLE "public"."payment_methods_config" TO "anon";
GRANT ALL ON TABLE "public"."payment_methods_config" TO "authenticated";
GRANT ALL ON TABLE "public"."payment_methods_config" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT UPDATE("display_name") ON TABLE "public"."profiles" TO "authenticated";



GRANT UPDATE("avatar_url") ON TABLE "public"."profiles" TO "authenticated";



GRANT UPDATE("bio") ON TABLE "public"."profiles" TO "authenticated";



GRANT UPDATE("country_code") ON TABLE "public"."profiles" TO "authenticated";



GRANT UPDATE("age") ON TABLE "public"."profiles" TO "authenticated";



GRANT UPDATE("phone_number") ON TABLE "public"."profiles" TO "authenticated";



GRANT UPDATE("preferred_lang") ON TABLE "public"."profiles" TO "authenticated";



GRANT UPDATE("online_status") ON TABLE "public"."profiles" TO "authenticated";



GRANT UPDATE("in_game_status") ON TABLE "public"."profiles" TO "authenticated";



GRANT UPDATE("last_seen_at") ON TABLE "public"."profiles" TO "authenticated";



GRANT ALL ON TABLE "public"."room_members" TO "anon";
GRANT ALL ON TABLE "public"."room_members" TO "authenticated";
GRANT ALL ON TABLE "public"."room_members" TO "service_role";



GRANT ALL ON TABLE "public"."rooms" TO "anon";
GRANT ALL ON TABLE "public"."rooms" TO "authenticated";
GRANT ALL ON TABLE "public"."rooms" TO "service_role";



GRANT ALL ON TABLE "public"."profiles_public" TO "anon";
GRANT ALL ON TABLE "public"."profiles_public" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles_public" TO "service_role";



GRANT ALL ON TABLE "public"."promoted_packs" TO "anon";
GRANT ALL ON TABLE "public"."promoted_packs" TO "authenticated";
GRANT ALL ON TABLE "public"."promoted_packs" TO "service_role";



GRANT ALL ON TABLE "public"."reports" TO "anon";
GRANT ALL ON TABLE "public"."reports" TO "authenticated";
GRANT ALL ON TABLE "public"."reports" TO "service_role";



GRANT ALL ON TABLE "public"."room_bans" TO "anon";
GRANT ALL ON TABLE "public"."room_bans" TO "authenticated";
GRANT ALL ON TABLE "public"."room_bans" TO "service_role";



GRANT ALL ON TABLE "public"."room_chat_messages" TO "anon";
GRANT ALL ON TABLE "public"."room_chat_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."room_chat_messages" TO "service_role";



GRANT ALL ON TABLE "public"."room_creation_quotas" TO "anon";
GRANT ALL ON TABLE "public"."room_creation_quotas" TO "authenticated";
GRANT ALL ON TABLE "public"."room_creation_quotas" TO "service_role";



GRANT ALL ON TABLE "public"."room_invites" TO "anon";
GRANT ALL ON TABLE "public"."room_invites" TO "authenticated";
GRANT ALL ON TABLE "public"."room_invites" TO "service_role";



GRANT ALL ON TABLE "public"."room_join_requests" TO "anon";
GRANT ALL ON TABLE "public"."room_join_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."room_join_requests" TO "service_role";



GRANT ALL ON TABLE "public"."game_rejoin_requests" TO "anon";
GRANT ALL ON TABLE "public"."game_rejoin_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."game_rejoin_requests" TO "service_role";



GRANT ALL ON TABLE "public"."room_logs" TO "anon";
GRANT ALL ON TABLE "public"."room_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."room_logs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."room_logs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."room_logs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."room_logs_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."room_moderators" TO "anon";
GRANT ALL ON TABLE "public"."room_moderators" TO "authenticated";
GRANT ALL ON TABLE "public"."room_moderators" TO "service_role";



GRANT ALL ON TABLE "public"."room_played_packs" TO "anon";
GRANT ALL ON TABLE "public"."room_played_packs" TO "authenticated";
GRANT ALL ON TABLE "public"."room_played_packs" TO "service_role";



GRANT ALL ON TABLE "public"."room_return_timers" TO "anon";
GRANT ALL ON TABLE "public"."room_return_timers" TO "authenticated";
GRANT ALL ON TABLE "public"."room_return_timers" TO "service_role";



GRANT ALL ON TABLE "public"."room_settings" TO "anon";
GRANT ALL ON TABLE "public"."room_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."room_settings" TO "service_role";



GRANT ALL ON TABLE "public"."session_custom_cards" TO "anon";
GRANT ALL ON TABLE "public"."session_custom_cards" TO "authenticated";
GRANT ALL ON TABLE "public"."session_custom_cards" TO "service_role";



GRANT ALL ON TABLE "public"."sms_delivery_log" TO "anon";
GRANT ALL ON TABLE "public"."sms_delivery_log" TO "authenticated";
GRANT ALL ON TABLE "public"."sms_delivery_log" TO "service_role";



GRANT ALL ON TABLE "public"."tod_proof_views" TO "anon";
GRANT ALL ON TABLE "public"."tod_proof_views" TO "authenticated";
GRANT ALL ON TABLE "public"."tod_proof_views" TO "service_role";



GRANT ALL ON TABLE "public"."spectator_requests" TO "anon";
GRANT ALL ON TABLE "public"."spectator_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."spectator_requests" TO "service_role";



GRANT UPDATE("status") ON TABLE "public"."spectator_requests" TO "authenticated";



GRANT UPDATE("decided_by") ON TABLE "public"."spectator_requests" TO "authenticated";



GRANT UPDATE("decided_at") ON TABLE "public"."spectator_requests" TO "authenticated";



GRANT ALL ON TABLE "public"."subscriptions" TO "anon";
GRANT ALL ON TABLE "public"."subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."subscriptions" TO "service_role";



GRANT ALL ON TABLE "public"."wallets" TO "anon";
GRANT ALL ON TABLE "public"."wallets" TO "authenticated";
GRANT ALL ON TABLE "public"."wallets" TO "service_role";



GRANT ALL ON TABLE "public"."withdrawals" TO "anon";
GRANT ALL ON TABLE "public"."withdrawals" TO "authenticated";
GRANT ALL ON TABLE "public"."withdrawals" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







