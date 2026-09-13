import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/overlays/confirm_dialog.dart';

class AvatarConfig {
  const AvatarConfig({
    this.topType = 'ShortHairShortFlat',
    this.accessoriesType = 'Blank',
    this.hairColor = 'BrownDark',
    this.facialHairType = 'Blank',
    this.facialHairColor = 'BrownDark',
    this.clotheType = 'Hoodie',
    this.clotheColor = 'Blue01',
    this.eyeType = 'Default',
    this.eyebrowType = 'Default',
    this.mouthType = 'Smile',
    this.skinColor = 'Light',
  });

  final String topType;
  final String accessoriesType;
  final String hairColor;
  final String facialHairType;
  final String facialHairColor;
  final String clotheType;
  final String clotheColor;
  final String eyeType;
  final String eyebrowType;
  final String mouthType;
  final String skinColor;

  static AvatarConfig get defaults => const AvatarConfig();

  String get avatarUrl =>
      'https://avataaars.io/?avatarStyle=Circle'
      '&topType=$topType'
      '&accessoriesType=$accessoriesType'
      '&hairColor=$hairColor'
      '&facialHairType=$facialHairType'
      '&facialHairColor=$facialHairColor'
      '&clotheType=$clotheType'
      '&clotheColor=$clotheColor'
      '&eyeType=$eyeType'
      '&eyebrowType=$eyebrowType'
      '&mouthType=$mouthType'
      '&skinColor=$skinColor';

  Map<String, String> toMap() => {
    'topType': topType,
    'accessoriesType': accessoriesType,
    'hairColor': hairColor,
    'facialHairType': facialHairType,
    'facialHairColor': facialHairColor,
    'clotheType': clotheType,
    'clotheColor': clotheColor,
    'eyeType': eyeType,
    'eyebrowType': eyebrowType,
    'mouthType': mouthType,
    'skinColor': skinColor,
  };

  factory AvatarConfig.fromMap(Map<String, dynamic> m) => AvatarConfig(
    topType: m['topType'] as String? ?? 'ShortHairShortFlat',
    accessoriesType: m['accessoriesType'] as String? ?? 'Blank',
    hairColor: m['hairColor'] as String? ?? 'BrownDark',
    facialHairType: m['facialHairType'] as String? ?? 'Blank',
    facialHairColor: m['facialHairColor'] as String? ?? 'BrownDark',
    clotheType: m['clotheType'] as String? ?? 'Hoodie',
    clotheColor: m['clotheColor'] as String? ?? 'Blue01',
    eyeType: m['eyeType'] as String? ?? 'Default',
    eyebrowType: m['eyebrowType'] as String? ?? 'Default',
    mouthType: m['mouthType'] as String? ?? 'Smile',
    skinColor: m['skinColor'] as String? ?? 'Light',
  );

  static const Map<
    String,
    ({String eyeType, String mouthType, String eyebrowType, String emoji})
  >
  reactionExpressions = {
    'laugh': (
      eyeType: 'Squint',
      mouthType: 'Twinkle',
      eyebrowType: 'Default',
      emoji: '😂',
    ),
    'fire': (
      eyeType: 'Default',
      mouthType: 'Serious',
      eyebrowType: 'RaisedExcited',
      emoji: '🔥',
    ),
    'dead': (
      eyeType: 'Close',
      mouthType: 'Disbelief',
      eyebrowType: 'Default',
      emoji: '💀',
    ),
    'clap': (
      eyeType: 'Happy',
      mouthType: 'Default',
      eyebrowType: 'RaisedExcitedNatural',
      emoji: '👏',
    ),
    'rofl': (
      eyeType: 'Squint',
      mouthType: 'ScreamOpen',
      eyebrowType: 'Default',
      emoji: '🤣',
    ),
    'cry': (
      eyeType: 'Cry',
      mouthType: 'Sad',
      eyebrowType: 'SadConcerned',
      emoji: '😭',
    ),
    'salute': (
      eyeType: 'Default',
      mouthType: 'Serious',
      eyebrowType: 'UpDown',
      emoji: '🫡',
    ),
    'hundred': (
      eyeType: 'Default',
      mouthType: 'Smile',
      eyebrowType: 'RaisedExcited',
      emoji: '💯',
    ),
    'mindblown': (
      eyeType: 'Surprised',
      mouthType: 'ScreamOpen',
      eyebrowType: 'UpDown',
      emoji: '🤯',
    ),
    'crown': (
      eyeType: 'Default',
      mouthType: 'Twinkle',
      eyebrowType: 'Default',
      emoji: '👑',
    ),
    'annoyed': (
      eyeType: 'Default',
      mouthType: 'Grimace',
      eyebrowType: 'Angry',
      emoji: '😤',
    ),
    'touched': (
      eyeType: 'Happy',
      mouthType: 'Concerned',
      eyebrowType: 'SadConcernedNatural',
      emoji: '🥹',
    ),
    // Item 6 (reaction-expansion pass) — 12 new expressions, doubling the
    // avatar reaction picker. Every eyeType/mouthType/eyebrowType value
    // below is taken from this screen's OWN existing _eyes/_mouths/
    // _eyebrows option lists (see below) — no invented Avataaars values —
    // and each (eyeType, mouthType, eyebrowType) triple is verified
    // distinct from every triple above so no new key silently renders
    // identically to an existing one.
    'love': (
      eyeType: 'Hearts',
      mouthType: 'Smile',
      eyebrowType: 'Default',
      emoji: '😍',
    ),
    'wink': (
      eyeType: 'Wink',
      mouthType: 'Twinkle',
      eyebrowType: 'Default',
      emoji: '😉',
    ),
    'silly': (
      eyeType: 'WinkWacky',
      mouthType: 'Tongue',
      eyebrowType: 'UpDown',
      emoji: '🤪',
    ),
    'dizzy': (
      eyeType: 'Dizzy',
      mouthType: 'Disbelief',
      eyebrowType: 'UpDownNatural',
      emoji: '😵',
    ),
    'sad': (
      eyeType: 'Side',
      mouthType: 'Sad',
      eyebrowType: 'SadConcernedNatural',
      emoji: '😢',
    ),
    'shocked': (
      eyeType: 'Surprised',
      mouthType: 'Disbelief',
      eyebrowType: 'RaisedExcited',
      emoji: '😱',
    ),
    'confident': (
      eyeType: 'Side',
      mouthType: 'Serious',
      eyebrowType: 'RaisedExcitedNatural',
      emoji: '😏',
    ),
    'grumpy': (
      eyeType: 'EyeRoll',
      mouthType: 'Grimace',
      eyebrowType: 'AngryNatural',
      emoji: '😒',
    ),
    'sleepy': (
      eyeType: 'Close',
      mouthType: 'Default',
      eyebrowType: 'FlatNatural',
      emoji: '😴',
    ),
    'starstruck': (
      eyeType: 'Happy',
      mouthType: 'Twinkle',
      eyebrowType: 'RaisedExcited',
      emoji: '🤩',
    ),
    'yum': (
      eyeType: 'Happy',
      mouthType: 'Eating',
      eyebrowType: 'Default',
      emoji: '😋',
    ),
    'unimpressed': (
      eyeType: 'Side',
      mouthType: 'Concerned',
      eyebrowType: 'UnibrowNatural',
      emoji: '😑',
    ),
  };

  static const String reactionPrefix = 'avatar:';

  static bool isAvatarReaction(String value) =>
      value.startsWith(reactionPrefix);

  static String avatarReactionKey(String value) =>
      value.substring(reactionPrefix.length);

  String reactionUrl(String expressionKey) {
    final preset = reactionExpressions[expressionKey];
    if (preset == null) return avatarUrl;
    return copyWith(
      eyeType: preset.eyeType,
      mouthType: preset.mouthType,
      eyebrowType: preset.eyebrowType,
    ).avatarUrl;
  }

  AvatarConfig copyWith({
    String? topType,
    String? accessoriesType,
    String? hairColor,
    String? facialHairType,
    String? facialHairColor,
    String? clotheType,
    String? clotheColor,
    String? eyeType,
    String? eyebrowType,
    String? mouthType,
    String? skinColor,
  }) => AvatarConfig(
    topType: topType ?? this.topType,
    accessoriesType: accessoriesType ?? this.accessoriesType,
    hairColor: hairColor ?? this.hairColor,
    facialHairType: facialHairType ?? this.facialHairType,
    facialHairColor: facialHairColor ?? this.facialHairColor,
    clotheType: clotheType ?? this.clotheType,
    clotheColor: clotheColor ?? this.clotheColor,
    eyeType: eyeType ?? this.eyeType,
    eyebrowType: eyebrowType ?? this.eyebrowType,
    mouthType: mouthType ?? this.mouthType,
    skinColor: skinColor ?? this.skinColor,
  );
}

class AvatarService extends ChangeNotifier {
  AvatarService._();
  static final AvatarService instance = AvatarService._();

  static const _prefKey = 'avataaars_config_v1';
  static const _lastSavedKey = 'avataaars_last_saved_v1';
  static const _reactionStyleKey = 'reaction_style_v1';
  static const cooldown = Duration(hours: 24);

  AvatarConfig _config = AvatarConfig.defaults;
  DateTime? _lastSavedAt;
  String _reactionStyle = 'emoji';
  AvatarConfig get config => _config;
  String get reactionStyle => _reactionStyle;
  bool get reactionStyleIsAvatar => _reactionStyle == 'avatar';

  Future<void> setReactionStyle(String style) async {
    _reactionStyle = style == 'avatar' ? 'avatar' : 'emoji';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reactionStyleKey, _reactionStyle);
    notifyListeners();
  }

  Duration? get cooldownRemaining {
    if (_lastSavedAt == null) return null;
    final elapsed = DateTime.now().difference(_lastSavedAt!);
    if (elapsed >= cooldown) return null;
    return cooldown - elapsed;
  }

  bool get canSave => cooldownRemaining == null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      try {
        _config = AvatarConfig.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (_) {}
    }
    final lastSavedMs = prefs.getInt(_lastSavedKey);
    if (lastSavedMs != null) {
      _lastSavedAt = DateTime.fromMillisecondsSinceEpoch(lastSavedMs);
    }
    _reactionStyle = prefs.getString(_reactionStyleKey) ?? 'emoji';
    notifyListeners();
  }

  Future<bool> save(AvatarConfig cfg) async {
    if (!canSave) return false;
    _config = cfg;
    _lastSavedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(cfg.toMap()));
    await prefs.setInt(_lastSavedKey, _lastSavedAt!.millisecondsSinceEpoch);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_config': cfg.toMap()})
          .eq('id', uid)
          .catchError((_) {});
    }
    notifyListeners();
    return true;
  }

  /// Removes the user's premium generated avatar entirely — reverts
  /// profiles.avatar_config to null so UserAvatar's existing fallback
  /// chain takes over (uploaded photo avatarUrl if they have one, else
  /// initials), same as a user who never customized an avatar at all.
  /// DB write happens first and local state is only cleared on success,
  /// so a failed delete never leaves the local cache/UI out of sync with
  /// what's actually stored (the alternative — clearing local state
  /// regardless — would show "no avatar" locally while the old one
  /// silently reappears on next app restart).
  ///
  /// Deliberately does NOT touch _lastSavedAt/the 24h cooldown: it's
  /// already ticking down from whenever this avatar was last saved, and
  /// leaving it alone means delete-then-immediately-recreate isn't a way
  /// to dodge the cooldown.
  Future<bool> delete() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'avatar_config': null})
            .eq('id', uid);
      } catch (_) {
        return false;
      }
    }
    _config = AvatarConfig.defaults;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    notifyListeners();
    return true;
  }
}

class AvatarDisplay extends StatelessWidget {
  const AvatarDisplay({super.key, required this.avatarUrl, required this.size});
  final String avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.network(
    avatarUrl,
    width: size,
    height: size,
    placeholderBuilder: (_) => SizedBox(
      width: size,
      height: size,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.person,
          size: size * 0.5,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    ),
  );
}

class AvatarCreatorScreen extends StatefulWidget {
  const AvatarCreatorScreen({super.key});
  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  late AvatarConfig _config;
  bool _saving = false;

  static const _skinColors = [
    'Tanned',
    'Yellow',
    'Pale',
    'Light',
    'Brown',
    'DarkBrown',
    'Black',
  ];
  static const _hairColors = [
    'Auburn',
    'Black',
    'Blonde',
    'BlondeGolden',
    'Brown',
    'BrownDark',
    'PastelPink',
    'Platinum',
    'Red',
    'SilverGray',
  ];
  static const _topTypes = [
    'NoHair',
    'Eyepatch',
    'Hat',
    'Hijab',
    'Turban',
    'WinterHat1',
    'WinterHat2',
    'WinterHat3',
    'WinterHat4',
    'LongHairBigHair',
    'LongHairBob',
    'LongHairBun',
    'LongHairCurly',
    'LongHairCurvy',
    'LongHairDreads',
    'LongHairFrida',
    'LongHairFro',
    'LongHairFroBand',
    'LongHairNotTooLong',
    'LongHairShavedSides',
    'LongHairMiaWallace',
    'LongHairStraight',
    'LongHairStraight2',
    'LongHairStraightStrand',
    'ShortHairDreads01',
    'ShortHairDreads02',
    'ShortHairFrizzle',
    'ShortHairShaggyMullet',
    'ShortHairShortCurly',
    'ShortHairShortFlat',
    'ShortHairShortRound',
    'ShortHairShortWaved',
    'ShortHairSides',
    'ShortHairTheCaesar',
    'ShortHairTheCaesarSidePart',
  ];
  static const _accessories = [
    'Blank',
    'Kurt',
    'Prescription01',
    'Prescription02',
    'Round',
    'Sunglasses',
    'Wayfarers',
  ];
  static const _facialHair = [
    'Blank',
    'BeardMedium',
    'BeardLight',
    'BeardMagestic',
    'MoustacheFancy',
    'MoustacheMagnum',
  ];
  static const _clothes = [
    'BlazerShirt',
    'BlazerSweater',
    'CollarSweater',
    'GraphicShirt',
    'Hoodie',
    'Overall',
    'ShirtCrewNeck',
    'ShirtScoopNeck',
    'ShirtVNeck',
  ];
  static const _clotheColors = [
    'Black',
    'Blue01',
    'Blue02',
    'Blue03',
    'Gray01',
    'Gray02',
    'Heather',
    'PastelBlue',
    'PastelGreen',
    'PastelOrange',
    'PastelRed',
    'PastelYellow',
    'Pink',
    'Red',
    'White',
  ];
  static const _eyes = [
    'Close',
    'Cry',
    'Default',
    'Dizzy',
    'EyeRoll',
    'Happy',
    'Hearts',
    'Side',
    'Squint',
    'Surprised',
    'Wink',
    'WinkWacky',
  ];
  static const _eyebrows = [
    'Angry',
    'AngryNatural',
    'Default',
    'DefaultNatural',
    'FlatNatural',
    'RaisedExcited',
    'RaisedExcitedNatural',
    'SadConcerned',
    'SadConcernedNatural',
    'UnibrowNatural',
    'UpDown',
    'UpDownNatural',
  ];
  static const _mouths = [
    'Concerned',
    'Default',
    'Disbelief',
    'Eating',
    'Grimace',
    'Sad',
    'ScreamOpen',
    'Serious',
    'Smile',
    'Tongue',
    'Twinkle',
    'Vomit',
  ];

  @override
  void initState() {
    super.initState();
    _config = AvatarService.instance.config;
  }

  Future<void> _save() async {
    final remaining = AvatarService.instance.cooldownRemaining;
    if (remaining != null) {
      final hours = remaining.inHours;
      final mins = remaining.inMinutes % 60;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.avatarUpdateCooldownNotice(hours, mins)),
          behavior: SnackBarBehavior.fixed,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await AvatarService.instance.save(_config);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? context.l10n.avatarSaved : context.l10n.avatarSaveFailed,
          ),
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  bool _deleting = false;

  Future<void> _deleteAvatar() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: context.l10n.avatarDeleteDialogTitle,
      message: context.l10n.avatarDeleteDialogMessage,
      confirmLabel: context.l10n.avatarDeleteAction,
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final ok = await AvatarService.instance.delete();
    if (!mounted) return;
    setState(() {
      _deleting = false;
      // Local form state also resets to defaults so this screen (still
      // open, on top of the now-cleared avatar) immediately reflects it
      // instead of showing the just-deleted customization until reopened.
      if (ok) _config = AvatarService.instance.config;
    });
    if (ok) {
      // Keeps AuthProvider.currentUser in sync so every other screen
      // reading it (not just this one, which already watches
      // AvatarService directly) reflects the deletion immediately too —
      // same "update profile immediately" requirement as any other
      // profile mutation in this app.
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      if (user != null) {
        auth.updateCurrentUser(user.copyWith(clearAvatarConfig: true));
      }
      context.showSnackBar(context.l10n.avatarDeleted);
    } else {
      context.showErrorSnackBar(context.l10n.avatarDeleteFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().currentUser;
    final isPremium = authUser?.isPremiumActive ?? false;
    // Whether there's actually a saved custom avatar to delete — distinct
    // from _config (this screen's editing-form state, which always holds
    // *something*, defaulting to AvatarConfig.defaults even when nothing
    // was ever saved). Drives whether the delete action even appears.
    final hasCustomAvatar = authUser?.avatarConfig?.isNotEmpty ?? false;
    final theme = context.theme;

    if (!isPremium) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.profileMyAvatar)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AvatarDisplay(
                  avatarUrl: AvatarConfig.defaults.avatarUrl,
                  size: 120,
                ),
                const SizedBox(height: 20),
                Text(
                  context.l10n.avatarCustomAvatarsTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.avatarCustomAvatarsHint,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => AppRouter.router.push(RouteNames.premium),
                  child: Text(context.l10n.avatarUpgradeToPremium),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final remaining = context.watch<AvatarService>().cooldownRemaining;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.profileMyAvatar),
          actions: [
            if (hasCustomAvatar)
              IconButton(
                icon: _deleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
                tooltip: context.l10n.avatarDeleteAction,
                onPressed: _deleting ? null : _deleteAvatar,
              ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: context.l10n.avatarTabHair),
              Tab(text: context.l10n.avatarTabFace),
              Tab(text: context.l10n.avatarTabEyes),
              Tab(text: context.l10n.avatarTabMouth),
              Tab(text: context.l10n.avatarTabOutfit),
              Tab(text: context.l10n.avatarTabExtras),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saving ? null : _save,
          backgroundColor: remaining != null ? Colors.grey : null,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  remaining != null
                      ? Icons.lock_clock_rounded
                      : Icons.check_rounded,
                ),
          label: Text(
            _saving
                ? context.l10n.avatarSavingEllipsis
                : remaining != null
                ? context.l10n.avatarOnCooldown
                : context.l10n.avatarSaveAvatar,
          ),
        ),
        body: Column(
          children: [
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: ClipOval(
                  child: AvatarDisplay(avatarUrl: _config.avatarUrl, size: 120),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                context.l10n.avatarReactionsDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (remaining != null)
              Container(
                width: double.infinity,
                color: theme.colorScheme.errorContainer,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_clock_rounded,
                      size: 16,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.avatarAlreadyUpdatedNotice(
                          remaining.inHours,
                          remaining.inMinutes % 60,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _TraitTab(
                    children: [
                      _OptionRow(
                        context.l10n.avatarOptHairStyle,
                        _topTypes,
                        _config.topType,
                        (v) => setState(
                          () => _config = _config.copyWith(topType: v),
                        ),
                      ),
                      _OptionRow(
                        context.l10n.avatarOptHairColor,
                        _hairColors,
                        _config.hairColor,
                        (v) => setState(
                          () => _config = _config.copyWith(hairColor: v),
                        ),
                      ),
                    ],
                  ),
                  _TraitTab(
                    children: [
                      _OptionRow(
                        context.l10n.avatarOptSkinTone,
                        _skinColors,
                        _config.skinColor,
                        (v) => setState(
                          () => _config = _config.copyWith(skinColor: v),
                        ),
                      ),
                      _OptionRow(
                        context.l10n.avatarOptFacialHair,
                        _facialHair,
                        _config.facialHairType,
                        (v) => setState(
                          () => _config = _config.copyWith(facialHairType: v),
                        ),
                      ),
                      _OptionRow(
                        context.l10n.avatarOptFacialHairColor,
                        _hairColors,
                        _config.facialHairColor,
                        (v) => setState(
                          () => _config = _config.copyWith(facialHairColor: v),
                        ),
                      ),
                    ],
                  ),
                  _TraitTab(
                    children: [
                      _OptionRow(
                        context.l10n.avatarOptEyes,
                        _eyes,
                        _config.eyeType,
                        (v) => setState(
                          () => _config = _config.copyWith(eyeType: v),
                        ),
                      ),
                      _OptionRow(
                        context.l10n.avatarOptEyebrows,
                        _eyebrows,
                        _config.eyebrowType,
                        (v) => setState(
                          () => _config = _config.copyWith(eyebrowType: v),
                        ),
                      ),
                      _OptionRow(
                        context.l10n.avatarOptAccessories,
                        _accessories,
                        _config.accessoriesType,
                        (v) => setState(
                          () => _config = _config.copyWith(accessoriesType: v),
                        ),
                      ),
                    ],
                  ),
                  _TraitTab(
                    children: [
                      _OptionRow(
                        context.l10n.avatarOptMouth,
                        _mouths,
                        _config.mouthType,
                        (v) => setState(
                          () => _config = _config.copyWith(mouthType: v),
                        ),
                      ),
                    ],
                  ),
                  _TraitTab(
                    children: [
                      _OptionRow(
                        context.l10n.avatarOptOutfit,
                        _clothes,
                        _config.clotheType,
                        (v) => setState(
                          () => _config = _config.copyWith(clotheType: v),
                        ),
                      ),
                      _OptionRow(
                        context.l10n.avatarOptOutfitColor,
                        _clotheColors,
                        _config.clotheColor,
                        (v) => setState(
                          () => _config = _config.copyWith(clotheColor: v),
                        ),
                      ),
                    ],
                  ),
                  _TraitTab(
                    children: [
                      _RandomRow(
                        onRandom: () =>
                            setState(() => _config = _randomConfig()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AvatarConfig _randomConfig() {
    final r = DateTime.now().millisecondsSinceEpoch;
    T pick<T>(List<T> list) => list[r % list.length];
    return AvatarConfig(
      topType: pick(_topTypes),
      accessoriesType: pick(_accessories),
      hairColor: pick(_hairColors),
      facialHairType: pick(_facialHair),
      facialHairColor: pick(_hairColors),
      clotheType: pick(_clothes),
      clotheColor: pick(_clotheColors),
      eyeType: pick(_eyes),
      eyebrowType: pick(_eyebrows),
      mouthType: pick(_mouths),
      skinColor: pick(_skinColors),
    );
  }
}

class _TraitTab extends StatelessWidget {
  const _TraitTab({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(16), children: children);
}

class _OptionRow extends StatelessWidget {
  const _OptionRow(this.label, this.options, this.selected, this.onSelect);
  final String label;
  final List<String> options;
  final String selected;
  final void Function(String) onSelect;

  /// Last-resort fallback ONLY — a raw camelCase avataaars.io API value
  /// split into English words. Used only if [_localizedOption] doesn't
  /// recognize the value (should never happen for anything in this
  /// screen's own _skinColors/_hairColors/_topTypes/etc. lists; kept as a
  /// safety net, not a substitute for real translation).
  String _humanize(String s) => s
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
      .replaceAllMapped(RegExp(r'\d+'), (m) => ' ${m[0]}')
      .trim();

  /// Item 4 fix — every one of these ChoiceChip labels used to be the raw
  /// avataaars.io API value (e.g. 'ShortHairShortFlat', 'BrownDark') run
  /// through [_humanize], which only ever produces English text regardless
  /// of app locale. This resolves each value to its real EN/AR/FR
  /// translation. Keyed by the raw value alone (not per-category) since
  /// these are drawn from disjoint style vocabularies with no meaningful
  /// case where the same raw string means something different in two
  /// categories (e.g. 'Default'/'Blank' consistently mean "none/default"
  /// everywhere they appear; 'Black'/'Red'/'Brown' are the same color name
  /// whether describing hair, skin, or clothing).
  String _localizedOption(BuildContext context, String value) {
    final l10n = context.l10n;
    return switch (value) {
      // Skin colors
      'Tanned' => l10n.avatarOptTanned,
      'Yellow' => l10n.avatarOptYellow,
      'Pale' => l10n.avatarOptPale,
      'Light' => l10n.avatarOptLight,
      'Brown' => l10n.avatarOptBrown,
      'DarkBrown' => l10n.avatarOptDarkBrown,
      'Black' => l10n.avatarOptBlack,
      // Hair colors (Black/Brown/Red already covered above)
      'Auburn' => l10n.avatarOptAuburn,
      'Blonde' => l10n.avatarOptBlonde,
      'BlondeGolden' => l10n.avatarOptBlondeGolden,
      'BrownDark' => l10n.avatarOptBrownDark,
      'PastelPink' => l10n.avatarOptPastelPink,
      'Platinum' => l10n.avatarOptPlatinum,
      'Red' => l10n.avatarOptRed,
      'SilverGray' => l10n.avatarOptSilverGray,
      // Top types (hair styles / headwear)
      'NoHair' => l10n.avatarOptNoHair,
      'Eyepatch' => l10n.avatarOptEyepatch,
      'Hat' => l10n.avatarOptHat,
      'Hijab' => l10n.avatarOptHijab,
      'Turban' => l10n.avatarOptTurban,
      'WinterHat1' => l10n.avatarOptWinterHat1,
      'WinterHat2' => l10n.avatarOptWinterHat2,
      'WinterHat3' => l10n.avatarOptWinterHat3,
      'WinterHat4' => l10n.avatarOptWinterHat4,
      'LongHairBigHair' => l10n.avatarOptLongHairBigHair,
      'LongHairBob' => l10n.avatarOptLongHairBob,
      'LongHairBun' => l10n.avatarOptLongHairBun,
      'LongHairCurly' => l10n.avatarOptLongHairCurly,
      'LongHairCurvy' => l10n.avatarOptLongHairCurvy,
      'LongHairDreads' => l10n.avatarOptLongHairDreads,
      'LongHairFrida' => l10n.avatarOptLongHairFrida,
      'LongHairFro' => l10n.avatarOptLongHairFro,
      'LongHairFroBand' => l10n.avatarOptLongHairFroBand,
      'LongHairNotTooLong' => l10n.avatarOptLongHairNotTooLong,
      'LongHairShavedSides' => l10n.avatarOptLongHairShavedSides,
      'LongHairMiaWallace' => l10n.avatarOptLongHairMiaWallace,
      'LongHairStraight' => l10n.avatarOptLongHairStraight,
      'LongHairStraight2' => l10n.avatarOptLongHairStraight2,
      'LongHairStraightStrand' => l10n.avatarOptLongHairStraightStrand,
      'ShortHairDreads01' => l10n.avatarOptShortHairDreads01,
      'ShortHairDreads02' => l10n.avatarOptShortHairDreads02,
      'ShortHairFrizzle' => l10n.avatarOptShortHairFrizzle,
      'ShortHairShaggyMullet' => l10n.avatarOptShortHairShaggyMullet,
      'ShortHairShortCurly' => l10n.avatarOptShortHairShortCurly,
      'ShortHairShortFlat' => l10n.avatarOptShortHairShortFlat,
      'ShortHairShortRound' => l10n.avatarOptShortHairShortRound,
      'ShortHairShortWaved' => l10n.avatarOptShortHairShortWaved,
      'ShortHairSides' => l10n.avatarOptShortHairSides,
      'ShortHairTheCaesar' => l10n.avatarOptShortHairTheCaesar,
      'ShortHairTheCaesarSidePart' => l10n.avatarOptShortHairTheCaesarSidePart,
      // Accessories / facial hair (Blank shared by both)
      'Blank' => l10n.avatarOptBlank,
      'Kurt' => l10n.avatarOptKurt,
      'Prescription01' => l10n.avatarOptPrescription01,
      'Prescription02' => l10n.avatarOptPrescription02,
      'Round' => l10n.avatarOptRound,
      'Sunglasses' => l10n.avatarOptSunglasses,
      'Wayfarers' => l10n.avatarOptWayfarers,
      'BeardMedium' => l10n.avatarOptBeardMedium,
      'BeardLight' => l10n.avatarOptBeardLight,
      'BeardMagestic' => l10n.avatarOptBeardMagestic,
      'MoustacheFancy' => l10n.avatarOptMoustacheFancy,
      'MoustacheMagnum' => l10n.avatarOptMoustacheMagnum,
      // Clothes
      'BlazerShirt' => l10n.avatarOptBlazerShirt,
      'BlazerSweater' => l10n.avatarOptBlazerSweater,
      'CollarSweater' => l10n.avatarOptCollarSweater,
      'GraphicShirt' => l10n.avatarOptGraphicShirt,
      'Hoodie' => l10n.avatarOptHoodie,
      'Overall' => l10n.avatarOptOverall,
      'ShirtCrewNeck' => l10n.avatarOptShirtCrewNeck,
      'ShirtScoopNeck' => l10n.avatarOptShirtScoopNeck,
      'ShirtVNeck' => l10n.avatarOptShirtVNeck,
      // Clothe colors (Black/Red/Pink covered above)
      'Blue01' => l10n.avatarOptBlue01,
      'Blue02' => l10n.avatarOptBlue02,
      'Blue03' => l10n.avatarOptBlue03,
      'Gray01' => l10n.avatarOptGray01,
      'Gray02' => l10n.avatarOptGray02,
      'Heather' => l10n.avatarOptHeather,
      'PastelBlue' => l10n.avatarOptPastelBlue,
      'PastelGreen' => l10n.avatarOptPastelGreen,
      'PastelOrange' => l10n.avatarOptPastelOrange,
      'PastelRed' => l10n.avatarOptPastelRed,
      'PastelYellow' => l10n.avatarOptPastelYellow,
      'Pink' => l10n.avatarOptPink,
      'White' => l10n.avatarOptWhite,
      // Eyes / eyebrows / mouth (Default shared)
      'Close' => l10n.avatarOptClose,
      'Cry' => l10n.avatarOptCry,
      'Default' => l10n.avatarOptDefault,
      'Dizzy' => l10n.avatarOptDizzy,
      'EyeRoll' => l10n.avatarOptEyeRoll,
      'Happy' => l10n.avatarOptHappy,
      'Hearts' => l10n.avatarOptHearts,
      'Side' => l10n.avatarOptSide,
      'Squint' => l10n.avatarOptSquint,
      'Surprised' => l10n.avatarOptSurprised,
      'Wink' => l10n.avatarOptWink,
      'WinkWacky' => l10n.avatarOptWinkWacky,
      'Angry' => l10n.avatarOptAngry,
      'AngryNatural' => l10n.avatarOptAngryNatural,
      'DefaultNatural' => l10n.avatarOptDefaultNatural,
      'FlatNatural' => l10n.avatarOptFlatNatural,
      'RaisedExcited' => l10n.avatarOptRaisedExcited,
      'RaisedExcitedNatural' => l10n.avatarOptRaisedExcitedNatural,
      'SadConcerned' => l10n.avatarOptSadConcerned,
      'SadConcernedNatural' => l10n.avatarOptSadConcernedNatural,
      'UnibrowNatural' => l10n.avatarOptUnibrowNatural,
      'UpDown' => l10n.avatarOptUpDown,
      'UpDownNatural' => l10n.avatarOptUpDownNatural,
      'Concerned' => l10n.avatarOptConcerned,
      'Disbelief' => l10n.avatarOptDisbelief,
      'Eating' => l10n.avatarOptEating,
      'Grimace' => l10n.avatarOptGrimace,
      'Sad' => l10n.avatarOptSad,
      'ScreamOpen' => l10n.avatarOptScreamOpen,
      'Serious' => l10n.avatarOptSerious,
      'Smile' => l10n.avatarOptSmile,
      'Tongue' => l10n.avatarOptTongue,
      'Twinkle' => l10n.avatarOptTwinkle,
      'Vomit' => l10n.avatarOptVomit,
      _ => _humanize(value),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map(
                  (opt) => ChoiceChip(
                    label: Text(
                      _localizedOption(context, opt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: selected == opt,
                    onSelected: (_) => onSelect(opt),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RandomRow extends StatelessWidget {
  const _RandomRow({required this.onRandom});
  final VoidCallback onRandom;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text('🎲', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            context.l10n.avatarFeelingLucky,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.avatarGenerateRandomHint,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRandom,
            icon: const Icon(Icons.shuffle_rounded),
            label: Text(context.l10n.avatarRandomizeAvatar),
          ),
        ],
      ),
    ),
  );
}
