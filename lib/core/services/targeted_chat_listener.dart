import 'package:supabase_flutter/supabase_flutter.dart';

/// Item 2 — Premium Plus targeted chat: secure realtime delivery for a
/// targeted (`audience_type = 'selected'`) message.
///
/// Deliberately NOT built on RealtimeService's broadcast channel — that
/// channel has no server-side authorization (see the migration's own
/// header comment for the full audit), so anything sent over it is
/// delivered to every subscriber regardless of intended audience. This
/// instead reuses the same secure pattern NotificationProvider already
/// uses for its own realtime delivery: Postgres Changes (CDC) on the
/// underlying table, which Supabase Realtime evaluates against the
/// SUBSCRIBING user's RLS — a row a user's RLS policy wouldn't let them
/// SELECT is also never delivered to them as a CDC event. The
/// `room_chat: member read` RLS policy is what actually enforces
/// audience privacy here, not this class.
///
/// Every "everyone"-mode chat message (lobby or game) is completely
/// unaffected — this listener only ever surfaces newly-INSERTed rows,
/// and only 'selected'-audience (or, for lobby, any) rows are ever
/// persisted for a client to receive this way; ordinary "everyone" game
/// chat stays exactly as it was: broadcast-only, never touching this
/// table or this listener.
class TargetedChatListener {
  RealtimeChannel? _channel;

  /// Starts listening for new `room_chat_messages` rows in [roomId].
  /// [onInsert] receives the raw inserted row (no joined profile data —
  /// CDC only ever carries the changed table's own columns) whenever one
  /// arrives that this user's RLS allows them to see. Call [stop] (or
  /// just call [start] again) before disposal / when leaving the room.
  void start({
    required String roomId,
    required void Function(Map<String, dynamic> row) onInsert,
  }) {
    stop();
    _channel = Supabase.instance.client
        .channel('room-chat-cdc-$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'room_chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }

  void stop() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
