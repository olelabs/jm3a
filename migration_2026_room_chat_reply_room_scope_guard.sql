-- Real-device bug: replying to a lobby chat message always failed
-- ("Failed, try sending a message again"). Root cause (fixed client-side
-- in RoomRepository.persistChatMessage / RoomProvider.sendChatMessage):
-- the client generates its own message id up front (used for the
-- optimistic local entry AND the realtime broadcast payload — see
-- RoomProvider._handleChatBroadcast, which builds every received
-- message's ChatMessageEntity.id straight from the broadcast's 'id'
-- field), but the INSERT into room_chat_messages never actually supplied
-- that id, letting the column's own DEFAULT gen_random_uuid() assign a
-- DIFFERENT id to the persisted row. Every client that received a
-- message live (the normal case for anything currently on screen) held
-- it locally under an id that did not match its real database row, so
-- swiping to reply to ANY such message sent reply_to_id = that
-- non-existent id — violating room_chat_messages_reply_to_id_fkey on
-- every single reply. Fixed by writing 'id' explicitly on insert, so
-- client id == broadcast id == database id, unconditionally.
--
-- This migration is the belt-and-suspenders DB-side half: the original
-- reply_to_id foreign key only checked that the referenced id existed
-- ANYWHERE in room_chat_messages — not that it belonged to the SAME room
-- as the message referencing it. A client that (accidentally or by
-- tampering with the request) supplied a reply_to_id belonging to a
-- message in a different room would have passed that check. Adds a
-- trigger enforcing same-room membership for reply_to_id, independent of
-- and in addition to the existing single-column foreign key (left
-- untouched — this is purely additive, no existing constraint is
-- dropped/recreated).

BEGIN;

CREATE OR REPLACE FUNCTION "public"."enforce_room_chat_reply_same_room"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF NEW.reply_to_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM "public"."room_chat_messages"
      WHERE "id" = NEW.reply_to_id AND "room_id" = NEW.room_id
    ) THEN
      RAISE EXCEPTION 'reply_to_id % does not belong to room %', NEW.reply_to_id, NEW.room_id
        USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS "trg_room_chat_reply_same_room" ON "public"."room_chat_messages";

CREATE TRIGGER "trg_room_chat_reply_same_room"
  BEFORE INSERT OR UPDATE OF "reply_to_id", "room_id" ON "public"."room_chat_messages"
  FOR EACH ROW
  EXECUTE FUNCTION "public"."enforce_room_chat_reply_same_room"();

COMMIT;
