-- migration_2026_sms_delivery_log.sql
--
-- Backend-only delivery log for Moorsyl SMS sends. Root cause of the
-- "accepted but never delivered" phone-OTP bug: the backend was calling
-- Moorsyl's hosted Verify product (/api/verify/send) instead of the plain
-- SMS product (/api/sms) the working curl test used — a 2xx from Verify
-- only meant Moorsyl accepted the verification request, not that anything
-- was actually sent. The app now generates/hashes/verifies its own OTP and
-- uses Moorsyl purely as an SMS transport (via the official @moorsyl/sdk),
-- matching the curl behavior exactly. This table stops the backend from
-- ever again treating "HTTP 200" as "delivered" by recording the real
-- provider response and refreshing delivery status via a follow-up
-- smsGet() poll.
--
-- Safe to run multiple times. Apply by hand in the Supabase SQL editor.

CREATE TABLE IF NOT EXISTS public.sms_delivery_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    phone text NOT NULL,
    message_id text,
    idempotency_key text,
    organization_id text,
    provider text DEFAULT 'moorsyl'::text NOT NULL,
    status text DEFAULT 'accepted'::text NOT NULL,
    provider_response jsonb,
    error_message text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.sms_delivery_log OWNER TO postgres;

ALTER TABLE ONLY public.sms_delivery_log
    DROP CONSTRAINT IF EXISTS sms_delivery_log_pkey;
ALTER TABLE ONLY public.sms_delivery_log
    ADD CONSTRAINT sms_delivery_log_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.sms_delivery_log
    DROP CONSTRAINT IF EXISTS sms_delivery_log_status_check;
ALTER TABLE ONLY public.sms_delivery_log
    ADD CONSTRAINT sms_delivery_log_status_check
      CHECK ((status = ANY (ARRAY['accepted'::text, 'pending'::text, 'processing'::text, 'sent'::text, 'failed'::text, 'error'::text])));

ALTER TABLE public.sms_delivery_log ENABLE ROW LEVEL SECURITY;

-- Self-referential-RLS-recursion sweep: this single policy is a constant
-- USING (false) with no subquery on the table itself — no recursion risk.
-- Backend-only table: the jma3a-api service uses the service-role client,
-- which bypasses RLS entirely; this policy just blocks anon/authenticated
-- as a defense-in-depth backstop, matching financial_audit_log's pattern.
DROP POLICY IF EXISTS "sms_delivery_log: no client access" ON public.sms_delivery_log;
CREATE POLICY "sms_delivery_log: no client access" ON public.sms_delivery_log USING (false);

GRANT ALL ON TABLE public.sms_delivery_log TO anon;
GRANT ALL ON TABLE public.sms_delivery_log TO authenticated;
GRANT ALL ON TABLE public.sms_delivery_log TO service_role;
