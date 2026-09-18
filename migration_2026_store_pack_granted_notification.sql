-- Adds the 'pack_granted' notification type. jma3a-api's
-- notificationService.js NOTIFICATION_TEMPLATES already defines this
-- type's copy ("A new pack '[Pack Name]' has been added to your packs.")
-- and storeOrdersService.js's approveOrder() already calls
-- sendNotification({type: 'pack_granted', ...}) after a Store pack grant
-- succeeds — but the INSERT into public.notifications was failing because
-- this value was never added to the live notification_type_enum, so
-- Postgres rejected it (caught only by approveOrder()'s fire-and-forget
-- .catch(), logged server-side, never surfaced to the user or the admin).
--
-- This migration ONLY extends the enum. No wording, no application code,
-- and no other enum value changes — subscription_started (used for the
-- "You are now Premium[.../ Plus]." copy) already exists and is untouched.
--
-- Idempotent (ADD VALUE IF NOT EXISTS), safe to run multiple times.

BEGIN;

ALTER TYPE "public"."notification_type_enum" ADD VALUE IF NOT EXISTS 'pack_granted';

COMMIT;
