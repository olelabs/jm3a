-- Item 2 (TOD settings: enable/disable dares).
--
-- Adds the durable "dares enabled" toggle to room_settings, matching the
-- exact existing precedent of force_dare_mode/max_truths/
-- honesty_vote_enabled on the same table (see 20260904090000_tod_
-- force_dare_mode.sql-equivalent / migration_2026_tod_force_dare_
-- persistence.sql history for that convention). Server-side enforcement
-- of the setting itself lives in the ToD engine (TruthOrDareEngine, an
-- owner-run broadcast-relay authority — see that file's own comment on
-- why ToD has no separate RPC/backend re-validation path for any of its
-- rules, force_dare_mode included), not in this column directly; this
-- migration only adds the durable STORAGE for the choice, exactly like
-- every other ToD room setting already works.
--
-- DEFAULT true preserves existing behavior for every room that already
-- exists (dares were always available before this setting existed) —
-- no migration should silently disable dares for anyone.

ALTER TABLE public.room_settings
  ADD COLUMN IF NOT EXISTS dares_enabled boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.room_settings.dares_enabled IS
  'Truth or Dare only. When false, TruthOrDareEngine._onChoice coerces every dare selection back to truth (mirrors the existing force_dare_mode truth->dare coercion in the opposite direction) — the client-facing pre-game sheet and in-round Dare button both hide accordingly, but the actual enforcement is this engine-side coercion, not the UI. Meaningless for other game types, same as force_dare_mode/max_truths already are.';
