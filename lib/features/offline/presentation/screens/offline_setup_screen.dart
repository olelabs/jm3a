// // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // // // import 'package:provider/provider.dart';

// // // // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // // // import '../../../../shared/widgets/buttons/j_button.dart';
// // // // // // // // import '../../../games/engine/base_game_engine.dart';
// // // // // // // // import '../../data/offline_game_provider.dart';
// // // // // // // // import '../../data/offline_repository.dart';
// // // // // // // // import '../../domain/offline_session.dart';
// // // // // // // // import 'offline_play_screen.dart';
// // // // // // // // import 'lan_host_screen.dart';

// // // // // // // // /// Setup screen shared by both pass-and-play and LAN host modes.
// // // // // // // // /// Steps: 1. Pack selection  2. Game settings  3. Players
// // // // // // // // class OfflineSetupScreen extends StatefulWidget {
// // // // // // // //   const OfflineSetupScreen({super.key, required this.mode});
// // // // // // // //   final OfflineMode mode;

// // // // // // // //   @override
// // // // // // // //   State<OfflineSetupScreen> createState() => _OfflineSetupScreenState();
// // // // // // // // }

// // // // // // // // class _OfflineSetupScreenState extends State<OfflineSetupScreen> {
// // // // // // // //   // ── Setup state ─────────────────────────────────────────────────────────
// // // // // // // //   List<OfflinePack> _packs        = [];
// // // // // // // //   OfflinePack?      _selectedPack;
// // // // // // // //   GameType          _gameType     = GameType.truthOrDare;
// // // // // // // //   int               _maxRounds    = 10;
// // // // // // // //   bool              _allowSpicy   = false;
// // // // // // // //   bool              _timerEnabled = false;
// // // // // // // //   int               _timerSecs    = 60;
// // // // // // // //   bool              _allowSkip    = true;

// // // // // // // //   final List<String>       _players    = [];
// // // // // // // //   final _playerCtrl = TextEditingController();
// // // // // // // //   bool _isLoading = true;

// // // // // // // //   @override
// // // // // // // //   void initState() {
// // // // // // // //     super.initState();
// // // // // // // //     _loadPacks();
// // // // // // // //   }

// // // // // // // //   @override
// // // // // // // //   void dispose() {
// // // // // // // //     _playerCtrl.dispose();
// // // // // // // //     super.dispose();
// // // // // // // //   }

// // // // // // // //   Future<void> _loadPacks() async {
// // // // // // // //     setState(() => _isLoading = true);
// // // // // // // //     final packs = await OfflineRepository.instance.getAvailablePacks(
// // // // // // // //         gameType: _gameType);
// // // // // // // //     setState(() {
// // // // // // // //       _packs = packs.where((p) => p.isUsable).toList();
// // // // // // // //       _selectedPack = _packs.isNotEmpty ? _packs.first : null;
// // // // // // // //       _isLoading = false;
// // // // // // // //     });
// // // // // // // //   }

// // // // // // // //   void _addPlayer() {
// // // // // // // //     final name = _playerCtrl.text.trim();
// // // // // // // //     if (name.isEmpty || _players.length >= 12) return;
// // // // // // // //     if (_players.any((p) => p.toLowerCase() == name.toLowerCase())) {
// // // // // // // //       context.showErrorSnackBar('Name "$name" already added');
// // // // // // // //       return;
// // // // // // // //     }
// // // // // // // //     setState(() { _players.add(name); _playerCtrl.clear(); });
// // // // // // // //   }

// // // // // // // //   Future<void> _start() async {
// // // // // // // //     if (_selectedPack == null) return;
// // // // // // // //     if (_players.length < 2 && widget.mode == OfflineMode.passAndPlay) {
// // // // // // // //       context.showErrorSnackBar('Add at least 2 players');
// // // // // // // //       return;
// // // // // // // //     }
// // // // // // // //     if (widget.mode == OfflineMode.lan && _players.isEmpty) {
// // // // // // // //       context.showErrorSnackBar('Enter your name');
// // // // // // // //       return;
// // // // // // // //     }

// // // // // // // //     final config = GameConfig(
// // // // // // // //       maxRounds:        _maxRounds,
// // // // // // // //       turnTimerSeconds: _timerEnabled ? _timerSecs : 0,
// // // // // // // //       allowSkip:        _allowSkip,
// // // // // // // //       allowSpicy:       _allowSpicy,
// // // // // // // //       packId:           _selectedPack!.id,
// // // // // // // //       language:         _selectedPack!.language,
// // // // // // // //     );

// // // // // // // //     final provider = context.read<OfflineGameProvider>();

// // // // // // // //     if (widget.mode == OfflineMode.passAndPlay) {
// // // // // // // //       await provider.startPassAndPlay(
// // // // // // // //         gameType:    _gameType,
// // // // // // // //         config:      config,
// // // // // // // //         playerNames: _players,
// // // // // // // //         packId:      _selectedPack!.id,
// // // // // // // //         packName:    _selectedPack!.name,
// // // // // // // //       );
// // // // // // // //       if (provider.loadState == OfflineLoadState.ready && mounted) {
// // // // // // // //         Navigator.pushReplacement(
// // // // // // // //           context,
// // // // // // // //           MaterialPageRoute(
// // // // // // // //             builder: (_) => ChangeNotifierProvider.value(
// // // // // // // //               value: provider,
// // // // // // // //               child: const OfflinePlayScreen(),
// // // // // // // //             ),
// // // // // // // //           ),
// // // // // // // //         );
// // // // // // // //       }
// // // // // // // //     } else {
// // // // // // // //       // LAN host — go to lobby screen
// // // // // // // //       if (!mounted) return;
// // // // // // // //       Navigator.pushReplacement(
// // // // // // // //         context,
// // // // // // // //         MaterialPageRoute(
// // // // // // // //           builder: (_) => ChangeNotifierProvider.value(
// // // // // // // //             value: provider,
// // // // // // // //             child: LanHostScreen(
// // // // // // // //               hostName:   _players.isNotEmpty ? _players.first : 'Host',
// // // // // // // //               config:     config,
// // // // // // // //               gameType:   _gameType,
// // // // // // // //               pack:       _selectedPack!,
// // // // // // // //             ),
// // // // // // // //           ),
// // // // // // // //         ),
// // // // // // // //       );
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     final theme   = context.theme;
// // // // // // // //     final isLan   = widget.mode == OfflineMode.lan;
// // // // // // // //     final canStart = _selectedPack != null &&
// // // // // // // //         (isLan ? _players.isNotEmpty : _players.length >= 2);

// // // // // // // //     return Scaffold(
// // // // // // // //       appBar: AppBar(
// // // // // // // //         title: Text(isLan ? 'Host LAN Room' : 'Pass & Play Setup'),
// // // // // // // //       ),
// // // // // // // //       body: Consumer<OfflineGameProvider>(
// // // // // // // //         builder: (ctx, provider, _) {
// // // // // // // //           if (provider.loadState == OfflineLoadState.loading) {
// // // // // // // //             return const Center(
// // // // // // // //               child: Column(
// // // // // // // //                 mainAxisSize: MainAxisSize.min,
// // // // // // // //                 children: [
// // // // // // // //                   CircularProgressIndicator(),
// // // // // // // //                   SizedBox(height: 16),
// // // // // // // //                   Text('Loading cards…'),
// // // // // // // //                 ],
// // // // // // // //               ),
// // // // // // // //             );
// // // // // // // //           }

// // // // // // // //           if (provider.loadState == OfflineLoadState.error) {
// // // // // // // //             return Center(
// // // // // // // //               child: Padding(
// // // // // // // //                 padding: const EdgeInsets.all(24),
// // // // // // // //                 child: Column(
// // // // // // // //                   mainAxisSize: MainAxisSize.min,
// // // // // // // //                   children: [
// // // // // // // //                     const Text('❌', style: TextStyle(fontSize: 48)),
// // // // // // // //                     const SizedBox(height: 12),
// // // // // // // //                     Text(provider.error ?? 'Setup failed.',
// // // // // // // //                         textAlign: TextAlign.center),
// // // // // // // //                     const SizedBox(height: 16),
// // // // // // // //                     OutlinedButton(
// // // // // // // //                       onPressed: () => provider.reset(),
// // // // // // // //                       child: const Text('Try again'),
// // // // // // // //                     ),
// // // // // // // //                   ],
// // // // // // // //                 ),
// // // // // // // //               ),
// // // // // // // //             );
// // // // // // // //           }

// // // // // // // //           return SingleChildScrollView(
// // // // // // // //             padding: const EdgeInsets.all(20),
// // // // // // // //             child: Column(
// // // // // // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // //               children: [
// // // // // // // //                 // ── Game type ─────────────────────────────────────────────
// // // // // // // //                 Text('Game',
// // // // // // // //                     style: theme.textTheme.titleSmall?.copyWith(
// // // // // // // //                         fontWeight: FontWeight.w700)),
// // // // // // // //                 const SizedBox(height: 8),
// // // // // // // //                 _GameTypeSelector(
// // // // // // // //                   selected: _gameType,
// // // // // // // //                   onChanged: (gt) {
// // // // // // // //                     setState(() => _gameType = gt);
// // // // // // // //                     _loadPacks();
// // // // // // // //                   },
// // // // // // // //                 ).animate().fadeIn(),

// // // // // // // //                 const SizedBox(height: 20),

// // // // // // // //                 // ── Pack selection ────────────────────────────────────────
// // // // // // // //                 Text('Pack',
// // // // // // // //                     style: theme.textTheme.titleSmall?.copyWith(
// // // // // // // //                         fontWeight: FontWeight.w700)),
// // // // // // // //                 const SizedBox(height: 8),
// // // // // // // //                 if (_isLoading)
// // // // // // // //                   const Center(child: CircularProgressIndicator())
// // // // // // // //                 else if (_packs.isEmpty)
// // // // // // // //                   _NoPacksNotice(gameType: _gameType)
// // // // // // // //                 else
// // // // // // // //                   _PackSelector(
// // // // // // // //                     packs:    _packs,
// // // // // // // //                     selected: _selectedPack,
// // // // // // // //                     onSelect: (p) => setState(() => _selectedPack = p),
// // // // // // // //                   ).animate(delay: 40.ms).fadeIn(),

// // // // // // // //                 const SizedBox(height: 20),

// // // // // // // //                 // ── Settings ──────────────────────────────────────────────
// // // // // // // //                 _GameSettings(
// // // // // // // //                   maxRounds:    _maxRounds,
// // // // // // // //                   allowSpicy:   _allowSpicy,
// // // // // // // //                   timerEnabled: _timerEnabled,
// // // // // // // //                   timerSecs:    _timerSecs,
// // // // // // // //                   allowSkip:    _allowSkip,
// // // // // // // //                   onMaxRoundsChanged:  (v) => setState(() => _maxRounds = v),
// // // // // // // //                   onSpicyChanged:      (v) => setState(() => _allowSpicy = v),
// // // // // // // //                   onTimerChanged:      (v) => setState(() => _timerEnabled = v),
// // // // // // // //                   onTimerSecsChanged:  (v) => setState(() => _timerSecs = v),
// // // // // // // //                   onSkipChanged:       (v) => setState(() => _allowSkip = v),
// // // // // // // //                 ).animate(delay: 60.ms).fadeIn(),

// // // // // // // //                 const SizedBox(height: 20),

// // // // // // // //                 // ── Players ───────────────────────────────────────────────
// // // // // // // //                 Text(isLan ? 'Your name' : 'Players (${_players.length}/12)',
// // // // // // // //                     style: theme.textTheme.titleSmall?.copyWith(
// // // // // // // //                         fontWeight: FontWeight.w700)),
// // // // // // // //                 const SizedBox(height: 8),

// // // // // // // //                 Row(
// // // // // // // //                   children: [
// // // // // // // //                     Expanded(
// // // // // // // //                       child: TextField(
// // // // // // // //                         controller: _playerCtrl,
// // // // // // // //                         textCapitalization: TextCapitalization.words,
// // // // // // // //                         textInputAction: TextInputAction.done,
// // // // // // // //                         onSubmitted: (_) => _addPlayer(),
// // // // // // // //                         decoration: InputDecoration(
// // // // // // // //                           hintText:   isLan ? 'Your name' : 'Player name',
// // // // // // // //                           prefixIcon: const Icon(Icons.person_outline_rounded),
// // // // // // // //                         ),
// // // // // // // //                       ),
// // // // // // // //                     ),
// // // // // // // //                     const SizedBox(width: 8),
// // // // // // // //                     FilledButton(
// // // // // // // //                         onPressed: _addPlayer,
// // // // // // // //                         child: Text(isLan ? 'Set' : 'Add')),
// // // // // // // //                   ],
// // // // // // // //                 ),

// // // // // // // //                 if (_players.isNotEmpty) ...[
// // // // // // // //                   const SizedBox(height: 10),
// // // // // // // //                   Wrap(
// // // // // // // //                     spacing: 8, runSpacing: 8,
// // // // // // // //                     children: _players.asMap().entries.map((e) => Chip(
// // // // // // // //                       label: Text(isLan
// // // // // // // //                           ? e.value
// // // // // // // //                           : '${e.key + 1}. ${e.value}'),
// // // // // // // //                       deleteIcon: const Icon(Icons.close_rounded, size: 14),
// // // // // // // //                       onDeleted: isLan && e.key == 0
// // // // // // // //                           ? null
// // // // // // // //                           : () => setState(() => _players.remove(e.value)),
// // // // // // // //                     ).animate(delay: (e.key * 25).ms).fadeIn()).toList(),
// // // // // // // //                   ),
// // // // // // // //                 ],

// // // // // // // //                 const SizedBox(height: 32),

// // // // // // // //                 JButton(
// // // // // // // //                   label:     isLan ? 'Create LAN Room' : 'Start Game',
// // // // // // // //                   onPressed: canStart ? _start : null,
// // // // // // // //                   icon:      isLan
// // // // // // // //                       ? Icons.wifi_tethering_rounded
// // // // // // // //                       : Icons.play_arrow_rounded,
// // // // // // // //                 ).animate(delay: 80.ms).fadeIn(),
// // // // // // // //               ],
// // // // // // // //             ),
// // // // // // // //           );
// // // // // // // //         },
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // // ── Sub-widgets ───────────────────────────────────────────────────────────────

// // // // // // // // class _GameTypeSelector extends StatelessWidget {
// // // // // // // //   const _GameTypeSelector({required this.selected, required this.onChanged});
// // // // // // // //   final GameType selected;
// // // // // // // //   final void Function(GameType) onChanged;

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     return Row(
// // // // // // // //       children: GameType.values.map((gt) {
// // // // // // // //         final isSelected = selected == gt;
// // // // // // // //         return Expanded(
// // // // // // // //           child: Padding(
// // // // // // // //             padding: const EdgeInsets.only(right: 8),
// // // // // // // //             child: GestureDetector(
// // // // // // // //               onTap: () => onChanged(gt),
// // // // // // // //               child: AnimatedContainer(
// // // // // // // //                 duration: const Duration(milliseconds: 150),
// // // // // // // //                 padding: const EdgeInsets.symmetric(vertical: 10),
// // // // // // // //                 decoration: BoxDecoration(
// // // // // // // //                   color: isSelected
// // // // // // // //                       ? AppColors.navyBlue
// // // // // // // //                       : context.colorScheme.surfaceContainerHighest,
// // // // // // // //                   borderRadius: BorderRadius.circular(10),
// // // // // // // //                 ),
// // // // // // // //                 child: Center(
// // // // // // // //                   child: Text(
// // // // // // // //                     _emoji(gt),
// // // // // // // //                     style: const TextStyle(fontSize: 22),
// // // // // // // //                   ),
// // // // // // // //                 ),
// // // // // // // //               ),
// // // // // // // //             ),
// // // // // // // //           ),
// // // // // // // //         );
// // // // // // // //       }).toList(),
// // // // // // // //     );
// // // // // // // //   }

// // // // // // // //   String _emoji(GameType gt) => switch (gt) {
// // // // // // // //     GameType.truthOrDare    => '🎯',
// // // // // // // //     GameType.neverHaveIEver => '🍹',
// // // // // // // //     GameType.memeGame       => '😂',
// // // // // // // //   };
// // // // // // // // }

// // // // // // // // class _PackSelector extends StatelessWidget {
// // // // // // // //   const _PackSelector({
// // // // // // // //     required this.packs,
// // // // // // // //     required this.selected,
// // // // // // // //     required this.onSelect,
// // // // // // // //   });
// // // // // // // //   final List<OfflinePack>  packs;
// // // // // // // //   final OfflinePack?       selected;
// // // // // // // //   final void Function(OfflinePack) onSelect;

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     return Column(
// // // // // // // //       children: packs.map((pack) {
// // // // // // // //         final isSelected = selected?.id == pack.id;
// // // // // // // //         return GestureDetector(
// // // // // // // //           onTap: () => onSelect(pack),
// // // // // // // //           child: AnimatedContainer(
// // // // // // // //             duration: const Duration(milliseconds: 150),
// // // // // // // //             margin:  const EdgeInsets.only(bottom: 8),
// // // // // // // //             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
// // // // // // // //             decoration: BoxDecoration(
// // // // // // // //               color: isSelected
// // // // // // // //                   ? AppColors.navyBlue.withOpacity(0.08)
// // // // // // // //                   : context.colorScheme.surfaceContainerHighest,
// // // // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // // // //               border: isSelected
// // // // // // // //                   ? Border.all(color: AppColors.navyBlue, width: 2)
// // // // // // // //                   : Border.all(color: context.colorScheme.outlineVariant),
// // // // // // // //             ),
// // // // // // // //             child: Row(
// // // // // // // //               children: [
// // // // // // // //                 Icon(
// // // // // // // //                   isSelected
// // // // // // // //                       ? Icons.radio_button_checked_rounded
// // // // // // // //                       : Icons.radio_button_off_rounded,
// // // // // // // //                   color: isSelected
// // // // // // // //                       ? AppColors.navyBlue
// // // // // // // //                       : context.colorScheme.onSurfaceVariant,
// // // // // // // //                   size: 18,
// // // // // // // //                 ),
// // // // // // // //                 const SizedBox(width: 10),
// // // // // // // //                 Expanded(
// // // // // // // //                   child: Column(
// // // // // // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // //                     children: [
// // // // // // // //                       Text(pack.name,
// // // // // // // //                           style: context.textTheme.titleSmall?.copyWith(
// // // // // // // //                               fontWeight: FontWeight.w600)),
// // // // // // // //                       Text('${pack.cardCount} cards • '
// // // // // // // //                           '${pack.language.toUpperCase()} • '
// // // // // // // //                           '${pack.isFree ? "Free" : "Purchased"}',
// // // // // // // //                           style: context.textTheme.bodySmall?.copyWith(
// // // // // // // //                               color: context.colorScheme.onSurfaceVariant)),
// // // // // // // //                     ],
// // // // // // // //                   ),
// // // // // // // //                 ),
// // // // // // // //                 if (pack.expiresAt != null)
// // // // // // // //                   Text(
// // // // // // // //                     'Exp: ${pack.expiresAt!.day}/${pack.expiresAt!.month}',
// // // // // // // //                     style: context.textTheme.labelSmall?.copyWith(
// // // // // // // //                         color: AppColors.warningAmber),
// // // // // // // //                   ),
// // // // // // // //               ],
// // // // // // // //             ),
// // // // // // // //           ),
// // // // // // // //         );
// // // // // // // //       }).toList(),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // class _NoPacksNotice extends StatelessWidget {
// // // // // // // //   const _NoPacksNotice({required this.gameType});
// // // // // // // //   final GameType gameType;

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     return Container(
// // // // // // // //       padding: const EdgeInsets.all(16),
// // // // // // // //       decoration: BoxDecoration(
// // // // // // // //         color:        AppColors.warningAmber.withOpacity(0.08),
// // // // // // // //         borderRadius: BorderRadius.circular(12),
// // // // // // // //       ),
// // // // // // // //       child: Row(
// // // // // // // //         children: [
// // // // // // // //           const Icon(Icons.cloud_off_rounded,
// // // // // // // //               color: AppColors.warningAmber),
// // // // // // // //           const SizedBox(width: 10),
// // // // // // // //           Expanded(
// // // // // // // //             child: Text(
// // // // // // // //               'No ${gameType.displayName} packs downloaded. '
// // // // // // // //               'Go online to download packs.',
// // // // // // // //               style: const TextStyle(fontSize: 13),
// // // // // // // //             ),
// // // // // // // //           ),
// // // // // // // //         ],
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // class _GameSettings extends StatelessWidget {
// // // // // // // //   const _GameSettings({
// // // // // // // //     required this.maxRounds,
// // // // // // // //     required this.allowSpicy,
// // // // // // // //     required this.timerEnabled,
// // // // // // // //     required this.timerSecs,
// // // // // // // //     required this.allowSkip,
// // // // // // // //     required this.onMaxRoundsChanged,
// // // // // // // //     required this.onSpicyChanged,
// // // // // // // //     required this.onTimerChanged,
// // // // // // // //     required this.onTimerSecsChanged,
// // // // // // // //     required this.onSkipChanged,
// // // // // // // //   });

// // // // // // // //   final int  maxRounds;
// // // // // // // //   final bool allowSpicy;
// // // // // // // //   final bool timerEnabled;
// // // // // // // //   final int  timerSecs;
// // // // // // // //   final bool allowSkip;
// // // // // // // //   final void Function(int)  onMaxRoundsChanged;
// // // // // // // //   final void Function(bool) onSpicyChanged;
// // // // // // // //   final void Function(bool) onTimerChanged;
// // // // // // // //   final void Function(int)  onTimerSecsChanged;
// // // // // // // //   final void Function(bool) onSkipChanged;

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     return Column(
// // // // // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // //       children: [
// // // // // // // //         Text('Settings',
// // // // // // // //             style: context.textTheme.titleSmall?.copyWith(
// // // // // // // //                 fontWeight: FontWeight.w700)),
// // // // // // // //         const SizedBox(height: 6),

// // // // // // // //         // Rounds
// // // // // // // //         Row(
// // // // // // // //           children: [
// // // // // // // //             Expanded(child: Text('Rounds: $maxRounds')),
// // // // // // // //             Slider(
// // // // // // // //               value:     maxRounds.toDouble(),
// // // // // // // //               min: 3,    max: 30, divisions: 27,
// // // // // // // //               label:     '$maxRounds',
// // // // // // // //               onChanged: (v) => onMaxRoundsChanged(v.round()),
// // // // // // // //             ),
// // // // // // // //           ],
// // // // // // // //         ),

// // // // // // // //         SwitchListTile(
// // // // // // // //           title:      const Text('Allow skip'),
// // // // // // // //           value:      allowSkip,
// // // // // // // //           onChanged:  onSkipChanged,
// // // // // // // //           dense:      true,
// // // // // // // //           contentPadding: EdgeInsets.zero,
// // // // // // // //         ),

// // // // // // // //         SwitchListTile(
// // // // // // // //           title:     const Text('Spicy content'),
// // // // // // // //           subtitle:  const Text('Enable 18+ cards'),
// // // // // // // //           value:     allowSpicy,
// // // // // // // //           onChanged: onSpicyChanged,
// // // // // // // //           dense:     true,
// // // // // // // //           contentPadding: EdgeInsets.zero,
// // // // // // // //         ),

// // // // // // // //         SwitchListTile(
// // // // // // // //           title:     const Text('Turn timer'),
// // // // // // // //           value:     timerEnabled,
// // // // // // // //           onChanged: onTimerChanged,
// // // // // // // //           dense:     true,
// // // // // // // //           contentPadding: EdgeInsets.zero,
// // // // // // // //         ),

// // // // // // // //         if (timerEnabled) ...[
// // // // // // // //           Row(
// // // // // // // //             children: [
// // // // // // // //               Expanded(child: Text('Timer: ${timerSecs}s')),
// // // // // // // //               Slider(
// // // // // // // //                 value:     timerSecs.toDouble(),
// // // // // // // //                 min: 15,   max: 120, divisions: 21,
// // // // // // // //                 label:     '${timerSecs}s',
// // // // // // // //                 onChanged: (v) => onTimerSecsChanged(v.round()),
// // // // // // // //               ),
// // // // // // // //             ],
// // // // // // // //           ),
// // // // // // // //         ],
// // // // // // // //       ],
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // // import 'package:provider/provider.dart';

// // // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // // import '../../../../shared/widgets/buttons/j_button.dart';
// // // // // // // import '../../../games/engine/base_game_engine.dart';
// // // // // // // import '../../data/offline_game_provider.dart';
// // // // // // // import '../../data/offline_repository.dart';
// // // // // // // import '../../domain/offline_session.dart';
// // // // // // // import 'offline_play_screen.dart';
// // // // // // // import 'lan_host_screen.dart';

// // // // // // // /// Setup screen shared by both pass-and-play and LAN host modes.
// // // // // // // /// Steps: 1. Pack selection  2. Game settings  3. Players
// // // // // // // class OfflineSetupScreen extends StatefulWidget {
// // // // // // //   const OfflineSetupScreen({super.key, required this.mode});
// // // // // // //   final OfflineMode mode;

// // // // // // //   @override
// // // // // // //   State<OfflineSetupScreen> createState() => _OfflineSetupScreenState();
// // // // // // // }

// // // // // // // class _OfflineSetupScreenState extends State<OfflineSetupScreen> {
// // // // // // //   // ── Setup state ─────────────────────────────────────────────────────────
// // // // // // //   List<OfflinePack> _packs = [];
// // // // // // //   OfflinePack? _selectedPack;
// // // // // // //   GameType _gameType = GameType.truthOrDare;
// // // // // // //   int _maxRounds = 10;
// // // // // // //   bool _allowSpicy = false;
// // // // // // //   bool _timerEnabled = false;
// // // // // // //   int _timerSecs = 60;
// // // // // // //   bool _allowSkip = true;

// // // // // // //   final List<String> _players = [];
// // // // // // //   final _playerCtrl = TextEditingController();
// // // // // // //   bool _isLoading = true;

// // // // // // //   @override
// // // // // // //   void initState() {
// // // // // // //     super.initState();
// // // // // // //     _loadPacks();
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   void dispose() {
// // // // // // //     _playerCtrl.dispose();
// // // // // // //     super.dispose();
// // // // // // //   }

// // // // // // //   Future<void> _loadPacks() async {
// // // // // // //     setState(() => _isLoading = true);
// // // // // // //     final packs = await OfflineRepository.instance.getAvailablePacks(
// // // // // // //       gameType: _gameType,
// // // // // // //     );
// // // // // // //     setState(() {
// // // // // // //       _packs = packs.where((p) => p.isUsable).toList();
// // // // // // //       _selectedPack = _packs.isNotEmpty ? _packs.first : null;
// // // // // // //       _isLoading = false;
// // // // // // //     });
// // // // // // //   }

// // // // // // //   void _addPlayer() {
// // // // // // //     final name = _playerCtrl.text.trim();
// // // // // // //     if (name.isEmpty || _players.length >= 12) return;
// // // // // // //     if (_players.any((p) => p.toLowerCase() == name.toLowerCase())) {
// // // // // // //       context.showErrorSnackBar('Name "$name" already added');
// // // // // // //       return;
// // // // // // //     }
// // // // // // //     setState(() {
// // // // // // //       _players.add(name);
// // // // // // //       _playerCtrl.clear();
// // // // // // //     });
// // // // // // //   }

// // // // // // //   Future<void> _start() async {
// // // // // // //     if (_selectedPack == null) return;
// // // // // // //     if (_players.length < 2 && widget.mode == OfflineMode.passAndPlay) {
// // // // // // //       context.showErrorSnackBar('Add at least 2 players');
// // // // // // //       return;
// // // // // // //     }
// // // // // // //     if (widget.mode == OfflineMode.lan && _players.isEmpty) {
// // // // // // //       context.showErrorSnackBar('Enter your name');
// // // // // // //       return;
// // // // // // //     }

// // // // // // //     final config = GameConfig(
// // // // // // //       maxRounds: _maxRounds,
// // // // // // //       turnTimerSeconds: _timerEnabled ? _timerSecs : 0,
// // // // // // //       allowSkip: _allowSkip,
// // // // // // //       allowSpicy: _allowSpicy,
// // // // // // //       packId: _selectedPack!.id,
// // // // // // //       language: _selectedPack!.language,
// // // // // // //     );

// // // // // // //     final provider = context.read<OfflineGameProvider>();

// // // // // // //     if (widget.mode == OfflineMode.passAndPlay) {
// // // // // // //       await provider.startPassAndPlay(
// // // // // // //         gameType: _gameType,
// // // // // // //         config: config,
// // // // // // //         playerNames: _players,
// // // // // // //         packId: _selectedPack!.id,
// // // // // // //         packName: _selectedPack!.name,
// // // // // // //       );
// // // // // // //       if (provider.loadState == OfflineLoadState.ready && mounted) {
// // // // // // //         Navigator.pushReplacement(
// // // // // // //           context,
// // // // // // //           MaterialPageRoute(
// // // // // // //             builder: (_) => ChangeNotifierProvider.value(
// // // // // // //               value: provider,
// // // // // // //               child: const OfflinePlayScreen(),
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         );
// // // // // // //       }
// // // // // // //     } else {
// // // // // // //       // LAN host — go to lobby screen
// // // // // // //       if (!mounted) return;
// // // // // // //       Navigator.pushReplacement(
// // // // // // //         context,
// // // // // // //         MaterialPageRoute(
// // // // // // //           builder: (_) => ChangeNotifierProvider.value(
// // // // // // //             value: provider,
// // // // // // //             child: LanHostScreen(
// // // // // // //               hostName: _players.isNotEmpty ? _players.first : 'Host',
// // // // // // //               config: config,
// // // // // // //               gameType: _gameType,
// // // // // // //               pack: _selectedPack!,
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //       );
// // // // // // //     }
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     final theme = context.theme;
// // // // // // //     final isLan = widget.mode == OfflineMode.lan;
// // // // // // //     final canStart =
// // // // // // //         _selectedPack != null &&
// // // // // // //         (isLan ? _players.isNotEmpty : _players.length >= 2);

// // // // // // //     return Scaffold(
// // // // // // //       appBar: AppBar(
// // // // // // //         title: Text(isLan ? 'Host LAN Room' : 'Pass & Play Setup'),
// // // // // // //       ),
// // // // // // //       body: Consumer<OfflineGameProvider>(
// // // // // // //         builder: (ctx, provider, _) {
// // // // // // //           if (provider.loadState == OfflineLoadState.loading) {
// // // // // // //             return const Center(
// // // // // // //               child: Column(
// // // // // // //                 mainAxisSize: MainAxisSize.min,
// // // // // // //                 children: [
// // // // // // //                   CircularProgressIndicator(),
// // // // // // //                   SizedBox(height: 16),
// // // // // // //                   Text('Loading cards…'),
// // // // // // //                 ],
// // // // // // //               ),
// // // // // // //             );
// // // // // // //           }

// // // // // // //           if (provider.loadState == OfflineLoadState.error) {
// // // // // // //             return Center(
// // // // // // //               child: Padding(
// // // // // // //                 padding: const EdgeInsets.all(24),
// // // // // // //                 child: Column(
// // // // // // //                   mainAxisSize: MainAxisSize.min,
// // // // // // //                   children: [
// // // // // // //                     const Text('❌', style: TextStyle(fontSize: 48)),
// // // // // // //                     const SizedBox(height: 12),
// // // // // // //                     Text(
// // // // // // //                       provider.error ?? 'Setup failed.',
// // // // // // //                       textAlign: TextAlign.center,
// // // // // // //                     ),
// // // // // // //                     const SizedBox(height: 16),
// // // // // // //                     OutlinedButton(
// // // // // // //                       onPressed: () => provider.reset(),
// // // // // // //                       child: const Text('Try again'),
// // // // // // //                     ),
// // // // // // //                   ],
// // // // // // //                 ),
// // // // // // //               ),
// // // // // // //             );
// // // // // // //           }

// // // // // // //           return SingleChildScrollView(
// // // // // // //             padding: const EdgeInsets.all(20),
// // // // // // //             child: Column(
// // // // // // //               crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // // // //               children: [
// // // // // // //                 // ── Game type ─────────────────────────────────────────────
// // // // // // //                 Text(
// // // // // // //                   'Game',
// // // // // // //                   style: theme.textTheme.titleSmall?.copyWith(
// // // // // // //                     fontWeight: FontWeight.w700,
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //                 const SizedBox(height: 8),
// // // // // // //                 _GameTypeSelector(
// // // // // // //                   selected: _gameType,
// // // // // // //                   onChanged: (gt) {
// // // // // // //                     setState(() => _gameType = gt);
// // // // // // //                     _loadPacks();
// // // // // // //                   },
// // // // // // //                 ).animate().fadeIn(),

// // // // // // //                 const SizedBox(height: 20),

// // // // // // //                 // ── Pack selection ────────────────────────────────────────
// // // // // // //                 Text(
// // // // // // //                   'Pack',
// // // // // // //                   style: theme.textTheme.titleSmall?.copyWith(
// // // // // // //                     fontWeight: FontWeight.w700,
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //                 const SizedBox(height: 8),
// // // // // // //                 if (_isLoading)
// // // // // // //                   const Center(child: CircularProgressIndicator())
// // // // // // //                 else if (_packs.isEmpty)
// // // // // // //                   _NoPacksNotice(gameType: _gameType)
// // // // // // //                 else
// // // // // // //                   _PackSelector(
// // // // // // //                     packs: _packs,
// // // // // // //                     selected: _selectedPack,
// // // // // // //                     onSelect: (p) => setState(() => _selectedPack = p),
// // // // // // //                   ).animate(delay: 40.ms).fadeIn(),

// // // // // // //                 const SizedBox(height: 20),

// // // // // // //                 // ── Settings ──────────────────────────────────────────────
// // // // // // //                 _GameSettings(
// // // // // // //                   maxRounds: _maxRounds,
// // // // // // //                   allowSpicy: _allowSpicy,
// // // // // // //                   timerEnabled: _timerEnabled,
// // // // // // //                   timerSecs: _timerSecs,
// // // // // // //                   allowSkip: _allowSkip,
// // // // // // //                   onMaxRoundsChanged: (v) => setState(() => _maxRounds = v),
// // // // // // //                   onSpicyChanged: (v) => setState(() => _allowSpicy = v),
// // // // // // //                   onTimerChanged: (v) => setState(() => _timerEnabled = v),
// // // // // // //                   onTimerSecsChanged: (v) => setState(() => _timerSecs = v),
// // // // // // //                   onSkipChanged: (v) => setState(() => _allowSkip = v),
// // // // // // //                 ).animate(delay: 60.ms).fadeIn(),

// // // // // // //                 const SizedBox(height: 20),

// // // // // // //                 // ── Players ───────────────────────────────────────────────
// // // // // // //                 Text(
// // // // // // //                   isLan ? 'Your name' : 'Players (${_players.length}/12)',
// // // // // // //                   style: theme.textTheme.titleSmall?.copyWith(
// // // // // // //                     fontWeight: FontWeight.w700,
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //                 const SizedBox(height: 8),

// // // // // // //                 Row(
// // // // // // //                   children: [
// // // // // // //                     Expanded(
// // // // // // //                       child: TextField(
// // // // // // //                         controller: _playerCtrl,
// // // // // // //                         textCapitalization: TextCapitalization.words,
// // // // // // //                         textInputAction: TextInputAction.done,
// // // // // // //                         onSubmitted: (_) => _addPlayer(),
// // // // // // //                         decoration: InputDecoration(
// // // // // // //                           hintText: isLan ? 'Your name' : 'Player name',
// // // // // // //                           prefixIcon: const Icon(Icons.person_outline_rounded),
// // // // // // //                         ),
// // // // // // //                       ),
// // // // // // //                     ),
// // // // // // //                     const SizedBox(width: 8),
// // // // // // //                     SizedBox(
// // // // // // //                       height: 52,
// // // // // // //                       child: FilledButton(
// // // // // // //                         onPressed: _addPlayer,
// // // // // // //                         child: Text(isLan ? 'Set' : 'Add'),
// // // // // // //                       ),
// // // // // // //                     ),
// // // // // // //                   ],
// // // // // // //                 ),

// // // // // // //                 if (_players.isNotEmpty) ...[
// // // // // // //                   const SizedBox(height: 10),
// // // // // // //                   Wrap(
// // // // // // //                     spacing: 8,
// // // // // // //                     runSpacing: 8,
// // // // // // //                     children: _players
// // // // // // //                         .asMap()
// // // // // // //                         .entries
// // // // // // //                         .map(
// // // // // // //                           (e) => Chip(
// // // // // // //                             label: Text(
// // // // // // //                               isLan ? e.value : '${e.key + 1}. ${e.value}',
// // // // // // //                             ),
// // // // // // //                             deleteIcon: const Icon(
// // // // // // //                               Icons.close_rounded,
// // // // // // //                               size: 14,
// // // // // // //                             ),
// // // // // // //                             onDeleted: isLan && e.key == 0
// // // // // // //                                 ? null
// // // // // // //                                 : () =>
// // // // // // //                                       setState(() => _players.remove(e.value)),
// // // // // // //                           ).animate(delay: (e.key * 25).ms).fadeIn(),
// // // // // // //                         )
// // // // // // //                         .toList(),
// // // // // // //                   ),
// // // // // // //                 ],

// // // // // // //                 const SizedBox(height: 32),

// // // // // // //                 JButton(
// // // // // // //                   label: isLan ? 'Create LAN Room' : 'Start Game',
// // // // // // //                   onPressed: canStart ? _start : null,
// // // // // // //                   icon: isLan
// // // // // // //                       ? Icons.wifi_tethering_rounded
// // // // // // //                       : Icons.play_arrow_rounded,
// // // // // // //                 ).animate(delay: 80.ms).fadeIn(),
// // // // // // //               ],
// // // // // // //             ),
// // // // // // //           );
// // // // // // //         },
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // // ── Sub-widgets ───────────────────────────────────────────────────────────────

// // // // // // // class _GameTypeSelector extends StatelessWidget {
// // // // // // //   const _GameTypeSelector({required this.selected, required this.onChanged});
// // // // // // //   final GameType selected;
// // // // // // //   final void Function(GameType) onChanged;

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     return Row(
// // // // // // //       children: GameType.values.map((gt) {
// // // // // // //         final isSelected = selected == gt;
// // // // // // //         return Expanded(
// // // // // // //           child: Padding(
// // // // // // //             padding: const EdgeInsets.only(right: 8),
// // // // // // //             child: GestureDetector(
// // // // // // //               onTap: () => onChanged(gt),
// // // // // // //               child: AnimatedContainer(
// // // // // // //                 duration: const Duration(milliseconds: 150),
// // // // // // //                 padding: const EdgeInsets.symmetric(vertical: 10),
// // // // // // //                 decoration: BoxDecoration(
// // // // // // //                   color: isSelected
// // // // // // //                       ? AppColors.navyBlue
// // // // // // //                       : context.colorScheme.surfaceContainerHighest,
// // // // // // //                   borderRadius: BorderRadius.circular(10),
// // // // // // //                 ),
// // // // // // //                 child: Center(
// // // // // // //                   child: Text(_emoji(gt), style: const TextStyle(fontSize: 22)),
// // // // // // //                 ),
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         );
// // // // // // //       }).toList(),
// // // // // // //     );
// // // // // // //   }

// // // // // // //   String _emoji(GameType gt) => switch (gt) {
// // // // // // //     GameType.truthOrDare => '🎯',
// // // // // // //     GameType.neverHaveIEver => '🍹',
// // // // // // //     GameType.memeGame => '😂',
// // // // // // //   };
// // // // // // // }

// // // // // // // class _PackSelector extends StatelessWidget {
// // // // // // //   const _PackSelector({
// // // // // // //     required this.packs,
// // // // // // //     required this.selected,
// // // // // // //     required this.onSelect,
// // // // // // //   });
// // // // // // //   final List<OfflinePack> packs;
// // // // // // //   final OfflinePack? selected;
// // // // // // //   final void Function(OfflinePack) onSelect;

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     return Column(
// // // // // // //       children: packs.map((pack) {
// // // // // // //         final isSelected = selected?.id == pack.id;
// // // // // // //         return GestureDetector(
// // // // // // //           onTap: () => onSelect(pack),
// // // // // // //           child: AnimatedContainer(
// // // // // // //             duration: const Duration(milliseconds: 150),
// // // // // // //             margin: const EdgeInsets.only(bottom: 8),
// // // // // // //             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
// // // // // // //             decoration: BoxDecoration(
// // // // // // //               color: isSelected
// // // // // // //                   ? AppColors.navyBlue.withOpacity(0.08)
// // // // // // //                   : context.colorScheme.surfaceContainerHighest,
// // // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // // //               border: isSelected
// // // // // // //                   ? Border.all(color: AppColors.navyBlue, width: 2)
// // // // // // //                   : Border.all(color: context.colorScheme.outlineVariant),
// // // // // // //             ),
// // // // // // //             child: Row(
// // // // // // //               children: [
// // // // // // //                 Icon(
// // // // // // //                   isSelected
// // // // // // //                       ? Icons.radio_button_checked_rounded
// // // // // // //                       : Icons.radio_button_off_rounded,
// // // // // // //                   color: isSelected
// // // // // // //                       ? AppColors.navyBlue
// // // // // // //                       : context.colorScheme.onSurfaceVariant,
// // // // // // //                   size: 18,
// // // // // // //                 ),
// // // // // // //                 const SizedBox(width: 10),
// // // // // // //                 Expanded(
// // // // // // //                   child: Column(
// // // // // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // //                     children: [
// // // // // // //                       Text(
// // // // // // //                         pack.name,
// // // // // // //                         style: context.textTheme.titleSmall?.copyWith(
// // // // // // //                           fontWeight: FontWeight.w600,
// // // // // // //                         ),
// // // // // // //                       ),
// // // // // // //                       Text(
// // // // // // //                         '${pack.cardCount} cards • '
// // // // // // //                         '${pack.language.toUpperCase()} • '
// // // // // // //                         '${pack.isFree ? "Free" : "Purchased"}',
// // // // // // //                         style: context.textTheme.bodySmall?.copyWith(
// // // // // // //                           color: context.colorScheme.onSurfaceVariant,
// // // // // // //                         ),
// // // // // // //                       ),
// // // // // // //                     ],
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //                 if (pack.expiresAt != null)
// // // // // // //                   Text(
// // // // // // //                     'Exp: ${pack.expiresAt!.day}/${pack.expiresAt!.month}',
// // // // // // //                     style: context.textTheme.labelSmall?.copyWith(
// // // // // // //                       color: AppColors.warningAmber,
// // // // // // //                     ),
// // // // // // //                   ),
// // // // // // //               ],
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         );
// // // // // // //       }).toList(),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // class _NoPacksNotice extends StatelessWidget {
// // // // // // //   const _NoPacksNotice({required this.gameType});
// // // // // // //   final GameType gameType;

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     return Container(
// // // // // // //       padding: const EdgeInsets.all(16),
// // // // // // //       decoration: BoxDecoration(
// // // // // // //         color: AppColors.warningAmber.withOpacity(0.08),
// // // // // // //         borderRadius: BorderRadius.circular(12),
// // // // // // //       ),
// // // // // // //       child: Row(
// // // // // // //         children: [
// // // // // // //           const Icon(Icons.cloud_off_rounded, color: AppColors.warningAmber),
// // // // // // //           const SizedBox(width: 10),
// // // // // // //           Expanded(
// // // // // // //             child: Text(
// // // // // // //               'No ${gameType.displayName} packs downloaded. '
// // // // // // //               'Go online to download packs.',
// // // // // // //               style: const TextStyle(fontSize: 13),
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         ],
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // class _GameSettings extends StatelessWidget {
// // // // // // //   const _GameSettings({
// // // // // // //     required this.maxRounds,
// // // // // // //     required this.allowSpicy,
// // // // // // //     required this.timerEnabled,
// // // // // // //     required this.timerSecs,
// // // // // // //     required this.allowSkip,
// // // // // // //     required this.onMaxRoundsChanged,
// // // // // // //     required this.onSpicyChanged,
// // // // // // //     required this.onTimerChanged,
// // // // // // //     required this.onTimerSecsChanged,
// // // // // // //     required this.onSkipChanged,
// // // // // // //   });

// // // // // // //   final int maxRounds;
// // // // // // //   final bool allowSpicy;
// // // // // // //   final bool timerEnabled;
// // // // // // //   final int timerSecs;
// // // // // // //   final bool allowSkip;
// // // // // // //   final void Function(int) onMaxRoundsChanged;
// // // // // // //   final void Function(bool) onSpicyChanged;
// // // // // // //   final void Function(bool) onTimerChanged;
// // // // // // //   final void Function(int) onTimerSecsChanged;
// // // // // // //   final void Function(bool) onSkipChanged;

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     return Column(
// // // // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // //       children: [
// // // // // // //         Text(
// // // // // // //           'Settings',
// // // // // // //           style: context.textTheme.titleSmall?.copyWith(
// // // // // // //             fontWeight: FontWeight.w700,
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //         const SizedBox(height: 6),

// // // // // // //         // Rounds
// // // // // // //         Row(
// // // // // // //           children: [
// // // // // // //             Expanded(child: Text('Rounds: $maxRounds')),
// // // // // // //             Slider(
// // // // // // //               value: maxRounds.toDouble(),
// // // // // // //               min: 3,
// // // // // // //               max: 30,
// // // // // // //               divisions: 27,
// // // // // // //               label: '$maxRounds',
// // // // // // //               onChanged: (v) => onMaxRoundsChanged(v.round()),
// // // // // // //             ),
// // // // // // //           ],
// // // // // // //         ),

// // // // // // //         SwitchListTile(
// // // // // // //           title: const Text('Allow skip'),
// // // // // // //           value: allowSkip,
// // // // // // //           onChanged: onSkipChanged,
// // // // // // //           dense: true,
// // // // // // //           contentPadding: EdgeInsets.zero,
// // // // // // //         ),

// // // // // // //         SwitchListTile(
// // // // // // //           title: const Text('Spicy content'),
// // // // // // //           subtitle: const Text('Enable 18+ cards'),
// // // // // // //           value: allowSpicy,
// // // // // // //           onChanged: onSpicyChanged,
// // // // // // //           dense: true,
// // // // // // //           contentPadding: EdgeInsets.zero,
// // // // // // //         ),

// // // // // // //         SwitchListTile(
// // // // // // //           title: const Text('Turn timer'),
// // // // // // //           value: timerEnabled,
// // // // // // //           onChanged: onTimerChanged,
// // // // // // //           dense: true,
// // // // // // //           contentPadding: EdgeInsets.zero,
// // // // // // //         ),

// // // // // // //         if (timerEnabled) ...[
// // // // // // //           Row(
// // // // // // //             children: [
// // // // // // //               Expanded(child: Text('Timer: ${timerSecs}s')),
// // // // // // //               Slider(
// // // // // // //                 value: timerSecs.toDouble(),
// // // // // // //                 min: 15,
// // // // // // //                 max: 120,
// // // // // // //                 divisions: 21,
// // // // // // //                 label: '${timerSecs}s',
// // // // // // //                 onChanged: (v) => onTimerSecsChanged(v.round()),
// // // // // // //               ),
// // // // // // //             ],
// // // // // // //           ),
// // // // // // //         ],
// // // // // // //       ],
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // import 'package:provider/provider.dart';

// // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // import '../../../../shared/widgets/buttons/j_button.dart';
// // // // // // import '../../../games/engine/base_game_engine.dart';
// // // // // // import '../../data/offline_game_provider.dart';
// // // // // // import '../../data/offline_repository.dart';
// // // // // // import '../../domain/offline_session.dart';
// // // // // // import 'offline_play_screen.dart';
// // // // // // import 'lan_host_screen.dart';

// // // // // // /// Setup screen shared by both pass-and-play and LAN host modes.
// // // // // // /// Steps: 1. Pack selection  2. Game settings  3. Players
// // // // // // class OfflineSetupScreen extends StatefulWidget {
// // // // // //   const OfflineSetupScreen({super.key, required this.mode});
// // // // // //   final OfflineMode mode;

// // // // // //   @override
// // // // // //   State<OfflineSetupScreen> createState() => _OfflineSetupScreenState();
// // // // // // }

// // // // // // class _OfflineSetupScreenState extends State<OfflineSetupScreen> {
// // // // // //   // ── Setup state ─────────────────────────────────────────────────────────
// // // // // //   List<OfflinePack> _packs = [];
// // // // // //   OfflinePack? _selectedPack;
// // // // // //   GameType _gameType = GameType.truthOrDare;
// // // // // //   int _maxRounds = 10;
// // // // // //   bool _allowSpicy = false;
// // // // // //   bool _timerEnabled = false;
// // // // // //   int _timerSecs = 60;
// // // // // //   bool _allowSkip = true;

// // // // // //   final List<String> _players = [];
// // // // // //   final _playerCtrl = TextEditingController();
// // // // // //   bool _isLoading = true;

// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();
// // // // // //     _loadPacks();
// // // // // //   }

// // // // // //   @override
// // // // // //   void dispose() {
// // // // // //     _playerCtrl.dispose();
// // // // // //     super.dispose();
// // // // // //   }

// // // // // //   Future<void> _loadPacks() async {
// // // // // //     setState(() => _isLoading = true);
// // // // // //     final packs = await OfflineRepository.instance.getAvailablePacks(
// // // // // //       gameType: _gameType,
// // // // // //     );
// // // // // //     setState(() {
// // // // // //       _packs = packs.where((p) => p.isUsable).toList();
// // // // // //       _selectedPack = _packs.isNotEmpty ? _packs.first : null;
// // // // // //       _isLoading = false;
// // // // // //     });
// // // // // //   }

// // // // // //   void _addPlayer() {
// // // // // //     final name = _playerCtrl.text.trim();
// // // // // //     if (name.isEmpty || _players.length >= 12) return;
// // // // // //     if (_players.any((p) => p.toLowerCase() == name.toLowerCase())) {
// // // // // //       context.showErrorSnackBar('Name "$name" already added');
// // // // // //       return;
// // // // // //     }
// // // // // //     setState(() {
// // // // // //       _players.add(name);
// // // // // //       _playerCtrl.clear();
// // // // // //     });
// // // // // //   }

// // // // // //   Future<void> _start() async {
// // // // // //     if (_selectedPack == null) return;
// // // // // //     if (_players.length < 2 && widget.mode == OfflineMode.passAndPlay) {
// // // // // //       context.showErrorSnackBar('Add at least 2 players');
// // // // // //       return;
// // // // // //     }
// // // // // //     if (widget.mode == OfflineMode.lan && _players.isEmpty) {
// // // // // //       context.showErrorSnackBar('Enter your name');
// // // // // //       return;
// // // // // //     }

// // // // // //     final config = GameConfig(
// // // // // //       maxRounds: _maxRounds,
// // // // // //       turnTimerSeconds: _timerEnabled ? _timerSecs : 0,
// // // // // //       allowSkip: _allowSkip,
// // // // // //       allowSpicy: _allowSpicy,
// // // // // //       packId: _selectedPack!.id,
// // // // // //       language: _selectedPack!.language,
// // // // // //     );

// // // // // //     final provider = context.read<OfflineGameProvider>();

// // // // // //     if (widget.mode == OfflineMode.passAndPlay) {
// // // // // //       await provider.startPassAndPlay(
// // // // // //         gameType: _gameType,
// // // // // //         config: config,
// // // // // //         playerNames: _players,
// // // // // //         packId: _selectedPack!.id,
// // // // // //         packName: _selectedPack!.name,
// // // // // //       );
// // // // // //       if (provider.loadState == OfflineLoadState.ready && mounted) {
// // // // // //         Navigator.pushReplacement(
// // // // // //           context,
// // // // // //           MaterialPageRoute(
// // // // // //             builder: (_) => ChangeNotifierProvider.value(
// // // // // //               value: provider,
// // // // // //               child: const OfflinePlayScreen(),
// // // // // //             ),
// // // // // //           ),
// // // // // //         );
// // // // // //       }
// // // // // //     } else {
// // // // // //       // LAN host — go to lobby screen
// // // // // //       if (!mounted) return;
// // // // // //       Navigator.pushReplacement(
// // // // // //         context,
// // // // // //         MaterialPageRoute(
// // // // // //           builder: (_) => ChangeNotifierProvider.value(
// // // // // //             value: provider,
// // // // // //             child: LanHostScreen(
// // // // // //               hostName: _players.isNotEmpty ? _players.first : 'Host',
// // // // // //               config: config,
// // // // // //               gameType: _gameType,
// // // // // //               pack: _selectedPack!,
// // // // // //             ),
// // // // // //           ),
// // // // // //         ),
// // // // // //       );
// // // // // //     }
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final theme = context.theme;
// // // // // //     final isLan = widget.mode == OfflineMode.lan;
// // // // // //     final canStart =
// // // // // //         _selectedPack != null &&
// // // // // //         (isLan ? _players.isNotEmpty : _players.length >= 2);

// // // // // //     return Scaffold(
// // // // // //       appBar: AppBar(
// // // // // //         title: Text(isLan ? 'Host LAN Room' : 'Pass & Play Setup'),
// // // // // //       ),
// // // // // //       body: Consumer<OfflineGameProvider>(
// // // // // //         builder: (ctx, provider, _) {
// // // // // //           if (provider.loadState == OfflineLoadState.loading) {
// // // // // //             return const Center(
// // // // // //               child: Column(
// // // // // //                 mainAxisSize: MainAxisSize.min,
// // // // // //                 children: [
// // // // // //                   CircularProgressIndicator(),
// // // // // //                   SizedBox(height: 16),
// // // // // //                   Text('Loading cards…'),
// // // // // //                 ],
// // // // // //               ),
// // // // // //             );
// // // // // //           }

// // // // // //           if (provider.loadState == OfflineLoadState.error) {
// // // // // //             return Center(
// // // // // //               child: Padding(
// // // // // //                 padding: const EdgeInsets.all(24),
// // // // // //                 child: Column(
// // // // // //                   mainAxisSize: MainAxisSize.min,
// // // // // //                   children: [
// // // // // //                     const Text('❌', style: TextStyle(fontSize: 48)),
// // // // // //                     const SizedBox(height: 12),
// // // // // //                     Text(
// // // // // //                       provider.error ?? 'Setup failed.',
// // // // // //                       textAlign: TextAlign.center,
// // // // // //                     ),
// // // // // //                     const SizedBox(height: 16),
// // // // // //                     OutlinedButton(
// // // // // //                       onPressed: () => provider.reset(),
// // // // // //                       child: const Text('Try again'),
// // // // // //                     ),
// // // // // //                   ],
// // // // // //                 ),
// // // // // //               ),
// // // // // //             );
// // // // // //           }

// // // // // //           return SingleChildScrollView(
// // // // // //             padding: const EdgeInsets.all(20),
// // // // // //             child: Column(
// // // // // //               crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // // //               children: [
// // // // // //                 // ── Game type ─────────────────────────────────────────────
// // // // // //                 Text(
// // // // // //                   'Game',
// // // // // //                   style: theme.textTheme.titleSmall?.copyWith(
// // // // // //                     fontWeight: FontWeight.w700,
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 8),
// // // // // //                 _GameTypeSelector(
// // // // // //                   selected: _gameType,
// // // // // //                   onChanged: (gt) {
// // // // // //                     setState(() => _gameType = gt);
// // // // // //                     _loadPacks();
// // // // // //                   },
// // // // // //                 ).animate().fadeIn(),

// // // // // //                 const SizedBox(height: 20),

// // // // // //                 // ── Pack selection ────────────────────────────────────────
// // // // // //                 Text(
// // // // // //                   'Pack',
// // // // // //                   style: theme.textTheme.titleSmall?.copyWith(
// // // // // //                     fontWeight: FontWeight.w700,
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 8),
// // // // // //                 if (_isLoading)
// // // // // //                   const Center(child: CircularProgressIndicator())
// // // // // //                 else if (_packs.isEmpty)
// // // // // //                   _NoPacksNotice(gameType: _gameType)
// // // // // //                 else
// // // // // //                   _PackSelector(
// // // // // //                     packs: _packs,
// // // // // //                     selected: _selectedPack,
// // // // // //                     onSelect: (p) => setState(() => _selectedPack = p),
// // // // // //                   ).animate(delay: 40.ms).fadeIn(),

// // // // // //                 const SizedBox(height: 20),

// // // // // //                 // ── Settings ──────────────────────────────────────────────
// // // // // //                 _GameSettings(
// // // // // //                   maxRounds: _maxRounds,
// // // // // //                   allowSpicy: _allowSpicy,
// // // // // //                   timerEnabled: _timerEnabled,
// // // // // //                   timerSecs: _timerSecs,
// // // // // //                   allowSkip: _allowSkip,
// // // // // //                   onMaxRoundsChanged: (v) => setState(() => _maxRounds = v),
// // // // // //                   onSpicyChanged: (v) => setState(() => _allowSpicy = v),
// // // // // //                   onTimerChanged: (v) => setState(() => _timerEnabled = v),
// // // // // //                   onTimerSecsChanged: (v) => setState(() => _timerSecs = v),
// // // // // //                   onSkipChanged: (v) => setState(() => _allowSkip = v),
// // // // // //                 ).animate(delay: 60.ms).fadeIn(),

// // // // // //                 const SizedBox(height: 20),

// // // // // //                 // ── Players ───────────────────────────────────────────────
// // // // // //                 Text(
// // // // // //                   isLan ? 'Your name' : 'Players (${_players.length}/12)',
// // // // // //                   style: theme.textTheme.titleSmall?.copyWith(
// // // // // //                     fontWeight: FontWeight.w700,
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 8),

// // // // // //                 Row(
// // // // // //                   children: [
// // // // // //                     Expanded(
// // // // // //                       child: TextField(
// // // // // //                         controller: _playerCtrl,
// // // // // //                         textCapitalization: TextCapitalization.words,
// // // // // //                         textInputAction: TextInputAction.done,
// // // // // //                         onSubmitted: (_) => _addPlayer(),
// // // // // //                         decoration: InputDecoration(
// // // // // //                           hintText: isLan ? 'Your name' : 'Player name',
// // // // // //                           prefixIcon: const Icon(Icons.person_outline_rounded),
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                     const SizedBox(width: 8),
// // // // // //                     SizedBox(
// // // // // //                       height: 52,
// // // // // //                       width: 80,
// // // // // //                       child: FilledButton(
// // // // // //                         onPressed: _addPlayer,
// // // // // //                         child: Text(isLan ? 'Set' : 'Add'),
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                   ],
// // // // // //                 ),

// // // // // //                 if (_players.isNotEmpty) ...[
// // // // // //                   const SizedBox(height: 10),
// // // // // //                   Wrap(
// // // // // //                     spacing: 8,
// // // // // //                     runSpacing: 8,
// // // // // //                     children: _players
// // // // // //                         .asMap()
// // // // // //                         .entries
// // // // // //                         .map(
// // // // // //                           (e) => Chip(
// // // // // //                             label: Text(
// // // // // //                               isLan ? e.value : '${e.key + 1}. ${e.value}',
// // // // // //                             ),
// // // // // //                             deleteIcon: const Icon(
// // // // // //                               Icons.close_rounded,
// // // // // //                               size: 14,
// // // // // //                             ),
// // // // // //                             onDeleted: isLan && e.key == 0
// // // // // //                                 ? null
// // // // // //                                 : () =>
// // // // // //                                       setState(() => _players.remove(e.value)),
// // // // // //                           ).animate(delay: (e.key * 25).ms).fadeIn(),
// // // // // //                         )
// // // // // //                         .toList(),
// // // // // //                   ),
// // // // // //                 ],

// // // // // //                 const SizedBox(height: 32),

// // // // // //                 JButton(
// // // // // //                   label: isLan ? 'Create LAN Room' : 'Start Game',
// // // // // //                   onPressed: canStart ? _start : null,
// // // // // //                   icon: isLan
// // // // // //                       ? Icons.wifi_tethering_rounded
// // // // // //                       : Icons.play_arrow_rounded,
// // // // // //                 ).animate(delay: 80.ms).fadeIn(),
// // // // // //               ],
// // // // // //             ),
// // // // // //           );
// // // // // //         },
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // // ── Sub-widgets ───────────────────────────────────────────────────────────────

// // // // // // class _GameTypeSelector extends StatelessWidget {
// // // // // //   const _GameTypeSelector({required this.selected, required this.onChanged});
// // // // // //   final GameType selected;
// // // // // //   final void Function(GameType) onChanged;

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Row(
// // // // // //       children: GameType.values.map((gt) {
// // // // // //         final isSelected = selected == gt;
// // // // // //         return Expanded(
// // // // // //           child: Padding(
// // // // // //             padding: const EdgeInsets.only(right: 8),
// // // // // //             child: GestureDetector(
// // // // // //               onTap: () => onChanged(gt),
// // // // // //               child: AnimatedContainer(
// // // // // //                 duration: const Duration(milliseconds: 150),
// // // // // //                 padding: const EdgeInsets.symmetric(vertical: 10),
// // // // // //                 decoration: BoxDecoration(
// // // // // //                   color: isSelected
// // // // // //                       ? AppColors.navyBlue
// // // // // //                       : context.colorScheme.surfaceContainerHighest,
// // // // // //                   borderRadius: BorderRadius.circular(10),
// // // // // //                 ),
// // // // // //                 child: Center(
// // // // // //                   child: Text(_emoji(gt), style: const TextStyle(fontSize: 22)),
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ),
// // // // // //           ),
// // // // // //         );
// // // // // //       }).toList(),
// // // // // //     );
// // // // // //   }

// // // // // //   String _emoji(GameType gt) => switch (gt) {
// // // // // //     GameType.truthOrDare => '🎯',
// // // // // //     GameType.neverHaveIEver => '🍹',
// // // // // //     GameType.memeGame => '😂',
// // // // // //   };
// // // // // // }

// // // // // // class _PackSelector extends StatelessWidget {
// // // // // //   const _PackSelector({
// // // // // //     required this.packs,
// // // // // //     required this.selected,
// // // // // //     required this.onSelect,
// // // // // //   });
// // // // // //   final List<OfflinePack> packs;
// // // // // //   final OfflinePack? selected;
// // // // // //   final void Function(OfflinePack) onSelect;

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Column(
// // // // // //       children: packs.map((pack) {
// // // // // //         final isSelected = selected?.id == pack.id;
// // // // // //         return GestureDetector(
// // // // // //           onTap: () => onSelect(pack),
// // // // // //           child: AnimatedContainer(
// // // // // //             duration: const Duration(milliseconds: 150),
// // // // // //             margin: const EdgeInsets.only(bottom: 8),
// // // // // //             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
// // // // // //             decoration: BoxDecoration(
// // // // // //               color: isSelected
// // // // // //                   ? AppColors.navyBlue.withOpacity(0.08)
// // // // // //                   : context.colorScheme.surfaceContainerHighest,
// // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // //               border: isSelected
// // // // // //                   ? Border.all(color: AppColors.navyBlue, width: 2)
// // // // // //                   : Border.all(color: context.colorScheme.outlineVariant),
// // // // // //             ),
// // // // // //             child: Row(
// // // // // //               children: [
// // // // // //                 Icon(
// // // // // //                   isSelected
// // // // // //                       ? Icons.radio_button_checked_rounded
// // // // // //                       : Icons.radio_button_off_rounded,
// // // // // //                   color: isSelected
// // // // // //                       ? AppColors.navyBlue
// // // // // //                       : context.colorScheme.onSurfaceVariant,
// // // // // //                   size: 18,
// // // // // //                 ),
// // // // // //                 const SizedBox(width: 10),
// // // // // //                 Expanded(
// // // // // //                   child: Column(
// // // // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //                     children: [
// // // // // //                       Text(
// // // // // //                         pack.name,
// // // // // //                         style: context.textTheme.titleSmall?.copyWith(
// // // // // //                           fontWeight: FontWeight.w600,
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                       Text(
// // // // // //                         '${pack.cardCount} cards • '
// // // // // //                         '${pack.language.toUpperCase()} • '
// // // // // //                         '${pack.isFree ? "Free" : "Purchased"}',
// // // // // //                         style: context.textTheme.bodySmall?.copyWith(
// // // // // //                           color: context.colorScheme.onSurfaceVariant,
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                     ],
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 if (pack.expiresAt != null)
// // // // // //                   Text(
// // // // // //                     'Exp: ${pack.expiresAt!.day}/${pack.expiresAt!.month}',
// // // // // //                     style: context.textTheme.labelSmall?.copyWith(
// // // // // //                       color: AppColors.warningAmber,
// // // // // //                     ),
// // // // // //                   ),
// // // // // //               ],
// // // // // //             ),
// // // // // //           ),
// // // // // //         );
// // // // // //       }).toList(),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // class _NoPacksNotice extends StatelessWidget {
// // // // // //   const _NoPacksNotice({required this.gameType});
// // // // // //   final GameType gameType;

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Container(
// // // // // //       padding: const EdgeInsets.all(16),
// // // // // //       decoration: BoxDecoration(
// // // // // //         color: AppColors.warningAmber.withOpacity(0.08),
// // // // // //         borderRadius: BorderRadius.circular(12),
// // // // // //       ),
// // // // // //       child: Row(
// // // // // //         children: [
// // // // // //           const Icon(Icons.cloud_off_rounded, color: AppColors.warningAmber),
// // // // // //           const SizedBox(width: 10),
// // // // // //           Expanded(
// // // // // //             child: Text(
// // // // // //               'No ${gameType.displayName} packs downloaded. '
// // // // // //               'Go online to download packs.',
// // // // // //               style: const TextStyle(fontSize: 13),
// // // // // //             ),
// // // // // //           ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // class _GameSettings extends StatelessWidget {
// // // // // //   const _GameSettings({
// // // // // //     required this.maxRounds,
// // // // // //     required this.allowSpicy,
// // // // // //     required this.timerEnabled,
// // // // // //     required this.timerSecs,
// // // // // //     required this.allowSkip,
// // // // // //     required this.onMaxRoundsChanged,
// // // // // //     required this.onSpicyChanged,
// // // // // //     required this.onTimerChanged,
// // // // // //     required this.onTimerSecsChanged,
// // // // // //     required this.onSkipChanged,
// // // // // //   });

// // // // // //   final int maxRounds;
// // // // // //   final bool allowSpicy;
// // // // // //   final bool timerEnabled;
// // // // // //   final int timerSecs;
// // // // // //   final bool allowSkip;
// // // // // //   final void Function(int) onMaxRoundsChanged;
// // // // // //   final void Function(bool) onSpicyChanged;
// // // // // //   final void Function(bool) onTimerChanged;
// // // // // //   final void Function(int) onTimerSecsChanged;
// // // // // //   final void Function(bool) onSkipChanged;

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Column(
// // // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //       children: [
// // // // // //         Text(
// // // // // //           'Settings',
// // // // // //           style: context.textTheme.titleSmall?.copyWith(
// // // // // //             fontWeight: FontWeight.w700,
// // // // // //           ),
// // // // // //         ),
// // // // // //         const SizedBox(height: 6),

// // // // // //         // Rounds
// // // // // //         Row(
// // // // // //           children: [
// // // // // //             Expanded(child: Text('Rounds: $maxRounds')),
// // // // // //             Slider(
// // // // // //               value: maxRounds.toDouble(),
// // // // // //               min: 3,
// // // // // //               max: 30,
// // // // // //               divisions: 27,
// // // // // //               label: '$maxRounds',
// // // // // //               onChanged: (v) => onMaxRoundsChanged(v.round()),
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),

// // // // // //         SwitchListTile(
// // // // // //           title: const Text('Allow skip'),
// // // // // //           value: allowSkip,
// // // // // //           onChanged: onSkipChanged,
// // // // // //           dense: true,
// // // // // //           contentPadding: EdgeInsets.zero,
// // // // // //         ),

// // // // // //         SwitchListTile(
// // // // // //           title: const Text('Spicy content'),
// // // // // //           subtitle: const Text('Enable 18+ cards'),
// // // // // //           value: allowSpicy,
// // // // // //           onChanged: onSpicyChanged,
// // // // // //           dense: true,
// // // // // //           contentPadding: EdgeInsets.zero,
// // // // // //         ),

// // // // // //         SwitchListTile(
// // // // // //           title: const Text('Turn timer'),
// // // // // //           value: timerEnabled,
// // // // // //           onChanged: onTimerChanged,
// // // // // //           dense: true,
// // // // // //           contentPadding: EdgeInsets.zero,
// // // // // //         ),

// // // // // //         if (timerEnabled) ...[
// // // // // //           Row(
// // // // // //             children: [
// // // // // //               Expanded(child: Text('Timer: ${timerSecs}s')),
// // // // // //               Slider(
// // // // // //                 value: timerSecs.toDouble(),
// // // // // //                 min: 15,
// // // // // //                 max: 120,
// // // // // //                 divisions: 21,
// // // // // //                 label: '${timerSecs}s',
// // // // // //                 onChanged: (v) => onTimerSecsChanged(v.round()),
// // // // // //               ),
// // // // // //             ],
// // // // // //           ),
// // // // // //         ],
// // // // // //       ],
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // import 'package:provider/provider.dart';

// // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // import '../../../../core/theme/app_colors.dart';
// // // // // import '../../../../shared/widgets/buttons/j_button.dart';
// // // // // import '../../../games/engine/base_game_engine.dart';
// // // // // import '../../data/offline_game_provider.dart';
// // // // // import '../../data/offline_repository.dart';
// // // // // import '../../domain/offline_session.dart';
// // // // // import 'offline_play_screen.dart';
// // // // // import 'lan_host_screen.dart';

// // // // // /// Setup screen shared by both pass-and-play and LAN host modes.
// // // // // /// Steps: 1. Pack selection  2. Game settings  3. Players
// // // // // class OfflineSetupScreen extends StatefulWidget {
// // // // //   const OfflineSetupScreen({super.key, required this.mode});
// // // // //   final OfflineMode mode;

// // // // //   @override
// // // // //   State<OfflineSetupScreen> createState() => _OfflineSetupScreenState();
// // // // // }

// // // // // class _OfflineSetupScreenState extends State<OfflineSetupScreen> {
// // // // //   // ── Setup state ─────────────────────────────────────────────────────────
// // // // //   List<OfflinePack> _packs = [];
// // // // //   OfflinePack? _selectedPack;
// // // // //   GameType _gameType = GameType.truthOrDare;
// // // // //   int _maxRounds = 10;
// // // // //   bool _allowSpicy = false;
// // // // //   bool _timerEnabled = false;
// // // // //   int _timerSecs = 60;
// // // // //   bool _allowSkip = true;

// // // // //   final List<String> _players = [];
// // // // //   final _playerCtrl = TextEditingController();
// // // // //   bool _isLoading = true;

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     _loadPacks();
// // // // //   }

// // // // //   @override
// // // // //   void dispose() {
// // // // //     _playerCtrl.dispose();
// // // // //     super.dispose();
// // // // //   }

// // // // //   Future<void> _loadPacks() async {
// // // // //     setState(() => _isLoading = true);
// // // // //     final packs = await OfflineRepository.instance.getAvailablePacks(
// // // // //       gameType: _gameType,
// // // // //     );
// // // // //     setState(() {
// // // // //       _packs = packs.where((p) => p.isUsable).toList();
// // // // //       _selectedPack = _packs.isNotEmpty ? _packs.first : null;
// // // // //       _isLoading = false;
// // // // //     });
// // // // //   }

// // // // //   void _addPlayer() {
// // // // //     final name = _playerCtrl.text.trim();
// // // // //     if (name.isEmpty || _players.length >= 12) return;
// // // // //     if (_players.any((p) => p.toLowerCase() == name.toLowerCase())) {
// // // // //       context.showErrorSnackBar('Name "$name" already added');
// // // // //       return;
// // // // //     }
// // // // //     setState(() {
// // // // //       _players.add(name);
// // // // //       _playerCtrl.clear();
// // // // //     });
// // // // //   }

// // // // //   Future<void> _start() async {
// // // // //     if (_selectedPack == null) return;
// // // // //     if (_players.length < 2 && widget.mode == OfflineMode.passAndPlay) {
// // // // //       context.showErrorSnackBar('Add at least 2 players');
// // // // //       return;
// // // // //     }
// // // // //     if (widget.mode == OfflineMode.lan && _players.isEmpty) {
// // // // //       context.showErrorSnackBar('Enter your name');
// // // // //       return;
// // // // //     }

// // // // //     final config = GameConfig(
// // // // //       maxRounds: _maxRounds,
// // // // //       turnTimerSeconds: _timerEnabled ? _timerSecs : 0,
// // // // //       allowSkip: _allowSkip,
// // // // //       allowSpicy: _allowSpicy,
// // // // //       packId: _selectedPack!.id,
// // // // //       language: _selectedPack!.language,
// // // // //     );

// // // // //     final provider = context.read<OfflineGameProvider>();

// // // // //     if (widget.mode == OfflineMode.passAndPlay) {
// // // // //       await provider.startPassAndPlay(
// // // // //         gameType: _gameType,
// // // // //         config: config,
// // // // //         playerNames: _players,
// // // // //         packId: _selectedPack!.id,
// // // // //         packName: _selectedPack!.name,
// // // // //         packCoverUrl: _selectedPack!.coverImageUrl,
// // // // //       );
// // // // //       if (provider.loadState == OfflineLoadState.ready && mounted) {
// // // // //         Navigator.pushReplacement(
// // // // //           context,
// // // // //           MaterialPageRoute(
// // // // //             builder: (_) => ChangeNotifierProvider.value(
// // // // //               value: provider,
// // // // //               child: const OfflinePlayScreen(),
// // // // //             ),
// // // // //           ),
// // // // //         );
// // // // //       }
// // // // //     } else {
// // // // //       // LAN host — go to lobby screen
// // // // //       if (!mounted) return;
// // // // //       Navigator.pushReplacement(
// // // // //         context,
// // // // //         MaterialPageRoute(
// // // // //           builder: (_) => ChangeNotifierProvider.value(
// // // // //             value: provider,
// // // // //             child: LanHostScreen(
// // // // //               hostName: _players.isNotEmpty ? _players.first : 'Host',
// // // // //               config: config,
// // // // //               gameType: _gameType,
// // // // //               pack: _selectedPack!,
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //       );
// // // // //     }
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final theme = context.theme;
// // // // //     final isLan = widget.mode == OfflineMode.lan;
// // // // //     final canStart =
// // // // //         _selectedPack != null &&
// // // // //         (isLan ? _players.isNotEmpty : _players.length >= 2);

// // // // //     return Scaffold(
// // // // //       appBar: AppBar(
// // // // //         title: Text(isLan ? 'Host LAN Room' : 'Pass & Play Setup'),
// // // // //       ),
// // // // //       body: Consumer<OfflineGameProvider>(
// // // // //         builder: (ctx, provider, _) {
// // // // //           if (provider.loadState == OfflineLoadState.loading) {
// // // // //             return const Center(
// // // // //               child: Column(
// // // // //                 mainAxisSize: MainAxisSize.min,
// // // // //                 children: [
// // // // //                   CircularProgressIndicator(),
// // // // //                   SizedBox(height: 16),
// // // // //                   Text('Loading cards…'),
// // // // //                 ],
// // // // //               ),
// // // // //             );
// // // // //           }

// // // // //           if (provider.loadState == OfflineLoadState.error) {
// // // // //             return Center(
// // // // //               child: Padding(
// // // // //                 padding: const EdgeInsets.all(24),
// // // // //                 child: Column(
// // // // //                   mainAxisSize: MainAxisSize.min,
// // // // //                   children: [
// // // // //                     const Text('❌', style: TextStyle(fontSize: 48)),
// // // // //                     const SizedBox(height: 12),
// // // // //                     Text(
// // // // //                       provider.error ?? 'Setup failed.',
// // // // //                       textAlign: TextAlign.center,
// // // // //                     ),
// // // // //                     const SizedBox(height: 16),
// // // // //                     OutlinedButton(
// // // // //                       onPressed: () => provider.reset(),
// // // // //                       child: const Text('Try again'),
// // // // //                     ),
// // // // //                   ],
// // // // //                 ),
// // // // //               ),
// // // // //             );
// // // // //           }

// // // // //           return SingleChildScrollView(
// // // // //             padding: const EdgeInsets.all(20),
// // // // //             child: Column(
// // // // //               crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // //               children: [
// // // // //                 // ── Game type ─────────────────────────────────────────────
// // // // //                 Text(
// // // // //                   'Game',
// // // // //                   style: theme.textTheme.titleSmall?.copyWith(
// // // // //                     fontWeight: FontWeight.w700,
// // // // //                   ),
// // // // //                 ),
// // // // //                 const SizedBox(height: 8),
// // // // //                 _GameTypeSelector(
// // // // //                   selected: _gameType,
// // // // //                   onChanged: (gt) {
// // // // //                     setState(() => _gameType = gt);
// // // // //                     _loadPacks();
// // // // //                   },
// // // // //                 ).animate().fadeIn(),

// // // // //                 const SizedBox(height: 20),

// // // // //                 // ── Pack selection ────────────────────────────────────────
// // // // //                 Text(
// // // // //                   'Pack',
// // // // //                   style: theme.textTheme.titleSmall?.copyWith(
// // // // //                     fontWeight: FontWeight.w700,
// // // // //                   ),
// // // // //                 ),
// // // // //                 const SizedBox(height: 8),
// // // // //                 if (_isLoading)
// // // // //                   const Center(child: CircularProgressIndicator())
// // // // //                 else if (_packs.isEmpty)
// // // // //                   _NoPacksNotice(gameType: _gameType)
// // // // //                 else
// // // // //                   _PackSelector(
// // // // //                     packs: _packs,
// // // // //                     selected: _selectedPack,
// // // // //                     onSelect: (p) => setState(() => _selectedPack = p),
// // // // //                   ).animate(delay: 40.ms).fadeIn(),

// // // // //                 const SizedBox(height: 20),

// // // // //                 // ── Settings ──────────────────────────────────────────────
// // // // //                 _GameSettings(
// // // // //                   maxRounds: _maxRounds,
// // // // //                   allowSpicy: _allowSpicy,
// // // // //                   timerEnabled: _timerEnabled,
// // // // //                   timerSecs: _timerSecs,
// // // // //                   allowSkip: _allowSkip,
// // // // //                   onMaxRoundsChanged: (v) => setState(() => _maxRounds = v),
// // // // //                   onSpicyChanged: (v) => setState(() => _allowSpicy = v),
// // // // //                   onTimerChanged: (v) => setState(() => _timerEnabled = v),
// // // // //                   onTimerSecsChanged: (v) => setState(() => _timerSecs = v),
// // // // //                   onSkipChanged: (v) => setState(() => _allowSkip = v),
// // // // //                 ).animate(delay: 60.ms).fadeIn(),

// // // // //                 const SizedBox(height: 20),

// // // // //                 // ── Players ───────────────────────────────────────────────
// // // // //                 Text(
// // // // //                   isLan ? 'Your name' : 'Players (${_players.length}/12)',
// // // // //                   style: theme.textTheme.titleSmall?.copyWith(
// // // // //                     fontWeight: FontWeight.w700,
// // // // //                   ),
// // // // //                 ),
// // // // //                 const SizedBox(height: 8),

// // // // //                 Row(
// // // // //                   children: [
// // // // //                     Expanded(
// // // // //                       child: TextField(
// // // // //                         controller: _playerCtrl,
// // // // //                         textCapitalization: TextCapitalization.words,
// // // // //                         textInputAction: TextInputAction.done,
// // // // //                         onSubmitted: (_) => _addPlayer(),
// // // // //                         decoration: InputDecoration(
// // // // //                           hintText: isLan ? 'Your name' : 'Player name',
// // // // //                           prefixIcon: const Icon(Icons.person_outline_rounded),
// // // // //                         ),
// // // // //                       ),
// // // // //                     ),
// // // // //                     const SizedBox(width: 8),
// // // // //                     SizedBox(
// // // // //                       height: 52,
// // // // //                       child: FilledButton(
// // // // //                         onPressed: _addPlayer,
// // // // //                         child: Text(isLan ? 'Set' : 'Add'),
// // // // //                       ),
// // // // //                     ),
// // // // //                   ],
// // // // //                 ),

// // // // //                 if (_players.isNotEmpty) ...[
// // // // //                   const SizedBox(height: 10),
// // // // //                   Wrap(
// // // // //                     spacing: 8,
// // // // //                     runSpacing: 8,
// // // // //                     children: _players
// // // // //                         .asMap()
// // // // //                         .entries
// // // // //                         .map(
// // // // //                           (e) => Chip(
// // // // //                             label: Text(
// // // // //                               isLan ? e.value : '${e.key + 1}. ${e.value}',
// // // // //                             ),
// // // // //                             deleteIcon: const Icon(
// // // // //                               Icons.close_rounded,
// // // // //                               size: 14,
// // // // //                             ),
// // // // //                             onDeleted: isLan && e.key == 0
// // // // //                                 ? null
// // // // //                                 : () =>
// // // // //                                       setState(() => _players.remove(e.value)),
// // // // //                           ).animate(delay: (e.key * 25).ms).fadeIn(),
// // // // //                         )
// // // // //                         .toList(),
// // // // //                   ),
// // // // //                 ],

// // // // //                 const SizedBox(height: 32),

// // // // //                 JButton(
// // // // //                   label: isLan ? 'Create LAN Room' : 'Start Game',
// // // // //                   onPressed: canStart ? _start : null,
// // // // //                   icon: isLan
// // // // //                       ? Icons.wifi_tethering_rounded
// // // // //                       : Icons.play_arrow_rounded,
// // // // //                 ).animate(delay: 80.ms).fadeIn(),
// // // // //               ],
// // // // //             ),
// // // // //           );
// // // // //         },
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // // ── Sub-widgets ───────────────────────────────────────────────────────────────

// // // // // class _GameTypeSelector extends StatelessWidget {
// // // // //   const _GameTypeSelector({required this.selected, required this.onChanged});
// // // // //   final GameType selected;
// // // // //   final void Function(GameType) onChanged;

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Row(
// // // // //       children: GameType.values.map((gt) {
// // // // //         final isSelected = selected == gt;
// // // // //         return Expanded(
// // // // //           child: Padding(
// // // // //             padding: const EdgeInsets.only(right: 8),
// // // // //             child: GestureDetector(
// // // // //               onTap: () => onChanged(gt),
// // // // //               child: AnimatedContainer(
// // // // //                 duration: const Duration(milliseconds: 150),
// // // // //                 padding: const EdgeInsets.symmetric(vertical: 10),
// // // // //                 decoration: BoxDecoration(
// // // // //                   color: isSelected
// // // // //                       ? AppColors.navyBlue
// // // // //                       : context.colorScheme.surfaceContainerHighest,
// // // // //                   borderRadius: BorderRadius.circular(10),
// // // // //                 ),
// // // // //                 child: Center(
// // // // //                   child: Text(_emoji(gt), style: const TextStyle(fontSize: 22)),
// // // // //                 ),
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //         );
// // // // //       }).toList(),
// // // // //     );
// // // // //   }

// // // // //   String _emoji(GameType gt) => switch (gt) {
// // // // //     GameType.truthOrDare => '🎯',
// // // // //     GameType.neverHaveIEver => '🍹',
// // // // //     GameType.memeGame => '😂',
// // // // //   };
// // // // // }

// // // // // class _PackSelector extends StatelessWidget {
// // // // //   const _PackSelector({
// // // // //     required this.packs,
// // // // //     required this.selected,
// // // // //     required this.onSelect,
// // // // //   });
// // // // //   final List<OfflinePack> packs;
// // // // //   final OfflinePack? selected;
// // // // //   final void Function(OfflinePack) onSelect;

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Column(
// // // // //       children: packs.map((pack) {
// // // // //         final isSelected = selected?.id == pack.id;
// // // // //         return GestureDetector(
// // // // //           onTap: () => onSelect(pack),
// // // // //           child: AnimatedContainer(
// // // // //             duration: const Duration(milliseconds: 150),
// // // // //             margin: const EdgeInsets.only(bottom: 8),
// // // // //             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
// // // // //             decoration: BoxDecoration(
// // // // //               color: isSelected
// // // // //                   ? AppColors.navyBlue.withOpacity(0.08)
// // // // //                   : context.colorScheme.surfaceContainerHighest,
// // // // //               borderRadius: BorderRadius.circular(12),
// // // // //               border: isSelected
// // // // //                   ? Border.all(color: AppColors.navyBlue, width: 2)
// // // // //                   : Border.all(color: context.colorScheme.outlineVariant),
// // // // //             ),
// // // // //             child: Row(
// // // // //               children: [
// // // // //                 Icon(
// // // // //                   isSelected
// // // // //                       ? Icons.radio_button_checked_rounded
// // // // //                       : Icons.radio_button_off_rounded,
// // // // //                   color: isSelected
// // // // //                       ? AppColors.navyBlue
// // // // //                       : context.colorScheme.onSurfaceVariant,
// // // // //                   size: 18,
// // // // //                 ),
// // // // //                 const SizedBox(width: 10),
// // // // //                 Expanded(
// // // // //                   child: Column(
// // // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // // //                     children: [
// // // // //                       Text(
// // // // //                         pack.name,
// // // // //                         style: context.textTheme.titleSmall?.copyWith(
// // // // //                           fontWeight: FontWeight.w600,
// // // // //                         ),
// // // // //                       ),
// // // // //                       Text(
// // // // //                         '${pack.cardCount} cards • '
// // // // //                         '${pack.language.toUpperCase()} • '
// // // // //                         '${pack.isFree ? "Free" : "Purchased"}',
// // // // //                         style: context.textTheme.bodySmall?.copyWith(
// // // // //                           color: context.colorScheme.onSurfaceVariant,
// // // // //                         ),
// // // // //                       ),
// // // // //                     ],
// // // // //                   ),
// // // // //                 ),
// // // // //                 if (pack.expiresAt != null)
// // // // //                   Text(
// // // // //                     'Exp: ${pack.expiresAt!.day}/${pack.expiresAt!.month}',
// // // // //                     style: context.textTheme.labelSmall?.copyWith(
// // // // //                       color: AppColors.warningAmber,
// // // // //                     ),
// // // // //                   ),
// // // // //               ],
// // // // //             ),
// // // // //           ),
// // // // //         );
// // // // //       }).toList(),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _NoPacksNotice extends StatelessWidget {
// // // // //   const _NoPacksNotice({required this.gameType});
// // // // //   final GameType gameType;

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Container(
// // // // //       padding: const EdgeInsets.all(16),
// // // // //       decoration: BoxDecoration(
// // // // //         color: AppColors.warningAmber.withOpacity(0.08),
// // // // //         borderRadius: BorderRadius.circular(12),
// // // // //       ),
// // // // //       child: Row(
// // // // //         children: [
// // // // //           const Icon(Icons.cloud_off_rounded, color: AppColors.warningAmber),
// // // // //           const SizedBox(width: 10),
// // // // //           Expanded(
// // // // //             child: Text(
// // // // //               'No ${gameType.displayName} packs downloaded. '
// // // // //               'Go online to download packs.',
// // // // //               style: const TextStyle(fontSize: 13),
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _GameSettings extends StatelessWidget {
// // // // //   const _GameSettings({
// // // // //     required this.maxRounds,
// // // // //     required this.allowSpicy,
// // // // //     required this.timerEnabled,
// // // // //     required this.timerSecs,
// // // // //     required this.allowSkip,
// // // // //     required this.onMaxRoundsChanged,
// // // // //     required this.onSpicyChanged,
// // // // //     required this.onTimerChanged,
// // // // //     required this.onTimerSecsChanged,
// // // // //     required this.onSkipChanged,
// // // // //   });

// // // // //   final int maxRounds;
// // // // //   final bool allowSpicy;
// // // // //   final bool timerEnabled;
// // // // //   final int timerSecs;
// // // // //   final bool allowSkip;
// // // // //   final void Function(int) onMaxRoundsChanged;
// // // // //   final void Function(bool) onSpicyChanged;
// // // // //   final void Function(bool) onTimerChanged;
// // // // //   final void Function(int) onTimerSecsChanged;
// // // // //   final void Function(bool) onSkipChanged;

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Column(
// // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // //       children: [
// // // // //         Text(
// // // // //           'Settings',
// // // // //           style: context.textTheme.titleSmall?.copyWith(
// // // // //             fontWeight: FontWeight.w700,
// // // // //           ),
// // // // //         ),
// // // // //         const SizedBox(height: 6),

// // // // //         // Rounds
// // // // //         Row(
// // // // //           children: [
// // // // //             Expanded(child: Text('Rounds: $maxRounds')),
// // // // //             Slider(
// // // // //               value: maxRounds.toDouble(),
// // // // //               min: 3,
// // // // //               max: 30,
// // // // //               divisions: 27,
// // // // //               label: '$maxRounds',
// // // // //               onChanged: (v) => onMaxRoundsChanged(v.round()),
// // // // //             ),
// // // // //           ],
// // // // //         ),

// // // // //         SwitchListTile(
// // // // //           title: const Text('Allow skip'),
// // // // //           value: allowSkip,
// // // // //           onChanged: onSkipChanged,
// // // // //           dense: true,
// // // // //           contentPadding: EdgeInsets.zero,
// // // // //         ),

// // // // //         SwitchListTile(
// // // // //           title: const Text('Spicy content'),
// // // // //           subtitle: const Text('Enable 18+ cards'),
// // // // //           value: allowSpicy,
// // // // //           onChanged: onSpicyChanged,
// // // // //           dense: true,
// // // // //           contentPadding: EdgeInsets.zero,
// // // // //         ),

// // // // //         SwitchListTile(
// // // // //           title: const Text('Turn timer'),
// // // // //           value: timerEnabled,
// // // // //           onChanged: onTimerChanged,
// // // // //           dense: true,
// // // // //           contentPadding: EdgeInsets.zero,
// // // // //         ),

// // // // //         if (timerEnabled) ...[
// // // // //           Row(
// // // // //             children: [
// // // // //               Expanded(child: Text('Timer: ${timerSecs}s')),
// // // // //               Slider(
// // // // //                 value: timerSecs.toDouble(),
// // // // //                 min: 15,
// // // // //                 max: 120,
// // // // //                 divisions: 21,
// // // // //                 label: '${timerSecs}s',
// // // // //                 onChanged: (v) => onTimerSecsChanged(v.round()),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //         ],
// // // // //       ],
// // // // //     );
// // // // //   }
// // // // // }

// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // import 'package:provider/provider.dart';

// // // // import '../../../../core/extensions/context_ext.dart';
// // // // import '../../../../core/theme/app_colors.dart';
// // // // import '../../../../shared/widgets/buttons/j_button.dart';
// // // // import '../../../games/engine/base_game_engine.dart';
// // // // import '../../data/offline_game_provider.dart';
// // // // import '../../data/offline_repository.dart';
// // // // import '../../domain/offline_session.dart';
// // // // import 'offline_play_screen.dart';
// // // // import 'lan_host_screen.dart';

// // // // /// Setup screen shared by both pass-and-play and LAN host modes.
// // // // /// Steps: 1. Pack selection  2. Game settings  3. Players
// // // // class OfflineSetupScreen extends StatefulWidget {
// // // //   const OfflineSetupScreen({super.key, required this.mode});
// // // //   final OfflineMode mode;

// // // //   @override
// // // //   State<OfflineSetupScreen> createState() => _OfflineSetupScreenState();
// // // // }

// // // // class _OfflineSetupScreenState extends State<OfflineSetupScreen> {
// // // //   // ── Setup state ─────────────────────────────────────────────────────────
// // // //   List<OfflinePack> _packs = [];
// // // //   OfflinePack? _selectedPack;
// // // //   GameType _gameType = GameType.truthOrDare;
// // // //   int _maxRounds = 10;
// // // //   bool _allowSpicy = false;
// // // //   bool _timerEnabled = false;
// // // //   int _timerSecs = 60;
// // // //   bool _allowSkip = true;

// // // //   final List<String> _players = [];
// // // //   final _playerCtrl = TextEditingController();
// // // //   bool _isLoading = true;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _loadPacks();
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _playerCtrl.dispose();
// // // //     super.dispose();
// // // //   }

// // // //   Future<void> _loadPacks() async {
// // // //     setState(() => _isLoading = true);
// // // //     final packs = await OfflineRepository.instance.getAvailablePacks(
// // // //       gameType: _gameType,
// // // //     );
// // // //     setState(() {
// // // //       _packs = packs.where((p) => p.isUsable).toList();
// // // //       _selectedPack = _packs.isNotEmpty ? _packs.first : null;
// // // //       _isLoading = false;
// // // //     });
// // // //   }

// // // //   void _addPlayer() {
// // // //     final name = _playerCtrl.text.trim();
// // // //     if (name.isEmpty || _players.length >= 12) return;
// // // //     if (_players.any((p) => p.toLowerCase() == name.toLowerCase())) {
// // // //       context.showErrorSnackBar('Name "$name" already added');
// // // //       return;
// // // //     }
// // // //     setState(() {
// // // //       _players.add(name);
// // // //       _playerCtrl.clear();
// // // //     });
// // // //   }

// // // //   Future<void> _start() async {
// // // //     if (_selectedPack == null) return;
// // // //     if (_players.length < 2 && widget.mode == OfflineMode.passAndPlay) {
// // // //       context.showErrorSnackBar('Add at least 2 players');
// // // //       return;
// // // //     }
// // // //     if (widget.mode == OfflineMode.lan && _players.isEmpty) {
// // // //       context.showErrorSnackBar('Enter your name');
// // // //       return;
// // // //     }

// // // //     final config = GameConfig(
// // // //       maxRounds: _maxRounds,
// // // //       turnTimerSeconds: _timerEnabled ? _timerSecs : 0,
// // // //       allowSkip: _allowSkip,
// // // //       allowSpicy: _allowSpicy,
// // // //       packId: _selectedPack!.id,
// // // //       language: _selectedPack!.language,
// // // //     );

// // // //     final provider = context.read<OfflineGameProvider>();

// // // //     if (widget.mode == OfflineMode.passAndPlay) {
// // // //       await provider.startPassAndPlay(
// // // //         gameType: _gameType,
// // // //         config: config,
// // // //         playerNames: _players,
// // // //         packId: _selectedPack!.id,
// // // //         packName: _selectedPack!.name,
// // // //         packCoverUrl: _selectedPack!.coverImageUrl,
// // // //       );
// // // //       if (provider.loadState == OfflineLoadState.ready && mounted) {
// // // //         Navigator.pushReplacement(
// // // //           context,
// // // //           MaterialPageRoute(
// // // //             builder: (_) => ChangeNotifierProvider.value(
// // // //               value: provider,
// // // //               child: const OfflinePlayScreen(),
// // // //             ),
// // // //           ),
// // // //         );
// // // //       }
// // // //     } else {
// // // //       // LAN host — go to lobby screen
// // // //       if (!mounted) return;
// // // //       Navigator.pushReplacement(
// // // //         context,
// // // //         MaterialPageRoute(
// // // //           builder: (_) => ChangeNotifierProvider.value(
// // // //             value: provider,
// // // //             child: LanHostScreen(
// // // //               hostName: _players.isNotEmpty ? _players.first : 'Host',
// // // //               config: config,
// // // //               gameType: _gameType,
// // // //               pack: _selectedPack!,
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       );
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = context.theme;
// // // //     final isLan = widget.mode == OfflineMode.lan;
// // // //     final canStart =
// // // //         _selectedPack != null &&
// // // //         (isLan ? _players.isNotEmpty : _players.length >= 2);

// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: Text(isLan ? 'Host LAN Room' : 'Pass & Play Setup'),
// // // //       ),
// // // //       body: Consumer<OfflineGameProvider>(
// // // //         builder: (ctx, provider, _) {
// // // //           if (provider.loadState == OfflineLoadState.loading) {
// // // //             return const Center(
// // // //               child: Column(
// // // //                 mainAxisSize: MainAxisSize.min,
// // // //                 children: [
// // // //                   CircularProgressIndicator(),
// // // //                   SizedBox(height: 16),
// // // //                   Text('Loading cards…'),
// // // //                 ],
// // // //               ),
// // // //             );
// // // //           }

// // // //           if (provider.loadState == OfflineLoadState.error) {
// // // //             return Center(
// // // //               child: Padding(
// // // //                 padding: const EdgeInsets.all(24),
// // // //                 child: Column(
// // // //                   mainAxisSize: MainAxisSize.min,
// // // //                   children: [
// // // //                     const Text('❌', style: TextStyle(fontSize: 48)),
// // // //                     const SizedBox(height: 12),
// // // //                     Text(
// // // //                       provider.error ?? 'Setup failed.',
// // // //                       textAlign: TextAlign.center,
// // // //                     ),
// // // //                     const SizedBox(height: 16),
// // // //                     OutlinedButton(
// // // //                       onPressed: () => provider.reset(),
// // // //                       child: const Text('Try again'),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //             );
// // // //           }

// // // //           return SingleChildScrollView(
// // // //             padding: const EdgeInsets.all(20),
// // // //             child: Column(
// // // //               crossAxisAlignment: CrossAxisAlignment.stretch,
// // // //               children: [
// // // //                 // ── Game type ─────────────────────────────────────────────
// // // //                 Text(
// // // //                   'Game',
// // // //                   style: theme.textTheme.titleSmall?.copyWith(
// // // //                     fontWeight: FontWeight.w700,
// // // //                   ),
// // // //                 ),
// // // //                 const SizedBox(height: 8),
// // // //                 _GameTypeSelector(
// // // //                   selected: _gameType,
// // // //                   onChanged: (gt) {
// // // //                     setState(() => _gameType = gt);
// // // //                     _loadPacks();
// // // //                   },
// // // //                 ),

// // // //                 const SizedBox(height: 20),

// // // //                 // ── Pack selection ────────────────────────────────────────
// // // //                 Text(
// // // //                   'Pack',
// // // //                   style: theme.textTheme.titleSmall?.copyWith(
// // // //                     fontWeight: FontWeight.w700,
// // // //                   ),
// // // //                 ),
// // // //                 const SizedBox(height: 8),
// // // //                 if (_isLoading)
// // // //                   const Center(child: CircularProgressIndicator())
// // // //                 else if (_packs.isEmpty)
// // // //                   _NoPacksNotice(gameType: _gameType)
// // // //                 else
// // // //                   _PackSelector(
// // // //                     packs: _packs,
// // // //                     selected: _selectedPack,
// // // //                     onSelect: (p) => setState(() => _selectedPack = p),
// // // //                   ),

// // // //                 const SizedBox(height: 20),

// // // //                 // ── Settings ──────────────────────────────────────────────
// // // //                 _GameSettings(
// // // //                   maxRounds: _maxRounds,
// // // //                   allowSpicy: _allowSpicy,
// // // //                   timerEnabled: _timerEnabled,
// // // //                   timerSecs: _timerSecs,
// // // //                   allowSkip: _allowSkip,
// // // //                   onMaxRoundsChanged: (v) => setState(() => _maxRounds = v),
// // // //                   onSpicyChanged: (v) => setState(() => _allowSpicy = v),
// // // //                   onTimerChanged: (v) => setState(() => _timerEnabled = v),
// // // //                   onTimerSecsChanged: (v) => setState(() => _timerSecs = v),
// // // //                   onSkipChanged: (v) => setState(() => _allowSkip = v),
// // // //                 ),

// // // //                 const SizedBox(height: 20),

// // // //                 // ── Players ───────────────────────────────────────────────
// // // //                 Text(
// // // //                   isLan ? 'Your name' : 'Players (${_players.length}/12)',
// // // //                   style: theme.textTheme.titleSmall?.copyWith(
// // // //                     fontWeight: FontWeight.w700,
// // // //                   ),
// // // //                 ),
// // // //                 const SizedBox(height: 8),

// // // //                 Row(
// // // //                   children: [
// // // //                     Expanded(
// // // //                       child: TextField(
// // // //                         controller: _playerCtrl,
// // // //                         textCapitalization: TextCapitalization.words,
// // // //                         textInputAction: TextInputAction.done,
// // // //                         onSubmitted: (_) => _addPlayer(),
// // // //                         decoration: InputDecoration(
// // // //                           hintText: isLan ? 'Your name' : 'Player name',
// // // //                           prefixIcon: const Icon(Icons.person_outline_rounded),
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                     const SizedBox(width: 8),
// // // //                     SizedBox(
// // // //                       height: 52,
// // // //                       child: FilledButton(
// // // //                         onPressed: _addPlayer,
// // // //                         child: Text(isLan ? 'Set' : 'Add'),
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),

// // // //                 // if (_players.isNotEmpty) ...[
// // // //                 //   const SizedBox(height: 10),
// // // //                 //   Wrap(
// // // //                 //     spacing: 8, runSpacing: 8,
// // // //                 //     children: _players.asMap().entries.map((e) => Chip(
// // // //                 //       label: Text(isLan
// // // //                 //           ? e.value
// // // //                 //           : '${e.key + 1}. ${e.value}'),
// // // //                 //       deleteIcon: const Icon(Icons.close_rounded, size: 14),
// // // //                 //       onDeleted: isLan && e.key == 0
// // // //                 //           ? null
// // // //                 //           : () => setState(() => _players.remove(e.value)),
// // // //                 //     ).toList(),
// // // //                 //   ),)
// // // //                 // ],
// // // //                 if (_players.isNotEmpty) ...[
// // // //                   const SizedBox(height: 10),
// // // //                   Wrap(
// // // //                     spacing: 8,
// // // //                     runSpacing: 8,
// // // //                     children: _players
// // // //                         .asMap()
// // // //                         .entries
// // // //                         .map(
// // // //                           (e) => Chip(
// // // //                             label: Text(
// // // //                               isLan ? e.value : '${e.key + 1}. ${e.value}',
// // // //                             ),
// // // //                             deleteIcon: const Icon(
// // // //                               Icons.close_rounded,
// // // //                               size: 14,
// // // //                             ),
// // // //                             onDeleted: isLan && e.key == 0
// // // //                                 ? null
// // // //                                 : () =>
// // // //                                       setState(() => _players.remove(e.value)),
// // // //                           ),
// // // //                         )
// // // //                         .toList(),
// // // //                   ),
// // // //                 ],

// // // //                 const SizedBox(height: 32),

// // // //                 JButton(
// // // //                   label: isLan ? 'Create LAN Room' : 'Start Game',
// // // //                   onPressed: canStart ? _start : null,
// // // //                   icon: isLan
// // // //                       ? Icons.wifi_tethering_rounded
// // // //                       : Icons.play_arrow_rounded,
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           );
// // // //         },
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // // ── Sub-widgets ───────────────────────────────────────────────────────────────

// // // // class _GameTypeSelector extends StatelessWidget {
// // // //   const _GameTypeSelector({required this.selected, required this.onChanged});
// // // //   final GameType selected;
// // // //   final void Function(GameType) onChanged;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Row(
// // // //       children: GameType.values.map((gt) {
// // // //         final isSelected = selected == gt;
// // // //         return Expanded(
// // // //           child: Padding(
// // // //             padding: const EdgeInsets.only(right: 8),
// // // //             child: GestureDetector(
// // // //               onTap: () => onChanged(gt),
// // // //               child: AnimatedContainer(
// // // //                 duration: const Duration(milliseconds: 150),
// // // //                 padding: const EdgeInsets.symmetric(vertical: 10),
// // // //                 decoration: BoxDecoration(
// // // //                   color: isSelected
// // // //                       ? AppColors.navyBlue
// // // //                       : context.colorScheme.surfaceContainerHighest,
// // // //                   borderRadius: BorderRadius.circular(10),
// // // //                 ),
// // // //                 child: Center(
// // // //                   child: Text(_emoji(gt), style: const TextStyle(fontSize: 22)),
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         );
// // // //       }).toList(),
// // // //     );
// // // //   }

// // // //   String _emoji(GameType gt) => switch (gt) {
// // // //     GameType.truthOrDare => '🎯',
// // // //     GameType.neverHaveIEver => '🍹',
// // // //     GameType.memeGame => '😂',
// // // //   };
// // // // }

// // // // class _PackSelector extends StatelessWidget {
// // // //   const _PackSelector({
// // // //     required this.packs,
// // // //     required this.selected,
// // // //     required this.onSelect,
// // // //   });
// // // //   final List<OfflinePack> packs;
// // // //   final OfflinePack? selected;
// // // //   final void Function(OfflinePack) onSelect;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Column(
// // // //       children: packs.map((pack) {
// // // //         final isSelected = selected?.id == pack.id;
// // // //         return GestureDetector(
// // // //           onTap: () => onSelect(pack),
// // // //           child: AnimatedContainer(
// // // //             duration: const Duration(milliseconds: 150),
// // // //             margin: const EdgeInsets.only(bottom: 8),
// // // //             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
// // // //             decoration: BoxDecoration(
// // // //               color: isSelected
// // // //                   ? AppColors.navyBlue.withOpacity(0.08)
// // // //                   : context.colorScheme.surfaceContainerHighest,
// // // //               borderRadius: BorderRadius.circular(12),
// // // //               border: isSelected
// // // //                   ? Border.all(color: AppColors.navyBlue, width: 2)
// // // //                   : Border.all(color: context.colorScheme.outlineVariant),
// // // //             ),
// // // //             child: Row(
// // // //               children: [
// // // //                 Icon(
// // // //                   isSelected
// // // //                       ? Icons.radio_button_checked_rounded
// // // //                       : Icons.radio_button_off_rounded,
// // // //                   color: isSelected
// // // //                       ? AppColors.navyBlue
// // // //                       : context.colorScheme.onSurfaceVariant,
// // // //                   size: 18,
// // // //                 ),
// // // //                 const SizedBox(width: 10),
// // // //                 Expanded(
// // // //                   child: Column(
// // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // //                     children: [
// // // //                       Text(
// // // //                         pack.name,
// // // //                         style: context.textTheme.titleSmall?.copyWith(
// // // //                           fontWeight: FontWeight.w600,
// // // //                         ),
// // // //                       ),
// // // //                       Text(
// // // //                         '${pack.cardCount} cards • '
// // // //                         '${pack.language.toUpperCase()} • '
// // // //                         '${pack.isFree ? "Free" : "Purchased"}',
// // // //                         style: context.textTheme.bodySmall?.copyWith(
// // // //                           color: context.colorScheme.onSurfaceVariant,
// // // //                         ),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                 ),
// // // //                 if (pack.expiresAt != null)
// // // //                   Text(
// // // //                     'Exp: ${pack.expiresAt!.day}/${pack.expiresAt!.month}',
// // // //                     style: context.textTheme.labelSmall?.copyWith(
// // // //                       color: AppColors.warningAmber,
// // // //                     ),
// // // //                   ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         );
// // // //       }).toList(),
// // // //     );
// // // //   }
// // // // }

// // // // class _NoPacksNotice extends StatelessWidget {
// // // //   const _NoPacksNotice({required this.gameType});
// // // //   final GameType gameType;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Container(
// // // //       padding: const EdgeInsets.all(16),
// // // //       decoration: BoxDecoration(
// // // //         color: AppColors.warningAmber.withOpacity(0.08),
// // // //         borderRadius: BorderRadius.circular(12),
// // // //       ),
// // // //       child: Row(
// // // //         children: [
// // // //           const Icon(Icons.cloud_off_rounded, color: AppColors.warningAmber),
// // // //           const SizedBox(width: 10),
// // // //           Expanded(
// // // //             child: Text(
// // // //               'No ${gameType.displayName} packs downloaded. '
// // // //               'Go online to download packs.',
// // // //               style: const TextStyle(fontSize: 13),
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _GameSettings extends StatelessWidget {
// // // //   const _GameSettings({
// // // //     required this.maxRounds,
// // // //     required this.allowSpicy,
// // // //     required this.timerEnabled,
// // // //     required this.timerSecs,
// // // //     required this.allowSkip,
// // // //     required this.onMaxRoundsChanged,
// // // //     required this.onSpicyChanged,
// // // //     required this.onTimerChanged,
// // // //     required this.onTimerSecsChanged,
// // // //     required this.onSkipChanged,
// // // //   });

// // // //   final int maxRounds;
// // // //   final bool allowSpicy;
// // // //   final bool timerEnabled;
// // // //   final int timerSecs;
// // // //   final bool allowSkip;
// // // //   final void Function(int) onMaxRoundsChanged;
// // // //   final void Function(bool) onSpicyChanged;
// // // //   final void Function(bool) onTimerChanged;
// // // //   final void Function(int) onTimerSecsChanged;
// // // //   final void Function(bool) onSkipChanged;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Column(
// // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // //       children: [
// // // //         Text(
// // // //           'Settings',
// // // //           style: context.textTheme.titleSmall?.copyWith(
// // // //             fontWeight: FontWeight.w700,
// // // //           ),
// // // //         ),
// // // //         const SizedBox(height: 6),

// // // //         // Rounds
// // // //         Row(
// // // //           children: [
// // // //             Expanded(child: Text('Rounds: $maxRounds')),
// // // //             Slider(
// // // //               value: maxRounds.toDouble(),
// // // //               min: 3,
// // // //               max: 30,
// // // //               divisions: 27,
// // // //               label: '$maxRounds',
// // // //               onChanged: (v) => onMaxRoundsChanged(v.round()),
// // // //             ),
// // // //           ],
// // // //         ),

// // // //         SwitchListTile(
// // // //           title: const Text('Allow skip'),
// // // //           value: allowSkip,
// // // //           onChanged: onSkipChanged,
// // // //           dense: true,
// // // //           contentPadding: EdgeInsets.zero,
// // // //         ),

// // // //         SwitchListTile(
// // // //           title: const Text('Spicy content'),
// // // //           subtitle: const Text('Enable 18+ cards'),
// // // //           value: allowSpicy,
// // // //           onChanged: onSpicyChanged,
// // // //           dense: true,
// // // //           contentPadding: EdgeInsets.zero,
// // // //         ),

// // // //         SwitchListTile(
// // // //           title: const Text('Turn timer'),
// // // //           value: timerEnabled,
// // // //           onChanged: onTimerChanged,
// // // //           dense: true,
// // // //           contentPadding: EdgeInsets.zero,
// // // //         ),

// // // //         if (timerEnabled) ...[
// // // //           Row(
// // // //             children: [
// // // //               Expanded(child: Text('Timer: ${timerSecs}s')),
// // // //               Slider(
// // // //                 value: timerSecs.toDouble(),
// // // //                 min: 15,
// // // //                 max: 120,
// // // //                 divisions: 21,
// // // //                 label: '${timerSecs}s',
// // // //                 onChanged: (v) => onTimerSecsChanged(v.round()),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ],
// // // //       ],
// // // //     );
// // // //   }
// // // // }

// // // import 'package:flutter/material.dart';
// // // import 'package:provider/provider.dart';

// // // import '../../../../core/extensions/context_ext.dart';
// // // import '../../../../core/theme/app_colors.dart';
// // // import '../../../../shared/widgets/buttons/j_button.dart';
// // // import '../../../games/engine/base_game_engine.dart';
// // // import '../../data/offline_game_provider.dart';
// // // import '../../data/offline_repository.dart';
// // // import '../../domain/offline_session.dart';
// // // import 'offline_play_screen.dart';
// // // import 'lan_host_screen.dart';

// // // /// Setup screen shared by both pass-and-play and LAN host modes.
// // // class OfflineSetupScreen extends StatefulWidget {
// // //   const OfflineSetupScreen({super.key, required this.mode});
// // //   final OfflineMode mode;

// // //   @override
// // //   State<OfflineSetupScreen> createState() => _OfflineSetupScreenState();
// // // }

// // // class _OfflineSetupScreenState extends State<OfflineSetupScreen> {
// // //   List<OfflinePack> _packs = [];
// // //   OfflinePack? _selectedPack;
// // //   GameType _gameType = GameType.truthOrDare;
// // //   int _maxRounds = 10;
// // //   bool _allowSpicy = false;
// // //   bool _timerEnabled = false;
// // //   int _timerSecs = 60;
// // //   bool _allowSkip = true;
// // //   final List<String> _players = [];
// // //   final _playerCtrl = TextEditingController();
// // //   bool _isLoading = true;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _loadPacks();
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _playerCtrl.dispose();
// // //     super.dispose();
// // //   }

// // //   Future<void> _loadPacks() async {
// // //     setState(() => _isLoading = true);
// // //     final packs = await OfflineRepository.instance.getAvailablePacks(
// // //       gameType: _gameType,
// // //     );
// // //     setState(() {
// // //       _packs = packs.where((p) => p.isUsable).toList();
// // //       _selectedPack = _packs.isNotEmpty ? _packs.first : null;
// // //       _isLoading = false;
// // //     });
// // //   }

// // //   void _addPlayer() {
// // //     final name = _playerCtrl.text.trim();
// // //     if (name.isEmpty || _players.length >= 12) return;
// // //     if (_players.any((p) => p.toLowerCase() == name.toLowerCase())) {
// // //       context.showErrorSnackBar('Name "$name" already added');
// // //       return;
// // //     }
// // //     setState(() {
// // //       _players.add(name);
// // //       _playerCtrl.clear();
// // //     });
// // //   }

// // //   Future<void> _start() async {
// // //     if (_selectedPack == null) return;
// // //     if (_players.length < 2 && widget.mode == OfflineMode.passAndPlay) {
// // //       context.showErrorSnackBar('Add at least 2 players');
// // //       return;
// // //     }
// // //     if (widget.mode == OfflineMode.lan && _players.isEmpty) {
// // //       context.showErrorSnackBar('Enter your name');
// // //       return;
// // //     }

// // //     final config = GameConfig(
// // //       maxRounds: _maxRounds,
// // //       turnTimerSeconds: _timerEnabled ? _timerSecs : 0,
// // //       allowSkip: _allowSkip,
// // //       allowSpicy: _allowSpicy,
// // //       packId: _selectedPack!.id,
// // //       language: _selectedPack!.language,
// // //     );

// // //     final provider = context.read<OfflineGameProvider>();

// // //     if (widget.mode == OfflineMode.passAndPlay) {
// // //       await provider.startPassAndPlay(
// // //         gameType: _gameType,
// // //         config: config,
// // //         playerNames: _players,
// // //         packId: _selectedPack!.id,
// // //         packName: _selectedPack!.name,
// // //         packCoverUrl: _selectedPack!.coverImageUrl,
// // //       );
// // //       if (provider.loadState == OfflineLoadState.ready && mounted) {
// // //         Navigator.pushReplacement(
// // //           context,
// // //           MaterialPageRoute(
// // //             builder: (_) => ChangeNotifierProvider.value(
// // //               value: provider,
// // //               child: const OfflinePlayScreen(),
// // //             ),
// // //           ),
// // //         );
// // //       }
// // //     } else {
// // //       if (!mounted) return;
// // //       Navigator.pushReplacement(
// // //         context,
// // //         MaterialPageRoute(
// // //           builder: (_) => ChangeNotifierProvider.value(
// // //             value: provider,
// // //             child: LanHostScreen(
// // //               hostName: _players.isNotEmpty ? _players.first : 'Host',
// // //               config: config,
// // //               gameType: _gameType,
// // //               pack: _selectedPack!,
// // //             ),
// // //           ),
// // //         ),
// // //       );
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;
// // //     final isLan = widget.mode == OfflineMode.lan;
// // //     final canStart =
// // //         _selectedPack != null &&
// // //         (isLan ? _players.isNotEmpty : _players.length >= 2);

// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: Text(isLan ? 'Host LAN Room' : 'Pass & Play Setup'),
// // //       ),
// // //       body: Consumer<OfflineGameProvider>(
// // //         builder: (ctx, provider, _) {
// // //           if (provider.loadState == OfflineLoadState.loading) {
// // //             return const Center(
// // //               child: Column(
// // //                 mainAxisSize: MainAxisSize.min,
// // //                 children: [
// // //                   CircularProgressIndicator(),
// // //                   SizedBox(height: 16),
// // //                   Text('Loading cards…'),
// // //                 ],
// // //               ),
// // //             );
// // //           }

// // //           if (provider.loadState == OfflineLoadState.error) {
// // //             return Center(
// // //               child: Padding(
// // //                 padding: const EdgeInsets.all(24),
// // //                 child: Column(
// // //                   mainAxisSize: MainAxisSize.min,
// // //                   children: [
// // //                     const Text('❌', style: TextStyle(fontSize: 48)),
// // //                     const SizedBox(height: 12),
// // //                     Text(
// // //                       provider.error ?? 'Setup failed.',
// // //                       textAlign: TextAlign.center,
// // //                     ),
// // //                     const SizedBox(height: 16),
// // //                     OutlinedButton(
// // //                       onPressed: () => provider.reset(),
// // //                       child: const Text('Try again'),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             );
// // //           }

// // //           // ── Main setup form ──────────────────────────────────────────────
// // //           return SingleChildScrollView(
// // //             padding: const EdgeInsets.all(20),
// // //             // crossAxisAlignment.start avoids stretch causing infinite width
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 // Game type
// // //                 Text(
// // //                   'Game',
// // //                   style: theme.textTheme.titleSmall?.copyWith(
// // //                     fontWeight: FontWeight.w700,
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 8),
// // //                 _GameTypeSelector(
// // //                   selected: _gameType,
// // //                   onChanged: (gt) {
// // //                     setState(() => _gameType = gt);
// // //                     _loadPacks();
// // //                   },
// // //                 ),
// // //                 const SizedBox(height: 20),

// // //                 // Pack selection
// // //                 Text(
// // //                   'Pack',
// // //                   style: theme.textTheme.titleSmall?.copyWith(
// // //                     fontWeight: FontWeight.w700,
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 8),
// // //                 if (_isLoading)
// // //                   const Center(child: CircularProgressIndicator())
// // //                 else if (_packs.isEmpty)
// // //                   _NoPacksNotice(gameType: _gameType)
// // //                 else
// // //                   _PackSelector(
// // //                     packs: _packs,
// // //                     selected: _selectedPack,
// // //                     onSelect: (p) => setState(() => _selectedPack = p),
// // //                   ),
// // //                 const SizedBox(height: 20),

// // //                 // Settings
// // //                 _GameSettings(
// // //                   maxRounds: _maxRounds,
// // //                   allowSpicy: _allowSpicy,
// // //                   timerEnabled: _timerEnabled,
// // //                   timerSecs: _timerSecs,
// // //                   allowSkip: _allowSkip,
// // //                   onMaxRoundsChanged: (v) => setState(() => _maxRounds = v),
// // //                   onSpicyChanged: (v) => setState(() => _allowSpicy = v),
// // //                   onTimerChanged: (v) => setState(() => _timerEnabled = v),
// // //                   onTimerSecsChanged: (v) => setState(() => _timerSecs = v),
// // //                   onSkipChanged: (v) => setState(() => _allowSkip = v),
// // //                 ),
// // //                 const SizedBox(height: 20),

// // //                 // Players
// // //                 Text(
// // //                   isLan ? 'Your name' : 'Players (${_players.length}/12)',
// // //                   style: theme.textTheme.titleSmall?.copyWith(
// // //                     fontWeight: FontWeight.w700,
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 8),
// // //                 Row(
// // //                   children: [
// // //                     Expanded(
// // //                       child: TextField(
// // //                         controller: _playerCtrl,
// // //                         textCapitalization: TextCapitalization.words,
// // //                         textInputAction: TextInputAction.done,
// // //                         onSubmitted: (_) => _addPlayer(),
// // //                         decoration: InputDecoration(
// // //                           hintText: isLan ? 'Your name' : 'Player name',
// // //                           prefixIcon: const Icon(Icons.person_outline_rounded),
// // //                         ),
// // //                       ),
// // //                     ),
// // //                     const SizedBox(width: 8),
// // //                     SizedBox(
// // //                       height: 52,
// // //                       width: 80,
// // //                       child: FilledButton(
// // //                         onPressed: _addPlayer,
// // //                         child: Text(isLan ? 'Set' : 'Add'),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),

// // //                 if (_players.isNotEmpty) ...[
// // //                   const SizedBox(height: 10),
// // //                   Wrap(
// // //                     spacing: 8,
// // //                     runSpacing: 8,
// // //                     children: _players
// // //                         .asMap()
// // //                         .entries
// // //                         .map(
// // //                           (e) => Chip(
// // //                             label: Text(
// // //                               isLan ? e.value : '${e.key + 1}. ${e.value}',
// // //                             ),
// // //                             deleteIcon: const Icon(
// // //                               Icons.close_rounded,
// // //                               size: 14,
// // //                             ),
// // //                             onDeleted: isLan && e.key == 0
// // //                                 ? null
// // //                                 : () =>
// // //                                       setState(() => _players.remove(e.value)),
// // //                           ),
// // //                         )
// // //                         .toList(),
// // //                   ),
// // //                 ],

// // //                 const SizedBox(height: 32),
// // //                 SizedBox(
// // //                   width: double.maxFinite,
// // //                   child: JButton(
// // //                     label: isLan ? 'Create LAN Room' : 'Start Game',
// // //                     onPressed: canStart ? _start : null,
// // //                     icon: isLan
// // //                         ? Icons.wifi_tethering_rounded
// // //                         : Icons.play_arrow_rounded,
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ── Game type selector ────────────────────────────────────────────────────────
// // // class _GameTypeSelector extends StatelessWidget {
// // //   const _GameTypeSelector({required this.selected, required this.onChanged});
// // //   final GameType selected;
// // //   final void Function(GameType) onChanged;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Row(
// // //       children: GameType.values.map((gt) {
// // //         final isSelected = selected == gt;
// // //         return Expanded(
// // //           child: Padding(
// // //             padding: const EdgeInsets.only(right: 8),
// // //             child: GestureDetector(
// // //               onTap: () => onChanged(gt),
// // //               child: AnimatedContainer(
// // //                 duration: const Duration(milliseconds: 150),
// // //                 padding: const EdgeInsets.symmetric(vertical: 10),
// // //                 decoration: BoxDecoration(
// // //                   color: isSelected
// // //                       ? AppColors.navyBlue
// // //                       : context.colorScheme.surfaceContainerHighest,
// // //                   borderRadius: BorderRadius.circular(10),
// // //                 ),
// // //                 child: Center(
// // //                   child: Text(_emoji(gt), style: const TextStyle(fontSize: 22)),
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //         );
// // //       }).toList(),
// // //     );
// // //   }

// // //   String _emoji(GameType gt) => switch (gt) {
// // //     GameType.truthOrDare => '🎯',
// // //     GameType.neverHaveIEver => '🍹',
// // //     GameType.memeGame => '😂',
// // //   };
// // // }

// // // // ── Pack selector ─────────────────────────────────────────────────────────────
// // // class _PackSelector extends StatelessWidget {
// // //   const _PackSelector({
// // //     required this.packs,
// // //     required this.selected,
// // //     required this.onSelect,
// // //   });
// // //   final List<OfflinePack> packs;
// // //   final OfflinePack? selected;
// // //   final void Function(OfflinePack) onSelect;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Column(
// // //       children: packs.map((pack) {
// // //         final isSelected = selected?.id == pack.id;
// // //         return GestureDetector(
// // //           onTap: () => onSelect(pack),
// // //           child: AnimatedContainer(
// // //             duration: const Duration(milliseconds: 150),
// // //             margin: const EdgeInsets.only(bottom: 8),
// // //             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
// // //             decoration: BoxDecoration(
// // //               color: isSelected
// // //                   ? AppColors.navyBlue.withOpacity(0.08)
// // //                   : context.colorScheme.surfaceContainerHighest,
// // //               borderRadius: BorderRadius.circular(12),
// // //               border: isSelected
// // //                   ? Border.all(color: AppColors.navyBlue, width: 2)
// // //                   : Border.all(color: context.colorScheme.outlineVariant),
// // //             ),
// // //             child: Row(
// // //               children: [
// // //                 Icon(
// // //                   isSelected
// // //                       ? Icons.radio_button_checked_rounded
// // //                       : Icons.radio_button_off_rounded,
// // //                   color: isSelected
// // //                       ? AppColors.navyBlue
// // //                       : context.colorScheme.onSurfaceVariant,
// // //                   size: 18,
// // //                 ),
// // //                 const SizedBox(width: 10),
// // //                 Expanded(
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     children: [
// // //                       Text(
// // //                         pack.name,
// // //                         style: context.textTheme.titleSmall?.copyWith(
// // //                           fontWeight: FontWeight.w600,
// // //                         ),
// // //                       ),
// // //                       Text(
// // //                         '${pack.cardCount} cards · '
// // //                         '${pack.language.toUpperCase()} · '
// // //                         '${pack.isFree ? "Free" : "Purchased"}',
// // //                         style: context.textTheme.bodySmall?.copyWith(
// // //                           color: context.colorScheme.onSurfaceVariant,
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //                 if (pack.expiresAt != null)
// // //                   Text(
// // //                     'Exp: ${pack.expiresAt!.day}/${pack.expiresAt!.month}',
// // //                     style: context.textTheme.labelSmall?.copyWith(
// // //                       color: AppColors.warningAmber,
// // //                     ),
// // //                   ),
// // //               ],
// // //             ),
// // //           ),
// // //         );
// // //       }).toList(),
// // //     );
// // //   }
// // // }

// // // // ── No packs notice ───────────────────────────────────────────────────────────
// // // class _NoPacksNotice extends StatelessWidget {
// // //   const _NoPacksNotice({required this.gameType});
// // //   final GameType gameType;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       padding: const EdgeInsets.all(16),
// // //       decoration: BoxDecoration(
// // //         color: AppColors.warningAmber.withOpacity(0.08),
// // //         borderRadius: BorderRadius.circular(12),
// // //       ),
// // //       child: Row(
// // //         children: [
// // //           const Icon(Icons.cloud_off_rounded, color: AppColors.warningAmber),
// // //           const SizedBox(width: 10),
// // //           Expanded(
// // //             child: Text(
// // //               'No ${gameType.displayName} packs downloaded. '
// // //               'Go online to download packs.',
// // //               style: const TextStyle(fontSize: 13),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ── Game settings ─────────────────────────────────────────────────────────────
// // // class _GameSettings extends StatelessWidget {
// // //   const _GameSettings({
// // //     required this.maxRounds,
// // //     required this.allowSpicy,
// // //     required this.timerEnabled,
// // //     required this.timerSecs,
// // //     required this.allowSkip,
// // //     required this.onMaxRoundsChanged,
// // //     required this.onSpicyChanged,
// // //     required this.onTimerChanged,
// // //     required this.onTimerSecsChanged,
// // //     required this.onSkipChanged,
// // //   });

// // //   final int maxRounds;
// // //   final bool allowSpicy;
// // //   final bool timerEnabled;
// // //   final int timerSecs;
// // //   final bool allowSkip;
// // //   final void Function(int) onMaxRoundsChanged;
// // //   final void Function(bool) onSpicyChanged;
// // //   final void Function(bool) onTimerChanged;
// // //   final void Function(int) onTimerSecsChanged;
// // //   final void Function(bool) onSkipChanged;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text(
// // //           'Settings',
// // //           style: context.textTheme.titleSmall?.copyWith(
// // //             fontWeight: FontWeight.w700,
// // //           ),
// // //         ),
// // //         const SizedBox(height: 6),

// // //         // Rounds slider
// // //         Row(
// // //           children: [
// // //             Expanded(child: Text('Rounds: $maxRounds')),
// // //             Slider(
// // //               value: maxRounds.toDouble(),
// // //               min: 3,
// // //               max: 30,
// // //               divisions: 27,
// // //               label: '$maxRounds',
// // //               onChanged: (v) => onMaxRoundsChanged(v.round()),
// // //             ),
// // //           ],
// // //         ),

// // //         SwitchListTile(
// // //           title: const Text('Allow skip'),
// // //           value: allowSkip,
// // //           onChanged: onSkipChanged,
// // //           dense: true,
// // //           contentPadding: EdgeInsets.zero,
// // //         ),

// // //         SwitchListTile(
// // //           title: const Text('Spicy content'),
// // //           subtitle: const Text('Enable 18+ cards'),
// // //           value: allowSpicy,
// // //           onChanged: onSpicyChanged,
// // //           dense: true,
// // //           contentPadding: EdgeInsets.zero,
// // //         ),

// // //         SwitchListTile(
// // //           title: const Text('Turn timer'),
// // //           value: timerEnabled,
// // //           onChanged: onTimerChanged,
// // //           dense: true,
// // //           contentPadding: EdgeInsets.zero,
// // //         ),

// // //         if (timerEnabled)
// // //           Row(
// // //             children: [
// // //               Expanded(child: Text('Timer: ${timerSecs}s')),
// // //               Slider(
// // //                 value: timerSecs.toDouble(),
// // //                 min: 15,
// // //                 max: 120,
// // //                 divisions: 21,
// // //                 label: '${timerSecs}s',
// // //                 onChanged: (v) => onTimerSecsChanged(v.round()),
// // //               ),
// // //             ],
// // //           ),
// // //       ],
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';

// // import '../../../../core/extensions/context_ext.dart';
// // import '../../../../core/theme/app_colors.dart';
// // import '../../../../shared/widgets/buttons/j_button.dart';
// // import '../../../games/engine/base_game_engine.dart';
// // import '../../data/offline_game_provider.dart';
// // import '../../data/offline_repository.dart';
// // import '../../domain/offline_session.dart';
// // import 'offline_play_screen.dart';
// // import 'lan_host_screen.dart';

// // /// Setup screen shared by both pass-and-play and LAN host modes.
// // class OfflineSetupScreen extends StatefulWidget {
// //   const OfflineSetupScreen({super.key, required this.mode});
// //   final OfflineMode mode;

// //   @override
// //   State<OfflineSetupScreen> createState() => _OfflineSetupScreenState();
// // }

// // class _OfflineSetupScreenState extends State<OfflineSetupScreen> {
// //   List<OfflinePack> _packs = [];
// //   OfflinePack? _selectedPack;
// //   GameType _gameType = GameType.truthOrDare;
// //   int _maxRounds = 10;
// //   bool _allowSpicy = false;
// //   bool _timerEnabled = false;
// //   int _timerSecs = 60;
// //   bool _allowSkip = true;
// //   final List<String> _players = [];
// //   final _playerCtrl = TextEditingController();
// //   bool _isLoading = true;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadPacks();
// //   }

// //   @override
// //   void dispose() {
// //     _playerCtrl.dispose();
// //     super.dispose();
// //   }

// //   Future<void> _loadPacks() async {
// //     setState(() => _isLoading = true);
// //     final packs = await OfflineRepository.instance.getAvailablePacks(
// //       gameType: _gameType,
// //     );
// //     setState(() {
// //       _packs = packs.where((p) => p.isUsable).toList();
// //       _selectedPack = _packs.isNotEmpty ? _packs.first : null;
// //       _isLoading = false;
// //     });
// //   }

// //   void _addPlayer() {
// //     final name = _playerCtrl.text.trim();
// //     if (name.isEmpty || _players.length >= 12) return;
// //     if (_players.any((p) => p.toLowerCase() == name.toLowerCase())) {
// //       context.showErrorSnackBar('Name "$name" already added');
// //       return;
// //     }
// //     setState(() {
// //       _players.add(name);
// //       _playerCtrl.clear();
// //     });
// //   }

// //   Future<void> _start() async {
// //     if (_selectedPack == null) return;
// //     if (_players.length < 2 && widget.mode == OfflineMode.passAndPlay) {
// //       context.showErrorSnackBar('Add at least 2 players');
// //       return;
// //     }
// //     if (widget.mode == OfflineMode.lan && _players.isEmpty) {
// //       context.showErrorSnackBar('Enter your name');
// //       return;
// //     }

// //     final config = GameConfig(
// //       maxRounds: _maxRounds,
// //       turnTimerSeconds: _timerEnabled ? _timerSecs : 0,
// //       allowSkip: _allowSkip,
// //       allowSpicy: _allowSpicy,
// //       packId: _selectedPack!.id,
// //       language: _selectedPack!.language,
// //     );

// //     final provider = context.read<OfflineGameProvider>();

// //     if (widget.mode == OfflineMode.passAndPlay) {
// //       await provider.startPassAndPlay(
// //         gameType: _gameType,
// //         config: config,
// //         playerNames: _players,
// //         packId: _selectedPack!.id,
// //         packName: _selectedPack!.name,
// //         packCoverUrl: _selectedPack!.coverImageUrl,
// //       );
// //       if (provider.loadState == OfflineLoadState.ready && mounted) {
// //         Navigator.pushReplacement(
// //           context,
// //           MaterialPageRoute(
// //             builder: (_) => ChangeNotifierProvider.value(
// //               value: provider,
// //               child: const OfflinePlayScreen(),
// //             ),
// //           ),
// //         );
// //       }
// //     } else {
// //       if (!mounted) return;
// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(
// //           builder: (_) => ChangeNotifierProvider.value(
// //             value: provider,
// //             child: LanHostScreen(
// //               hostName: _players.isNotEmpty ? _players.first : 'Host',
// //               config: config,
// //               gameType: _gameType,
// //               pack: _selectedPack!,
// //             ),
// //           ),
// //         ),
// //       );
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     final isLan = widget.mode == OfflineMode.lan;
// //     final canStart =
// //         _selectedPack != null &&
// //         (isLan ? _players.isNotEmpty : _players.length >= 2);

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(isLan ? 'Host LAN Room' : 'Pass & Play Setup'),
// //       ),
// //       body: Consumer<OfflineGameProvider>(
// //         builder: (ctx, provider, _) {
// //           if (provider.loadState == OfflineLoadState.loading) {
// //             return const Center(
// //               child: Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 children: [
// //                   CircularProgressIndicator(),
// //                   SizedBox(height: 16),
// //                   Text('Loading cards…'),
// //                 ],
// //               ),
// //             );
// //           }

// //           if (provider.loadState == OfflineLoadState.error) {
// //             return Center(
// //               child: Padding(
// //                 padding: const EdgeInsets.all(24),
// //                 child: Column(
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     const Text('❌', style: TextStyle(fontSize: 48)),
// //                     const SizedBox(height: 12),
// //                     Text(
// //                       provider.error ?? 'Setup failed.',
// //                       textAlign: TextAlign.center,
// //                     ),
// //                     const SizedBox(height: 16),
// //                     OutlinedButton(
// //                       onPressed: () => provider.reset(),
// //                       child: const Text('Try again'),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             );
// //           }

// //           // ── Main setup form ──────────────────────────────────────────────
// //           return SingleChildScrollView(
// //             padding: const EdgeInsets.all(20),
// //             // crossAxisAlignment.start avoids stretch causing infinite width
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 // Game type
// //                 Text(
// //                   'Game',
// //                   style: theme.textTheme.titleSmall?.copyWith(
// //                     fontWeight: FontWeight.w700,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 8),
// //                 _GameTypeSelector(
// //                   selected: _gameType,
// //                   onChanged: (gt) {
// //                     setState(() => _gameType = gt);
// //                     _loadPacks();
// //                   },
// //                 ),
// //                 const SizedBox(height: 20),

// //                 // Pack selection
// //                 Text(
// //                   'Pack',
// //                   style: theme.textTheme.titleSmall?.copyWith(
// //                     fontWeight: FontWeight.w700,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 8),
// //                 if (_isLoading)
// //                   const Center(child: CircularProgressIndicator())
// //                 else if (_packs.isEmpty)
// //                   _NoPacksNotice(gameType: _gameType)
// //                 else
// //                   _PackSelector(
// //                     packs: _packs,
// //                     selected: _selectedPack,
// //                     onSelect: (p) => setState(() => _selectedPack = p),
// //                   ),
// //                 const SizedBox(height: 20),

// //                 // Settings
// //                 _GameSettings(
// //                   maxRounds: _maxRounds,
// //                   allowSpicy: _allowSpicy,
// //                   timerEnabled: _timerEnabled,
// //                   timerSecs: _timerSecs,
// //                   allowSkip: _allowSkip,
// //                   onMaxRoundsChanged: (v) => setState(() => _maxRounds = v),
// //                   onSpicyChanged: (v) => setState(() => _allowSpicy = v),
// //                   onTimerChanged: (v) => setState(() => _timerEnabled = v),
// //                   onTimerSecsChanged: (v) => setState(() => _timerSecs = v),
// //                   onSkipChanged: (v) => setState(() => _allowSkip = v),
// //                 ),
// //                 const SizedBox(height: 20),

// //                 // Players
// //                 Text(
// //                   isLan ? 'Your name' : 'Players (${_players.length}/12)',
// //                   style: theme.textTheme.titleSmall?.copyWith(
// //                     fontWeight: FontWeight.w700,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 8),
// //                 Row(
// //                   children: [
// //                     Expanded(
// //                       child: TextField(
// //                         controller: _playerCtrl,
// //                         textCapitalization: TextCapitalization.words,
// //                         textInputAction: TextInputAction.done,
// //                         onSubmitted: (_) => _addPlayer(),
// //                         decoration: InputDecoration(
// //                           hintText: isLan ? 'Your name' : 'Player name',
// //                           prefixIcon: const Icon(Icons.person_outline_rounded),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(width: 8),
// //                     SizedBox(
// //                       height: 52,
// //                       width: 80,
// //                       child: FilledButton(
// //                         onPressed: _addPlayer,
// //                         child: Text(isLan ? 'Set' : 'Add'),
// //                       ),
// //                     ),
// //                   ],
// //                 ),

// //                 if (_players.isNotEmpty) ...[
// //                   const SizedBox(height: 10),
// //                   Wrap(
// //                     spacing: 8,
// //                     runSpacing: 8,
// //                     children: _players
// //                         .asMap()
// //                         .entries
// //                         .map(
// //                           (e) => Chip(
// //                             label: Text(
// //                               isLan ? e.value : '${e.key + 1}. ${e.value}',
// //                             ),
// //                             deleteIcon: const Icon(
// //                               Icons.close_rounded,
// //                               size: 14,
// //                             ),
// //                             onDeleted: isLan && e.key == 0
// //                                 ? null
// //                                 : () =>
// //                                       setState(() => _players.remove(e.value)),
// //                           ),
// //                         )
// //                         .toList(),
// //                   ),
// //                 ],

// //                 const SizedBox(height: 32),
// //                 SizedBox(
// //                   width: double.maxFinite,
// //                   child: JButton(
// //                     label: isLan ? 'Create LAN Room' : 'Start Game',
// //                     onPressed: canStart ? _start : null,
// //                     icon: isLan
// //                         ? Icons.wifi_tethering_rounded
// //                         : Icons.play_arrow_rounded,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }

// // // ── Game type selector ────────────────────────────────────────────────────────
// // class _GameTypeSelector extends StatelessWidget {
// //   const _GameTypeSelector({required this.selected, required this.onChanged});
// //   final GameType selected;
// //   final void Function(GameType) onChanged;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Row(
// //       children: GameType.values.map((gt) {
// //         final isSelected = selected == gt;
// //         return Expanded(
// //           child: Padding(
// //             padding: const EdgeInsets.only(right: 8),
// //             child: GestureDetector(
// //               onTap: () => onChanged(gt),
// //               child: AnimatedContainer(
// //                 duration: const Duration(milliseconds: 150),
// //                 padding: const EdgeInsets.symmetric(vertical: 10),
// //                 decoration: BoxDecoration(
// //                   color: isSelected
// //                       ? AppColors.navyBlue
// //                       : context.colorScheme.surfaceContainerHighest,
// //                   borderRadius: BorderRadius.circular(10),
// //                 ),
// //                 child: Center(
// //                   child: Text(_emoji(gt), style: const TextStyle(fontSize: 22)),
// //                 ),
// //               ),
// //             ),
// //           ),
// //         );
// //       }).toList(),
// //     );
// //   }

// //   String _emoji(GameType gt) => switch (gt) {
// //     GameType.truthOrDare => '🎯',
// //     GameType.neverHaveIEver => '🍹',
// //     GameType.memeGame => '😂',
// //   };
// // }

// // // ── Pack selector ─────────────────────────────────────────────────────────────
// // class _PackSelector extends StatelessWidget {
// //   const _PackSelector({
// //     required this.packs,
// //     required this.selected,
// //     required this.onSelect,
// //   });
// //   final List<OfflinePack> packs;
// //   final OfflinePack? selected;
// //   final void Function(OfflinePack) onSelect;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Column(
// //       children: packs.map((pack) {
// //         final isSelected = selected?.id == pack.id;
// //         return GestureDetector(
// //           onTap: () => onSelect(pack),
// //           child: AnimatedContainer(
// //             duration: const Duration(milliseconds: 150),
// //             margin: const EdgeInsets.only(bottom: 8),
// //             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
// //             decoration: BoxDecoration(
// //               color: isSelected
// //                   ? AppColors.navyBlue.withOpacity(0.08)
// //                   : context.colorScheme.surfaceContainerHighest,
// //               borderRadius: BorderRadius.circular(12),
// //               border: isSelected
// //                   ? Border.all(color: AppColors.navyBlue, width: 2)
// //                   : Border.all(color: context.colorScheme.outlineVariant),
// //             ),
// //             child: Row(
// //               children: [
// //                 Icon(
// //                   isSelected
// //                       ? Icons.radio_button_checked_rounded
// //                       : Icons.radio_button_off_rounded,
// //                   color: isSelected
// //                       ? AppColors.navyBlue
// //                       : context.colorScheme.onSurfaceVariant,
// //                   size: 18,
// //                 ),
// //                 const SizedBox(width: 10),
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         pack.name,
// //                         style: context.textTheme.titleSmall?.copyWith(
// //                           fontWeight: FontWeight.w600,
// //                         ),
// //                       ),
// //                       Text(
// //                         '${pack.cardCount} cards · '
// //                         '${pack.language.toUpperCase()} · '
// //                         '${pack.isFree ? "Free" : "Purchased"}',
// //                         style: context.textTheme.bodySmall?.copyWith(
// //                           color: context.colorScheme.onSurfaceVariant,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //                 if (pack.expiresAt != null)
// //                   Text(
// //                     'Exp: ${pack.expiresAt!.day}/${pack.expiresAt!.month}',
// //                     style: context.textTheme.labelSmall?.copyWith(
// //                       color: AppColors.warningAmber,
// //                     ),
// //                   ),
// //               ],
// //             ),
// //           ),
// //         );
// //       }).toList(),
// //     );
// //   }
// // }

// // // ── No packs notice ───────────────────────────────────────────────────────────
// // class _NoPacksNotice extends StatelessWidget {
// //   const _NoPacksNotice({required this.gameType});
// //   final GameType gameType;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: AppColors.warningAmber.withOpacity(0.08),
// //         borderRadius: BorderRadius.circular(12),
// //       ),
// //       child: Row(
// //         children: [
// //           const Icon(Icons.cloud_off_rounded, color: AppColors.warningAmber),
// //           const SizedBox(width: 10),
// //           Expanded(
// //             child: Text(
// //               'No ${gameType.displayName} packs downloaded. '
// //               'Go online to download packs.',
// //               style: const TextStyle(fontSize: 13),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // ── Game settings ─────────────────────────────────────────────────────────────
// // class _GameSettings extends StatelessWidget {
// //   const _GameSettings({
// //     required this.maxRounds,
// //     required this.allowSpicy,
// //     required this.timerEnabled,
// //     required this.timerSecs,
// //     required this.allowSkip,
// //     required this.onMaxRoundsChanged,
// //     required this.onSpicyChanged,
// //     required this.onTimerChanged,
// //     required this.onTimerSecsChanged,
// //     required this.onSkipChanged,
// //   });

// //   final int maxRounds;
// //   final bool allowSpicy;
// //   final bool timerEnabled;
// //   final int timerSecs;
// //   final bool allowSkip;
// //   final void Function(int) onMaxRoundsChanged;
// //   final void Function(bool) onSpicyChanged;
// //   final void Function(bool) onTimerChanged;
// //   final void Function(int) onTimerSecsChanged;
// //   final void Function(bool) onSkipChanged;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           'Settings',
// //           style: context.textTheme.titleSmall?.copyWith(
// //             fontWeight: FontWeight.w700,
// //           ),
// //         ),
// //         const SizedBox(height: 6),

// //         // Rounds slider
// //         Row(
// //           children: [
// //             SizedBox(width: 100, child: Text('Rounds: $maxRounds')),
// //             Expanded(
// //               child: Slider(
// //                 value: maxRounds.toDouble(),
// //                 min: 3,
// //                 max: 30,
// //                 divisions: 27,
// //                 label: '$maxRounds',
// //                 onChanged: (v) => onMaxRoundsChanged(v.round()),
// //               ),
// //             ),
// //           ],
// //         ),

// //         SwitchListTile(
// //           title: const Text('Allow skip'),
// //           value: allowSkip,
// //           onChanged: onSkipChanged,
// //           dense: true,
// //           contentPadding: EdgeInsets.zero,
// //         ),

// //         SwitchListTile(
// //           title: const Text('Spicy content'),
// //           subtitle: const Text('Enable 18+ cards'),
// //           value: allowSpicy,
// //           onChanged: onSpicyChanged,
// //           dense: true,
// //           contentPadding: EdgeInsets.zero,
// //         ),

// //         SwitchListTile(
// //           title: const Text('Turn timer'),
// //           value: timerEnabled,
// //           onChanged: onTimerChanged,
// //           dense: true,
// //           contentPadding: EdgeInsets.zero,
// //         ),

// //         if (timerEnabled)
// //           Row(
// //             children: [
// //               Expanded(child: Text('Timer: ${timerSecs}s')),
// //               Slider(
// //                 value: timerSecs.toDouble(),
// //                 min: 15,
// //                 max: 120,
// //                 divisions: 21,
// //                 label: '${timerSecs}s',
// //                 onChanged: (v) => onTimerSecsChanged(v.round()),
// //               ),
// //             ],
// //           ),
// //       ],
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/buttons/j_button.dart';
// import '../../../games/engine/base_game_engine.dart';
// import '../../data/offline_game_provider.dart';
// import '../../data/offline_repository.dart';
// import '../../domain/offline_session.dart';
// import 'offline_play_screen.dart';
// import 'lan_host_screen.dart';

// /// Setup screen shared by both pass-and-play and LAN host modes.
// class OfflineSetupScreen extends StatefulWidget {
//   const OfflineSetupScreen({super.key, required this.mode});
//   final OfflineMode mode;

//   @override
//   State<OfflineSetupScreen> createState() => _OfflineSetupScreenState();
// }

// class _OfflineSetupScreenState extends State<OfflineSetupScreen> {
//   List<OfflinePack> _packs = [];
//   OfflinePack? _selectedPack;
//   GameType _gameType = GameType.truthOrDare;
//   String _langFilter = 'all'; // 'all' | 'en' | 'ar' | 'fr'
//   int _maxRounds = 10;
//   bool _allowSpicy = false;
//   bool _timerEnabled = false;
//   int _timerSecs = 60;
//   bool _allowSkip = true;
//   final List<String> _players = [];
//   final _playerCtrl = TextEditingController();
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadPacks();
//   }

//   @override
//   void dispose() {
//     _playerCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _loadPacks() async {
//     setState(() => _isLoading = true);
//     final packs = await OfflineRepository.instance.getAvailablePacks(
//       gameType: _gameType,
//     );
//     setState(() {
//       final usable = packs.where((p) => p.isUsable).toList();
//       _packs = _langFilter == 'all'
//           ? usable
//           : usable
//                 .where(
//                   (p) => p.language == _langFilter || p.language == 'multi',
//                 )
//                 .toList();
//       _selectedPack = _packs.isNotEmpty ? _packs.first : null;
//       _isLoading = false;
//     });
//   }

//   void _addPlayer() {
//     final name = _playerCtrl.text.trim();
//     if (name.isEmpty || _players.length >= 12) return;
//     if (_players.any((p) => p.toLowerCase() == name.toLowerCase())) {
//       context.showErrorSnackBar('Name "$name" already added');
//       return;
//     }
//     setState(() {
//       _players.add(name);
//       _playerCtrl.clear();
//     });
//   }

//   Future<void> _start() async {
//     if (_selectedPack == null) return;
//     if (_players.length < 2 && widget.mode == OfflineMode.passAndPlay) {
//       context.showErrorSnackBar('Add at least 2 players');
//       return;
//     }
//     if (widget.mode == OfflineMode.lan && _players.isEmpty) {
//       context.showErrorSnackBar('Enter your name');
//       return;
//     }

//     final config = GameConfig(
//       maxRounds: _maxRounds,
//       turnTimerSeconds: _timerEnabled ? _timerSecs : 0,
//       allowSkip: _allowSkip,
//       allowSpicy: _allowSpicy,
//       packId: _selectedPack!.id,
//       language: _selectedPack!.language,
//     );

//     final provider = context.read<OfflineGameProvider>();

//     if (widget.mode == OfflineMode.passAndPlay) {
//       await provider.startPassAndPlay(
//         gameType: _gameType,
//         config: config,
//         playerNames: _players,
//         packId: _selectedPack!.id,
//         packName: _selectedPack!.name,
//         packCoverUrl: _selectedPack!.coverImageUrl,
//       );
//       if (provider.loadState == OfflineLoadState.ready && mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => ChangeNotifierProvider.value(
//               value: provider,
//               child: const OfflinePlayScreen(),
//             ),
//           ),
//         );
//       }
//     } else {
//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ChangeNotifierProvider.value(
//             value: provider,
//             child: LanHostScreen(
//               hostName: _players.isNotEmpty ? _players.first : 'Host',
//               config: config,
//               gameType: _gameType,
//               pack: _selectedPack!,
//             ),
//           ),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final isLan = widget.mode == OfflineMode.lan;
//     final canStart =
//         _selectedPack != null &&
//         (isLan ? _players.isNotEmpty : _players.length >= 2);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(isLan ? 'Host LAN Room' : 'Pass & Play Setup'),
//       ),
//       body: Consumer<OfflineGameProvider>(
//         builder: (ctx, provider, _) {
//           if (provider.loadState == OfflineLoadState.loading) {
//             return const Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 16),
//                   Text('Loading cards…'),
//                 ],
//               ),
//             );
//           }

//           if (provider.loadState == OfflineLoadState.error) {
//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text('❌', style: TextStyle(fontSize: 48)),
//                     const SizedBox(height: 12),
//                     Text(
//                       provider.error ?? 'Setup failed.',
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16),
//                     OutlinedButton(
//                       onPressed: () => provider.reset(),
//                       child: const Text('Try again'),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }

//           // ── Main setup form ──────────────────────────────────────────────
//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             // crossAxisAlignment.start avoids stretch causing infinite width
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Language filter
//                 Text(
//                   'Language',
//                   style: theme.textTheme.titleSmall?.copyWith(
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: [
//                       for (final lang in [
//                         ('all', '🌐 All'),
//                         ('en', '🇬🇧 EN'),
//                         ('ar', '🇸🇦 AR'),
//                         ('fr', '🇫🇷 FR'),
//                       ])
//                         Padding(
//                           padding: const EdgeInsets.only(right: 8),
//                           child: ChoiceChip(
//                             label: Text(lang.$2),
//                             selected: _langFilter == lang.$1,
//                             onSelected: (_) {
//                               setState(() => _langFilter = lang.$1);
//                               _loadPacks();
//                             },
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Game type
//                 Text(
//                   'Game',
//                   style: theme.textTheme.titleSmall?.copyWith(
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 _GameTypeSelector(
//                   selected: _gameType,
//                   onChanged: (gt) {
//                     setState(() => _gameType = gt);
//                     _loadPacks();
//                   },
//                 ),
//                 const SizedBox(height: 20),

//                 // Pack selection
//                 Text(
//                   'Pack',
//                   style: theme.textTheme.titleSmall?.copyWith(
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 if (_isLoading)
//                   const Center(child: CircularProgressIndicator())
//                 else if (_packs.isEmpty)
//                   _NoPacksNotice(gameType: _gameType)
//                 else
//                   _PackSelector(
//                     packs: _packs,
//                     selected: _selectedPack,
//                     onSelect: (p) => setState(() => _selectedPack = p),
//                   ),
//                 const SizedBox(height: 20),

//                 // Settings
//                 _GameSettings(
//                   maxRounds: _maxRounds,
//                   allowSpicy: _allowSpicy,
//                   timerEnabled: _timerEnabled,
//                   timerSecs: _timerSecs,
//                   allowSkip: _allowSkip,
//                   onMaxRoundsChanged: (v) => setState(() => _maxRounds = v),
//                   onSpicyChanged: (v) => setState(() => _allowSpicy = v),
//                   onTimerChanged: (v) => setState(() => _timerEnabled = v),
//                   onTimerSecsChanged: (v) => setState(() => _timerSecs = v),
//                   onSkipChanged: (v) => setState(() => _allowSkip = v),
//                 ),
//                 const SizedBox(height: 20),

//                 // Players
//                 Text(
//                   isLan ? 'Your name' : 'Players (${_players.length}/12)',
//                   style: theme.textTheme.titleSmall?.copyWith(
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _playerCtrl,
//                         textCapitalization: TextCapitalization.words,
//                         textInputAction: TextInputAction.done,
//                         onSubmitted: (_) => _addPlayer(),
//                         decoration: InputDecoration(
//                           hintText: isLan ? 'Your name' : 'Player name',
//                           prefixIcon: const Icon(Icons.person_outline_rounded),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     SizedBox(
//                       height: 52,
//                       width: 80,
//                       child: FilledButton(
//                         onPressed: _addPlayer,
//                         child: Text(isLan ? 'Set' : 'Add'),
//                       ),
//                     ),
//                   ],
//                 ),

//                 if (_players.isNotEmpty) ...[
//                   const SizedBox(height: 10),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: _players
//                         .asMap()
//                         .entries
//                         .map(
//                           (e) => Chip(
//                             label: Text(
//                               isLan ? e.value : '${e.key + 1}. ${e.value}',
//                             ),
//                             deleteIcon: const Icon(
//                               Icons.close_rounded,
//                               size: 14,
//                             ),
//                             onDeleted: isLan && e.key == 0
//                                 ? null
//                                 : () =>
//                                       setState(() => _players.remove(e.value)),
//                           ),
//                         )
//                         .toList(),
//                   ),
//                 ],

//                 const SizedBox(height: 32),
//                 SizedBox(
//                   width: double.maxFinite,
//                   child: JButton(
//                     label: isLan ? 'Create LAN Room' : 'Start Game',
//                     onPressed: canStart ? _start : null,
//                     icon: isLan
//                         ? Icons.wifi_tethering_rounded
//                         : Icons.play_arrow_rounded,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // ── Game type selector ────────────────────────────────────────────────────────
// class _GameTypeSelector extends StatelessWidget {
//   const _GameTypeSelector({required this.selected, required this.onChanged});
//   final GameType selected;
//   final void Function(GameType) onChanged;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: GameType.values.map((gt) {
//         final isSelected = selected == gt;
//         return Expanded(
//           child: Padding(
//             padding: const EdgeInsets.only(right: 8),
//             child: GestureDetector(
//               onTap: () => onChanged(gt),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 150),
//                 padding: const EdgeInsets.symmetric(vertical: 10),
//                 decoration: BoxDecoration(
//                   color: isSelected
//                       ? AppColors.navyBlue
//                       : context.colorScheme.surfaceContainerHighest,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Center(
//                   child: Text(_emoji(gt), style: const TextStyle(fontSize: 22)),
//                 ),
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   String _emoji(GameType gt) => switch (gt) {
//     GameType.truthOrDare => '🎯',
//     GameType.neverHaveIEver => '🍹',
//     GameType.memeGame => '😂',
//   };
// }

// // ── Pack selector ─────────────────────────────────────────────────────────────
// class _PackSelector extends StatelessWidget {
//   const _PackSelector({
//     required this.packs,
//     required this.selected,
//     required this.onSelect,
//   });
//   final List<OfflinePack> packs;
//   final OfflinePack? selected;
//   final void Function(OfflinePack) onSelect;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: packs.map((pack) {
//         final isSelected = selected?.id == pack.id;
//         return GestureDetector(
//           onTap: () => onSelect(pack),
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 150),
//             margin: const EdgeInsets.only(bottom: 8),
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//             decoration: BoxDecoration(
//               color: isSelected
//                   ? AppColors.navyBlue.withOpacity(0.08)
//                   : context.colorScheme.surfaceContainerHighest,
//               borderRadius: BorderRadius.circular(12),
//               border: isSelected
//                   ? Border.all(color: AppColors.navyBlue, width: 2)
//                   : Border.all(color: context.colorScheme.outlineVariant),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   isSelected
//                       ? Icons.radio_button_checked_rounded
//                       : Icons.radio_button_off_rounded,
//                   color: isSelected
//                       ? AppColors.navyBlue
//                       : context.colorScheme.onSurfaceVariant,
//                   size: 18,
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         pack.name,
//                         style: context.textTheme.titleSmall?.copyWith(
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       Text(
//                         '${pack.cardCount} cards · '
//                         '${pack.language.toUpperCase()} · '
//                         '${pack.isFree ? "Free" : "Purchased"}',
//                         style: context.textTheme.bodySmall?.copyWith(
//                           color: context.colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (pack.expiresAt != null)
//                   Text(
//                     'Exp: ${pack.expiresAt!.day}/${pack.expiresAt!.month}',
//                     style: context.textTheme.labelSmall?.copyWith(
//                       color: AppColors.warningAmber,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
// }

// // ── No packs notice ───────────────────────────────────────────────────────────
// class _NoPacksNotice extends StatelessWidget {
//   const _NoPacksNotice({required this.gameType});
//   final GameType gameType;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.warningAmber.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.cloud_off_rounded, color: AppColors.warningAmber),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               'No ${gameType.displayName} packs downloaded. '
//               'Go online to download packs.',
//               style: const TextStyle(fontSize: 13),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Game settings ─────────────────────────────────────────────────────────────
// class _GameSettings extends StatelessWidget {
//   const _GameSettings({
//     required this.maxRounds,
//     required this.allowSpicy,
//     required this.timerEnabled,
//     required this.timerSecs,
//     required this.allowSkip,
//     required this.onMaxRoundsChanged,
//     required this.onSpicyChanged,
//     required this.onTimerChanged,
//     required this.onTimerSecsChanged,
//     required this.onSkipChanged,
//   });

//   final int maxRounds;
//   final bool allowSpicy;
//   final bool timerEnabled;
//   final int timerSecs;
//   final bool allowSkip;
//   final void Function(int) onMaxRoundsChanged;
//   final void Function(bool) onSpicyChanged;
//   final void Function(bool) onTimerChanged;
//   final void Function(int) onTimerSecsChanged;
//   final void Function(bool) onSkipChanged;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Settings',
//           style: context.textTheme.titleSmall?.copyWith(
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         const SizedBox(height: 6),

//         // Rounds slider
//         Row(
//           children: [
//             SizedBox(width: 100, child: Text('Rounds: $maxRounds')),
//             Expanded(
//               child: Slider(
//                 value: maxRounds.toDouble(),
//                 min: 3,
//                 max: 30,
//                 divisions: 27,
//                 label: '$maxRounds',
//                 onChanged: (v) => onMaxRoundsChanged(v.round()),
//               ),
//             ),
//           ],
//         ),

//         SwitchListTile(
//           title: const Text('Allow skip'),
//           value: allowSkip,
//           onChanged: onSkipChanged,
//           dense: true,
//           contentPadding: EdgeInsets.zero,
//         ),

//         SwitchListTile(
//           title: const Text('Spicy content'),
//           subtitle: const Text('Enable 18+ cards'),
//           value: allowSpicy,
//           onChanged: onSpicyChanged,
//           dense: true,
//           contentPadding: EdgeInsets.zero,
//         ),

//         SwitchListTile(
//           title: const Text('Turn timer'),
//           value: timerEnabled,
//           onChanged: onTimerChanged,
//           dense: true,
//           contentPadding: EdgeInsets.zero,
//         ),

//         if (timerEnabled)
//           Row(
//             children: [
//               Expanded(child: Text('Timer: ${timerSecs}s')),
//               Slider(
//                 value: timerSecs.toDouble(),
//                 min: 15,
//                 max: 120,
//                 divisions: 21,
//                 label: '${timerSecs}s',
//                 onChanged: (v) => onTimerSecsChanged(v.round()),
//               ),
//             ],
//           ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../games/engine/base_game_engine.dart';
import '../../data/offline_game_provider.dart';
import '../../data/offline_repository.dart';
import '../../domain/offline_session.dart';
import 'offline_play_screen.dart';
import 'lan_host_screen.dart';

/// Setup screen shared by both pass-and-play and LAN host modes.
class OfflineSetupScreen extends StatefulWidget {
  const OfflineSetupScreen({super.key, required this.mode});
  final OfflineMode mode;

  @override
  State<OfflineSetupScreen> createState() => _OfflineSetupScreenState();
}

class _OfflineSetupScreenState extends State<OfflineSetupScreen> {
  List<OfflinePack> _packs = [];
  OfflinePack? _selectedPack;
  GameType _gameType = GameType.truthOrDare;
  String _langFilter = 'all'; // 'all' | 'en' | 'ar' | 'fr'
  int _maxRounds = 10;
  bool _allowSpicy = false;
  bool _timerEnabled = false;
  int _timerSecs = 60;
  bool _allowSkip = true;
  final List<String> _players = [];
  final _playerCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  @override
  void dispose() {
    _playerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPacks() async {
    setState(() => _isLoading = true);
    final packs = await OfflineRepository.instance.getAvailablePacks(
      gameType: _gameType,
    );
    setState(() {
      final usable = packs.where((p) => p.isUsable).toList();
      _packs = _langFilter == 'all'
          ? usable
          : usable
                .where(
                  (p) =>
                      p.language == _langFilter ||
                      p.language == 'multi' ||
                      p.language.contains(_langFilter),
                )
                .toList();
      _selectedPack = _packs.isNotEmpty ? _packs.first : null;
      _isLoading = false;
    });
  }

  void _addPlayer() {
    final name = _playerCtrl.text.trim();
    if (name.isEmpty || _players.length >= 12) return;
    if (_players.any((p) => p.toLowerCase() == name.toLowerCase())) {
      context.showErrorSnackBar('Name "$name" already added');
      return;
    }
    setState(() {
      _players.add(name);
      _playerCtrl.clear();
    });
  }

  Future<void> _start() async {
    if (_selectedPack == null) return;
    if (_players.length < 2 && widget.mode == OfflineMode.passAndPlay) {
      context.showErrorSnackBar('Add at least 2 players');
      return;
    }
    if (widget.mode == OfflineMode.lan && _players.isEmpty) {
      context.showErrorSnackBar('Enter your name');
      return;
    }

    final config = GameConfig(
      maxRounds: _maxRounds,
      turnTimerSeconds: _timerEnabled ? _timerSecs : 0,
      allowSkip: _allowSkip,
      allowSpicy: _allowSpicy,
      packId: _selectedPack!.id,
      language: _selectedPack!.language,
    );

    final provider = context.read<OfflineGameProvider>();

    if (widget.mode == OfflineMode.passAndPlay) {
      await provider.startPassAndPlay(
        gameType: _gameType,
        config: config,
        playerNames: _players,
        packId: _selectedPack!.id,
        packName: _selectedPack!.name,
        packCoverUrl: _selectedPack!.coverImageUrl,
      );
      if (provider.loadState == OfflineLoadState.ready && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: const OfflinePlayScreen(),
            ),
          ),
        );
      }
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: LanHostScreen(
              hostName: _players.isNotEmpty ? _players.first : 'Host',
              config: config,
              gameType: _gameType,
              pack: _selectedPack!,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isLan = widget.mode == OfflineMode.lan;
    final canStart =
        _selectedPack != null &&
        (isLan ? _players.isNotEmpty : _players.length >= 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(isLan ? 'Host LAN Room' : 'Pass & Play Setup'),
      ),
      body: Consumer<OfflineGameProvider>(
        builder: (ctx, provider, _) {
          if (provider.loadState == OfflineLoadState.loading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading cards…'),
                ],
              ),
            );
          }

          if (provider.loadState == OfflineLoadState.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('❌', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      provider.error ?? 'Setup failed.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => provider.reset(),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Main setup form ──────────────────────────────────────────────
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            // crossAxisAlignment.start avoids stretch causing infinite width
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language filter
                Text(
                  'Language',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final lang in [
                        ('all', '🌐 All'),
                        ('en', '🇬🇧 EN'),
                        ('ar', '🇸🇦 AR'),
                        ('fr', '🇫🇷 FR'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(lang.$2),
                            selected: _langFilter == lang.$1,
                            onSelected: (_) {
                              setState(() => _langFilter = lang.$1);
                              _loadPacks();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Game type
                Text(
                  'Game',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _GameTypeSelector(
                  selected: _gameType,
                  onChanged: (gt) {
                    setState(() => _gameType = gt);
                    _loadPacks();
                  },
                ),
                const SizedBox(height: 20),

                // Pack selection
                Text(
                  'Pack',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_packs.isEmpty)
                  _NoPacksNotice(gameType: _gameType)
                else
                  _PackSelector(
                    packs: _packs,
                    selected: _selectedPack,
                    onSelect: (p) => setState(() => _selectedPack = p),
                  ),
                const SizedBox(height: 20),

                // Settings
                _GameSettings(
                  maxRounds: _maxRounds,
                  allowSpicy: _allowSpicy,
                  timerEnabled: _timerEnabled,
                  timerSecs: _timerSecs,
                  allowSkip: _allowSkip,
                  onMaxRoundsChanged: (v) => setState(() => _maxRounds = v),
                  onSpicyChanged: (v) => setState(() => _allowSpicy = v),
                  onTimerChanged: (v) => setState(() => _timerEnabled = v),
                  onTimerSecsChanged: (v) => setState(() => _timerSecs = v),
                  onSkipChanged: (v) => setState(() => _allowSkip = v),
                ),
                const SizedBox(height: 20),

                // Players
                Text(
                  isLan ? 'Your name' : 'Players (${_players.length}/12)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _playerCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addPlayer(),
                        decoration: InputDecoration(
                          hintText: isLan ? 'Your name' : 'Player name',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 52,
                      width: 80,
                      child: FilledButton(
                        onPressed: _addPlayer,
                        child: Text(isLan ? 'Set' : 'Add'),
                      ),
                    ),
                  ],
                ),

                if (_players.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _players
                        .asMap()
                        .entries
                        .map(
                          (e) => Chip(
                            label: Text(
                              isLan ? e.value : '${e.key + 1}. ${e.value}',
                            ),
                            deleteIcon: const Icon(
                              Icons.close_rounded,
                              size: 14,
                            ),
                            onDeleted: isLan && e.key == 0
                                ? null
                                : () =>
                                      setState(() => _players.remove(e.value)),
                          ),
                        )
                        .toList(),
                  ),
                ],

                const SizedBox(height: 32),
                SizedBox(
                  width: double.maxFinite,
                  child: JButton(
                    label: isLan ? 'Create LAN Room' : 'Start Game',
                    onPressed: canStart ? _start : null,
                    icon: isLan
                        ? Icons.wifi_tethering_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Game type selector ────────────────────────────────────────────────────────
class _GameTypeSelector extends StatelessWidget {
  const _GameTypeSelector({required this.selected, required this.onChanged});
  final GameType selected;
  final void Function(GameType) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: GameType.values.map((gt) {
        final isSelected = selected == gt;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(gt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.navyBlue
                      : context.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(_emoji(gt), style: const TextStyle(fontSize: 22)),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _emoji(GameType gt) => switch (gt) {
    GameType.truthOrDare => '🎯',
    GameType.neverHaveIEver => '🍹',
    GameType.memeGame => '😂',
  };
}

// ── Pack selector ─────────────────────────────────────────────────────────────
class _PackSelector extends StatelessWidget {
  const _PackSelector({
    required this.packs,
    required this.selected,
    required this.onSelect,
  });
  final List<OfflinePack> packs;
  final OfflinePack? selected;
  final void Function(OfflinePack) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: packs.map((pack) {
        final isSelected = selected?.id == pack.id;
        return GestureDetector(
          onTap: () => onSelect(pack),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.navyBlue.withOpacity(0.08)
                  : context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.navyBlue, width: 2)
                  : Border.all(color: context.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected
                      ? AppColors.navyBlue
                      : context.colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.name,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${pack.cardCount} cards · '
                        '${pack.language.toUpperCase()} · '
                        '${pack.isFree ? "Free" : "Purchased"}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pack.expiresAt != null)
                  Text(
                    'Exp: ${pack.expiresAt!.day}/${pack.expiresAt!.month}',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: AppColors.warningAmber,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── No packs notice ───────────────────────────────────────────────────────────
class _NoPacksNotice extends StatelessWidget {
  const _NoPacksNotice({required this.gameType});
  final GameType gameType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.warningAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No ${gameType.displayName} packs downloaded. '
              'Go online to download packs.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Game settings ─────────────────────────────────────────────────────────────
class _GameSettings extends StatelessWidget {
  const _GameSettings({
    required this.maxRounds,
    required this.allowSpicy,
    required this.timerEnabled,
    required this.timerSecs,
    required this.allowSkip,
    required this.onMaxRoundsChanged,
    required this.onSpicyChanged,
    required this.onTimerChanged,
    required this.onTimerSecsChanged,
    required this.onSkipChanged,
  });

  final int maxRounds;
  final bool allowSpicy;
  final bool timerEnabled;
  final int timerSecs;
  final bool allowSkip;
  final void Function(int) onMaxRoundsChanged;
  final void Function(bool) onSpicyChanged;
  final void Function(bool) onTimerChanged;
  final void Function(int) onTimerSecsChanged;
  final void Function(bool) onSkipChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),

        // Rounds slider
        Row(
          children: [
            SizedBox(width: 100, child: Text('Rounds: $maxRounds')),
            Expanded(
              child: Slider(
                value: maxRounds.toDouble(),
                min: 3,
                max: 30,
                divisions: 27,
                label: '$maxRounds',
                onChanged: (v) => onMaxRoundsChanged(v.round()),
              ),
            ),
          ],
        ),

        SwitchListTile(
          title: const Text('Allow skip'),
          value: allowSkip,
          onChanged: onSkipChanged,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),

        SwitchListTile(
          title: const Text('Spicy content'),
          subtitle: const Text('Enable 18+ cards'),
          value: allowSpicy,
          onChanged: onSpicyChanged,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),

        SwitchListTile(
          title: const Text('Turn timer'),
          value: timerEnabled,
          onChanged: onTimerChanged,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),

        if (timerEnabled)
          Row(
            children: [
              Expanded(child: Text('Timer: ${timerSecs}s')),
              Slider(
                value: timerSecs.toDouble(),
                min: 15,
                max: 120,
                divisions: 21,
                label: '${timerSecs}s',
                onChanged: (v) => onTimerSecsChanged(v.round()),
              ),
            ],
          ),
      ],
    );
  }
}
