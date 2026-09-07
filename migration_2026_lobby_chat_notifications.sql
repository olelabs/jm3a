-- Item 5: a normal in-app notification for other room members when
-- someone sends a lobby chat message (room_chat_messages) — reusing the
-- EXISTING notification pipeline end-to-end:
--   - the existing public.send_notification(...) RPC (already used by
--     every other notification type — checks notification_preferences.
--     in_app before inserting, so per-type opt-out keeps working for free)
--   - the existing public.notifications table / notification_type_enum
--   - the existing client-side NotificationProvider CDC subscription
--     (notification_provider.dart), which picks up the new row exactly
--     like every other type
--
-- No second notification system. The "already viewing this room's chat"
-- suppression (never show a redundant notification for a room the
-- recipient currently has open on the chat tab) is a CLIENT-side concern
-- (the DB has no notion of which screen/tab a device is currently
-- showing) — see NotificationProvider.setActiveChatRoom /
-- notification_provider.dart's CDC handler for that half.
--
-- The sender never gets their own message's notification (excluded by
-- the recipient query below). An anonymous message's notification never
-- reveals the real sender's name (mirrors the client's own
-- roomsAnonymousSender treatment).

BEGIN;

ALTER TYPE "public"."notification_type_enum" ADD VALUE IF NOT EXISTS 'room_chat_message';

COMMIT;

-- ADD VALUE cannot run in the same transaction it's used in, so the
-- function referencing it is created in a second transaction.
BEGIN;

CREATE OR REPLACE FUNCTION "public"."notify_room_chat_message"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_sender_name text;
  v_snippet text;
  v_title jsonb;
  v_recipient record;
BEGIN
  -- System messages ("X joined", etc.) and soft-deleted rows never
  -- generate a chat notification.
  IF NEW.is_system OR NEW.is_deleted THEN
    RETURN NEW;
  END IF;

  IF NEW.is_anonymous THEN
    v_sender_name := 'Anonymous';
  ELSE
    SELECT COALESCE(display_name, username, 'Player') INTO v_sender_name
    FROM public.profiles WHERE id = NEW.user_id;
  END IF;

  v_snippet := CASE
    WHEN char_length(NEW.content) > 120 THEN left(NEW.content, 120) || '…'
    ELSE NEW.content
  END;
  v_title := jsonb_build_object('en', v_sender_name);

  FOR v_recipient IN
    SELECT user_id FROM public.room_members
    WHERE room_id = NEW.room_id
      AND left_at IS NULL
      AND user_id <> NEW.user_id
  LOOP
    PERFORM public.send_notification(
      v_recipient.user_id,
      'room_chat_message'::public.notification_type_enum,
      v_title,
      jsonb_build_object('en', v_snippet),
      jsonb_build_object(
        'room_id', NEW.room_id,
        'message_id', NEW.id,
        'sender_id', NEW.user_id
      )
    );
  END LOOP;

  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."notify_room_chat_message"() OWNER TO "postgres";

CREATE OR REPLACE TRIGGER "trg_room_chat_messages_notify" AFTER INSERT ON "public"."room_chat_messages" FOR EACH ROW EXECUTE FUNCTION "public"."notify_room_chat_message"();

COMMIT;
