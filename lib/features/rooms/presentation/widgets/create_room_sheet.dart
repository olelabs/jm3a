
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/app_tutorial_service.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/tutorial/screen_tutorial.dart';
import '../../domain/room_entity.dart';

class CreateRoomSheet extends StatefulWidget {
  const CreateRoomSheet({super.key});

  @override
  State<CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<CreateRoomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  // First-time room-creation tutorial targets. (The name field is not a tour
  // step — see the `steps` comment in build.)
  final GlobalKey _visibilityShowcaseKey = GlobalKey();
  final GlobalKey _spectatorsShowcaseKey = GlobalKey();
  final GlobalKey _createShowcaseKey = GlobalKey();

  RoomVisibility _visibility = RoomVisibility.public;
  int _maxPlayers = 6;
  String _emoji = '🎮';
  bool _isCreating = false;
  bool _allowSpectators = false;
  bool _requireApproval = false;
  bool _spectatorApprovalRequired = false;
  bool _maxPlayersCapInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs once, after context is available (unlike initState) — seeds the
    // slider from the owner's actual subscription-tier cap instead of the
    // hardcoded default of 6, without overwriting a choice they've already
    // made on later rebuilds.
    if (!_maxPlayersCapInitialized) {
      _maxPlayersCapInitialized = true;
      final cap = context.read<AuthProvider>().currentUser?.roomPlayerCap ?? 3;
      _maxPlayers = _maxPlayers.clamp(2, cap);
    }
  }

  static const _freeEmojis = [
    '🎮',
    '🎯',
    '🎲',
    '🃏',
    '🎪',
    '🎉',
    '🌟',
    '🔥',
    '💥',
    '😂',
  ];

  static const _premiumEmojis = [
    '👑',
    '💎',
    '🌈',
    '🦄',
    '🐉',
    '🌙',
    '⚡',
    '🎭',
    '🥷',
    '🤖',
    '🌺',
    '🎸',
    '🏆',
    '🚀',
    '🦋',
    '🍄',
    '🌊',
    '🎨',
    '🦁',
    '🐺',
    '🌋',
    '🎠',
    '🧿',
    '🔮',
    '✨',
    '🎆',
    '🃏',
    '🎰',
    '🎳',
    '🎻',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isCreating = true);
    try {
      final userId = context.read<AuthProvider>().currentUser!.id;
      final room = await sl.roomRepository.createRoom(
        ownerId: userId,
        name: _nameCtrl.text.trim(),
        visibility: _visibility,
        maxPlayers: _maxPlayers,
        coverEmoji: _emoji,
      );
      if (_allowSpectators || _requireApproval) {
        try {
          await sl.roomRepository.updateSettings(
            room.id,
            RoomSettingsEntity(
              allowSpectators: _allowSpectators,
              requiresApproval: _requireApproval,
              spectatorApprovalRequired:
                  _allowSpectators && _spectatorApprovalRequired,
            ),
          );
        } catch (_) {}
      }
      if (mounted) Navigator.pop(context, room);
    } on Failure catch (e) {
      // The race-condition fallback path — the pre-flight duplicate-room
      // check in room_browser_screen.dart already intercepts the common
      // case, so this only fires if a room was created between that check
      // and this submit. Surface the specific, already-friendly message
      // (e.g. "You already have an open room...") instead of a generic one.
      if (mounted) {
        context.showErrorSnackBar(e.message);
        setState(() => _isCreating = false);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(context.l10n.errorUnexpected);
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;

    return ScreenTutorial(
      tutorialId: TutorialIds.roomCreationIntro,
      // The room-name field is deliberately NOT a tour step. A showcaseview
      // Showcase wrapped directly around a focusable TextField hijacks the
      // first tap: the tap focuses the field (keyboard opens) AND fires the
      // showcase target-tap, which advances the tour to the next full-screen
      // overlay — and that overlay change immediately steals focus, closing
      // the keyboard (the "first tap opens then closes, second tap works"
      // bug). The tour still highlights the non-text controls below.
      steps: [
        _visibilityShowcaseKey,
        _spectatorsShowcaseKey,
        _createShowcaseKey,
      ],
      child: Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                l10n.roomsCreate,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),

              // Emoji selector + name row
              Row(
                children: [
                  // Emoji picker
                  GestureDetector(
                    onTap: () => _pickEmoji(context),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    // Plain field — NOT wrapped in a showcase (see the tour
                    // `steps` comment above) so the first tap reliably keeps
                    // the keyboard open.
                    child: TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      // Dismiss the keyboard, don't submit — pressing the
                      // keyboard's Done key used to create the room
                      // immediately, skipping every option below the name
                      // field (visibility/max players/spectators). Only the
                      // actual "Create Room" button submits now.
                      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        labelText: context.l10n.roomsNameLabel,
                        hintText: context.l10n.roomsNameHint,
                      ),
                      validator: (v) {
                        if ((v?.trim() ?? '').length < 3)
                          return context.l10n.roomsNameTooShort;
                        if ((v?.trim() ?? '').length > 60)
                          return context.l10n.roomsNameTooLong;
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Visibility
              Text(context.l10n.roomsVisibility, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              tutorialShowcase(
                context: context,
                showcaseKey: _visibilityShowcaseKey,
                title: context.l10n.tutCreateVisibilityTitle,
                description: context.l10n.tutCreateVisibilityBody,
                child: SegmentedButton<RoomVisibility>(
                segments: [
                  ButtonSegment(
                    value: RoomVisibility.public,
                    label: Text(context.l10n.roomsPublic),
                    icon: const Icon(Icons.public_rounded),
                  ),
                  ButtonSegment(
                    value: RoomVisibility.private,
                    label: Text(context.l10n.roomsPrivate),
                    icon: const Icon(Icons.lock_outline_rounded),
                  ),
                ],
                selected: {_visibility},
                onSelectionChanged: (v) =>
                    setState(() => _visibility = v.first),
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                ),
              ),
              const SizedBox(height: 20),

              // Max players slider — capped by the owner's subscription tier
              // (Basic=3/Premium=8/Premium Plus=12), enforced server-side
              // in the create_room RPC; this is display-only.
              Builder(
                builder: (context) {
                  final cap =
                      context.watch<AuthProvider>().currentUser?.roomPlayerCap ??
                      3;
                  if (_maxPlayers > cap) _maxPlayers = cap;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            context.l10n.roomsMaxPlayers,
                            style: theme.textTheme.labelLarge,
                          ),
                          const Spacer(),
                          Text(
                            '$_maxPlayers',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _maxPlayers.toDouble(),
                        min: 2,
                        max: cap.toDouble(),
                        divisions: (cap - 2).clamp(1, 10),
                        label: '$_maxPlayers',
                        onChanged: (v) =>
                            setState(() => _maxPlayers = v.round()),
                      ),
                      Text(
                        context.l10n.roomsSupportsUpToPlayers(cap),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),

              tutorialShowcase(
                context: context,
                showcaseKey: _spectatorsShowcaseKey,
                title: context.l10n.tutCreateSpectatorsTitle,
                description: context.l10n.tutCreateSpectatorsBody,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.roomsAllowSpectators),
                  subtitle: Text(context.l10n.roomsAllowSpectatorsHint),
                  value: _allowSpectators,
                  onChanged: (v) => setState(() {
                    _allowSpectators = v;
                    if (!v) _spectatorApprovalRequired = false;
                  }),
                ),
              ),
              if (_allowSpectators)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.roomsRequireSpectatorApproval),
                  subtitle: Text(
                    context.l10n.roomsRequireSpectatorApprovalHint,
                  ),
                  value: _spectatorApprovalRequired,
                  onChanged: (v) =>
                      setState(() => _spectatorApprovalRequired = v),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.roomsRequireJoinApproval),
                subtitle: Text(context.l10n.roomsRequireJoinApprovalHint),
                value: _requireApproval,
                onChanged: (v) => setState(() => _requireApproval = v),
              ),
              const SizedBox(height: 8),

              tutorialShowcase(
                context: context,
                showcaseKey: _createShowcaseKey,
                title: context.l10n.tutCreateButtonTitle,
                description: context.l10n.tutCreateButtonBody,
                child: JButton(
                  label: l10n.roomsCreate,
                  onPressed: _create,
                  isLoading: _isCreating,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _pickEmoji(BuildContext context) async {
    final isPremium =
        context.read<AuthProvider>().currentUser?.isPremiumActive ?? false;
    final theme = context.theme;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        builder: (_, sc) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      context.l10n.roomsRoomIcon,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Text(
                      context.l10n.roomsIconFree,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _freeEmojis
                          .map(
                            (e) => _EmojiTile(
                              emoji: e,
                              selected: e == _emoji,
                              locked: false,
                              onTap: () {
                                setState(() => _emoji = e);
                                Navigator.pop(ctx);
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          context.l10n.roomsIconPremium,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFFF5A623),
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!isPremium) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              AppRouter.router.push(RouteNames.premium);
                            },
                            child: Text(
                              context.l10n.roomsUpgradeArrow,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _premiumEmojis
                          .map(
                            (e) => _EmojiTile(
                              emoji: e,
                              selected: e == _emoji,
                              locked: !isPremium,
                              onTap: isPremium
                                  ? () {
                                      setState(() => _emoji = e);
                                      Navigator.pop(ctx);
                                    }
                                  : () {
                                      Navigator.pop(ctx);
                                      AppRouter.router.push(RouteNames.premium);
                                    },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiTile extends StatelessWidget {
  const _EmojiTile({
    required this.emoji,
    required this.selected,
    required this.locked,
    required this.onTap,
  });
  final String emoji;
  final bool selected, locked;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
            if (locked)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
