-- ============================================================================
-- Run this in the Supabase SQL Editor right after reproducing the "game #2
-- won't start" bug — while the room is actively stuck in the loading/lobby
-- loop, BEFORE backing out or retrying anything further. Replace the
-- room_id below with the actual room you tested with. Paste the full
-- result back.
--
-- What we're specifically checking: whether the ToD session from game #1
-- is STILL status='active' (not yet 'completed') at this exact moment —
-- ToD's own _handleGameOver() fires both its game_sessions-completing
-- write (TodRepository.completeSession) and the notifyGameEnded backend
-- call as fire-and-forget (.ignore()), never awaited, so there is a real
-- window where the room's status/pack_id has already reset (letting the
-- lobby offer "Start Game" for NHIE/Meme again) while the OLD ToD session
-- row is still sitting at status='active'. If it's still 'active' here,
-- and game_type='truth_or_dare' rather than the game you tried to start
-- second, that confirms it.
-- ============================================================================

with target_room as (
  select id from public.rooms where id = 'PASTE_ROOM_ID_HERE'::uuid
)

select 'ROOM' as section,
  format(
    'id=%s status=%s owner_id=%s pack_id=%s game_type=%s last_active_at=%s updated_at=%s',
    r.id, r.status, r.owner_id, coalesce(r.pack_id::text, 'NULL'),
    coalesce(r.game_type::text, 'NULL'), r.last_active_at, r.updated_at
  ) as detail
from public.rooms r
where r.id = (select id from target_room)

union all

select 'GAME_SESSIONS (all, this room)',
  coalesce(string_agg(
    format(
      'id=%s game_type=%s status=%s lifecycle_state=%s started_at=%s ended_at=%s paused_at=%s player_ids=%s pack_id=%s',
      gs.id, gs.game_type, gs.status, coalesce(gs.lifecycle_state, 'NULL'), gs.started_at,
      coalesce(gs.ended_at::text, 'NULL'), coalesce(gs.paused_at::text, 'NULL'),
      gs.player_ids, coalesce(gs.pack_id::text, 'NULL')
    ), E'\n' order by gs.started_at desc
  ), 'NO SESSIONS FOUND FOR THIS ROOM')
from public.game_sessions gs
where gs.room_id = (select id from target_room)

union all

select 'ACTIVE_OR_PAUSED_SESSIONS_ONLY (should be exactly 0 or 1 row — this is the crux of the bug if it shows the WRONG game_type)',
  coalesce(string_agg(
    format('id=%s game_type=%s status=%s started_at=%s', gs.id, gs.game_type, gs.status, gs.started_at),
    E'\n'
  ), 'NONE — no active/paused session for this room right now')
from public.game_sessions gs
where gs.room_id = (select id from target_room)
  and gs.status in ('active', 'paused')

union all

select 'ROOM_PLAYED_PACKS (this room)',
  coalesce(string_agg(
    format('pack_id=%s played_at=%s', rpp.pack_id, rpp.played_at),
    E'\n' order by rpp.played_at desc
  ), 'NONE')
from public.room_played_packs rpp
where rpp.room_id = (select id from target_room)

union all

select 'ROOM_MEMBERS (this room, currently present)',
  coalesce(string_agg(
    format('user_id=%s role=%s is_ready=%s is_away=%s left_at=%s', rm.user_id, rm.role, rm.is_ready, rm.is_away, coalesce(rm.left_at::text,'NULL')),
    E'\n'
  ), 'NONE')
from public.room_members rm
where rm.room_id = (select id from target_room) and rm.left_at is null

order by section;
