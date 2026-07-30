-- Migration: ownership transfer cooldown, max players cap, notification
-- infrastructure fixes.
--
-- This repo has no supabase CLI / migration tooling — apply this by hand
-- against the live Supabase project (SQL editor or `psql`). schema.sql has
-- already been updated to reflect this as the target end-state for future
-- fresh installs; this script brings an existing, already-provisioned
-- database up to the same state.
--
-- Safe to run multiple times (IF NOT EXISTS / guarded ADD VALUE).

-- 1. Room ownership transfer cooldown (24h) — new nullable column, no
--    backfill needed, existing rooms simply have no prior transfer.
ALTER TABLE public.rooms
  ADD COLUMN IF NOT EXISTS owner_transferred_at timestamp with time zone;

-- 2. Max players cap lowered from 12 to 8. Any existing room already above
--    8 must be resolved manually before the constraint can be applied —
--    the UPDATE below clamps them down first so this script doesn't fail.
UPDATE public.rooms SET max_players = 8 WHERE max_players > 8;

ALTER TABLE public.rooms DROP CONSTRAINT IF EXISTS rooms_max_players_check;
ALTER TABLE public.rooms
  ADD CONSTRAINT rooms_max_players_check
  CHECK (max_players >= 2 AND max_players <= 8);

-- 3. Notification type enum was missing values already referenced by
--    jma3a-api's NOTIFICATION_TEMPLATES (room_join_request/approved/
--    rejected) — inserting one of these today fails outright. game_ended
--    is new. Each ADD VALUE must run in its own statement/transaction per
--    Postgres rules for enum alteration.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'room_join_request'
      AND enumtypid = 'public.notification_type_enum'::regtype
  ) THEN
    ALTER TYPE public.notification_type_enum ADD VALUE 'room_join_request';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'room_join_approved'
      AND enumtypid = 'public.notification_type_enum'::regtype
  ) THEN
    ALTER TYPE public.notification_type_enum ADD VALUE 'room_join_approved';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'room_join_rejected'
      AND enumtypid = 'public.notification_type_enum'::regtype
  ) THEN
    ALTER TYPE public.notification_type_enum ADD VALUE 'room_join_rejected';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'game_ended'
      AND enumtypid = 'public.notification_type_enum'::regtype
  ) THEN
    ALTER TYPE public.notification_type_enum ADD VALUE 'game_ended';
  END IF;
END $$;

-- 4. notifications.idempotency_key — notificationService.js's
--    sendNotification() already queries this column for the existing
--    room_invite/notify-friends routes; the column doesn't exist yet,
--    so those calls have been silently failing. Also needed for the new
--    kick/ban/join-request/game-started/game-ended call sites so a
--    duplicate client retry can't double-send.
ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS idempotency_key text;

ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_idempotency_key_key;
ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_idempotency_key_key UNIQUE (idempotency_key);
