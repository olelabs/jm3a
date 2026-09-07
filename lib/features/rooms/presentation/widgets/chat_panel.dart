import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jma3a/shared/widgets/cards/permium_badge.dart';
import 'package:provider/provider.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../../../shared/widgets/chat/chat_audience_picker.dart';
import '../../../../shared/widgets/game/game_chat_sheet.dart'
    show SwipeToReplyBubble;
import '../../domain/room_entity.dart';
import '../room_provider.dart';

const _kChatColors = [
  Color(0xFF4ECDC4),
  Color(0xFFA855F7),
  Color(0xFFFF6B6B),
  Color(0xFF4ADE80),
  Color(0xFFFB923C),
  Color(0xFF60A5FA),
  Color(0xFFF472B6),
  Color(0xFFFFD60A),
  Color(0xFF34D399),
  Color(0xFFC084FC),
];

Color _userColor(String userId) =>
    _kChatColors[userId.hashCode.abs() % _kChatColors.length];

class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key, required this.room});
  final RoomProvider room;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  bool _showScrollDown = false;
  bool _sendAnonymous = false;

  // Item 6 — reply-to-message. ChatMessageEntity/RoomProvider.sendChatMessage
  // already fully supported a reply reference before this change (replyToId/
  // replyToContent/replyToDisplayName, persisted via
  // RoomRepository.persistChatMessage); only the swipe gesture + preview UI
  // was missing here, which is all this adds.
  ChatMessageEntity? _replyTo;
  final Map<String, GlobalKey> _bubbleKeys = {};
  String? _highlightedId;

  bool get _isPremium =>
      context.read<AuthProvider>().currentUser?.isPremiumActive ?? false;

  // Item 2 — Premium Plus targeted chat. Distinct from _isPremium above
  // (plain Premium already gates anonymous sending) — targeting is a
  // Premium Plus-only capability. Server-side enforcement lives in
  // send_targeted_chat_message() regardless of this gate; this only
  // controls whether the picker UI is ever shown at all, per item 2's
  // "do not expose hidden targeting controls" requirement.
  bool get _isPremiumPlus =>
      context.read<AuthProvider>().currentUser?.isPremiumPlusActive ?? false;

  ChatAudienceSelection _audience = const ChatAudienceSelection.everyone();

  @override
  void initState() {
    super.initState();
    widget.room.addListener(_onMessages);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.room.removeListener(_onMessages);
    _scrollCtrl.removeListener(_onScroll);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onMessages() {
    if (!_showScrollDown) _scrollToBottom();
  }

  void _onScroll() {
    final atBottom =
        _scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 80;
    if (atBottom != !_showScrollDown) {
      setState(() => _showScrollDown = !atBottom);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      if (animated) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final replyTo = _replyTo;
    final targeted = _isPremiumPlus && !_audience.isEveryone;

    final ok = targeted
        ? await widget.room.sendTargetedMessage(
            content: text,
            recipientIds: _audience.recipientIds,
            recipientNames: _audience.recipientNames,
            replyTo: replyTo,
          )
        : await widget.room.sendChatMessage(
            text,
            anonymous: _sendAnonymous,
            replyTo: replyTo,
          );
    if (!mounted) return;
    if (ok) {
      // Item 7 — only clear the composer/close the keyboard AFTER a
      // confirmed successful send. The audience choice resets to
      // Everyone after a successful send (item 2's own mockup shows it as
      // a per-message choice, not a sticky mode) — a targeted send is a
      // deliberate one-off action, and resetting avoids a user
      // accidentally leaving a LATER, meant-to-be-public message
      // silently restricted to a stale audience.
      _ctrl.clear();
      setState(() {
        _replyTo = null;
        _audience = const ChatAudienceSelection.everyone();
      });
      _focusNode.unfocus();
      _scrollToBottom();
    } else {
      // Never silently discard the draft — keep the text and focus so the
      // user can just retry.
      final failure = widget.room.failure;
      final message = targeted
          ? _targetedFailureMessage(context, failure)
          : context.l10n.chatSendFailed;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _targetedFailureMessage(BuildContext context, Failure? failure) {
    final l10n = context.l10n;
    return switch (failure) {
      ForbiddenFailure(:final message) when message.contains('Premium Plus') =>
        l10n.chatAudienceRequiresPremiumPlus,
      ForbiddenFailure() => l10n.chatAudienceNoLongerRoomMember,
      ValidationFailure() => l10n.chatAudienceRecipientUnavailable,
      _ => l10n.chatSendFailed,
    };
  }

  Future<void> _openAudiencePicker() async {
    final room = widget.room;
    final myId = room.currentMember?.userId;
    final candidates = room.members
        .where((m) => m.userId != myId && !m.leftDefinitively)
        .toList();
    final result = await showChatAudiencePickerSheet(
      context,
      candidates: candidates,
      current: _audience,
    );
    if (result != null && mounted) setState(() => _audience = result);
  }

  void _startReply(ChatMessageEntity msg) {
    setState(() => _replyTo = msg);
    _focusNode.requestFocus();
  }

  void _cancelReply() => setState(() => _replyTo = null);

  void _scrollToAndHighlight(String targetId) {
    final key = _bubbleKeys[targetId];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: 0.5,
    );
    setState(() => _highlightedId = targetId);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _highlightedId == targetId) {
        setState(() => _highlightedId = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final l10n = context.l10n;
    final theme = context.theme;
    final isMuted = room.isCurrentUserMuted;
    final chatOff = !room.settings.chatEnabled;

    return SizedBox.expand(
      child: Column(
        children: [
          if (chatOff)
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.voice_over_off_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.chatDisabledForRoom,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: Stack(
              children: [
                room.chatMessages.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n.chatNoMessagesYet,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        itemCount: room.chatMessages.length,
                        itemBuilder: (_, i) {
                          final msg = room.chatMessages[i];
                          final isMe = msg.userId == room.currentMember?.userId;
                          final key = _bubbleKeys.putIfAbsent(
                            msg.id,
                            () => GlobalKey(),
                          );
                          return SwipeToReplyBubble(
                            key: key,
                            highlighted: msg.id == _highlightedId,
                            onSwipeReply: msg.isSystem
                                ? () {}
                                : () => _startReply(msg),
                            child:
                                _ChatBubble(
                                      message: msg,
                                      isMe: isMe,
                                      showAvatar:
                                          i == 0 ||
                                          room.chatMessages[i - 1].userId !=
                                              msg.userId,
                                      onTapReplyPreview: msg.replyToId == null
                                          ? null
                                          : () => _scrollToAndHighlight(
                                              msg.replyToId!,
                                            ),
                                    )
                                    .animate(delay: 20.ms)
                                    .fadeIn()
                                    .slideY(begin: 0.05, end: 0),
                          );
                        },
                      ),

                if (_showScrollDown)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'scroll_down',
                      onPressed: _scrollToBottom,
                      child: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ),
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.viewInsetsOf(context).bottom + 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Item 2 — never rendered at all for a non-Premium-Plus
                // sender (no hidden/disabled control, per the task's own
                // requirement), and only while chat is actually usable.
                if (_isPremiumPlus && !isMuted && !chatOff)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ChatAudienceTrigger(
                        selection: _audience,
                        onTap: _openAudiencePicker,
                      ),
                    ),
                  ),
                if (_replyTo != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border(
                        left: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.l10n.chatReplyingTo(
                                  _replyTo!.isAnonymous
                                      ? context.l10n.roomsAnonymousSender
                                      : _replyTo!.displayName,
                                ),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _replyTo!.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: _cancelReply,
                          tooltip: context.l10n.chatCancelReply,
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        enabled: !isMuted && !chatOff,
                        maxLength: 500,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: isMuted
                              ? l10n.chatMuted
                              : chatOff
                              ? l10n.roomsChatDisabled
                              : _sendAnonymous
                              ? l10n.roomsMessageAsAnonymous
                              : l10n.chatPlaceholder,
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: _sendAnonymous
                              ? Colors.purple.shade50
                              : theme.colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    if (_isPremium) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: _sendAnonymous
                            ? l10n.roomsAnonymousModeOn
                            : l10n.roomsSendAnonymouslyPremium,
                        child: IconButton(
                          icon: Icon(
                            _sendAnonymous
                                ? Icons.person_off_rounded
                                : Icons.person_outline_rounded,
                            color: _sendAnonymous
                                ? Colors.purple
                                : theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _sendAnonymous = !_sendAnonymous),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    _SendButton(
                      onSend: _send,
                      isSending: room.isSendingChat,
                      isDisabled: isMuted || chatOff,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.isMe,
    this.showAvatar = true,
    this.onTapReplyPreview,
  });

  final ChatMessageEntity message;
  final bool isMe;
  final bool showAvatar;

  /// Item 6 — tapping the quoted reply preview inside this message scrolls
  /// to and briefly highlights the original. Null when this message isn't
  /// a reply.
  final VoidCallback? onTapReplyPreview;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe && showAvatar) ...[
            UserAvatar(
              avatarUrl: message.avatarUrl,
              displayName: message.displayName,
              size: 26,
            ),
            const SizedBox(width: 6),
          ] else if (!isMe)
            const SizedBox(width: 32),

          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.isAnonymous)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.person_off_rounded,
                              size: 11,
                              color: Colors.purple,
                            ),
                          ),
                        Text(
                          message.isAnonymous
                              ? context.l10n.roomsAnonymousSender
                              : message.displayName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: message.isAnonymous
                                ? Colors.purple
                                : _userColor(message.userId),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (message.senderIsPremium &&
                            !message.isAnonymous) ...[
                          const SizedBox(width: 3),
                          PremiumBadge(
                            size: 10,
                            tier: message.senderPremiumTier,
                          ),
                        ],
                      ],
                    ),
                  ),
                Opacity(
                  opacity: message.isOptimistic ? 0.65 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? theme.colorScheme.primary
                          : message.isAnonymous
                          ? Colors.purple.withOpacity(0.12)
                          : _userColor(message.userId).withOpacity(0.18),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(isMe ? 14 : 3),
                        bottomRight: Radius.circular(isMe ? 3 : 14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.replyToId != null)
                          GestureDetector(
                            onTap: onTapReplyPreview,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isMe
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface)
                                        .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(
                                    color: isMe
                                        ? theme.colorScheme.onPrimary
                                        : _userColor(message.userId),
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                '${message.replyToDisplayName ?? ''}: '
                                '${message.replyToContent ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color:
                                      (isMe
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface)
                                          .withValues(alpha: 0.75),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                        Text(
                          message.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isMe
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Item 2 — targeted-message indicator. The SENDER
                        // sees exactly who it went to (they already chose
                        // the audience); a RECIPIENT sees only that it was
                        // private, never the other recipients — matches
                        // "do not reveal unintended recipient information".
                        if (message.isTargeted) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_person_rounded,
                                size: 11,
                                color:
                                    (isMe
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface)
                                        .withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  isMe && message.recipientNames.isNotEmpty
                                      ? context.l10n.chatTargetedIndicatorSender(
                                          message.recipientNames.join(', '),
                                        )
                                      : context.l10n.chatTargetedIndicatorRecipient,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        (isMe
                                                ? theme.colorScheme.onPrimary
                                                : theme.colorScheme.onSurface)
                                            .withValues(alpha: 0.7),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.onSend,
    required this.isSending,
    required this.isDisabled,
  });

  final VoidCallback onSend;
  final bool isSending;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final active = !isSending && !isDisabled;
    return GestureDetector(
      onTap: active ? onSend : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active
              ? context.colorScheme.primary
              : context.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: isSending
            ? const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : Icon(
                Icons.send_rounded,
                size: 18,
                color: active
                    ? Colors.white
                    : context.colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}
