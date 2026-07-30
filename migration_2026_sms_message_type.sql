-- migration_2026_sms_message_type.sql
--
-- Adds message_type to sms_delivery_log so a deliverability investigation
-- can distinguish OTP-worded sends from plain-text test sends on the same
-- account/route/number, per the ongoing "accepted but not delivered"
-- investigation. Safe to run multiple times.

ALTER TABLE public.sms_delivery_log
  ADD COLUMN IF NOT EXISTS message_type text DEFAULT 'otp'::text NOT NULL;

ALTER TABLE public.sms_delivery_log
  DROP CONSTRAINT IF EXISTS sms_delivery_log_message_type_check;
ALTER TABLE public.sms_delivery_log
  ADD CONSTRAINT sms_delivery_log_message_type_check
    CHECK ((message_type = ANY (ARRAY['otp'::text, 'test'::text, 'diagnostic'::text])));
