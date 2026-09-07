import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../features/rooms/domain/room_entity.dart' show RoomMemberEntity;
import '../cards/permium_badge.dart';
import '../cards/user_avatar.dart';
import '../chat/chat_audience_picker.dart';

/// Shared in-game chat message model. Originally ToD's own `TodChatMsg` —
/// generalized here (item 4) so NHIE and Meme can reuse the exact same
/// model, sheet UI, and reply mechanics instead of each growing their own.
/// `tod_game_provider.dart` keeps `TodChatMsg` as a type alias of this
/// class, so every existing ToD call site is untouched.
///
/// [id]/[replyToId]/[replyToSenderName]/[replyToText] are new, OPTIONAL
/// fields added for item 6 (reply-to-message) — every existing message
/// (ToD's included) that doesn't set them keeps working exactly as before;
/// they're simply null (an ordinary, non-reply message).
class GameChatMsg {
  const GameChatMsg({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.ts,
    String? id,
    this.replyToId,
    this.replyToSenderName,
    this.replyToText,
    this.audienceType = 'everyone',
    this.recipientNames = const [],
  }) : id = id ?? _noId;

  final String senderId;
  final String senderName;
  final String text;
  final DateTime ts;

  /// Item 2 — Premium Plus targeted chat. 'everyone' for every existing
  /// message; 'selected' only for a targeted message delivered via the
  /// RLS-gated CDC listener, never via the plain broadcast fan-out.
  final String audienceType;

  /// Display names of the selected recipients — sender-side only, for the
  /// "Only visible to: X, Y" indicator. Never populated for a message
  /// this user didn't send.
  final List<String> recipientNames;

  bool get isTargeted => audienceType == 'selected';

  /// Stable per-message id. Falls back to a sentinel when the sender
  /// didn't supply one (e.g. an older client/build) — reply-to-lookup and
  /// tap-to-scroll simply won't resolve for such a message, everything
  /// else about it still works.
  final String id;
  static const _noId = '';

  /// Set only when this message is a reply. [replyToText]/[replyToSenderName]
  /// are a compact SNAPSHOT of the original at reply time (so the preview
  /// still renders correctly even if the original later scrolls out of the
  /// locally-held history) — [replyToId] is what tap-to-scroll/highlight
  /// resolves against the current message list.
  final String? replyToId;
  final String? replyToSenderName;
  final String? replyToText;

  bool get isReply => replyToId != null && replyToId!.isNotEmpty;
}

// ToD's original per-sender color palette (unchanged) — kept as the one
// shared palette so consolidating onto GameChatSheet doesn't change ToD's
// existing chat's visual output.
const kGameChatColors = [
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

/// Shared in-game chat bottom sheet (item 4) — the exact UI ToD's game
/// chat already used, generalized to take its data/callbacks as
/// parameters instead of a concrete `TodGameProvider`, so NHIE and Meme
/// can present the identical experience over their own provider's chat
/// state. Adds (item 6) swipe-to-reply with a cancellable compact preview
/// and tap-to-scroll/highlight on a quoted reply, (item 7) closes the
/// keyboard only after a successful send while preserving the draft on
/// failure, and (items 18.7-18.9) expands as a draggable panel that grows
/// to make room the moment the keyboard opens.
class GameChatSheet extends StatefulWidget {
  const GameChatSheet({
    super.key,
    required this.listenable,
    required this.messagesOf,
    required this.myId,
    required this.title,
    required this.onSend,
    this.memberOf,
    this.isPremiumPlus = false,
    this.participants = const [],
    this.onSendTargeted,
  });

  /// Rebuilds this sheet whenever new messages arrive (mirrors the
  /// `ListenableBuilder(listenable: widget.game, ...)` pattern the ToD
  /// sheet already used — typically the owning game provider itself).
  final Listenable listenable;
  final List<GameChatMsg> Function() messagesOf;
  final String myId;
  final String title;

  /// Returns true on success (the composer clears and the keyboard
  /// closes), false on failure (the composer/keyboard are left exactly as
  /// the user had them, so they can retry without retyping).
  final Future<bool> Function(String text, {GameChatMsg? replyTo}) onSend;

  /// Resolves a message's sender to the room's own member record — the
  /// SAME data (avatarUrl/avatarConfig/isPremium) every other in-game
  /// avatar already reads (e.g. reaction avatars), reused here rather
  /// than inventing a second identity source. Typically
  /// `roomProvider.memberById` passed straight through from the game
  /// screen. Null (the default) means "no avatar data available" — the
  /// message still renders exactly as before, just without an avatar,
  /// so nothing breaks for a caller that doesn't pass this.
  final RoomMemberEntity? Function(String senderId)? memberOf;

  /// Item 2 — Premium Plus targeted chat. Defaults (false/empty/null)
  /// mean the audience picker never renders at all — every existing
  /// GameChatSheet call site keeps working exactly as before with zero
  /// changes required.
  final bool isPremiumPlus;

  /// Current game participants eligible to be targeted (already excluding
  /// the sender and anyone who left — the caller's job, same contract as
  /// [memberOf]).
  final List<RoomMemberEntity> participants;

  /// Only called when the audience picker actually selected specific
  /// people. Null (the default) means targeting is unavailable for this
  /// caller even if [isPremiumPlus] is true.
  final Future<bool> Function(
    String text, {
    required List<String> recipientIds,
    required List<String> recipientNames,
    GameChatMsg? replyTo,
  })?
  onSendTargeted;

  @override
  State<GameChatSheet> createState() => _GameChatSheetState();
}

class _GameChatSheetState extends State<GameChatSheet>
    with WidgetsBindingObserver {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  final _sheetController = DraggableScrollableController();
  final Map<String, GlobalKey> _bubbleKeys = {};
  GameChatMsg? _replyTo;
  String? _highlightedId;
  bool _sending = false;
  ChatAudienceSelection _audience = const ChatAudienceSelection.everyone();

  // Item 9 root-cause fix: this used to be a FIXED 0.92 (matching the
  // room settings sheet's own constant) — which is genuinely a hard
  // ceiling DraggableScrollableSheet enforces, not just a snap target; the
  // user physically cannot drag past maxChildSize no matter how far they
  // pull. 0.92 of the FULL screen height (showModalBottomSheet's
  // isScrollControlled:true + the default useSafeArea:false already give
  // this widget the entire screen height to size itself against — no
  // ancestor Scaffold/SafeArea/BottomSheetThemeData.constraints was found
  // trimming that; see app_theme.dart's bottomSheetTheme, which sets no
  // `constraints` at all) simply wasn't the "~95%, drag to the top"
  // ceiling this item asks for. Recomputed per-build from the actual
  // device's top safe-area inset so the sheet can get close to the true
  // top of the screen without ever drawing OVER the status bar/notch.
  //
  // Real-device follow-up: this used to only be the DRAG CEILING, with
  // the sheet OPENING at a much smaller `_collapsedSize` (0.55) and only
  // animating up to this once the keyboard opened. That's exactly the
  // "opens at 55%" bug — a game chat should open fully expanded
  // immediately, matching this widget's own name. `_collapsedSize` is
  // gone; `_maxSize` is now also `initialChildSize` and the sheet's only
  // snap target. `_minSize` remains purely as how far a user can drag
  // the sheet DOWN before [_handleSheetExtent] treats it as "close the
  // sheet" (see build()'s NotificationListener) — not a resting state of
  // its own.
  static const _minSize = 0.35;
  double _maxSize(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    if (screenHeight <= 0) return 0.95;
    final topInsetFraction = MediaQuery.paddingOf(context).top / screenHeight;
    return (0.97 - topInsetFraction).clamp(0.80, 0.97);
  }

  double _lastBottomInsetPx = 0;
  ScrollController? _activeScrollController;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    // Item 18.7 — WidgetsBindingObserver.didChangeMetrics fires exactly
    // once per real OS keyboard show/hide transition, independent of
    // whatever else causes this widget to rebuild — a more reliable
    // signal than re-deriving "did the keyboard just open" from
    // MediaQuery inside build() (which reruns for other reasons too,
    // e.g. every incoming message via widget.listenable).
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    _focusNode.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    // Real-device follow-up root-cause fix: didChangeMetrics() fires
    // SYNCHRONOUSLY from WidgetsBinding.handleMetricsChanged(), before
    // any widget rebuild has happened — MediaQuery.viewInsetsOf(context)
    // reads whatever MediaQueryData the ancestor MediaQuery InheritedWidget
    // last built with, which at this exact moment is still the OLD
    // (pre-transition) value. That made this comparison a same-value
    // no-op on its very first call after a real metrics change, silently
    // skipping the auto-expand/auto-scroll below. View.of(context)
    // .viewInsets reads directly off the live FlutterView instead of a
    // cached InheritedWidget snapshot, so it's already current the
    // instant this callback runs (in physical pixels — divided by
    // devicePixelRatio to match the logical-pixel values used
    // everywhere else in this widget).
    final view = View.of(context);
    final bottomInsetPx = view.viewInsets.bottom / view.devicePixelRatio;
    if (bottomInsetPx == _lastBottomInsetPx) return;
    final wasOpen = _lastBottomInsetPx > 0;
    final isOpen = bottomInsetPx > 0;
    _lastBottomInsetPx = bottomInsetPx;
    if (isOpen == wasOpen) return; // still animating the same transition
    // Item 18.7 — grow the sheet the moment the keyboard starts opening.
    // The sheet already OPENS at _maxSize by default now (see build()),
    // so in the common case this is a no-op re-affirmation; it still
    // matters if the user had manually dragged the sheet down before
    // tapping the composer. Posted to the next frame — this callback runs
    // outside the normal build/layout phase, and
    // DraggableScrollableController requires the sheet to be attached
    // (laid out at least once) before animateTo is valid.
    //
    // Real-device follow-up: on CLOSE, this used to animate the sheet
    // back down to a fixed "collapsed" size — exactly the "weird jump"
    // this item asks to remove. The sheet now simply stays at whatever
    // size it's already at when the keyboard closes; nothing to restore.
    // Also scrolls to the latest message the moment the keyboard opens
    // (item D) — a one-time scroll, not a continuous lock, so normal
    // manual scrolling afterward is untouched.
    if (isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_sheetController.isAttached) return;
        _sheetController.animateTo(
          _maxSize(context),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Defense-in-depth (swipe-down-to-close red screen investigation):
      // this callback can fire on a frame after the sheet has already
      // been dismissed (e.g. keyboard-open scroll scheduled just before
      // the user also swiped the sheet closed) — `_activeScrollController`
      // is owned by DraggableScrollableSheet's own builder and gets
      // disposed along with it, so touching it post-dismissal would
      // throw "used after being disposed".
      if (!mounted) return;
      final scroll = _activeScrollController;
      if (scroll != null && scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    final replyTo = _replyTo;
    final targeted =
        widget.isPremiumPlus &&
        !_audience.isEveryone &&
        widget.onSendTargeted != null;
    final ok = targeted
        ? await widget.onSendTargeted!(
            t,
            recipientIds: _audience.recipientIds,
            recipientNames: _audience.recipientNames,
            replyTo: replyTo,
          )
        : await widget.onSend(t, replyTo: replyTo);
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _ctrl.clear();
      setState(() {
        _replyTo = null;
        // Item 2 — same reasoning as the lobby ChatPanel: a targeted send
        // is a deliberate one-off, so the picker resets to Everyone
        // rather than staying a sticky mode.
        _audience = const ChatAudienceSelection.everyone();
      });
      // Only unfocus AFTER a confirmed successful send — never dismiss the
      // keyboard preemptively, and never while the user is merely typing.
      _focusNode.unfocus();
      _scrollToBottom();
    } else {
      // Keep the composer text and focus so the user can just retry —
      // never silently discard what they wrote.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.chatSendFailed)));
      }
    }
  }

  Future<void> _openAudiencePicker() async {
    final result = await showChatAudiencePickerSheet(
      context,
      candidates: widget.participants,
      current: _audience,
    );
    if (result != null && mounted) setState(() => _audience = result);
  }

  void _startReply(GameChatMsg msg) {
    if (msg.id.isEmpty) return; // nothing stable to reference
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
    final maxSize = _maxSize(context);
    // Item B (real-device follow-up) root-cause fix: showModalBottomSheet
    // itself only offers drag-to-dismiss on its OWN direct child — a
    // DraggableScrollableSheet captures every vertical drag for its own
    // resizing instead, so that gesture never reaches the enclosing
    // BottomSheet's dismiss handling (isDismissible/enableDrag still
    // cover tap-outside-the-barrier and the system back gesture, both
    // untouched here). DraggableScrollableNotification fires continuously
    // during a drag (not just once it settles), so a drag that reaches
    // _minSize is treated as "the user wants to close" and pops the
    // route directly — no separate close button needed.
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        // Real-device root-cause fix (swipe-down-to-close red screen):
        // `mounted` first — a notification can still be IN FLIGHT
        // (dispatched by a ballistic/settle simulation) on the exact
        // frame this widget is being torn down; touching `context`/
        // scheduling work on an unmounted State is exactly the class of
        // bug this item asks to eliminate.
        if (!mounted || _closing) return false;
        if (notification.extent <= _minSize + 0.005) {
          _closing = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final route = ModalRoute.of(context);
            // isCurrent, not just canPop — guards against a double pop if
            // the user ALSO tapped the scrim barrier (or the system back
            // gesture) during the same drag; either dismissal path
            // reaching Navigator.pop() first makes this route no longer
            // "current", so the second one is a safe no-op instead of
            // popping whatever route happens to be under it next.
            if (route?.isCurrent == true && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        // Item A root-cause fix: this used to open at a fixed 0.55 —
        // "opens at 55%, jumps to full only once the keyboard appears".
        // A game chat sheet now opens fully expanded immediately.
        initialChildSize: maxSize,
        minChildSize: _minSize,
        maxChildSize: maxSize,
        expand: false,
        // Real-device root-cause fix (swipe-down-to-close red screen):
        // `snap: true` was NOT just a cosmetic "settle at a target size"
        // — checking the Flutter SDK source
        // (draggable_scrollable_sheet.dart's goBallistic()) shows it
        // starts its OWN AnimationController-driven ballistic/snap
        // simulation the instant the user lifts their finger, ticking
        // every frame via `context.notificationContext!` (a
        // force-unwrap). The SAME release gesture that crosses this
        // widget's own dismiss threshold also triggers that simulation
        // — so Navigator.pop() (removing this whole subtree) and the
        // sheet's own snap animation were racing every time the user
        // actually swiped down to close: once the subtree started being
        // torn down mid-pop, that ballistic tick's next frame found
        // notificationContext already null and crashed the null-check
        // operator. No snap target ever included "closed" anyway (only
        // maxSize did), so disabling snap only removes an animation that
        // was fighting this widget's own dismiss logic — the sheet still
        // tracks the drag directly and still settles via normal (safe,
        // non-snapping) scroll physics on release.
        snap: false,
        builder: (context, scrollController) {
          _activeScrollController = scrollController;
          return _buildSheetBody(context, scrollController);
        },
      ),
    );
  }

  Widget _buildSheetBody(
    BuildContext context,
    ScrollController scrollController,
  ) {
    // Item 5 (real-device follow-up) root-cause fix: the earlier "item
    // 18.8" comment below (composer padding) assumed
    // showModalBottomSheet(isScrollControlled: true) already shifts this
    // sheet's content up by the keyboard's height on its own. Checking
    // the actual Flutter SDK source (bottom_sheet.dart) disproves that:
    // isScrollControlled's own layout
    // (_RenderBottomSheetLayoutWithSizeListener) always anchors the
    // sheet's BOTTOM edge to the literal bottom of the screen and applies
    // no MediaQuery.viewInsets compensation anywhere in that chain —
    // useSafeArea:false (the default, used everywhere this sheet is
    // shown) only strips the TOP padding via MediaQuery.removePadding,
    // nothing about viewInsets. That means growing the sheet's height
    // fraction (maxChildSize) — this session's earlier fix for "doesn't
    // reach full height" — could never by itself keep the composer above
    // the keyboard: a taller sheet only reveals more message history
    // ABOVE, while its bottom edge (where the composer lives) stays
    // pinned to the physical screen bottom, directly behind the OS
    // keyboard overlay, no matter how tall the sheet grows. The fix is to
    // reserve exactly the keyboard's own height at the bottom of the
    // sheet's CONTENT so the composer sits just above it — animated so it
    // tracks the keyboard's own open/close transition smoothly instead of
    // jumping.
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A2E45),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.listenable,
                builder: (_, __) {
                  final msgs = widget.messagesOf();
                  if (msgs.isEmpty) {
                    return Center(
                      child: Text(
                        context.l10n.chatNoMessagesYet,
                        style: const TextStyle(color: Colors.white38),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final m = msgs[i];
                      final isMe = m.senderId == widget.myId;
                      // Item 1 (real-device follow-up) — the same room
                      // member data every other in-game avatar already
                      // reads (see e.g. the reaction avatars in
                      // Sticker.dart/meme_game_screen.dart's
                      // _ReactorReactionChip), not a second identity
                      // source. Null (no resolver passed, or sender not
                      // a current room member) simply means no avatar —
                      // handled below via UserAvatar's own initial-letter
                      // fallback.
                      final member = widget.memberOf?.call(m.senderId);
                      final color =
                          kGameChatColors[m.senderId.hashCode.abs() %
                              kGameChatColors.length];
                      final key = m.id.isNotEmpty
                          ? _bubbleKeys.putIfAbsent(m.id, () => GlobalKey())
                          : null;
                      final highlighted =
                          m.id.isNotEmpty && m.id == _highlightedId;
                      return SwipeToReplyBubble(
                        key: key,
                        highlighted: highlighted,
                        onSwipeReply: () => _startReply(m),
                        // Item 1 (real-device follow-up) root-cause fix:
                        // avatars were entirely absent from game chat —
                        // this Row (only ever built for !isMe — own
                        // messages keep their existing appearance
                        // unchanged, matching the lobby chat convention
                        // this mirrors) puts a compact circular avatar
                        // beside the message without touching the
                        // existing Padding/Column below at all: a single
                        // Expanded child inside a Row lays out
                        // identically to no Row, so the isMe path is
                        // byte-for-byte the same layout as before.
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 22),
                                child: UserAvatar(
                                  avatarUrl: member?.avatarUrl,
                                  avatarConfig: member?.avatarConfig,
                                  isPremium: member?.isPremium ?? false,
                                  displayName: m.senderName,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: 8,
                                  left: isMe ? 48 : 0,
                                  right: isMe ? 0 : 48,
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 4,
                                          bottom: 2,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              m.senderName,
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (member?.isPremium ?? false) ...[
                                              const SizedBox(width: 3),
                                              PremiumBadge(
                                                size: 10,
                                                tier: member?.premiumTier,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? const Color(0xFFFFD60A)
                                            : color.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(16)
                                            .copyWith(
                                              bottomRight: isMe
                                                  ? const Radius.circular(4)
                                                  : null,
                                              bottomLeft: isMe
                                                  ? null
                                                  : const Radius.circular(4),
                                            ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (m.isReply)
                                            GestureDetector(
                                              onTap: () =>
                                                  _scrollToAndHighlight(
                                                    m.replyToId!,
                                                  ),
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 6,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      (isMe
                                                              ? const Color(
                                                                  0xFF0D1B2A,
                                                                )
                                                              : Colors.white)
                                                          .withValues(
                                                            alpha: 0.14,
                                                          ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border(
                                                    left: BorderSide(
                                                      color: isMe
                                                          ? const Color(
                                                              0xFF0D1B2A,
                                                            )
                                                          : color,
                                                      width: 2.5,
                                                    ),
                                                  ),
                                                ),
                                                child: Text(
                                                  '${m.replyToSenderName ?? ''}: '
                                                  '${m.replyToText ?? ''}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: isMe
                                                        ? const Color(
                                                            0xFF0D1B2A,
                                                          ).withValues(
                                                            alpha: 0.75,
                                                          )
                                                        : Colors.white70,
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Text(
                                            m.text,
                                            style: TextStyle(
                                              color: isMe
                                                  ? const Color(0xFF0D1B2A)
                                                  : Colors.white,
                                              fontWeight: isMe
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                          // Item 2 — same sender/recipient
                                          // indicator rule as lobby chat:
                                          // the sender sees who it went
                                          // to, a recipient only sees that
                                          // it was private.
                                          if (m.isTargeted)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.lock_person_rounded,
                                                    size: 11,
                                                    color: isMe
                                                        ? const Color(
                                                            0xFF0D1B2A,
                                                          ).withValues(
                                                            alpha: 0.7,
                                                          )
                                                        : Colors.white70,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Flexible(
                                                    child: Text(
                                                      isMe &&
                                                              m
                                                                  .recipientNames
                                                                  .isNotEmpty
                                                          ? context
                                                                .l10n
                                                                .chatTargetedIndicatorSender(
                                                                  m.recipientNames
                                                                      .join(
                                                                        ', ',
                                                                      ),
                                                                )
                                                          : context
                                                                .l10n
                                                                .chatTargetedIndicatorRecipient,
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color: isMe
                                                            ? const Color(
                                                                0xFF0D1B2A,
                                                              ).withValues(
                                                                alpha: 0.7,
                                                              )
                                                            : Colors.white70,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (widget.isPremiumPlus && widget.onSendTargeted != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
                // Real-device root-cause fix (first-swipe-to-reply
                // keyboard open→close glitch): this Container appears
                // CONDITIONALLY, directly above the composer, inside an
                // otherwise-unkeyed Column children list. The exact same
                // setState() that makes it appear (_startReply) also
                // calls _focusNode.requestFocus() — and inserting an
                // unkeyed sibling ahead of another widget in a children
                // list can make Flutter's reconciliation treat everything
                // AFTER the insertion point as changed-in-place rather
                // than "shifted down unchanged", which for a StatefulWidget
                // means losing (and rebuilding) its Element — exactly
                // the kind of mid-transition disruption the composer's
                // own comment below already documents causing this
                // identical "opens then immediately closes" symptom for
                // a completely different reason (double viewInsets
                // compensation). An explicit key on both this preview and
                // the composer below removes any ambiguity: Flutter now
                // always matches each by its own stable identity,
                // regardless of what gets inserted/removed around them.
                key: const ValueKey('game_chat_reply_preview'),
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    left: BorderSide(color: Color(0xFFFFD60A), width: 3),
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
                            context.l10n.chatReplyingTo(_replyTo!.senderName),
                            style: const TextStyle(
                              color: Color(0xFFFFD60A),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _replyTo!.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onPressed: _cancelReply,
                      tooltip: context.l10n.chatCancelReply,
                    ),
                  ],
                ),
              ),
            // Item 18.8 root-cause fix: showModalBottomSheet(isScrollControlled:
            // true) — every call site's own wrapper — ALREADY shifts its whole
            // child up by MediaQuery.viewInsets.bottom as the keyboard
            // animates (its own internal AnimatedPadding). This composer used
            // to ALSO add the same viewInsets.bottom into its own padding on
            // top of that, double-compensating: the composer/TextField ended
            // up positioned far higher than the keyboard's actual top edge,
            // and during the keyboard's OWN open animation the two
            // independent, competing shifts destabilized this field's layout
            // on the very first focus attempt — the OS text-input connection
            // would drop before the frame settled, closing the keyboard right
            // after it opened; a second tap worked because by then the
            // transition had already finished. Only a small fixed bottom
            // margin is needed here now; the surrounding sheet/modal already
            // keeps this row above the keyboard.
            Container(
              // See the reply-preview Container's matching key above —
              // this composer is the StatefulWidget (TextField) whose
              // Element/focus/platform-input-connection identity must
              // survive that sibling appearing/disappearing.
              key: const ValueKey('game_chat_composer'),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              color: const Color(0xFF1A2E45),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: context.l10n.chatSayHint,
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.07),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD60A),
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0D1B2A),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Color(0xFF0D1B2A),
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps one message bubble with a horizontal-swipe-to-reply gesture
/// (item 6). Deliberately NOT a `Dismissible` — nothing is ever removed,
/// the bubble always springs back to its resting position; a swipe past
/// the threshold only triggers [onSwipeReply] once and re-arms after the
/// finger lifts. Only responds to a clearly horizontal drag past a
/// minimum distance, so it never fights the list's own vertical scroll or
/// any other gesture in the chat UI.
class SwipeToReplyBubble extends StatefulWidget {
  const SwipeToReplyBubble({
    super.key,
    required this.child,
    required this.onSwipeReply,
    required this.highlighted,
  });
  final Widget child;
  final VoidCallback onSwipeReply;
  final bool highlighted;

  @override
  State<SwipeToReplyBubble> createState() => SwipeToReplyBubbleState();
}

class SwipeToReplyBubbleState extends State<SwipeToReplyBubble> {
  static const _threshold = 56.0;
  double _dx = 0;
  bool _triggered = false;

  void _onUpdate(DragUpdateDetails d) {
    setState(() {
      _dx = (_dx + d.delta.dx).clamp(-_threshold, _threshold);
      if (!_triggered && _dx.abs() >= _threshold) {
        _triggered = true;
        widget.onSwipeReply();
      }
    });
  }

  void _onEnd(DragEndDetails d) {
    setState(() {
      _dx = 0;
      _triggered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      onHorizontalDragCancel: () => setState(() {
        _dx = 0;
        _triggered = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: widget.highlighted
            ? const Color(0xFFFFD60A).withValues(alpha: 0.16)
            : Colors.transparent,
        transform: Matrix4.translationValues(_dx, 0, 0),
        child: widget.child,
      ),
    );
  }
}
