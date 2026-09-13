-- Adds a persisted, per-room "Honesty vote" enable/disable setting.
--
-- Honesty voting (the shared cast_honesty_vote RPC / honesty_votes table,
-- rendered via CompactHonestyVoteButtons in NHIE/Meme Game and
-- _HonestyVoteRow in ToD) was previously ALWAYS on with no way for a
-- room's admin to disable it — no field for it existed anywhere in
-- room_settings, RoomSettingsEntity, or GameConfig. This adds the
-- missing persisted column, following the exact same pattern every other
-- boolean room setting already uses (allow_skip, chat_enabled,
-- enable_punishments, etc.) — see RoomSettingsEntity.toMap/fromMap and
-- RoomProvider._handleSettingsChange in the Dart codebase for the
-- corresponding application-side wiring.
--
-- Default TRUE: honesty voting was unconditionally on for every room
-- that already exists, so defaulting new rows to enabled preserves
-- existing behavior for those rooms — this migration only adds the
-- ability to turn it OFF, it does not silently change any room's
-- current behavior.

ALTER TABLE public.room_settings
  ADD COLUMN IF NOT EXISTS honesty_vote_enabled boolean DEFAULT true NOT NULL;
