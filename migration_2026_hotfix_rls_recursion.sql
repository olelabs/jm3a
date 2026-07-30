-- ============================================================================
-- HOTFIX: infinite recursion in "room_members: read" RLS policy
-- ============================================================================
-- Symptom: PostgrestException 42P17 "infinite recursion detected in policy
-- for relation room_members" on every getPublicRooms / room list query.
--
-- Root cause: this policy pre-dates this session's audit and was inert while
-- RLS was OFF on room_members. migration_2026_audit_fixes.sql (Section 1)
-- correctly turned RLS on for room_members, which activated this policy for
-- the first time -- and it contains a raw, un-wrapped subquery against
-- room_members from inside a policy defined ON room_members. Postgres has to
-- re-run the same policy to evaluate that subquery, which recurses forever.
--
-- Fix: move the "is this user an active player/moderator/owner of this room"
-- check into a SECURITY DEFINER helper function (same proven pattern already
-- used by is_room_member/is_room_moderator/is_room_owner elsewhere in this
-- schema) so the internal lookup bypasses RLS instead of re-entering it.
--
-- Safe to run multiple times. Apply this immediately -- it is a standalone
-- fix and does not depend on anything else being applied first.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."can_view_hidden_room_member"("p_room_id" "uuid", "p_user_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  select exists (
    select 1 from public.room_members "mod"
    where "mod"."room_id" = p_room_id
      and "mod"."user_id" = p_user_id
      and (
        "mod"."role" = any (array['player'::public.room_member_role_enum, 'moderator'::public.room_member_role_enum])
        or "mod"."user_id" = (select "rooms"."owner_id" from public.rooms where "rooms"."id" = p_room_id)
      )
      and "mod"."left_at" is null
  );
$$;

ALTER FUNCTION "public"."can_view_hidden_room_member"("p_room_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";

DROP POLICY IF EXISTS "room_members: read" ON "public"."room_members";

CREATE POLICY "room_members: read" ON "public"."room_members" FOR SELECT USING ((("user_id" = "auth"."uid"()) OR ("is_hidden_spectator" = false) OR "public"."can_view_hidden_room_member"("room_id", "auth"."uid"())));
