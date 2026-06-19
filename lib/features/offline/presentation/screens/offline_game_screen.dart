// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/providers/auth_provider.dart';
// import '../../../../core/router/route_names.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../data/offline_game_provider.dart';
// import '../../data/offline_repository.dart';
// import '../../domain/offline_session.dart';
// import 'offline_setup_screen.dart';
// import 'offline_play_screen.dart';
// import 'lan_host_screen.dart';
// import 'lan_join_screen.dart';

// class OfflineGameScreen extends StatefulWidget {
//   const OfflineGameScreen({super.key});

//   @override
//   State<OfflineGameScreen> createState() => _OfflineGameScreenState();
// }

// class _OfflineGameScreenState extends State<OfflineGameScreen> {
//   late final OfflineGameProvider _provider;
//   OfflineSession? _resumable;
//   int _packCount = 0;
//   bool _checking = true;

//   @override
//   void initState() {
//     super.initState();
//     _provider = OfflineGameProvider(repository: OfflineRepository.instance);
//     _checkState();
//   }

//   @override
//   void dispose() {
//     _provider.dispose();
//     super.dispose();
//   }

//   Future<void> _checkState() async {
//     try {
//       final results = await Future.wait([
//         OfflineRepository.instance.getActiveSession(),
//         OfflineRepository.instance.getAvailablePackCount(),
//       ]);
//       if (mounted) {
//         setState(() {
//           _resumable = results[0] as OfflineSession?;
//           _packCount = results[1] as int;
//           _checking = false;
//         });
//       }
//     } catch (_) {
//       if (mounted) setState(() => _checking = false);
//     }
//   }

//   void _exitGuestMode() {
//     context.read<AuthProvider>().exitGuestMode();
//     context.go(RouteNames.authEmail);
//   }

//   // ── Navigation helpers ────────────────────────────────────────────────────

//   void _goToSetup(OfflineMode mode) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ChangeNotifierProvider.value(
//           value: _provider,
//           child: OfflineSetupScreen(mode: mode),
//         ),
//       ),
//     );
//   }

//   Future<void> _resumeSession() async {
//     final ok = await _provider.resumeActiveSession();
//     if (!mounted) return;
//     if (ok) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ChangeNotifierProvider.value(
//             value: _provider,
//             child: const OfflinePlayScreen(),
//           ),
//         ),
//       );
//     } else {
//       context.showErrorSnackBar('Could not resume session.');
//     }
//   }

//   void _showLanOptions() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (_) => _LanSheet(
//         canHost: _packCount > 0,
//         onHost: () => _goToSetup(OfflineMode.lan),
//         onJoin: () => Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => ChangeNotifierProvider.value(
//               value: _provider,
//               child: const LanJoinScreen(),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;

//     return ChangeNotifierProvider.value(
//       value: _provider,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Offline Play'),
//           actions: [_StatusBadge(), const SizedBox(width: 8)],
//         ),
//         body: _checking
//             ? const Center(child: CircularProgressIndicator())
//             : SingleChildScrollView(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Pack banner
//                     _PacksBanner(packCount: _packCount),
//                     const SizedBox(height: 20),

//                     // Resume card
//                     if (_resumable != null) ...[
//                       _ResumeCard(
//                         session: _resumable!,
//                         onResume: _resumeSession,
//                         onDiscard: () {
//                           _provider.reset();
//                           setState(() => _resumable = null);
//                         },
//                       ).animate().fadeIn().slideY(begin: -0.05, end: 0),
//                       const SizedBox(height: 16),
//                     ],

//                     // Mode label
//                     Text(
//                       'Choose mode',
//                       style: theme.textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 12),

//                     // Pass & Play
//                     _ModeCard(
//                           emoji: '📱',
//                           title: 'Pass & Play',
//                           subtitle: 'One device. Players take turns.',
//                           color: AppColors.navyBlue,
//                           isEnabled: _packCount > 0,
//                           onTap: () => _goToSetup(OfflineMode.passAndPlay),
//                         )
//                         .animate(delay: 40.ms)
//                         .fadeIn()
//                         .slideX(begin: -0.05, end: 0),

//                     const SizedBox(height: 12),

//                     // LAN
//                     _ModeCard(
//                       emoji: '📡',
//                       title: 'LAN Multiplayer',
//                       subtitle:
//                           'Same WiFi / hotspot. Each player on their own device.',
//                       color: AppColors.tealGreen,
//                       isEnabled:
//                           true, // Always enabled — join doesn't need packs
//                       onTap: _showLanOptions,
//                     ).animate(delay: 80.ms).fadeIn().slideX(begin: 0.05, end: 0),

//                     if (_packCount == 0) ...[
//                       const SizedBox(height: 20),
//                       _NoPacksNotice(onSignIn: _exitGuestMode),
//                     ],

//                     const SizedBox(height: 24),
//                     _InfoBox(),
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }
// }

// // ── Status badge ──────────────────────────────────────────────────────────────

// class _StatusBadge extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     // In guest / offline mode this is always offline for multiplayer features.
//     const isOnline = false;
//     final color = isOnline ? AppColors.successGreen : AppColors.warningAmber;
//     return Padding(
//       padding: const EdgeInsets.only(right: 4),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 8,
//             height: 8,
//             decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//           ),
//           const SizedBox(width: 4),
//           Text(
//             isOnline ? 'Online' : 'Offline',
//             style: TextStyle(
//               fontSize: 12,
//               color: color,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Pack availability banner ──────────────────────────────────────────────────

// class _PacksBanner extends StatelessWidget {
//   const _PacksBanner({required this.packCount});
//   final int packCount;

//   @override
//   Widget build(BuildContext context) {
//     final hasAny = packCount > 0;
//     final color = hasAny ? AppColors.successGreen : AppColors.warningAmber;
//     final icon = hasAny ? Icons.offline_pin_rounded : Icons.cloud_off_rounded;
//     final text = hasAny
//         ? '$packCount pack${packCount == 1 ? '' : 's'} available offline'
//         : 'No packs downloaded. Sign in and download packs first.';

//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.09),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.25)),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: color, size: 20),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyle(
//                 color: color,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 13,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Resume card ───────────────────────────────────────────────────────────────

// class _ResumeCard extends StatelessWidget {
//   const _ResumeCard({
//     required this.session,
//     required this.onResume,
//     required this.onDiscard,
//   });
//   final OfflineSession session;
//   final VoidCallback onResume;
//   final VoidCallback onDiscard;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surfaceContainerHighest,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.infoBlue.withOpacity(0.25)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Text('🔄', style: TextStyle(fontSize: 20)),
//               const SizedBox(width: 8),
//               Text(
//                 'Resume game',
//                 style: theme.textTheme.titleSmall?.copyWith(
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.infoBlue,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Text(
//             '${session.packName} · ${session.players.length} players',
//             style: theme.textTheme.bodySmall?.copyWith(
//               color: theme.colorScheme.onSurfaceVariant,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: onDiscard,
//                   style: OutlinedButton.styleFrom(
//                     visualDensity: VisualDensity.compact,
//                   ),
//                   child: const Text('Discard'),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 flex: 2,
//                 child: FilledButton.tonal(
//                   onPressed: onResume,
//                   child: const Text('Resume'),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Mode card ─────────────────────────────────────────────────────────────────

// class _ModeCard extends StatelessWidget {
//   const _ModeCard({
//     required this.emoji,
//     required this.title,
//     required this.subtitle,
//     required this.color,
//     required this.isEnabled,
//     required this.onTap,
//   });
//   final String emoji;
//   final String title;
//   final String subtitle;
//   final Color color;
//   final bool isEnabled;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Opacity(
//       opacity: isEnabled ? 1.0 : 0.45,
//       child: GestureDetector(
//         onTap: isEnabled
//             ? onTap
//             : () => context.showSnackBar(
//                 'Download packs first to play offline.',
//                 isError: false,
//               ),
//         child: Container(
//           padding: const EdgeInsets.all(18),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [color, color.withOpacity(0.8)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: color.withOpacity(0.2),
//                 blurRadius: 12,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Row(
//             children: [
//               Text(emoji, style: const TextStyle(fontSize: 36)),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 17,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       subtitle,
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.8),
//                         fontSize: 13,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const Icon(
//                 Icons.chevron_right_rounded,
//                 color: Colors.white,
//                 size: 24,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ── LAN bottom sheet ──────────────────────────────────────────────────────────

// class _LanSheet extends StatelessWidget {
//   const _LanSheet({
//     required this.onHost,
//     required this.onJoin,
//     required this.canHost,
//   });
//   final VoidCallback onHost;
//   final VoidCallback onJoin;
//   final bool canHost;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Container(
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surface,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 36,
//             height: 4,
//             decoration: BoxDecoration(
//               color: theme.colorScheme.outlineVariant,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             'LAN Multiplayer',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 20),
//           ListTile(
//             leading: CircleAvatar(
//               backgroundColor: canHost ? AppColors.navyBlue : Colors.grey,
//               child: const Text('📡', style: TextStyle(fontSize: 18)),
//             ),
//             title: const Text('Host a room'),
//             subtitle: Text(
//               canHost
//                   ? 'Create a LAN room on your device'
//                   : 'Download a pack first to host',
//             ),
//             trailing: const Icon(Icons.chevron_right_rounded),
//             enabled: canHost,
//             onTap: canHost
//                 ? () {
//                     Navigator.pop(context);
//                     onHost();
//                   }
//                 : null,
//           ),
//           const Divider(height: 1),
//           ListTile(
//             leading: const CircleAvatar(
//               backgroundColor: AppColors.tealGreen,
//               child: Text('🔍', style: TextStyle(fontSize: 18)),
//             ),
//             title: const Text('Join a room'),
//             subtitle: const Text('Find nearby LAN rooms to join'),
//             trailing: const Icon(Icons.chevron_right_rounded),
//             onTap: () {
//               Navigator.pop(context);
//               onJoin();
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── No packs notice ───────────────────────────────────────────────────────────

// class _NoPacksNotice extends StatelessWidget {
//   const _NoPacksNotice({required this.onSignIn});
//   final VoidCallback onSignIn;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: AppColors.infoBlue.withOpacity(0.07),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.infoBlue.withOpacity(0.2)),
//       ),
//       child: Row(
//         children: [
//           const Icon(
//             Icons.info_outline_rounded,
//             color: AppColors.infoBlue,
//             size: 18,
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               'Sign in to download packs and unlock all games.',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: AppColors.infoBlue.withOpacity(0.9),
//               ),
//             ),
//           ),
//           TextButton(
//             onPressed: onSignIn,
//             style: TextButton.styleFrom(
//               foregroundColor: AppColors.infoBlue,
//               visualDensity: VisualDensity.compact,
//             ),
//             child: const Text('Sign In'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Info box ──────────────────────────────────────────────────────────────────

// class _InfoBox extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surfaceContainerHighest,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: const Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'ℹ️  How offline works',
//             style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
//           ),
//           SizedBox(height: 8),
//           _Bullet('Pass & Play: one phone, pass between players each turn.'),
//           _Bullet('LAN: each player on their own phone, same WiFi or hotspot.'),
//           _Bullet('Downloaded packs work fully offline — no internet needed.'),
//         ],
//       ),
//     );
//   }
// }

// class _Bullet extends StatelessWidget {
//   const _Bullet(this.text);
//   final String text;
//   @override
//   Widget build(BuildContext context) => Padding(
//     padding: const EdgeInsets.only(bottom: 4),
//     child: Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text('•  ', style: TextStyle(fontSize: 12)),
//         Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
//       ],
//     ),
//   );
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/offline_game_provider.dart';
import '../../data/offline_repository.dart';
import '../../domain/offline_session.dart';
import 'offline_setup_screen.dart';
import 'offline_play_screen.dart';
import 'lan_host_screen.dart';
import 'lan_join_screen.dart';

class OfflineGameScreen extends StatefulWidget {
  const OfflineGameScreen({super.key});

  @override
  State<OfflineGameScreen> createState() => _OfflineGameScreenState();
}

class _OfflineGameScreenState extends State<OfflineGameScreen> {
  late final OfflineGameProvider _provider;
  OfflineSession? _resumable;
  int _packCount = 0;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _provider = OfflineGameProvider(repository: OfflineRepository.instance);
    _checkState();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _checkState() async {
    try {
      final results = await Future.wait([
        OfflineRepository.instance.getActiveSession(),
        OfflineRepository.instance.getAvailablePackCount(),
      ]);
      if (mounted) {
        setState(() {
          _resumable = results[0] as OfflineSession?;
          _packCount = results[1] as int;
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _exitGuestMode() {
    context.read<AuthProvider>().exitGuestMode();
    context.go(RouteNames.authEmail);
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _goToSetup(OfflineMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: _provider,
          child: OfflineSetupScreen(mode: mode),
        ),
      ),
    );
  }

  Future<void> _resumeSession() async {
    final ok = await _provider.resumeActiveSession();
    if (!mounted) return;
    if (ok) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: _provider,
            child: const OfflinePlayScreen(),
          ),
        ),
      );
    } else {
      context.showErrorSnackBar('Could not resume session.');
    }
  }

  void _showLanOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanSheet(
        canHost: _packCount > 0,
        onHost: () => _goToSetup(OfflineMode.lan),
        onJoin: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: _provider,
              child: const LanJoinScreen(),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Offline Play'),
          actions: [_StatusBadge(), const SizedBox(width: 8)],
        ),
        body: _checking
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pack banner
                    _PacksBanner(packCount: _packCount),
                    const SizedBox(height: 20),

                    // Resume card
                    if (_resumable != null) ...[
                      _ResumeCard(
                        session: _resumable!,
                        onResume: _resumeSession,
                        onDiscard: () {
                          _provider.reset();
                          setState(() => _resumable = null);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Mode label
                    Text(
                      'Choose mode',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pass & Play
                    _ModeCard(
                      emoji: '📱',
                      title: 'Pass & Play',
                      subtitle: 'One device. Players take turns.',
                      color: AppColors.navyBlue,
                      isEnabled: _packCount > 0,
                      onTap: () => _goToSetup(OfflineMode.passAndPlay),
                    ),

                    const SizedBox(height: 12),

                    // LAN
                    _ModeCard(
                      emoji: '📡',
                      title: 'LAN Multiplayer',
                      subtitle:
                          'Same WiFi / hotspot. Each player on their own device.',
                      color: AppColors.tealGreen,
                      isEnabled:
                          true, // Always enabled — join doesn't need packs
                      onTap: _showLanOptions,
                    ),

                    if (_packCount == 0) ...[
                      const SizedBox(height: 20),
                      _NoPacksNotice(onSignIn: _exitGuestMode),
                    ],

                    const SizedBox(height: 24),
                    _InfoBox(),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // In guest / offline mode this is always offline for multiplayer features.
    const isOnline = false;
    final color = isOnline ? AppColors.successGreen : AppColors.warningAmber;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pack availability banner ──────────────────────────────────────────────────

class _PacksBanner extends StatelessWidget {
  const _PacksBanner({required this.packCount});
  final int packCount;

  @override
  Widget build(BuildContext context) {
    final hasAny = packCount > 0;
    final color = hasAny ? AppColors.successGreen : AppColors.warningAmber;
    final icon = hasAny ? Icons.offline_pin_rounded : Icons.cloud_off_rounded;
    final text = hasAny
        ? '$packCount pack${packCount == 1 ? '' : 's'} available offline'
        : 'No packs downloaded. Sign in and download packs first.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Resume card ───────────────────────────────────────────────────────────────

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.session,
    required this.onResume,
    required this.onDiscard,
  });
  final OfflineSession session;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.infoBlue.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔄', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Resume game',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.infoBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${session.packName} · ${session.players.length} players',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDiscard,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Discard'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.tonal(
                  onPressed: onResume,
                  child: const Text('Resume'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Mode card ─────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isEnabled,
    required this.onTap,
  });
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: isEnabled
            ? onTap
            : () => context.showSnackBar(
                'Download packs first to play offline.',
                isError: false,
              ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── LAN bottom sheet ──────────────────────────────────────────────────────────

class _LanSheet extends StatelessWidget {
  const _LanSheet({
    required this.onHost,
    required this.onJoin,
    required this.canHost,
  });
  final VoidCallback onHost;
  final VoidCallback onJoin;
  final bool canHost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'LAN Multiplayer',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: canHost ? AppColors.navyBlue : Colors.grey,
              child: const Text('📡', style: TextStyle(fontSize: 18)),
            ),
            title: const Text('Host a room'),
            subtitle: Text(
              canHost
                  ? 'Create a LAN room on your device'
                  : 'Download a pack first to host',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            enabled: canHost,
            onTap: canHost
                ? () {
                    Navigator.pop(context);
                    onHost();
                  }
                : null,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.tealGreen,
              child: Text('🔍', style: TextStyle(fontSize: 18)),
            ),
            title: const Text('Join a room'),
            subtitle: const Text('Find nearby LAN rooms to join'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.pop(context);
              onJoin();
            },
          ),
        ],
      ),
    );
  }
}

// ── No packs notice ───────────────────────────────────────────────────────────

class _NoPacksNotice extends StatelessWidget {
  const _NoPacksNotice({required this.onSignIn});
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBlue.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.infoBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.infoBlue,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sign in to download packs and unlock all games.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.infoBlue.withOpacity(0.9),
              ),
            ),
          ),
          TextButton(
            onPressed: onSignIn,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.infoBlue,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}

// ── Info box ──────────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ℹ️  How offline works',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          SizedBox(height: 8),
          _Bullet('Pass & Play: one phone, pass between players each turn.'),
          _Bullet('LAN: each player on their own phone, same WiFi or hotspot.'),
          _Bullet('Downloaded packs work fully offline — no internet needed.'),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  ', style: TextStyle(fontSize: 12)),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}
