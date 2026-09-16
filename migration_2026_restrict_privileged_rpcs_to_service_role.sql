-- Migration: restrict three privileged SECURITY DEFINER RPCs to
-- service_role-only execution.
--
-- This repo has no supabase CLI / migration tooling — apply this by hand
-- against the live Supabase project (SQL editor or `psql`). schema.sql
-- has already been left as-is pending this migration being applied and
-- separately re-synced from a live `pg_dump` afterward.
--
-- ── AUDIT FINDING ────────────────────────────────────────────────────────
-- All three functions below are SECURITY DEFINER and currently GRANTed
-- (GRANT ALL) to anon AND authenticated, in addition to service_role —
-- see schema.sql (Sep 11 snapshot) lines 7239-7241, 7269-7271, 7503-7505.
-- Supabase auto-exposes every public-schema function as a PostgREST RPC
-- endpoint (POST /rest/v1/rpc/<function>), so any anon or authenticated
-- client can currently call these directly over the API, completely
-- bypassing every application-layer check the Node backend normally does
-- before reaching them:
--
--   * apply_wallet_transaction — mutates ANY wallet's balance_mru /
--     earnings_balance_mru and inserts a 'completed' wallet_transactions
--     row for an attacker-chosen wallet_id, with no ownership check of
--     its own (that lives in jma3a-api, not in this function). Repo
--     search confirms every current caller uses jma3a-api's
--     `supabaseAdmin` client (service-role key — src/config/supabase.js),
--     never an anon/authenticated-keyed client.
--   * admin_grant_premium — inserts an 'active' subscriptions row for
--     ANY user_id, with an attacker-chosen tier and duration — i.e. a
--     client could grant themselves years of premium for free. Repo
--     search (jma3a, jma3a-api, jma3a_admin) found NO caller anywhere;
--     nothing legitimate currently depends on non-service-role access.
--   * send_notification — inserts an arbitrary notification row for ANY
--     user_id. Repo search found it is only ever invoked internally via
--     `PERFORM public.send_notification(...)` from OTHER Postgres
--     functions (e.g. schema.sql line 2597) — never as a client-facing
--     RPC from any repo. Internal same-database PERFORM calls are
--     unaffected by revoking the PostgREST-facing grant below.
--
-- Fix mirrors purchase_pack's existing, already-correct pattern
-- (schema.sql lines 751-752: REVOKE ALL ... FROM PUBLIC; GRANT ALL ... TO
-- service_role;) — EXECUTE is used here instead of ALL since EXECUTE is
-- the only privilege type that applies to a function, so it is exactly
-- equivalent in effect while stating the intent explicitly.
--
-- No function body, argument, return type, or SECURITY DEFINER attribute
-- is touched anywhere in this file — ONLY grants change.

-- ── apply_wallet_transaction ────────────────────────────────────────────
REVOKE ALL ON FUNCTION "public"."apply_wallet_transaction"(
  "uuid", "public"."transaction_type_enum", integer, "uuid", "text", "text", "text"
) FROM PUBLIC;

REVOKE ALL ON FUNCTION "public"."apply_wallet_transaction"(
  "uuid", "public"."transaction_type_enum", integer, "uuid", "text", "text", "text"
) FROM "anon";

REVOKE ALL ON FUNCTION "public"."apply_wallet_transaction"(
  "uuid", "public"."transaction_type_enum", integer, "uuid", "text", "text", "text"
) FROM "authenticated";

GRANT EXECUTE ON FUNCTION "public"."apply_wallet_transaction"(
  "uuid", "public"."transaction_type_enum", integer, "uuid", "text", "text", "text"
) TO "service_role";


-- ── admin_grant_premium ─────────────────────────────────────────────────
REVOKE ALL ON FUNCTION "public"."admin_grant_premium"(
  "uuid", integer, "text", "text"
) FROM PUBLIC;

REVOKE ALL ON FUNCTION "public"."admin_grant_premium"(
  "uuid", integer, "text", "text"
) FROM "anon";

REVOKE ALL ON FUNCTION "public"."admin_grant_premium"(
  "uuid", integer, "text", "text"
) FROM "authenticated";

GRANT EXECUTE ON FUNCTION "public"."admin_grant_premium"(
  "uuid", integer, "text", "text"
) TO "service_role";


-- ── send_notification ───────────────────────────────────────────────────
REVOKE ALL ON FUNCTION "public"."send_notification"(
  "uuid", "public"."notification_type_enum", "jsonb", "jsonb", "jsonb"
) FROM PUBLIC;

REVOKE ALL ON FUNCTION "public"."send_notification"(
  "uuid", "public"."notification_type_enum", "jsonb", "jsonb", "jsonb"
) FROM "anon";

REVOKE ALL ON FUNCTION "public"."send_notification"(
  "uuid", "public"."notification_type_enum", "jsonb", "jsonb", "jsonb"
) FROM "authenticated";

GRANT EXECUTE ON FUNCTION "public"."send_notification"(
  "uuid", "public"."notification_type_enum", "jsonb", "jsonb", "jsonb"
) TO "service_role";
