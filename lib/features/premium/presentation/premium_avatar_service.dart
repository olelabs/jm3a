import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/app_router.dart';

/// Represents a premium avatar (emoji-based for now; can be extended to images).
class PremiumAvatar {
  const PremiumAvatar({
    required this.id,
    required this.emoji,
    required this.name,
    this.isPremiumPlus = false,
  });
  final String id;
  final String emoji;
  final String name;
  final bool isPremiumPlus;
}

class PremiumAvatarService extends ChangeNotifier {
  PremiumAvatarService._();
  static final PremiumAvatarService instance = PremiumAvatarService._();

  static const _prefKey = 'selected_avatar_id';

  String? _selectedId;
  String? get selectedId => _selectedId;

  static const List<PremiumAvatar> allAvatars = [
    // Free avatars (emoji style)
    PremiumAvatar(id: 'star', emoji: '⭐', name: 'Star'),
    PremiumAvatar(id: 'fire', emoji: '🔥', name: 'Fire'),
    PremiumAvatar(id: 'lightning', emoji: '⚡', name: 'Lightning'),
    // Premium avatars
    PremiumAvatar(id: 'crown', emoji: '👑', name: 'Crown'),
    PremiumAvatar(id: 'diamond', emoji: '💎', name: 'Diamond'),
    PremiumAvatar(id: 'wizard', emoji: '🧙', name: 'Wizard'),
    PremiumAvatar(id: 'ninja', emoji: '🥷', name: 'Ninja'),
    PremiumAvatar(id: 'robot', emoji: '🤖', name: 'Robot'),
    PremiumAvatar(id: 'alien', emoji: '👽', name: 'Alien'),
    PremiumAvatar(id: 'ghost', emoji: '👻', name: 'Ghost'),
    PremiumAvatar(id: 'panda', emoji: '🐼', name: 'Panda'),
    PremiumAvatar(id: 'dragon', emoji: '🐉', name: 'Dragon'),
    // Premium Plus avatars
    PremiumAvatar(
      id: 'unicorn',
      emoji: '🦄',
      name: 'Unicorn',
      isPremiumPlus: true,
    ),
    PremiumAvatar(
      id: 'phoenix',
      emoji: '🦅',
      name: 'Phoenix',
      isPremiumPlus: true,
    ),
    PremiumAvatar(
      id: 'crystal',
      emoji: '🔮',
      name: 'Crystal',
      isPremiumPlus: true,
    ),
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedId = prefs.getString(_prefKey);
    notifyListeners();
  }

  Future<void> select(String id) async {
    _selectedId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, id);
    // Persist to profile
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_emoji': id})
          .eq('id', userId)
          .catchError((_) {});
    }
    notifyListeners();
  }

  String get currentEmoji {
    final a = allAvatars.firstWhere(
      (a) => a.id == _selectedId,
      orElse: () => allAvatars.first,
    );
    return a.emoji;
  }

  List<PremiumAvatar> availableFor({
    required bool isPremium,
    required bool isPremiumPlus,
  }) => allAvatars.where((a) {
    if (a.isPremiumPlus) return isPremiumPlus;
    if (!isPremium) return ['star', 'fire', 'lightning'].contains(a.id);
    return true;
  }).toList();
}

class AvatarPickerScreen extends StatelessWidget {
  const AvatarPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final avatarService = context.watch<PremiumAvatarService>();
    final user = context.watch<AuthProvider>().currentUser;
    final isPremium = user?.isPremiumActive ?? false;
    final isPremiumPlus = user?.premiumTier == 'premium_plus';

    final available = avatarService.availableFor(
      isPremium: isPremium,
      isPremiumPlus: isPremiumPlus,
    );
    final locked = PremiumAvatarService.allAvatars
        .where((a) => !available.contains(a))
        .toList();
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Avatar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Your Avatars',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: available
                .map(
                  (a) => _AvatarTile(
                    avatar: a,
                    isSelected: avatarService.selectedId == a.id,
                    locked: false,
                    onTap: () => avatarService.select(a.id),
                  ),
                )
                .toList(),
          ),
          if (locked.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Premium Avatars',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Upgrade to unlock',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: locked
                  .map(
                    (a) => _AvatarTile(
                      avatar: a,
                      isSelected: false,
                      locked: true,
                      onTap: () => AppRouter.router.push(RouteNames.premium),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.avatar,
    required this.isSelected,
    required this.locked,
    required this.onTap,
  });
  final PremiumAvatar avatar;
  final bool isSelected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(avatar.emoji, style: const TextStyle(fontSize: 32)),
                  Text(
                    avatar.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (locked)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
