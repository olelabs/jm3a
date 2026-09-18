-- Jma3a Store — Phase 2A foundation, part 1: a dedicated, stable,
-- public-safe "Jma3a Player ID" on profiles.
--
-- WHY a new column instead of reusing profiles.username: the Phase 2
-- investigation's original recommendation (reuse username) was
-- explicitly overturned by the follow-up correction — username is
-- user-changeable (see profiles.username_changed_at / the change-
-- username cooldown in jma3a-api/src/auth/profileService.js) and is a
-- different *concept* (a display handle) from a Player ID (a stable
-- account identifier safe to read aloud/type into an external system).
-- This migration adds a column that is generated once, never changes,
-- and is never derived from anything the user can edit.
--
-- VERIFIED AGAINST LIVE PRODUCTION (via Supabase SQL Editor, not the
-- stale jma3a/schema.sql dump — that dump was independently found to be
-- missing several real columns and is not treated as a source of truth
-- anywhere in this file):
--   * public.profiles has NO player_id column today — this migration is
--     purely additive.
--   * Live profiles columns include (beyond what either local dump
--     showed) gender, presence_mode, is_official_account,
--     creator_privileges_removed_at, general_score, honesty_points,
--     has_password. None of these interact with player_id in any way;
--     ADD COLUMN IF NOT EXISTS below is unaffected by the rest of the
--     table's shape.
--   * Live profiles triggers are exactly: trg_create_wallet,
--     trg_notify_creator_privileges_removed,
--     trg_prevent_client_has_password_update, trg_profiles_updated_at,
--     trg_track_creator_verification_login. This migration's new
--     trigger (trg_profiles_player_id, section 3 below) has a name
--     that doesn't collide with any of these five, and none of the
--     five are semantically related to player_id/ID-generation (they
--     govern wallet creation, a creator-privileges-removed
--     notification, blocking client writes to has_password, updated_at
--     maintenance, and creator-verification login tracking) — so
--     regardless of each one's exact BEFORE/AFTER/INSERT/UPDATE timing
--     (not itemized in what was verified), there is no realistic
--     interaction with the column this migration adds. This migration
--     does not modify, drop, rename, or reorder any of the five.
--
-- generate_player_id() (section 2) deliberately copies
-- generate_invite_code()'s existing style (plain plpgsql, no SECURITY
-- DEFINER needed since it grants nothing and reads nothing sensitive,
-- same random-character-from-a-fixed-alphabet loop) for consistency
-- with how this exact class of problem ("generate a short, public-safe,
-- non-sequential code") is already solved elsewhere in this codebase.
--
-- Idempotent (IF NOT EXISTS / CREATE OR REPLACE / DROP...CREATE), safe
-- to run multiple times. NOT applied automatically — for manual
-- application only. Not executed against production this session — see
-- the final report for what static/local validation was performed.

-- ─────────────────────────────────────────────────────────────────────────
-- 1. player_id column — added nullable first (required for the backfill
--    step below to even be possible), tightened to NOT NULL + UNIQUE at
--    the end once every existing row has a value.
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS player_id text;

COMMENT ON COLUMN public.profiles.player_id IS
  'Stable, public-safe Jma3a account identifier — distinct from both the internal auth/profile uuid (never exposed to third parties) and username (a user-changeable display handle). Generated once, server-side, never reassigned. Format: "JMA-" + 8 random unambiguous-alphabet characters. Safe to give to another person or an external system (e.g. the separate Jma3a Store) to identify this account without exposing profiles.id.';

-- ─────────────────────────────────────────────────────────────────────────
-- 2. generate_player_id() — same alphabet as the existing
--    generate_invite_code() (ABCDEFGHJKLMNPQRSTUVWXYZ23456789: excludes
--    0/O/1/I/L, the visually-confusable characters, matching that
--    function's own already-established choice), but longer (8 chars vs
--    invite_code's 6) and with an explicit uniqueness retry loop —
--    invite_code never needed one (a room code only has to be unique
--    among currently-live rooms and a collision is low-stakes/re-rolled
--    naturally on retry), whereas a Player ID must be unique across
--    EVERY account, forever, by construction, not by low collision
--    probability alone.
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.generate_player_id() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  chars  text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result text;
  i      int;
BEGIN
  LOOP
    result := 'JMA-';
    FOR i IN 1..8 LOOP
      result := result || substr(chars, floor(random() * length(chars))::int + 1, 1);
    END LOOP;
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.profiles WHERE player_id = result);
  END LOOP;
  RETURN result;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 3. Auto-assign on every new profile row, regardless of which code path
--    inserts it. This is deliberately a trigger on public.profiles
--    itself (not an edit to handle_new_user()) — it guarantees every
--    profiles row ever created gets a player_id, including any future
--    insert path that isn't handle_new_user(), without needing to touch
--    (or even re-verify) that existing, already-relied-upon function.
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.profiles_set_player_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.player_id IS NULL THEN
    NEW.player_id := public.generate_player_id();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_player_id ON public.profiles;
CREATE TRIGGER trg_profiles_player_id
    BEFORE INSERT ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.profiles_set_player_id();

-- ─────────────────────────────────────────────────────────────────────────
-- 4. Backfill every existing row, then tighten the column. Safe to
--    re-run: the WHERE clause means a second run touches zero rows, and
--    ADD COLUMN/ALTER COLUMN/ADD CONSTRAINT are all idempotent via the
--    IF NOT EXISTS / DROP-then-ADD forms used throughout this file.
-- ─────────────────────────────────────────────────────────────────────────
UPDATE public.profiles
SET player_id = public.generate_player_id()
WHERE player_id IS NULL;

ALTER TABLE public.profiles
  ALTER COLUMN player_id SET NOT NULL;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_player_id_key,
  ADD CONSTRAINT profiles_player_id_key UNIQUE (player_id);

-- Note: no RLS/GRANT changes in this migration. profiles' existing
-- SELECT policies already govern who can read this new column exactly
-- like every other profiles column (no change in exposure surface) —
-- the "never expose profiles.id to the Store" requirement is a Store-
-- bridge (jma3a-api) responsibility for a later phase, not something
-- enforceable or applicable at this column's own definition.
