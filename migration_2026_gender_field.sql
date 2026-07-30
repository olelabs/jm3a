-- migration_2026_gender_field.sql
--
-- Adds gender to profiles. Required at registration (enforced by the
-- /v1/auth/setup-profile validator and the onboarding form), but stored
-- as a nullable column here — same convention as `age` on this table —
-- since ALTER TABLE ... ADD COLUMN NOT NULL isn't safe to run against
-- profiles with existing rows and no backfill value to give them.
-- Safe to run multiple times.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS gender text;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_gender_check;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_gender_check
    CHECK (gender IS NULL OR gender = ANY (ARRAY['male'::text, 'female'::text]));
