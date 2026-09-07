-- Item 18.2: ToD's "Force Dare after N Truths" setting (forceDareMode /
-- maxTruths, chosen per-session in tod_pre_game_config_sheet.dart) was
-- never persisted anywhere durable. The game_started realtime broadcast
-- DID carry the correct values (RoomProvider._handleGameStarted receives
-- them in its payload), but that handler only reads game_type/status from
-- it and discards the rest — and _syncGameRoute's GameConfig
-- reconstruction (lobby_screen.dart's _pushGameRoute — the ONE path that
-- actually navigates ANY client, including the owner's own first
-- navigation into the game, into the game screen) only ever read
-- room.settings.*, which had no field for these two values at all. Net
-- effect: TruthOrDareEngine was constructed with forceDareMode='unlimited'
-- (the GameConfig default) from the very first round, regardless of what
-- the host configured — Force Dare silently never engaged.
--
-- Fix: persist these two values into room_settings (the same durable,
-- already-read-by-_syncGameRoute store maxRounds/turnTimerSeconds already
-- use) the moment the host confirms the pre-game sheet, so every
-- navigation into the game — first start, reconnect, or host migration —
-- reads the same authoritative values. This does NOT change the sheet's
-- own "ask fresh every ToD game start" UX; it only makes the chosen
-- answer durable for the lifetime of that game instead of being lost the
-- instant navigation happens.

ALTER TABLE public.room_settings
  ADD COLUMN IF NOT EXISTS force_dare_mode text DEFAULT 'unlimited'::text NOT NULL;

ALTER TABLE public.room_settings
  ADD COLUMN IF NOT EXISTS max_truths smallint DEFAULT 2 NOT NULL;

ALTER TABLE public.room_settings
  DROP CONSTRAINT IF EXISTS room_settings_force_dare_mode_check;

ALTER TABLE public.room_settings
  ADD CONSTRAINT room_settings_force_dare_mode_check
  CHECK (force_dare_mode = ANY (ARRAY['unlimited'::text, 'per_player'::text, 'per_turn'::text]));

ALTER TABLE public.room_settings
  DROP CONSTRAINT IF EXISTS room_settings_max_truths_check;

ALTER TABLE public.room_settings
  ADD CONSTRAINT room_settings_max_truths_check
  CHECK (max_truths >= 1 AND max_truths <= 20);

-- Defensive/documentation-only: game_sessions.config is the SEPARATE,
-- already-existing "real, working feature" TodRepository.createSession/
-- findActiveSession/findLatestSession already read and write (see their
-- comments and migration_2026_starting_state_and_tod_canonical_rpc.sql,
-- which confirms the OLD create_game_session(..., p_config) overload was
-- dropped from the live DB while this COLUMN — populated via a follow-up
-- UPDATE instead — remains in active use). It's what lets a RECONNECTING
-- client recover the exact GameConfig (forceDareMode/maxTruths included)
-- the session actually started with, instead of reconstructing one fresh.
-- schema.sql's CREATE TABLE for game_sessions was simply never
-- regenerated to include it — this is IF NOT EXISTS so it's a no-op
-- wherever the column is already live, and self-healing wherever it
-- somehow isn't.
ALTER TABLE public.game_sessions
  ADD COLUMN IF NOT EXISTS config jsonb DEFAULT '{}'::jsonb NOT NULL;
