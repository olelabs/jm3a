-- ============================================================================
-- Run this ENTIRE file as ONE query in the Supabase SQL Editor.
--
-- The previous version of this file was a sequence of separate SELECT
-- statements — the SQL Editor only returns the result of the LAST one when
-- you run multiple statements together, which is why the only output was
-- `count: 86` (that was query 9, `select count(*) from room_played_packs`;
-- everything before it was silently discarded, not because it failed).
--
-- This version is a single query: every check is UNION ALL'd together into
-- one result set with a `section` column to group by and a `detail` column
-- (text) holding the answer, so one execution returns everything at once.
-- Paste the FULL result table back (all rows, all sections).
-- ============================================================================

with

lifecycle_column as (
  select coalesce(
    string_agg(
      format('exists=true type=%s default=%s nullable=%s', data_type, coalesce(column_default, 'NULL'), is_nullable),
      E'\n'
    ),
    'COLUMN DOES NOT EXIST'
  ) as detail
  from information_schema.columns
  where table_schema = 'public' and table_name = 'game_sessions' and column_name = 'lifecycle_state'
),

fn_recover_owner_room as (
  select coalesce(
    string_agg(pg_get_functiondef(p.oid), E'\n\n---\n\n'),
    'FUNCTION DOES NOT EXIST'
  ) as detail
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'recover_owner_room'
),

fn_pause_game_if_owner_absent as (
  select coalesce(
    string_agg(pg_get_functiondef(p.oid), E'\n\n---\n\n'),
    'FUNCTION DOES NOT EXIST'
  ) as detail
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'pause_game_if_owner_absent'
),

fn_force_end_game_if_owner_absent as (
  select coalesce(
    string_agg(pg_get_functiondef(p.oid), E'\n\n---\n\n'),
    'FUNCTION DOES NOT EXIST'
  ) as detail
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'force_end_game_if_owner_absent'
),

fn_activate_game_session as (
  select coalesce(
    string_agg(pg_get_functiondef(p.oid), E'\n\n---\n\n'),
    'FUNCTION DOES NOT EXIST'
  ) as detail
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'activate_game_session'
),

fn_confirm_game_session_ready as (
  select coalesce(
    string_agg(pg_get_functiondef(p.oid), E'\n\n---\n\n'),
    'FUNCTION DOES NOT EXIST'
  ) as detail
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'confirm_game_session_ready'
),

fn_create_game_session as (
  select coalesce(
    string_agg(pg_get_functiondef(p.oid), E'\n\n---\n\n'),
    'FUNCTION DOES NOT EXIST'
  ) as detail
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'create_game_session'
),

fn_start_game_session_checks as (
  select coalesce(
    string_agg(pg_get_functiondef(p.oid), E'\n\n---\n\n'),
    'FUNCTION DOES NOT EXIST'
  ) as detail
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'start_game_session_checks'
),

fn_request_game_rejoin as (
  select coalesce(
    string_agg(pg_get_functiondef(p.oid), E'\n\n---\n\n'),
    'FUNCTION DOES NOT EXIST'
  ) as detail
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'request_game_rejoin'
),

fn_decide_game_rejoin_request as (
  select coalesce(
    string_agg(pg_get_functiondef(p.oid), E'\n\n---\n\n'),
    'FUNCTION DOES NOT EXIST'
  ) as detail
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'decide_game_rejoin_request'
),

fn_close_room as (
  select coalesce(
    string_agg(pg_get_functiondef(p.oid), E'\n\n---\n\n'),
    'FUNCTION DOES NOT EXIST'
  ) as detail
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'close_room'
),

duplicate_active_sessions as (
  select coalesce(
    string_agg(
      format('room_id=%s session_id=%s status=%s started_at=%s', room_id, id, status, started_at),
      E'\n' order by room_id, started_at desc
    ),
    'NONE — no room has more than one active/paused session'
  ) as detail
  from public.game_sessions
  where status in ('active', 'paused')
    and room_id in (
      select room_id from public.game_sessions
      where status in ('active', 'paused')
      group by room_id having count(*) > 1
    )
),

all_active_paused_sessions as (
  select coalesce(
    string_agg(
      format('room_id=%s session_id=%s status=%s lifecycle_state=%s paused_at=%s started_at=%s',
             room_id, id, status, coalesce(lifecycle_state, 'NULL'), coalesce(paused_at::text, 'NULL'), started_at),
      E'\n' order by started_at desc
    ),
    'NONE — no active/paused sessions currently exist'
  ) as detail
  from public.game_sessions
  where status in ('active', 'paused')
),

lifecycle_state_counts as (
  select coalesce(
    string_agg(format('lifecycle_state=%s count=%s', coalesce(lifecycle_state, 'NULL'), cnt), E'\n' order by cnt desc),
    'NO ROWS in game_sessions at all'
  ) as detail
  from (
    select lifecycle_state, count(*) as cnt
    from public.game_sessions
    group by lifecycle_state
  ) t
),

status_counts as (
  select coalesce(
    string_agg(format('status=%s count=%s', status, cnt), E'\n' order by cnt desc),
    'NO ROWS in game_sessions at all'
  ) as detail
  from (
    select status, count(*) as cnt
    from public.game_sessions
    group by status
  ) t
),

game_sessions_indexes as (
  select coalesce(
    string_agg(format('%s: %s', indexname, indexdef), E'\n' order by indexname),
    'NO INDEXES FOUND'
  ) as detail
  from pg_indexes
  where schemaname = 'public' and tablename = 'game_sessions'
),

function_grants as (
  select coalesce(
    string_agg(
      format('%s | %s | can_execute=%s', p.proname, r.rolname, has_function_privilege(r.rolname, p.oid, 'EXECUTE')),
      E'\n' order by p.proname, r.rolname
    ),
    'NO MATCHING FUNCTIONS FOUND'
  ) as detail
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  cross join (values ('anon'), ('authenticated'), ('service_role')) as r(rolname)
  where n.nspname = 'public'
    and p.proname in (
      'recover_owner_room', 'pause_game_if_owner_absent', 'activate_game_session',
      'create_game_session', 'request_game_rejoin'
    )
),

room_played_packs_count as (
  select format('total_rows=%s', count(*)) as detail
  from public.room_played_packs
)

select '01_LIFECYCLE_STATE_COLUMN' as section, detail from lifecycle_column
union all
select '02_RECOVER_OWNER_ROOM_FUNCTION', detail from fn_recover_owner_room
union all
select '03_PAUSE_GAME_IF_OWNER_ABSENT_FUNCTION', detail from fn_pause_game_if_owner_absent
union all
select '04_FORCE_END_GAME_IF_OWNER_ABSENT_FUNCTION', detail from fn_force_end_game_if_owner_absent
union all
select '05_ACTIVATE_GAME_SESSION_FUNCTION', detail from fn_activate_game_session
union all
select '06_CONFIRM_GAME_SESSION_READY_FUNCTION', detail from fn_confirm_game_session_ready
union all
select '07_CREATE_GAME_SESSION_FUNCTION', detail from fn_create_game_session
union all
select '08_START_GAME_SESSION_CHECKS_FUNCTION', detail from fn_start_game_session_checks
union all
select '09_REQUEST_GAME_REJOIN_FUNCTION', detail from fn_request_game_rejoin
union all
select '10_DECIDE_GAME_REJOIN_REQUEST_FUNCTION', detail from fn_decide_game_rejoin_request
union all
select '11_CLOSE_ROOM_FUNCTION', detail from fn_close_room
union all
select '12_DUPLICATE_ACTIVE_SESSIONS', detail from duplicate_active_sessions
union all
select '13_ALL_ACTIVE_PAUSED_SESSIONS', detail from all_active_paused_sessions
union all
select '14_LIFECYCLE_STATE_VALUE_COUNTS', detail from lifecycle_state_counts
union all
select '15_STATUS_VALUE_COUNTS', detail from status_counts
union all
select '16_GAME_SESSIONS_INDEXES', detail from game_sessions_indexes
union all
select '17_FUNCTION_GRANTS', detail from function_grants
union all
select '18_ROOM_PLAYED_PACKS_ROW_COUNT', detail from room_played_packs_count

order by section;
