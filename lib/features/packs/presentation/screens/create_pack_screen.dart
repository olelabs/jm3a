// // // // import 'dart:io';

// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // import 'package:go_router/go_router.dart';
// // // // import 'package:image_picker/image_picker.dart';
// // // // import 'package:provider/provider.dart';

// // // // import '../../../../core/extensions/context_ext.dart';
// // // // import '../../../../core/theme/app_colors.dart';
// // // // import '../../../../shared/widgets/buttons/j_button.dart';
// // // // import '../../data/pack_repository.dart';
// // // // import '../../data/pack_upload_service.dart';
// // // // import '../../data/pack_upload_service.dart';
// // // // import '../../domain/pack_entity.dart';
// // // // import '../pack_provider.dart';

// // // // /// Multi-step pack creation flow.
// // // // /// Steps: 1. Info  2. Cover  3. Cards  4. Review & Publish
// // // // class CreatePackScreen extends StatefulWidget {
// // // //   const CreatePackScreen({super.key, this.existingPackId, this.existingPack});
// // // //   final String? existingPackId;
// // // //   final PackEntity? existingPack;

// // // //   @override
// // // //   State<CreatePackScreen> createState() => _CreatePackScreenState();
// // // // }

// // // // class _CreatePackScreenState extends State<CreatePackScreen> {
// // // //   late final PackDraft _draft;
// // // //   int _step = 0;
// // // //   bool _isSaving = false;
// // // //   late String? _savedPackId;

// // // //   static const _steps = ['Info', 'Cover', 'Cards', 'Publish'];

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _savedPackId = widget.existingPackId;
// // // //     // Pre-fill draft from existing pack
// // // //     final p = widget.existingPack;
// // // //     if (p != null) {
// // // //       _draft = PackDraft(
// // // //         titleEn: p.titleFor('en'),
// // // //         titleAr: p.titleFor('ar'),
// // // //         titleFr: p.titleFor('fr'),
// // // //         descriptionEn: p.descriptionFor('en'),
// // // //         gameType: p.gameType,
// // // //         language: p.language,
// // // //         priceMru: p.priceMru,
// // // //         categoryId: p.categoryId,
// // // //         allowSpicy: p.hasSpicy,
// // // //         coverImageUrl: p.coverImageUrl,
// // // //         cards: [],
// // // //       );
// // // //       // Jump to cards step if basic info already saved
// // // //       _step = _savedPackId != null ? 2 : 0;
// // // //     } else {
// // // //       _draft = PackDraft();
// // // //     }
// // // //   }

// // // //   // static const _steps     = ['Info', 'Cover', 'Cards', 'Publish'];
// // // //   static const _stepsMeme = ['Info', 'Cover', 'Cards', 'Reactions', 'Publish'];
// // // //   List<String> get _activeSteps =>
// // // //       _draft.gameType == 'meme_game' ? _stepsMeme : _steps;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return PopScope(
// // // //       onPopInvokedWithResult: (_, __) {
// // // //         if (mounted) context.read<PackProvider>().loadCreatedPacks();
// // // //       },
// // // //       child: Scaffold(
// // // //         appBar: AppBar(
// // // //           title: Text('Create Pack — ${_activeSteps[_step]}'),
// // // //           bottom: PreferredSize(
// // // //             preferredSize: const Size.fromHeight(4),
// // // //             child: LinearProgressIndicator(
// // // //               value: (_step + 1) / _activeSteps.length,
// // // //               minHeight: 4,
// // // //               color: AppColors.navyBlue,
// // // //               backgroundColor: context.colorScheme.surfaceContainerHighest,
// // // //             ),
// // // //           ),
// // // //         ),
// // // //         body: AnimatedSwitcher(
// // // //           duration: const Duration(milliseconds: 250),
// // // //           child: KeyedSubtree(
// // // //             key: ValueKey(_step),
// // // //             child: switch (_step) {
// // // //               0 => _InfoStep(draft: _draft, onNext: _nextStep),
// // // //               1 => _CoverStep(
// // // //                 draft: _draft,
// // // //                 onNext: _nextStep,
// // // //                 onBack: _prevStep,
// // // //               ),
// // // //               2 => _CardsStep(
// // // //                 draft: _draft,
// // // //                 packId: _savedPackId,
// // // //                 onNext: _nextStep,
// // // //                 onBack: _prevStep,
// // // //               ),
// // // //               3 when _draft.gameType == 'meme_game' => _ReactionsStep(
// // // //                 draft: _draft,
// // // //                 packId: _savedPackId,
// // // //                 onNext: _nextStep,
// // // //                 onBack: _prevStep,
// // // //               ),
// // // //               _ => _PublishStep(
// // // //                 draft: _draft,
// // // //                 packId: _savedPackId,
// // // //                 isSaving: _isSaving,
// // // //                 onPublish: _submit,
// // // //                 onBack: _prevStep,
// // // //               ),
// // // //             },
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   void _nextStep() {
// // // //     if (_step == 0 && _savedPackId == null) {
// // // //       _saveDraft();
// // // //     } else {
// // // //       setState(() => _step = (_step + 1).clamp(0, _activeSteps.length - 1));
// // // //     }
// // // //   }

// // // //   void _prevStep() =>
// // // //       setState(() => _step = (_step - 1).clamp(0, _activeSteps.length - 1));

// // // //   Future<void> _saveDraft() async {
// // // //     setState(() => _isSaving = true);
// // // //     try {
// // // //       final packs = context.read<PackProvider>();
// // // //       final userId = packs.currentUserId;
// // // //       if (userId == null) throw Exception('Not logged in');

// // // //       PackEntity pack;
// // // //       if (_savedPackId == null) {
// // // //         pack = await PackRepository.instance.createPackDraft(_draft, userId);
// // // //         _savedPackId = pack.id;
// // // //       } else {
// // // //         pack = await PackRepository.instance.updatePackDraft(
// // // //           _savedPackId!,
// // // //           _draft,
// // // //         );
// // // //       }
// // // //       setState(() {
// // // //         _isSaving = false;
// // // //         _step = 1;
// // // //       });
// // // //     } catch (e) {
// // // //       setState(() => _isSaving = false);
// // // //       if (mounted) context.showErrorSnackBar('Failed to save: $e');
// // // //     }
// // // //   }

// // // //   Future<void> _submit() async {
// // // //     if (_savedPackId == null) return;
// // // //     setState(() => _isSaving = true);
// // // //     try {
// // // //       await PackRepository.instance.submitForReview(_savedPackId!);
// // // //       if (mounted) {
// // // //         context.read<PackProvider>().loadCreatedPacks();
// // // //         context.showSnackBar(
// // // //           'Pack submitted for review! You\'ll be notified when approved.',
// // // //         );
// // // //         context.pop();
// // // //       }
// // // //     } catch (e) {
// // // //       setState(() => _isSaving = false);
// // // //       if (mounted) context.showErrorSnackBar('Submission failed: $e');
// // // //     }
// // // //   }
// // // // }

// // // // // ── Step 1: Info ──────────────────────────────────────────────────────────────
// // // // class _InfoStep extends StatefulWidget {
// // // //   const _InfoStep({required this.draft, required this.onNext});
// // // //   final PackDraft draft;
// // // //   final VoidCallback onNext;

// // // //   @override
// // // //   State<_InfoStep> createState() => _InfoStepState();
// // // // }

// // // // class _InfoStepState extends State<_InfoStep> {
// // // //   late final TextEditingController _titleCtrl;
// // // //   late final TextEditingController _descCtrl;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _titleCtrl = TextEditingController(text: widget.draft.titleEn);
// // // //     _descCtrl = TextEditingController(text: widget.draft.descriptionEn);
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _titleCtrl.dispose();
// // // //     _descCtrl.dispose();
// // // //     super.dispose();
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = context.theme;

// // // //     return SingleChildScrollView(
// // // //       padding: const EdgeInsets.all(24),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         children: [
// // // //           Text(
// // // //             'Pack information',
// // // //             style: theme.textTheme.titleLarge?.copyWith(
// // // //               fontWeight: FontWeight.w700,
// // // //             ),
// // // //           ).animate().fadeIn(),
// // // //           const SizedBox(height: 24),

// // // //           TextFormField(
// // // //             controller: _titleCtrl,
// // // //             onChanged: (v) => widget.draft.titleEn = v,
// // // //             decoration: const InputDecoration(
// // // //               labelText: 'Pack title (English)*',
// // // //               hintText: 'e.g. Wild Friday Night',
// // // //             ),
// // // //             textCapitalization: TextCapitalization.words,
// // // //           ).animate(delay: 60.ms).fadeIn(),

// // // //           const SizedBox(height: 16),

// // // //           TextFormField(
// // // //             controller: _descCtrl,
// // // //             onChanged: (v) => widget.draft.descriptionEn = v,
// // // //             maxLines: 3,
// // // //             maxLength: 500,
// // // //             decoration: const InputDecoration(
// // // //               labelText: 'Description (optional)',
// // // //               counterText: '',
// // // //             ),
// // // //           ).animate(delay: 80.ms).fadeIn(),

// // // //           const SizedBox(height: 16),

// // // //           // Game type
// // // //           DropdownButtonFormField<String>(
// // // //             value: widget.draft.gameType,
// // // //             decoration: const InputDecoration(labelText: 'Game type'),
// // // //             items: const [
// // // //               DropdownMenuItem(
// // // //                 value: 'truth_or_dare',
// // // //                 child: Text('🎯 Truth or Dare'),
// // // //               ),
// // // //               DropdownMenuItem(
// // // //                 value: 'never_have_i_ever',
// // // //                 child: Text('🍹 Never Have I Ever'),
// // // //               ),
// // // //               DropdownMenuItem(value: 'meme_game', child: Text('😂 Meme Game')),
// // // //             ],
// // // //             onChanged: (v) =>
// // // //                 setState(() => widget.draft.gameType = v ?? 'truth_or_dare'),
// // // //           ).animate(delay: 100.ms).fadeIn(),

// // // //           const SizedBox(height: 16),

// // // //           // Price
// // // //           Row(
// // // //             children: [
// // // //               Expanded(
// // // //                 child: TextFormField(
// // // //                   initialValue: widget.draft.priceMru.toString(),
// // // //                   keyboardType: TextInputType.number,
// // // //                   decoration: const InputDecoration(
// // // //                     labelText: 'Price (MRU)',
// // // //                     hintText: '0 for free',
// // // //                     suffixText: 'MRU',
// // // //                   ),
// // // //                   onChanged: (v) =>
// // // //                       widget.draft.priceMru = int.tryParse(v) ?? 0,
// // // //                 ),
// // // //               ),
// // // //               const SizedBox(width: 12),
// // // //               Row(
// // // //                 children: [
// // // //                   Text(
// // // //                     'Spicy 🌶️',
// // // //                     style: Theme.of(context).textTheme.bodyMedium,
// // // //                   ),
// // // //                   const SizedBox(width: 8),
// // // //                   Switch(
// // // //                     value: widget.draft.allowSpicy,
// // // //                     onChanged: (v) =>
// // // //                         setState(() => widget.draft.allowSpicy = v),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ],
// // // //           ).animate(delay: 120.ms).fadeIn(),

// // // //           const SizedBox(height: 32),

// // // //           JButton(
// // // //             label: 'Continue →',
// // // //             onPressed: widget.draft.hasTitle ? widget.onNext : null,
// // // //             icon: Icons.arrow_forward_rounded,
// // // //           ).animate(delay: 140.ms).fadeIn(),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // // ── Step 2: Cover ─────────────────────────────────────────────────────────────
// // // // class _CoverStep extends StatefulWidget {
// // // //   const _CoverStep({
// // // //     required this.draft,
// // // //     required this.onNext,
// // // //     required this.onBack,
// // // //   });
// // // //   final PackDraft draft;
// // // //   final VoidCallback onNext;
// // // //   final VoidCallback onBack;

// // // //   @override
// // // //   State<_CoverStep> createState() => _CoverStepState();
// // // // }

// // // // class _CoverStepState extends State<_CoverStep> {
// // // //   bool _isUploading = false;

// // // //   Future<void> _pickAndUpload() async {
// // // //     final picker = ImagePicker();
// // // //     final picked = await picker.pickImage(
// // // //       source: ImageSource.gallery,
// // // //       maxWidth: 1024,
// // // //       maxHeight: 1024,
// // // //       imageQuality: 85,
// // // //     );
// // // //     if (picked == null) return;

// // // //     setState(() => _isUploading = true);
// // // //     try {
// // // //       final url = await PackUploadService.instance.uploadCoverImage(
// // // //         File(picked.path),
// // // //       );
// // // //       setState(() {
// // // //         widget.draft.coverImagePath = picked.path;
// // // //         widget.draft.coverImageUrl = url;
// // // //         _isUploading = false;
// // // //       });
// // // //     } catch (e) {
// // // //       setState(() => _isUploading = false);
// // // //       if (mounted) context.showErrorSnackBar('Upload failed: $e');
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = context.theme;

// // // //     return Padding(
// // // //       padding: const EdgeInsets.all(24),
// // // //       child: Column(
// // // //         children: [
// // // //           Text(
// // // //             'Cover image',
// // // //             style: theme.textTheme.titleLarge?.copyWith(
// // // //               fontWeight: FontWeight.w700,
// // // //             ),
// // // //           ).animate().fadeIn(),
// // // //           const SizedBox(height: 8),
// // // //           Text(
// // // //             'Add an attractive cover to increase pack visibility.',
// // // //             style: theme.textTheme.bodyMedium?.copyWith(
// // // //               color: theme.colorScheme.onSurfaceVariant,
// // // //             ),
// // // //           ).animate(delay: 40.ms).fadeIn(),

// // // //           const SizedBox(height: 32),

// // // //           // Cover preview
// // // //           GestureDetector(
// // // //                 onTap: _isUploading ? null : _pickAndUpload,
// // // //                 child: Container(
// // // //                   width: 220,
// // // //                   height: 220,
// // // //                   decoration: BoxDecoration(
// // // //                     color: theme.colorScheme.surfaceContainerHighest,
// // // //                     borderRadius: BorderRadius.circular(20),
// // // //                     border: Border.all(
// // // //                       color: theme.colorScheme.outline,
// // // //                       width: 2,
// // // //                       strokeAlign: BorderSide.strokeAlignOutside,
// // // //                     ),
// // // //                   ),
// // // //                   child: _isUploading
// // // //                       ? const Center(child: CircularProgressIndicator())
// // // //                       : widget.draft.coverImagePath != null
// // // //                       ? ClipRRect(
// // // //                           borderRadius: BorderRadius.circular(18),
// // // //                           child: Image.file(
// // // //                             File(widget.draft.coverImagePath!),
// // // //                             fit: BoxFit.cover,
// // // //                           ),
// // // //                         )
// // // //                       : Column(
// // // //                           mainAxisAlignment: MainAxisAlignment.center,
// // // //                           children: [
// // // //                             Icon(
// // // //                               Icons.add_photo_alternate_outlined,
// // // //                               size: 48,
// // // //                               color: theme.colorScheme.onSurfaceVariant,
// // // //                             ),
// // // //                             const SizedBox(height: 8),
// // // //                             Text(
// // // //                               'Tap to add cover',
// // // //                               style: theme.textTheme.bodyMedium?.copyWith(
// // // //                                 color: theme.colorScheme.onSurfaceVariant,
// // // //                               ),
// // // //                             ),
// // // //                           ],
// // // //                         ),
// // // //                 ),
// // // //               )
// // // //               .animate(delay: 80.ms)
// // // //               .fadeIn()
// // // //               .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

// // // //           const Spacer(),

// // // //           Row(
// // // //             children: [
// // // //               Expanded(
// // // //                 child: OutlinedButton(
// // // //                   onPressed: widget.onBack,
// // // //                   child: const Text('Back'),
// // // //                 ),
// // // //               ),
// // // //               const SizedBox(width: 12),
// // // //               Expanded(
// // // //                 child: JButton(
// // // //                   label: 'Continue →',
// // // //                   onPressed: widget.draft.coverImageUrl != null
// // // //                       ? widget.onNext
// // // //                       : null,
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ).animate(delay: 120.ms).fadeIn(),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // // ── Step 3: Cards ─────────────────────────────────────────────────────────────
// // // // class _CardsStep extends StatefulWidget {
// // // //   const _CardsStep({
// // // //     required this.draft,
// // // //     required this.packId,
// // // //     required this.onNext,
// // // //     required this.onBack,
// // // //   });
// // // //   final PackDraft draft;
// // // //   final String? packId;
// // // //   final VoidCallback onNext;
// // // //   final VoidCallback onBack;

// // // //   @override
// // // //   State<_CardsStep> createState() => _CardsStepState();
// // // // }

// // // // class _CardsStepState extends State<_CardsStep> {
// // // //   final _contentCtrl = TextEditingController();
// // // //   late CardType _type;
// // // //   CardDifficulty _difficulty = CardDifficulty.mild;
// // // //   bool _isSaving = false;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     // Set default card type based on game type
// // // //     _type = _defaultTypeForGame(widget.draft.gameType);
// // // //   }

// // // //   CardType _defaultTypeForGame(String gameType) {
// // // //     switch (gameType) {
// // // //       case 'never_have_i_ever':
// // // //         return CardType.statement;
// // // //       case 'meme_game':
// // // //         return CardType.prompt;
// // // //       default:
// // // //         return CardType.truth; // truth_or_dare
// // // //     }
// // // //   }

// // // //   List<(CardType, String, Color)> _typesForGame(String gameType) {
// // // //     switch (gameType) {
// // // //       case 'never_have_i_ever':
// // // //         return [(CardType.statement, 'Statement 🍹', AppColors.tealGreen)];
// // // //       case 'meme_game':
// // // //         return [(CardType.prompt, 'Prompt 😂', AppColors.purple)];
// // // //       default:
// // // //         return [
// // // //           (CardType.truth, 'Truth 🤔', AppColors.truthColor),
// // // //           (CardType.dare, 'Dare 🔥', AppColors.dareColor),
// // // //         ];
// // // //     }
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _contentCtrl.dispose();
// // // //     super.dispose();
// // // //   }

// // // //   void _addCard() {
// // // //     final text = _contentCtrl.text.trim();
// // // //     if (text.isEmpty) return;
// // // //     setState(() {
// // // //       widget.draft.cards.add(
// // // //         CardDraft(contentEn: text, type: _type, difficulty: _difficulty),
// // // //       );
// // // //       _contentCtrl.clear();
// // // //     });
// // // //   }

// // // //   Future<void> _saveAndContinue() async {
// // // //     if (widget.packId == null) return;
// // // //     if (widget.draft.cards.isEmpty) return;

// // // //     setState(() => _isSaving = true);
// // // //     try {
// // // //       await PackRepository.instance.addCards(
// // // //         widget.packId!,
// // // //         widget.draft.cards,
// // // //       );
// // // //       widget.onNext();
// // // //     } catch (e) {
// // // //       if (mounted) context.showErrorSnackBar('Failed to save cards: $e');
// // // //     } finally {
// // // //       setState(() => _isSaving = false);
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = context.theme;
// // // //     final cards = widget.draft.cards;

// // // //     return Column(
// // // //       children: [
// // // //         // Card input area
// // // //         Padding(
// // // //           padding: const EdgeInsets.all(16),
// // // //           child: Column(
// // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // //             children: [
// // // //               Row(
// // // //                 children: [
// // // //                   Text(
// // // //                     '${cards.length} / 20+ cards',
// // // //                     style: theme.textTheme.titleSmall?.copyWith(
// // // //                       fontWeight: FontWeight.w700,
// // // //                     ),
// // // //                   ),
// // // //                   const Spacer(),
// // // //                   Text(
// // // //                     cards.length < 20
// // // //                         ? '${20 - cards.length} more needed'
// // // //                         : '✅ Minimum reached',
// // // //                     style: TextStyle(
// // // //                       fontSize: 12,
// // // //                       color: cards.length >= 20
// // // //                           ? AppColors.successGreen
// // // //                           : AppColors.warningAmber,
// // // //                       fontWeight: FontWeight.w600,
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //               const SizedBox(height: 8),

// // // //               // Type + difficulty selectors — adapts to game type
// // // //               Row(
// // // //                 children: [
// // // //                   ..._typesForGame(widget.draft.gameType).map((t) {
// // // //                     final (type, label, color) = t;
// // // //                     return Padding(
// // // //                       padding: const EdgeInsets.only(right: 8),
// // // //                       child: _TypeButton(
// // // //                         label: label,
// // // //                         isSelected: _type == type,
// // // //                         color: color,
// // // //                         onTap: () => setState(() => _type = type),
// // // //                       ),
// // // //                     );
// // // //                   }),
// // // //                   const SizedBox(width: 4),
// // // //                   DropdownButton<CardDifficulty>(
// // // //                     value: _difficulty,
// // // //                     underline: const SizedBox.shrink(),
// // // //                     items: CardDifficulty.values
// // // //                         .map(
// // // //                           (d) =>
// // // //                               DropdownMenuItem(value: d, child: Text(d.name)),
// // // //                         )
// // // //                         .toList(),
// // // //                     onChanged: (d) => setState(() => _difficulty = d!),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //               const SizedBox(height: 8),

// // // //               Row(
// // // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // // //                 children: [
// // // //                   Expanded(
// // // //                     child: TextField(
// // // //                       controller: _contentCtrl,
// // // //                       maxLines: 2,
// // // //                       decoration: const InputDecoration(
// // // //                         hintText: 'Card content…',
// // // //                         isDense: true,
// // // //                       ),
// // // //                       onSubmitted: (_) => _addCard(),
// // // //                     ),
// // // //                   ),
// // // //                   const SizedBox(width: 8),
// // // //                   IconButton.filled(
// // // //                     onPressed: _addCard,
// // // //                     icon: const Icon(Icons.add_rounded),
// // // //                     style: IconButton.styleFrom(
// // // //                       backgroundColor: AppColors.navyBlue,
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),

// // // //         const Divider(height: 1),

// // // //         // Card list
// // // //         Expanded(
// // // //           child: cards.isEmpty
// // // //               ? const Center(child: Text('Add your first card above!'))
// // // //               : ListView.separated(
// // // //                   padding: const EdgeInsets.all(12),
// // // //                   itemCount: cards.length,
// // // //                   separatorBuilder: (_, __) => const SizedBox(height: 6),
// // // //                   itemBuilder: (_, i) {
// // // //                     final card = cards[i];
// // // //                     final color = card.type == CardType.truth
// // // //                         ? AppColors.truthColor
// // // //                         : AppColors.dareColor;
// // // //                     return Container(
// // // //                       padding: const EdgeInsets.all(10),
// // // //                       decoration: BoxDecoration(
// // // //                         color: color.withOpacity(0.06),
// // // //                         borderRadius: BorderRadius.circular(8),
// // // //                         border: Border.all(color: color.withOpacity(0.2)),
// // // //                       ),
// // // //                       child: Row(
// // // //                         children: [
// // // //                           Container(
// // // //                             padding: const EdgeInsets.symmetric(
// // // //                               horizontal: 6,
// // // //                               vertical: 2,
// // // //                             ),
// // // //                             decoration: BoxDecoration(
// // // //                               color: color.withOpacity(0.15),
// // // //                               borderRadius: BorderRadius.circular(4),
// // // //                             ),
// // // //                             child: Row(
// // // //                               mainAxisSize: MainAxisSize.min,
// // // //                               children: [
// // // //                                 Text(
// // // //                                   card.type == CardType.truth ? '🤔' : '🔥',
// // // //                                   style: const TextStyle(fontSize: 12),
// // // //                                 ),
// // // //                                 const SizedBox(width: 3),
// // // //                                 Text(
// // // //                                   card.type == CardType.truth
// // // //                                       ? 'Truth'
// // // //                                       : 'Dare',
// // // //                                   style: TextStyle(
// // // //                                     fontSize: 11,
// // // //                                     fontWeight: FontWeight.w700,
// // // //                                     color: color,
// // // //                                   ),
// // // //                                 ),
// // // //                               ],
// // // //                             ),
// // // //                           ),
// // // //                           const SizedBox(width: 8),
// // // //                           Expanded(
// // // //                             child: Text(
// // // //                               card.contentEn,
// // // //                               style: theme.textTheme.bodySmall,
// // // //                             ),
// // // //                           ),
// // // //                           IconButton(
// // // //                             icon: const Icon(Icons.close_rounded, size: 16),
// // // //                             onPressed: () => setState(() => cards.removeAt(i)),
// // // //                             visualDensity: VisualDensity.compact,
// // // //                             padding: EdgeInsets.zero,
// // // //                           ),
// // // //                         ],
// // // //                       ),
// // // //                     ).animate(delay: (i * 15).ms).fadeIn();
// // // //                   },
// // // //                 ),
// // // //         ),

// // // //         // Bottom bar
// // // //         Padding(
// // // //           padding: const EdgeInsets.all(16),
// // // //           child: Row(
// // // //             children: [
// // // //               Expanded(
// // // //                 child: OutlinedButton(
// // // //                   onPressed: widget.onBack,
// // // //                   child: const Text('Back'),
// // // //                 ),
// // // //               ),
// // // //               const SizedBox(width: 12),
// // // //               Expanded(
// // // //                 child: JButton(
// // // //                   label: 'Continue →',
// // // //                   onPressed: cards.length >= 20 ? _saveAndContinue : null,
// // // //                   isLoading: _isSaving,
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // // }

// // // // class _TypeButton extends StatelessWidget {
// // // //   const _TypeButton({
// // // //     required this.label,
// // // //     required this.isSelected,
// // // //     required this.color,
// // // //     required this.onTap,
// // // //   });
// // // //   final String label;
// // // //   final bool isSelected;
// // // //   final Color color;
// // // //   final VoidCallback onTap;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return GestureDetector(
// // // //       onTap: onTap,
// // // //       child: Container(
// // // //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// // // //         decoration: BoxDecoration(
// // // //           color: isSelected ? color : color.withOpacity(0.08),
// // // //           borderRadius: BorderRadius.circular(8),
// // // //         ),
// // // //         child: Text(
// // // //           label,
// // // //           style: TextStyle(
// // // //             color: isSelected ? Colors.white : color,
// // // //             fontWeight: FontWeight.w700,
// // // //             fontSize: 13,
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // // ── Step 4: Publish ───────────────────────────────────────────────────────────
// // // // // ── Step 4 (Meme only): Reactions ─────────────────────────────────────────────
// // // // class _ReactionsStep extends StatefulWidget {
// // // //   const _ReactionsStep({
// // // //     required this.draft,
// // // //     required this.packId,
// // // //     required this.onNext,
// // // //     required this.onBack,
// // // //   });
// // // //   final PackDraft draft;
// // // //   final String? packId;
// // // //   final VoidCallback onNext;
// // // //   final VoidCallback onBack;

// // // //   @override
// // // //   State<_ReactionsStep> createState() => _ReactionsStepState();
// // // // }

// // // // class _ReactionsStepState extends State<_ReactionsStep> {
// // // //   bool _isSaving = false;

// // // //   Future<void> _pickAndUpload() async {
// // // //     if (widget.draft.reactionImageUrls.length >= 30) {
// // // //       context.showErrorSnackBar('Maximum 30 reaction images reached');
// // // //       return;
// // // //     }
// // // //     final picker = ImagePicker();
// // // //     final picked = await picker.pickMultiImage(imageQuality: 85);
// // // //     if (picked.isEmpty || !mounted) return;

// // // //     final remaining = 30 - widget.draft.reactionImageUrls.length;
// // // //     final toUpload = picked.take(remaining).toList();

// // // //     setState(() => _isSaving = true);
// // // //     try {
// // // //       for (final xfile in toUpload) {
// // // //         final file = File(xfile.path);
// // // //         final url = await PackUploadService.instance.uploadCardImage(file);
// // // //         setState(() => widget.draft.reactionImageUrls.add(url));
// // // //       }
// // // //     } catch (e) {
// // // //       if (mounted) context.showErrorSnackBar('Upload failed: $e');
// // // //     } finally {
// // // //       if (mounted) setState(() => _isSaving = false);
// // // //     }
// // // //   }

// // // //   Future<void> _saveAndContinue() async {
// // // //     if (widget.packId == null) {
// // // //       widget.onNext();
// // // //       return;
// // // //     }
// // // //     setState(() => _isSaving = true);
// // // //     try {
// // // //       await PackRepository.instance.savePackReactions(
// // // //         widget.packId!,
// // // //         widget.draft.reactionImageUrls,
// // // //       );
// // // //       widget.onNext();
// // // //     } catch (e) {
// // // //       if (mounted) context.showErrorSnackBar('Failed to save reactions: $e');
// // // //     } finally {
// // // //       if (mounted) setState(() => _isSaving = false);
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = context.theme;
// // // //     final reactions = widget.draft.reactionImageUrls;

// // // //     return Column(
// // // //       children: [
// // // //         Padding(
// // // //           padding: const EdgeInsets.all(16),
// // // //           child: Column(
// // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // //             children: [
// // // //               Row(
// // // //                 children: [
// // // //                   Text(
// // // //                     '${reactions.length} / 30 reaction images',
// // // //                     style: theme.textTheme.titleSmall?.copyWith(
// // // //                       fontWeight: FontWeight.w700,
// // // //                     ),
// // // //                   ),
// // // //                   const Spacer(),
// // // //                   Text(
// // // //                     reactions.isEmpty
// // // //                         ? 'Optional — skip to use defaults'
// // // //                         : '${30 - reactions.length} slots remaining',
// // // //                     style: TextStyle(
// // // //                       fontSize: 12,
// // // //                       color: theme.colorScheme.onSurfaceVariant,
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //               const SizedBox(height: 4),
// // // //               Text(
// // // //                 'Players will use these images as reactions during the game. '
// // // //                 'Add up to 30. If none, default stickers are used.',
// // // //                 style: theme.textTheme.bodySmall?.copyWith(
// // // //                   color: theme.colorScheme.onSurfaceVariant,
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),

// // // //         Expanded(
// // // //           child: reactions.isEmpty
// // // //               ? Center(
// // // //                   child: Column(
// // // //                     mainAxisSize: MainAxisSize.min,
// // // //                     children: [
// // // //                       Icon(
// // // //                         Icons.image_outlined,
// // // //                         size: 64,
// // // //                         color: theme.colorScheme.onSurfaceVariant,
// // // //                       ),
// // // //                       const SizedBox(height: 8),
// // // //                       Text(
// // // //                         'No reaction images yet',
// // // //                         style: theme.textTheme.bodyMedium?.copyWith(
// // // //                           color: theme.colorScheme.onSurfaceVariant,
// // // //                         ),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                 )
// // // //               : GridView.builder(
// // // //                   padding: const EdgeInsets.symmetric(horizontal: 12),
// // // //                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// // // //                     crossAxisCount: 4,
// // // //                     mainAxisSpacing: 8,
// // // //                     crossAxisSpacing: 8,
// // // //                     childAspectRatio: 1,
// // // //                   ),
// // // //                   itemCount: reactions.length,
// // // //                   itemBuilder: (_, i) {
// // // //                     return Stack(
// // // //                       children: [
// // // //                         ClipRRect(
// // // //                           borderRadius: BorderRadius.circular(8),
// // // //                           child: Image.network(
// // // //                             reactions[i],
// // // //                             width: double.infinity,
// // // //                             height: double.infinity,
// // // //                             fit: BoxFit.cover,
// // // //                             errorBuilder: (_, __, ___) =>
// // // //                                 const Icon(Icons.broken_image),
// // // //                           ),
// // // //                         ),
// // // //                         Positioned(
// // // //                           top: 2,
// // // //                           right: 2,
// // // //                           child: GestureDetector(
// // // //                             onTap: () => setState(() => reactions.removeAt(i)),
// // // //                             child: Container(
// // // //                               decoration: const BoxDecoration(
// // // //                                 color: Colors.black54,
// // // //                                 shape: BoxShape.circle,
// // // //                               ),
// // // //                               child: const Icon(
// // // //                                 Icons.close_rounded,
// // // //                                 color: Colors.white,
// // // //                                 size: 16,
// // // //                               ),
// // // //                             ),
// // // //                           ),
// // // //                         ),
// // // //                       ],
// // // //                     );
// // // //                   },
// // // //                 ),
// // // //         ),

// // // //         Padding(
// // // //           padding: const EdgeInsets.all(16),
// // // //           child: Column(
// // // //             children: [
// // // //               if (reactions.length < 30)
// // // //                 SizedBox(
// // // //                   width: double.infinity,
// // // //                   child: OutlinedButton.icon(
// // // //                     onPressed: _isSaving ? null : _pickAndUpload,
// // // //                     icon: _isSaving
// // // //                         ? const SizedBox(
// // // //                             width: 16,
// // // //                             height: 16,
// // // //                             child: CircularProgressIndicator(strokeWidth: 2),
// // // //                           )
// // // //                         : const Icon(Icons.add_photo_alternate_rounded),
// // // //                     label: Text(_isSaving ? 'Uploading...' : 'Add Images'),
// // // //                   ),
// // // //                 ),
// // // //               const SizedBox(height: 8),
// // // //               Row(
// // // //                 children: [
// // // //                   Expanded(
// // // //                     child: OutlinedButton(
// // // //                       onPressed: widget.onBack,
// // // //                       child: const Text('Back'),
// // // //                     ),
// // // //                   ),
// // // //                   const SizedBox(width: 12),
// // // //                   Expanded(
// // // //                     child: FilledButton(
// // // //                       onPressed: _isSaving ? null : _saveAndContinue,
// // // //                       child: Text(reactions.isEmpty ? 'Skip' : 'Continue'),
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // // }

// // // // // ── Step 4/5: Publish ──────────────────────────────────────────────────────────
// // // // class _PublishStep extends StatelessWidget {
// // // //   const _PublishStep({
// // // //     required this.draft,
// // // //     required this.packId,
// // // //     required this.isSaving,
// // // //     required this.onPublish,
// // // //     required this.onBack,
// // // //   });
// // // //   final PackDraft draft;
// // // //   final String? packId;
// // // //   final bool isSaving;
// // // //   final VoidCallback onPublish;
// // // //   final VoidCallback onBack;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = context.theme;
// // // //     final canPublish = draft.canPublish && packId != null;

// // // //     return SingleChildScrollView(
// // // //       padding: const EdgeInsets.all(24),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         children: [
// // // //           Text(
// // // //             'Ready to publish?',
// // // //             style: theme.textTheme.headlineSmall?.copyWith(
// // // //               fontWeight: FontWeight.w800,
// // // //             ),
// // // //           ).animate().fadeIn(),
// // // //           const SizedBox(height: 8),
// // // //           Text(
// // // //             'Review your pack before submitting for moderation.',
// // // //             style: theme.textTheme.bodyMedium?.copyWith(
// // // //               color: theme.colorScheme.onSurfaceVariant,
// // // //             ),
// // // //           ).animate(delay: 40.ms).fadeIn(),

// // // //           const SizedBox(height: 24),

// // // //           // Summary card
// // // //           Container(
// // // //             padding: const EdgeInsets.all(18),
// // // //             decoration: BoxDecoration(
// // // //               color: theme.colorScheme.surfaceContainerHighest,
// // // //               borderRadius: BorderRadius.circular(16),
// // // //             ),
// // // //             child: Column(
// // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // //               children: [
// // // //                 _SummaryRow(label: 'Title', value: draft.titleEn, icon: '📦'),
// // // //                 _SummaryRow(
// // // //                   label: 'Game type',
// // // //                   value: draft.gameType,
// // // //                   icon: '🎮',
// // // //                 ),
// // // //                 _SummaryRow(
// // // //                   label: 'Cards',
// // // //                   value:
// // // //                       '${draft.cards.length} (${draft.truthCount}T + ${draft.dareCount}D)',
// // // //                   icon: '🃏',
// // // //                 ),
// // // //                 _SummaryRow(
// // // //                   label: 'Price',
// // // //                   value: draft.priceMru == 0 ? 'Free' : '${draft.priceMru} MRU',
// // // //                   icon: '💰',
// // // //                 ),
// // // //                 _SummaryRow(
// // // //                   label: 'Spicy content',
// // // //                   value: draft.allowSpicy ? 'Allowed' : 'No',
// // // //                   icon: '🌶',
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ).animate(delay: 80.ms).fadeIn(),

// // // //           const SizedBox(height: 16),

// // // //           // Rules reminder
// // // //           Container(
// // // //             padding: const EdgeInsets.all(14),
// // // //             decoration: BoxDecoration(
// // // //               color: AppColors.infoBlue.withOpacity(0.08),
// // // //               borderRadius: BorderRadius.circular(12),
// // // //               border: Border.all(color: AppColors.infoBlue.withOpacity(0.25)),
// // // //             ),
// // // //             child: const Column(
// // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // //               children: [
// // // //                 Text(
// // // //                   '📋 Important rules:',
// // // //                   style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
// // // //                 ),
// // // //                 SizedBox(height: 6),
// // // //                 Text(
// // // //                   '• Packs cannot be edited after publishing.\n'
// // // //                   '• You must purchase your own pack to use it in games.\n'
// // // //                   '• Moderation review takes 1–3 business days.',
// // // //                   style: TextStyle(fontSize: 13, height: 1.6),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ).animate(delay: 100.ms).fadeIn(),

// // // //           const SizedBox(height: 32),

// // // //           Row(
// // // //             children: [
// // // //               Expanded(
// // // //                 child: OutlinedButton(
// // // //                   onPressed: onBack,
// // // //                   child: const Text('Back'),
// // // //                 ),
// // // //               ),
// // // //               const SizedBox(width: 12),
// // // //               Expanded(
// // // //                 child: JButton(
// // // //                   label: 'Submit for Review',
// // // //                   onPressed: canPublish ? onPublish : null,
// // // //                   isLoading: isSaving,
// // // //                   icon: Icons.send_rounded,
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ).animate(delay: 120.ms).fadeIn(),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _SummaryRow extends StatelessWidget {
// // // //   const _SummaryRow({
// // // //     required this.label,
// // // //     required this.value,
// // // //     required this.icon,
// // // //   });
// // // //   final String label;
// // // //   final String value;
// // // //   final String icon;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Padding(
// // // //       padding: const EdgeInsets.symmetric(vertical: 4),
// // // //       child: Row(
// // // //         children: [
// // // //           Text(icon, style: const TextStyle(fontSize: 16)),
// // // //           const SizedBox(width: 10),
// // // //           Text(
// // // //             '$label: ',
// // // //             style: context.textTheme.bodySmall?.copyWith(
// // // //               color: context.colorScheme.onSurfaceVariant,
// // // //             ),
// // // //           ),
// // // //           Expanded(
// // // //             child: Text(
// // // //               value,
// // // //               style: context.textTheme.bodySmall?.copyWith(
// // // //                 fontWeight: FontWeight.w600,
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // import 'dart:io';

// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_animate/flutter_animate.dart';
// // // import 'package:go_router/go_router.dart';
// // // import 'package:image_picker/image_picker.dart';
// // // import 'package:provider/provider.dart';

// // // import '../../../../core/extensions/context_ext.dart';
// // // import '../../../../core/theme/app_colors.dart';
// // // import '../../../../shared/widgets/buttons/j_button.dart';
// // // import '../../data/pack_repository.dart';
// // // import '../../data/pack_upload_service.dart';
// // // import '../../data/pack_upload_service.dart';
// // // import '../../domain/pack_entity.dart';
// // // import '../pack_provider.dart';

// // // /// Multi-step pack creation flow.
// // // /// Steps: 1. Info  2. Cover  3. Cards  4. Review & Publish
// // // class CreatePackScreen extends StatefulWidget {
// // //   const CreatePackScreen({super.key, this.existingPackId, this.existingPack});
// // //   final String? existingPackId;
// // //   final PackEntity? existingPack;

// // //   @override
// // //   State<CreatePackScreen> createState() => _CreatePackScreenState();
// // // }

// // // class _CreatePackScreenState extends State<CreatePackScreen> {
// // //   late final PackDraft _draft;
// // //   int _step = 0;
// // //   bool _isSaving = false;
// // //   late String? _savedPackId;

// // //   static const _steps = ['Info', 'Cover', 'Cards', 'Publish'];

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _savedPackId = widget.existingPackId;
// // //     // Pre-fill draft from existing pack
// // //     final p = widget.existingPack;
// // //     if (p != null) {
// // //       _draft = PackDraft(
// // //         titleEn: p.titleFor('en'),
// // //         titleAr: p.titleFor('ar'),
// // //         titleFr: p.titleFor('fr'),
// // //         descriptionEn: p.descriptionFor('en'),
// // //         gameType: p.gameType,
// // //         language: p.language,
// // //         priceMru: p.priceMru,
// // //         categoryId: p.categoryId,
// // //         allowSpicy: p.hasSpicy,
// // //         coverImageUrl: p.coverImageUrl,
// // //         cards: [],
// // //       );
// // //       // Jump to cards step if basic info already saved
// // //       _step = _savedPackId != null ? 2 : 0;
// // //     } else {
// // //       _draft = PackDraft();
// // //     }
// // //   }

// // //   // static const _steps     = ['Info', 'Cover', 'Cards', 'Publish'];
// // //   static const _stepsMeme = ['Info', 'Cover', 'Cards', 'Reactions', 'Publish'];
// // //   List<String> get _activeSteps =>
// // //       _draft.gameType == 'meme_game' ? _stepsMeme : _steps;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return PopScope(
// // //       onPopInvokedWithResult: (_, __) {
// // //         if (mounted) context.read<PackProvider>().loadCreatedPacks();
// // //       },
// // //       child: Scaffold(
// // //         appBar: AppBar(
// // //           title: Text('Create Pack — ${_activeSteps[_step]}'),
// // //           bottom: PreferredSize(
// // //             preferredSize: const Size.fromHeight(4),
// // //             child: LinearProgressIndicator(
// // //               value: (_step + 1) / _activeSteps.length,
// // //               minHeight: 4,
// // //               color: AppColors.navyBlue,
// // //               backgroundColor: context.colorScheme.surfaceContainerHighest,
// // //             ),
// // //           ),
// // //         ),
// // //         body: AnimatedSwitcher(
// // //           duration: const Duration(milliseconds: 250),
// // //           child: KeyedSubtree(
// // //             key: ValueKey(_step),
// // //             child: switch (_step) {
// // //               0 => _InfoStep(draft: _draft, onNext: _nextStep),
// // //               1 => _CoverStep(
// // //                 draft: _draft,
// // //                 onNext: _nextStep,
// // //                 onBack: _prevStep,
// // //               ),
// // //               2 => _CardsStep(
// // //                 draft: _draft,
// // //                 packId: _savedPackId,
// // //                 onNext: _nextStep,
// // //                 onBack: _prevStep,
// // //               ),
// // //               3 when _draft.gameType == 'meme_game' => _ReactionsStep(
// // //                 draft: _draft,
// // //                 packId: _savedPackId,
// // //                 onNext: _nextStep,
// // //                 onBack: _prevStep,
// // //               ),
// // //               _ => _PublishStep(
// // //                 draft: _draft,
// // //                 packId: _savedPackId,
// // //                 isSaving: _isSaving,
// // //                 onPublish: _submit,
// // //                 onBack: _prevStep,
// // //               ),
// // //             },
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   void _nextStep() {
// // //     if (_step == 0 && _savedPackId == null) {
// // //       _saveDraft();
// // //     } else {
// // //       setState(() => _step = (_step + 1).clamp(0, _activeSteps.length - 1));
// // //     }
// // //   }

// // //   void _prevStep() =>
// // //       setState(() => _step = (_step - 1).clamp(0, _activeSteps.length - 1));

// // //   Future<void> _saveDraft() async {
// // //     setState(() => _isSaving = true);
// // //     try {
// // //       final packs = context.read<PackProvider>();
// // //       final userId = packs.currentUserId;
// // //       if (userId == null) throw Exception('Not logged in');

// // //       PackEntity pack;
// // //       if (_savedPackId == null) {
// // //         pack = await PackRepository.instance.createPackDraft(_draft, userId);
// // //         _savedPackId = pack.id;
// // //       } else {
// // //         pack = await PackRepository.instance.updatePackDraft(
// // //           _savedPackId!,
// // //           _draft,
// // //         );
// // //       }
// // //       setState(() {
// // //         _isSaving = false;
// // //         _step = 1;
// // //       });
// // //     } catch (e) {
// // //       setState(() => _isSaving = false);
// // //       if (mounted) context.showErrorSnackBar('Failed to save: $e');
// // //     }
// // //   }

// // //   Future<void> _submit() async {
// // //     if (_savedPackId == null) return;
// // //     setState(() => _isSaving = true);
// // //     try {
// // //       await PackRepository.instance.submitForReview(_savedPackId!);
// // //       if (mounted) {
// // //         context.read<PackProvider>().loadCreatedPacks();
// // //         context.showSnackBar(
// // //           'Pack submitted for review! You\'ll be notified when approved.',
// // //         );
// // //         context.pop();
// // //       }
// // //     } catch (e) {
// // //       setState(() => _isSaving = false);
// // //       if (mounted) context.showErrorSnackBar('Submission failed: $e');
// // //     }
// // //   }
// // // }

// // // // ── Step 1: Info ──────────────────────────────────────────────────────────────
// // // class _InfoStep extends StatefulWidget {
// // //   const _InfoStep({required this.draft, required this.onNext});
// // //   final PackDraft draft;
// // //   final VoidCallback onNext;

// // //   @override
// // //   State<_InfoStep> createState() => _InfoStepState();
// // // }

// // // class _InfoStepState extends State<_InfoStep> {
// // //   late final TextEditingController _titleCtrl;
// // //   late final TextEditingController _descCtrl;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _titleCtrl = TextEditingController(text: widget.draft.titleEn);
// // //     _descCtrl = TextEditingController(text: widget.draft.descriptionEn);
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _titleCtrl.dispose();
// // //     _descCtrl.dispose();
// // //     super.dispose();
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;

// // //     return SingleChildScrollView(
// // //       padding: const EdgeInsets.all(24),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Text(
// // //             'Pack information',
// // //             style: theme.textTheme.titleLarge?.copyWith(
// // //               fontWeight: FontWeight.w700,
// // //             ),
// // //           ).animate().fadeIn(),
// // //           const SizedBox(height: 24),

// // //           TextFormField(
// // //             controller: _titleCtrl,
// // //             onChanged: (v) => widget.draft.titleEn = v,
// // //             decoration: const InputDecoration(
// // //               labelText: 'Pack title (English)*',
// // //               hintText: 'e.g. Wild Friday Night',
// // //             ),
// // //             textCapitalization: TextCapitalization.words,
// // //           ).animate(delay: 60.ms).fadeIn(),

// // //           const SizedBox(height: 16),

// // //           TextFormField(
// // //             controller: _descCtrl,
// // //             onChanged: (v) => widget.draft.descriptionEn = v,
// // //             maxLines: 3,
// // //             maxLength: 500,
// // //             decoration: const InputDecoration(
// // //               labelText: 'Description (optional)',
// // //               counterText: '',
// // //             ),
// // //           ).animate(delay: 80.ms).fadeIn(),

// // //           const SizedBox(height: 16),

// // //           // Game type
// // //           DropdownButtonFormField<String>(
// // //             value: widget.draft.gameType,
// // //             decoration: const InputDecoration(labelText: 'Game type'),
// // //             items: const [
// // //               DropdownMenuItem(
// // //                 value: 'truth_or_dare',
// // //                 child: Text('🎯 Truth or Dare'),
// // //               ),
// // //               DropdownMenuItem(
// // //                 value: 'never_have_i_ever',
// // //                 child: Text('🍹 Never Have I Ever'),
// // //               ),
// // //               DropdownMenuItem(value: 'meme_game', child: Text('😂 Meme Game')),
// // //             ],
// // //             onChanged: (v) =>
// // //                 setState(() => widget.draft.gameType = v ?? 'truth_or_dare'),
// // //           ).animate(delay: 100.ms).fadeIn(),

// // //           const SizedBox(height: 16),

// // //           // Price
// // //           Row(
// // //             children: [
// // //               Expanded(
// // //                 child: TextFormField(
// // //                   initialValue: widget.draft.priceMru.toString(),
// // //                   keyboardType: TextInputType.number,
// // //                   decoration: const InputDecoration(
// // //                     labelText: 'Price (MRU)',
// // //                     hintText: '0 for free',
// // //                     suffixText: 'MRU',
// // //                   ),
// // //                   onChanged: (v) =>
// // //                       widget.draft.priceMru = int.tryParse(v) ?? 0,
// // //                 ),
// // //               ),
// // //               const SizedBox(width: 12),
// // //               Row(
// // //                 children: [
// // //                   Text(
// // //                     'Spicy 🌶️',
// // //                     style: Theme.of(context).textTheme.bodyMedium,
// // //                   ),
// // //                   const SizedBox(width: 8),
// // //                   Switch(
// // //                     value: widget.draft.allowSpicy,
// // //                     onChanged: (v) =>
// // //                         setState(() => widget.draft.allowSpicy = v),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ],
// // //           ).animate(delay: 120.ms).fadeIn(),

// // //           const SizedBox(height: 32),

// // //           JButton(
// // //             label: 'Continue →',
// // //             onPressed: widget.draft.hasTitle ? widget.onNext : null,
// // //             icon: Icons.arrow_forward_rounded,
// // //           ).animate(delay: 140.ms).fadeIn(),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ── Step 2: Cover ─────────────────────────────────────────────────────────────
// // // class _CoverStep extends StatefulWidget {
// // //   const _CoverStep({
// // //     required this.draft,
// // //     required this.onNext,
// // //     required this.onBack,
// // //   });
// // //   final PackDraft draft;
// // //   final VoidCallback onNext;
// // //   final VoidCallback onBack;

// // //   @override
// // //   State<_CoverStep> createState() => _CoverStepState();
// // // }

// // // class _CoverStepState extends State<_CoverStep> {
// // //   bool _isUploading = false;

// // //   Future<void> _pickAndUpload() async {
// // //     final picker = ImagePicker();
// // //     final picked = await picker.pickImage(
// // //       source: ImageSource.gallery,
// // //       maxWidth: 1024,
// // //       maxHeight: 1024,
// // //       imageQuality: 85,
// // //     );
// // //     if (picked == null) return;

// // //     setState(() => _isUploading = true);
// // //     try {
// // //       final url = await PackUploadService.instance.uploadCoverImage(
// // //         File(picked.path),
// // //       );
// // //       setState(() {
// // //         widget.draft.coverImagePath = picked.path;
// // //         widget.draft.coverImageUrl = url;
// // //         _isUploading = false;
// // //       });
// // //     } catch (e) {
// // //       setState(() => _isUploading = false);
// // //       if (mounted) context.showErrorSnackBar('Upload failed: $e');
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;

// // //     return Padding(
// // //       padding: const EdgeInsets.all(24),
// // //       child: Column(
// // //         children: [
// // //           Text(
// // //             'Cover image',
// // //             style: theme.textTheme.titleLarge?.copyWith(
// // //               fontWeight: FontWeight.w700,
// // //             ),
// // //           ).animate().fadeIn(),
// // //           const SizedBox(height: 8),
// // //           Text(
// // //             'Add an attractive cover to increase pack visibility.',
// // //             style: theme.textTheme.bodyMedium?.copyWith(
// // //               color: theme.colorScheme.onSurfaceVariant,
// // //             ),
// // //           ).animate(delay: 40.ms).fadeIn(),

// // //           const SizedBox(height: 32),

// // //           // Cover preview
// // //           GestureDetector(
// // //                 onTap: _isUploading ? null : _pickAndUpload,
// // //                 child: Container(
// // //                   width: 220,
// // //                   height: 220,
// // //                   decoration: BoxDecoration(
// // //                     color: theme.colorScheme.surfaceContainerHighest,
// // //                     borderRadius: BorderRadius.circular(20),
// // //                     border: Border.all(
// // //                       color: theme.colorScheme.outline,
// // //                       width: 2,
// // //                       strokeAlign: BorderSide.strokeAlignOutside,
// // //                     ),
// // //                   ),
// // //                   child: _isUploading
// // //                       ? const Center(child: CircularProgressIndicator())
// // //                       : widget.draft.coverImagePath != null
// // //                       ? ClipRRect(
// // //                           borderRadius: BorderRadius.circular(18),
// // //                           child: Image.file(
// // //                             File(widget.draft.coverImagePath!),
// // //                             fit: BoxFit.cover,
// // //                           ),
// // //                         )
// // //                       : Column(
// // //                           mainAxisAlignment: MainAxisAlignment.center,
// // //                           children: [
// // //                             Icon(
// // //                               Icons.add_photo_alternate_outlined,
// // //                               size: 48,
// // //                               color: theme.colorScheme.onSurfaceVariant,
// // //                             ),
// // //                             const SizedBox(height: 8),
// // //                             Text(
// // //                               'Tap to add cover',
// // //                               style: theme.textTheme.bodyMedium?.copyWith(
// // //                                 color: theme.colorScheme.onSurfaceVariant,
// // //                               ),
// // //                             ),
// // //                           ],
// // //                         ),
// // //                 ),
// // //               )
// // //               .animate(delay: 80.ms)
// // //               .fadeIn()
// // //               .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

// // //           const Spacer(),

// // //           Row(
// // //             children: [
// // //               Expanded(
// // //                 child: OutlinedButton(
// // //                   onPressed: widget.onBack,
// // //                   child: const Text('Back'),
// // //                 ),
// // //               ),
// // //               const SizedBox(width: 12),
// // //               Expanded(
// // //                 child: JButton(
// // //                   label: 'Continue →',
// // //                   onPressed: widget.draft.coverImageUrl != null
// // //                       ? widget.onNext
// // //                       : null,
// // //                 ),
// // //               ),
// // //             ],
// // //           ).animate(delay: 120.ms).fadeIn(),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ── Step 3: Cards ─────────────────────────────────────────────────────────────

// // // String _cardTypeEmoji(CardType t) => switch (t) {
// // //   CardType.truth => '🤔',
// // //   CardType.dare => '🔥',
// // //   CardType.statement => '🍹',
// // //   CardType.prompt => '😂',
// // // };

// // // String _cardTypeLabel(CardType t) => switch (t) {
// // //   CardType.truth => 'Truth',
// // //   CardType.dare => 'Dare',
// // //   CardType.statement => 'Statement',
// // //   CardType.prompt => 'Prompt',
// // // };

// // // Color _cardTypeColor(CardType t) => switch (t) {
// // //   CardType.truth => AppColors.truthColor,
// // //   CardType.dare => AppColors.dareColor,
// // //   CardType.statement => AppColors.tealGreen,
// // //   CardType.prompt => AppColors.purple,
// // // };

// // // class _CardsStep extends StatefulWidget {
// // //   const _CardsStep({
// // //     required this.draft,
// // //     required this.packId,
// // //     required this.onNext,
// // //     required this.onBack,
// // //   });
// // //   final PackDraft draft;
// // //   final String? packId;
// // //   final VoidCallback onNext;
// // //   final VoidCallback onBack;

// // //   @override
// // //   State<_CardsStep> createState() => _CardsStepState();
// // // }

// // // class _CardsStepState extends State<_CardsStep> {
// // //   final _contentCtrl = TextEditingController();
// // //   late CardType _type;
// // //   CardDifficulty _difficulty = CardDifficulty.mild;
// // //   bool _isSaving = false;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     // Set default card type based on game type
// // //     _type = _defaultTypeForGame(widget.draft.gameType);
// // //   }

// // //   CardType _defaultTypeForGame(String gameType) {
// // //     switch (gameType) {
// // //       case 'never_have_i_ever':
// // //         return CardType.statement;
// // //       case 'meme_game':
// // //         return CardType.prompt;
// // //       default:
// // //         return CardType.truth; // truth_or_dare
// // //     }
// // //   }

// // //   List<(CardType, String, Color)> _typesForGame(String gameType) {
// // //     switch (gameType) {
// // //       case 'never_have_i_ever':
// // //         return [(CardType.statement, 'Statement 🍹', AppColors.tealGreen)];
// // //       case 'meme_game':
// // //         return [(CardType.prompt, 'Prompt 😂', AppColors.purple)];
// // //       default:
// // //         return [
// // //           (CardType.truth, 'Truth 🤔', AppColors.truthColor),
// // //           (CardType.dare, 'Dare 🔥', AppColors.dareColor),
// // //         ];
// // //     }
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _contentCtrl.dispose();
// // //     super.dispose();
// // //   }

// // //   void _addCard() {
// // //     final text = _contentCtrl.text.trim();
// // //     if (text.isEmpty) return;
// // //     setState(() {
// // //       widget.draft.cards.add(
// // //         CardDraft(contentEn: text, type: _type, difficulty: _difficulty),
// // //       );
// // //       _contentCtrl.clear();
// // //     });
// // //   }

// // //   Future<void> _saveAndContinue() async {
// // //     if (widget.packId == null) return;
// // //     if (widget.draft.cards.isEmpty) return;

// // //     setState(() => _isSaving = true);
// // //     try {
// // //       await PackRepository.instance.addCards(
// // //         widget.packId!,
// // //         widget.draft.cards,
// // //       );
// // //       widget.onNext();
// // //     } catch (e) {
// // //       if (mounted) context.showErrorSnackBar('Failed to save cards: $e');
// // //     } finally {
// // //       setState(() => _isSaving = false);
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;
// // //     final cards = widget.draft.cards;

// // //     return Column(
// // //       children: [
// // //         // Card input area
// // //         Padding(
// // //           padding: const EdgeInsets.all(16),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               Row(
// // //                 children: [
// // //                   Text(
// // //                     '${cards.length} / 20+ cards',
// // //                     style: theme.textTheme.titleSmall?.copyWith(
// // //                       fontWeight: FontWeight.w700,
// // //                     ),
// // //                   ),
// // //                   const Spacer(),
// // //                   Text(
// // //                     cards.length < 20
// // //                         ? '${20 - cards.length} more needed'
// // //                         : '✅ Minimum reached',
// // //                     style: TextStyle(
// // //                       fontSize: 12,
// // //                       color: cards.length >= 20
// // //                           ? AppColors.successGreen
// // //                           : AppColors.warningAmber,
// // //                       fontWeight: FontWeight.w600,
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //               const SizedBox(height: 8),

// // //               // Type + difficulty selectors — adapts to game type
// // //               Row(
// // //                 children: [
// // //                   ..._typesForGame(widget.draft.gameType).map((t) {
// // //                     final (type, label, color) = t;
// // //                     return Padding(
// // //                       padding: const EdgeInsets.only(right: 8),
// // //                       child: _TypeButton(
// // //                         label: label,
// // //                         isSelected: _type == type,
// // //                         color: color,
// // //                         onTap: () => setState(() => _type = type),
// // //                       ),
// // //                     );
// // //                   }),
// // //                   const SizedBox(width: 4),
// // //                   DropdownButton<CardDifficulty>(
// // //                     value: _difficulty,
// // //                     underline: const SizedBox.shrink(),
// // //                     items: CardDifficulty.values
// // //                         .map(
// // //                           (d) =>
// // //                               DropdownMenuItem(value: d, child: Text(d.name)),
// // //                         )
// // //                         .toList(),
// // //                     onChanged: (d) => setState(() => _difficulty = d!),
// // //                   ),
// // //                 ],
// // //               ),
// // //               const SizedBox(height: 8),

// // //               Row(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   Expanded(
// // //                     child: TextField(
// // //                       controller: _contentCtrl,
// // //                       maxLines: 2,
// // //                       decoration: const InputDecoration(
// // //                         hintText: 'Card content…',
// // //                         isDense: true,
// // //                       ),
// // //                       onSubmitted: (_) => _addCard(),
// // //                     ),
// // //                   ),
// // //                   const SizedBox(width: 8),
// // //                   IconButton.filled(
// // //                     onPressed: _addCard,
// // //                     icon: const Icon(Icons.add_rounded),
// // //                     style: IconButton.styleFrom(
// // //                       backgroundColor: AppColors.navyBlue,
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ],
// // //           ),
// // //         ),

// // //         const Divider(height: 1),

// // //         // Card list
// // //         Expanded(
// // //           child: cards.isEmpty
// // //               ? const Center(child: Text('Add your first card above!'))
// // //               : ListView.separated(
// // //                   padding: const EdgeInsets.all(12),
// // //                   itemCount: cards.length,
// // //                   separatorBuilder: (_, __) => const SizedBox(height: 6),
// // //                   itemBuilder: (_, i) {
// // //                     final card = cards[i];
// // //                     final color = _cardTypeColor(card.type);
// // //                     return Container(
// // //                       padding: const EdgeInsets.all(10),
// // //                       decoration: BoxDecoration(
// // //                         color: color.withOpacity(0.06),
// // //                         borderRadius: BorderRadius.circular(8),
// // //                         border: Border.all(color: color.withOpacity(0.2)),
// // //                       ),
// // //                       child: Row(
// // //                         children: [
// // //                           Container(
// // //                             padding: const EdgeInsets.symmetric(
// // //                               horizontal: 6,
// // //                               vertical: 2,
// // //                             ),
// // //                             decoration: BoxDecoration(
// // //                               color: color.withOpacity(0.15),
// // //                               borderRadius: BorderRadius.circular(4),
// // //                             ),
// // //                             child: Row(
// // //                               mainAxisSize: MainAxisSize.min,
// // //                               children: [
// // //                                 Text(
// // //                                   _cardTypeEmoji(card.type),
// // //                                   style: const TextStyle(fontSize: 12),
// // //                                 ),
// // //                                 const SizedBox(width: 3),
// // //                                 Text(
// // //                                   _cardTypeLabel(card.type),
// // //                                   style: TextStyle(
// // //                                     fontSize: 11,
// // //                                     fontWeight: FontWeight.w700,
// // //                                     color: color,
// // //                                   ),
// // //                                 ),
// // //                               ],
// // //                             ),
// // //                           ),
// // //                           const SizedBox(width: 8),
// // //                           Expanded(
// // //                             child: Text(
// // //                               card.contentEn,
// // //                               style: theme.textTheme.bodySmall,
// // //                             ),
// // //                           ),
// // //                           IconButton(
// // //                             icon: const Icon(Icons.close_rounded, size: 16),
// // //                             onPressed: () => setState(() => cards.removeAt(i)),
// // //                             visualDensity: VisualDensity.compact,
// // //                             padding: EdgeInsets.zero,
// // //                           ),
// // //                         ],
// // //                       ),
// // //                     ).animate(delay: (i * 15).ms).fadeIn();
// // //                   },
// // //                 ),
// // //         ),

// // //         // Bottom bar
// // //         Padding(
// // //           padding: const EdgeInsets.all(16),
// // //           child: Row(
// // //             children: [
// // //               Expanded(
// // //                 child: OutlinedButton(
// // //                   onPressed: widget.onBack,
// // //                   child: const Text('Back'),
// // //                 ),
// // //               ),
// // //               const SizedBox(width: 12),
// // //               Expanded(
// // //                 child: JButton(
// // //                   label: 'Continue →',
// // //                   onPressed: cards.length >= 20 ? _saveAndContinue : null,
// // //                   isLoading: _isSaving,
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // }

// // // class _TypeButton extends StatelessWidget {
// // //   const _TypeButton({
// // //     required this.label,
// // //     required this.isSelected,
// // //     required this.color,
// // //     required this.onTap,
// // //   });
// // //   final String label;
// // //   final bool isSelected;
// // //   final Color color;
// // //   final VoidCallback onTap;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return GestureDetector(
// // //       onTap: onTap,
// // //       child: Container(
// // //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// // //         decoration: BoxDecoration(
// // //           color: isSelected ? color : color.withOpacity(0.08),
// // //           borderRadius: BorderRadius.circular(8),
// // //         ),
// // //         child: Text(
// // //           label,
// // //           style: TextStyle(
// // //             color: isSelected ? Colors.white : color,
// // //             fontWeight: FontWeight.w700,
// // //             fontSize: 13,
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ── Step 4: Publish ───────────────────────────────────────────────────────────
// // // // ── Step 4 (Meme only): Reactions ─────────────────────────────────────────────
// // // class _ReactionsStep extends StatefulWidget {
// // //   const _ReactionsStep({
// // //     required this.draft,
// // //     required this.packId,
// // //     required this.onNext,
// // //     required this.onBack,
// // //   });
// // //   final PackDraft draft;
// // //   final String? packId;
// // //   final VoidCallback onNext;
// // //   final VoidCallback onBack;

// // //   @override
// // //   State<_ReactionsStep> createState() => _ReactionsStepState();
// // // }

// // // class _ReactionsStepState extends State<_ReactionsStep> {
// // //   bool _isSaving = false;

// // //   Future<void> _pickAndUpload() async {
// // //     if (widget.draft.reactionImageUrls.length >= 30) {
// // //       context.showErrorSnackBar('Maximum 30 reaction images reached');
// // //       return;
// // //     }
// // //     final picker = ImagePicker();
// // //     final picked = await picker.pickMultiImage(imageQuality: 85);
// // //     if (picked.isEmpty || !mounted) return;

// // //     final remaining = 30 - widget.draft.reactionImageUrls.length;
// // //     final toUpload = picked.take(remaining).toList();

// // //     setState(() => _isSaving = true);
// // //     try {
// // //       for (final xfile in toUpload) {
// // //         final file = File(xfile.path);
// // //         final url = await PackUploadService.instance.uploadCardImage(file);
// // //         setState(() => widget.draft.reactionImageUrls.add(url));
// // //       }
// // //     } catch (e) {
// // //       if (mounted) context.showErrorSnackBar('Upload failed: $e');
// // //     } finally {
// // //       if (mounted) setState(() => _isSaving = false);
// // //     }
// // //   }

// // //   Future<void> _saveAndContinue() async {
// // //     if (widget.packId == null) {
// // //       widget.onNext();
// // //       return;
// // //     }
// // //     setState(() => _isSaving = true);
// // //     try {
// // //       await PackRepository.instance.savePackReactions(
// // //         widget.packId!,
// // //         widget.draft.reactionImageUrls,
// // //       );
// // //       widget.onNext();
// // //     } catch (e) {
// // //       if (mounted) context.showErrorSnackBar('Failed to save reactions: $e');
// // //     } finally {
// // //       if (mounted) setState(() => _isSaving = false);
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;
// // //     final reactions = widget.draft.reactionImageUrls;

// // //     return Column(
// // //       children: [
// // //         Padding(
// // //           padding: const EdgeInsets.all(16),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               Row(
// // //                 children: [
// // //                   Text(
// // //                     '${reactions.length} / 30 reaction images',
// // //                     style: theme.textTheme.titleSmall?.copyWith(
// // //                       fontWeight: FontWeight.w700,
// // //                     ),
// // //                   ),
// // //                   const Spacer(),
// // //                   Text(
// // //                     reactions.isEmpty
// // //                         ? 'Optional — skip to use defaults'
// // //                         : '${30 - reactions.length} slots remaining',
// // //                     style: TextStyle(
// // //                       fontSize: 12,
// // //                       color: theme.colorScheme.onSurfaceVariant,
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //               const SizedBox(height: 4),
// // //               Text(
// // //                 'Players will use these images as reactions during the game. '
// // //                 'Add up to 30. If none, default stickers are used.',
// // //                 style: theme.textTheme.bodySmall?.copyWith(
// // //                   color: theme.colorScheme.onSurfaceVariant,
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),

// // //         Expanded(
// // //           child: reactions.isEmpty
// // //               ? Center(
// // //                   child: Column(
// // //                     mainAxisSize: MainAxisSize.min,
// // //                     children: [
// // //                       Icon(
// // //                         Icons.image_outlined,
// // //                         size: 64,
// // //                         color: theme.colorScheme.onSurfaceVariant,
// // //                       ),
// // //                       const SizedBox(height: 8),
// // //                       Text(
// // //                         'No reaction images yet',
// // //                         style: theme.textTheme.bodyMedium?.copyWith(
// // //                           color: theme.colorScheme.onSurfaceVariant,
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 )
// // //               : GridView.builder(
// // //                   padding: const EdgeInsets.symmetric(horizontal: 12),
// // //                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// // //                     crossAxisCount: 4,
// // //                     mainAxisSpacing: 8,
// // //                     crossAxisSpacing: 8,
// // //                     childAspectRatio: 1,
// // //                   ),
// // //                   itemCount: reactions.length,
// // //                   itemBuilder: (_, i) {
// // //                     return Stack(
// // //                       children: [
// // //                         ClipRRect(
// // //                           borderRadius: BorderRadius.circular(8),
// // //                           child: Image.network(
// // //                             reactions[i],
// // //                             width: double.infinity,
// // //                             height: double.infinity,
// // //                             fit: BoxFit.cover,
// // //                             errorBuilder: (_, __, ___) =>
// // //                                 const Icon(Icons.broken_image),
// // //                           ),
// // //                         ),
// // //                         Positioned(
// // //                           top: 2,
// // //                           right: 2,
// // //                           child: GestureDetector(
// // //                             onTap: () => setState(() => reactions.removeAt(i)),
// // //                             child: Container(
// // //                               decoration: const BoxDecoration(
// // //                                 color: Colors.black54,
// // //                                 shape: BoxShape.circle,
// // //                               ),
// // //                               child: const Icon(
// // //                                 Icons.close_rounded,
// // //                                 color: Colors.white,
// // //                                 size: 16,
// // //                               ),
// // //                             ),
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     );
// // //                   },
// // //                 ),
// // //         ),

// // //         Padding(
// // //           padding: const EdgeInsets.all(16),
// // //           child: Column(
// // //             children: [
// // //               if (reactions.length < 30)
// // //                 SizedBox(
// // //                   width: double.infinity,
// // //                   child: OutlinedButton.icon(
// // //                     onPressed: _isSaving ? null : _pickAndUpload,
// // //                     icon: _isSaving
// // //                         ? const SizedBox(
// // //                             width: 16,
// // //                             height: 16,
// // //                             child: CircularProgressIndicator(strokeWidth: 2),
// // //                           )
// // //                         : const Icon(Icons.add_photo_alternate_rounded),
// // //                     label: Text(_isSaving ? 'Uploading...' : 'Add Images'),
// // //                   ),
// // //                 ),
// // //               const SizedBox(height: 8),
// // //               Row(
// // //                 children: [
// // //                   Expanded(
// // //                     child: OutlinedButton(
// // //                       onPressed: widget.onBack,
// // //                       child: const Text('Back'),
// // //                     ),
// // //                   ),
// // //                   const SizedBox(width: 12),
// // //                   Expanded(
// // //                     child: FilledButton(
// // //                       onPressed: _isSaving ? null : _saveAndContinue,
// // //                       child: Text(reactions.isEmpty ? 'Skip' : 'Continue'),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // }

// // // // ── Step 4/5: Publish ──────────────────────────────────────────────────────────
// // // class _PublishStep extends StatelessWidget {
// // //   const _PublishStep({
// // //     required this.draft,
// // //     required this.packId,
// // //     required this.isSaving,
// // //     required this.onPublish,
// // //     required this.onBack,
// // //   });
// // //   final PackDraft draft;
// // //   final String? packId;
// // //   final bool isSaving;
// // //   final VoidCallback onPublish;
// // //   final VoidCallback onBack;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;
// // //     final canPublish = draft.canPublish && packId != null;

// // //     return SingleChildScrollView(
// // //       padding: const EdgeInsets.all(24),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Text(
// // //             'Ready to publish?',
// // //             style: theme.textTheme.headlineSmall?.copyWith(
// // //               fontWeight: FontWeight.w800,
// // //             ),
// // //           ).animate().fadeIn(),
// // //           const SizedBox(height: 8),
// // //           Text(
// // //             'Review your pack before submitting for moderation.',
// // //             style: theme.textTheme.bodyMedium?.copyWith(
// // //               color: theme.colorScheme.onSurfaceVariant,
// // //             ),
// // //           ).animate(delay: 40.ms).fadeIn(),

// // //           const SizedBox(height: 24),

// // //           // Summary card
// // //           Container(
// // //             padding: const EdgeInsets.all(18),
// // //             decoration: BoxDecoration(
// // //               color: theme.colorScheme.surfaceContainerHighest,
// // //               borderRadius: BorderRadius.circular(16),
// // //             ),
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 _SummaryRow(label: 'Title', value: draft.titleEn, icon: '📦'),
// // //                 _SummaryRow(
// // //                   label: 'Game type',
// // //                   value: draft.gameType,
// // //                   icon: '🎮',
// // //                 ),
// // //                 _SummaryRow(
// // //                   label: 'Cards',
// // //                   value:
// // //                       '${draft.cards.length} (${draft.truthCount}T + ${draft.dareCount}D)',
// // //                   icon: '🃏',
// // //                 ),
// // //                 _SummaryRow(
// // //                   label: 'Price',
// // //                   value: draft.priceMru == 0 ? 'Free' : '${draft.priceMru} MRU',
// // //                   icon: '💰',
// // //                 ),
// // //                 _SummaryRow(
// // //                   label: 'Spicy content',
// // //                   value: draft.allowSpicy ? 'Allowed' : 'No',
// // //                   icon: '🌶',
// // //                 ),
// // //               ],
// // //             ),
// // //           ).animate(delay: 80.ms).fadeIn(),

// // //           const SizedBox(height: 16),

// // //           // Rules reminder
// // //           Container(
// // //             padding: const EdgeInsets.all(14),
// // //             decoration: BoxDecoration(
// // //               color: AppColors.infoBlue.withOpacity(0.08),
// // //               borderRadius: BorderRadius.circular(12),
// // //               border: Border.all(color: AppColors.infoBlue.withOpacity(0.25)),
// // //             ),
// // //             child: const Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 Text(
// // //                   '📋 Important rules:',
// // //                   style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
// // //                 ),
// // //                 SizedBox(height: 6),
// // //                 Text(
// // //                   '• Packs cannot be edited after publishing.\n'
// // //                   '• You must purchase your own pack to use it in games.\n'
// // //                   '• Moderation review takes 1–3 business days.',
// // //                   style: TextStyle(fontSize: 13, height: 1.6),
// // //                 ),
// // //               ],
// // //             ),
// // //           ).animate(delay: 100.ms).fadeIn(),

// // //           const SizedBox(height: 32),

// // //           Row(
// // //             children: [
// // //               Expanded(
// // //                 child: OutlinedButton(
// // //                   onPressed: onBack,
// // //                   child: const Text('Back'),
// // //                 ),
// // //               ),
// // //               const SizedBox(width: 12),
// // //               Expanded(
// // //                 child: JButton(
// // //                   label: 'Submit for Review',
// // //                   onPressed: canPublish ? onPublish : null,
// // //                   isLoading: isSaving,
// // //                   icon: Icons.send_rounded,
// // //                 ),
// // //               ),
// // //             ],
// // //           ).animate(delay: 120.ms).fadeIn(),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _SummaryRow extends StatelessWidget {
// // //   const _SummaryRow({
// // //     required this.label,
// // //     required this.value,
// // //     required this.icon,
// // //   });
// // //   final String label;
// // //   final String value;
// // //   final String icon;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(vertical: 4),
// // //       child: Row(
// // //         children: [
// // //           Text(icon, style: const TextStyle(fontSize: 16)),
// // //           const SizedBox(width: 10),
// // //           Text(
// // //             '$label: ',
// // //             style: context.textTheme.bodySmall?.copyWith(
// // //               color: context.colorScheme.onSurfaceVariant,
// // //             ),
// // //           ),
// // //           Expanded(
// // //             child: Text(
// // //               value,
// // //               style: context.textTheme.bodySmall?.copyWith(
// // //                 fontWeight: FontWeight.w600,
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'dart:io';

// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'package:provider/provider.dart';

// // import '../../../../core/extensions/context_ext.dart';
// // import '../../../../core/theme/app_colors.dart';
// // import '../../../../shared/widgets/buttons/j_button.dart';
// // import '../../data/pack_repository.dart';
// // import '../../data/pack_upload_service.dart';
// // import '../../data/pack_upload_service.dart';
// // import '../../domain/pack_entity.dart';
// // import '../pack_provider.dart';

// // /// Multi-step pack creation flow.
// // /// Steps: 1. Info  2. Cover  3. Cards  4. Review & Publish
// // class CreatePackScreen extends StatefulWidget {
// //   const CreatePackScreen({super.key, this.existingPackId, this.existingPack});
// //   final String? existingPackId;
// //   final PackEntity? existingPack;

// //   @override
// //   State<CreatePackScreen> createState() => _CreatePackScreenState();
// // }

// // class _CreatePackScreenState extends State<CreatePackScreen> {
// //   late final PackDraft _draft;
// //   int _step = 0;
// //   bool _isSaving = false;
// //   late String? _savedPackId;

// //   static const _steps = ['Info', 'Cover', 'Cards', 'Publish'];

// //   @override
// //   void initState() {
// //     super.initState();
// //     _savedPackId = widget.existingPackId;
// //     // Pre-fill draft from existing pack
// //     final p = widget.existingPack;
// //     if (p != null) {
// //       _draft = PackDraft(
// //         titleEn: p.titleFor('en'),
// //         titleAr: p.titleFor('ar'),
// //         titleFr: p.titleFor('fr'),
// //         descriptionEn: p.descriptionFor('en'),
// //         gameType: p.gameType,
// //         language: p.language,
// //         priceMru: p.priceMru,
// //         categoryId: p.categoryId,
// //         allowSpicy: p.hasSpicy,
// //         coverImageUrl: p.coverImageUrl,
// //         cards: [],
// //       );
// //       // Jump to cards step if basic info already saved
// //       _step = _savedPackId != null ? 2 : 0;
// //     } else {
// //       _draft = PackDraft();
// //     }
// //   }

// //   // static const _steps     = ['Info', 'Cover', 'Cards', 'Publish'];
// //   static const _stepsMeme = ['Info', 'Cover', 'Cards', 'Reactions', 'Publish'];
// //   List<String> get _activeSteps =>
// //       _draft.gameType == 'meme_game' ? _stepsMeme : _steps;

// //   @override
// //   Widget build(BuildContext context) {
// //     return PopScope(
// //       onPopInvokedWithResult: (_, __) {
// //         if (mounted) context.read<PackProvider>().loadCreatedPacks();
// //       },
// //       child: Scaffold(
// //         appBar: AppBar(
// //           title: Text('Create Pack — ${_activeSteps[_step]}'),
// //           bottom: PreferredSize(
// //             preferredSize: const Size.fromHeight(4),
// //             child: LinearProgressIndicator(
// //               value: (_step + 1) / _activeSteps.length,
// //               minHeight: 4,
// //               color: AppColors.navyBlue,
// //               backgroundColor: context.colorScheme.surfaceContainerHighest,
// //             ),
// //           ),
// //         ),
// //         body: AnimatedSwitcher(
// //           duration: const Duration(milliseconds: 250),
// //           child: KeyedSubtree(
// //             key: ValueKey(_step),
// //             child: switch (_step) {
// //               0 => _InfoStep(draft: _draft, onNext: _nextStep),
// //               1 => _CoverStep(
// //                 draft: _draft,
// //                 onNext: _nextStep,
// //                 onBack: _prevStep,
// //               ),
// //               2 => _CardsStep(
// //                 draft: _draft,
// //                 packId: _savedPackId,
// //                 onNext: _nextStep,
// //                 onBack: _prevStep,
// //               ),
// //               3 when _draft.gameType == 'meme_game' => _ReactionsStep(
// //                 draft: _draft,
// //                 packId: _savedPackId,
// //                 onNext: _nextStep,
// //                 onBack: _prevStep,
// //               ),
// //               _ => _PublishStep(
// //                 draft: _draft,
// //                 packId: _savedPackId,
// //                 isSaving: _isSaving,
// //                 onPublish: _submit,
// //                 onBack: _prevStep,
// //               ),
// //             },
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   void _nextStep() {
// //     if (_step == 0 && _savedPackId == null) {
// //       _saveDraft();
// //     } else {
// //       setState(() => _step = (_step + 1).clamp(0, _activeSteps.length - 1));
// //     }
// //   }

// //   void _prevStep() =>
// //       setState(() => _step = (_step - 1).clamp(0, _activeSteps.length - 1));

// //   Future<void> _saveDraft() async {
// //     setState(() => _isSaving = true);
// //     try {
// //       final packs = context.read<PackProvider>();
// //       final userId = packs.currentUserId;
// //       if (userId == null) throw Exception('Not logged in');

// //       PackEntity pack;
// //       if (_savedPackId == null) {
// //         pack = await PackRepository.instance.createPackDraft(_draft, userId);
// //         _savedPackId = pack.id;
// //       } else {
// //         pack = await PackRepository.instance.updatePackDraft(
// //           _savedPackId!,
// //           _draft,
// //         );
// //       }
// //       setState(() {
// //         _isSaving = false;
// //         _step = 1;
// //       });
// //     } catch (e) {
// //       setState(() => _isSaving = false);
// //       if (mounted) context.showErrorSnackBar('Failed to save: $e');
// //     }
// //   }

// //   Future<void> _submit() async {
// //     if (_savedPackId == null) return;
// //     setState(() => _isSaving = true);
// //     try {
// //       await PackRepository.instance.submitForReview(_savedPackId!);
// //       if (mounted) {
// //         context.read<PackProvider>().loadCreatedPacks();
// //         context.showSnackBar(
// //           'Pack submitted for review! You\'ll be notified when approved.',
// //         );
// //         context.pop();
// //       }
// //     } catch (e) {
// //       setState(() => _isSaving = false);
// //       if (mounted) context.showErrorSnackBar('Submission failed: $e');
// //     }
// //   }
// // }

// // // ── Step 1: Info ──────────────────────────────────────────────────────────────

// // // ── Category picker ───────────────────────────────────────────────────────────
// // class _CategoryPicker extends StatefulWidget {
// //   const _CategoryPicker({
// //     required this.gameType,
// //     required this.selectedId,
// //     required this.onSelected,
// //   });
// //   final String gameType;
// //   final String? selectedId;
// //   final ValueChanged<String?> onSelected;
// //   @override
// //   State<_CategoryPicker> createState() => _CategoryPickerState();
// // }

// // class _CategoryPickerState extends State<_CategoryPicker> {
// //   List<PackCategory>? _cats;
// //   bool _loading = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _load();
// //   }

// //   @override
// //   void didUpdateWidget(_CategoryPicker old) {
// //     super.didUpdateWidget(old);
// //     if (old.gameType != widget.gameType) _load();
// //   }

// //   Future<void> _load() async {
// //     setState(() {
// //       _loading = true;
// //       _cats = null;
// //     });
// //     try {
// //       final all = await PackRepository.instance.getCategories();
// //       if (mounted)
// //         setState(() {
// //           _cats = all;
// //           _loading = false;
// //         });
// //     } catch (_) {
// //       if (mounted) setState(() => _loading = false);
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (_loading) return const LinearProgressIndicator();
// //     final cats = _cats;
// //     if (cats == null || cats.isEmpty) return const SizedBox.shrink();
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           'Category (optional)',
// //           style: Theme.of(context).textTheme.labelMedium?.copyWith(
// //             color: Theme.of(context).colorScheme.onSurfaceVariant,
// //           ),
// //         ),
// //         const SizedBox(height: 8),
// //         Wrap(
// //           spacing: 8,
// //           runSpacing: 6,
// //           children: [
// //             // None option
// //             ChoiceChip(
// //               label: const Text('None'),
// //               selected: widget.selectedId == null,
// //               onSelected: (_) => widget.onSelected(null),
// //             ),
// //             ...cats.map(
// //               (c) => ChoiceChip(
// //                 avatar: Text(c.icon),
// //                 label: Text(c.nameJson['en'] as String? ?? c.slug),
// //                 selected: widget.selectedId == c.id,
// //                 onSelected: (_) =>
// //                     widget.onSelected(widget.selectedId == c.id ? null : c.id),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ],
// //     );
// //   }
// // }

// // class _InfoStep extends StatefulWidget {
// //   const _InfoStep({required this.draft, required this.onNext});
// //   final PackDraft draft;
// //   final VoidCallback onNext;

// //   @override
// //   State<_InfoStep> createState() => _InfoStepState();
// // }

// // class _InfoStepState extends State<_InfoStep> {
// //   late final TextEditingController _titleCtrl;
// //   late final TextEditingController _descCtrl;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _titleCtrl = TextEditingController(text: widget.draft.titleEn);
// //     _descCtrl = TextEditingController(text: widget.draft.descriptionEn);
// //   }

// //   @override
// //   void dispose() {
// //     _titleCtrl.dispose();
// //     _descCtrl.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;

// //     return SingleChildScrollView(
// //       padding: const EdgeInsets.all(24),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(
// //             'Pack information',
// //             style: theme.textTheme.titleLarge?.copyWith(
// //               fontWeight: FontWeight.w700,
// //             ),
// //           ).animate().fadeIn(),
// //           const SizedBox(height: 24),

// //           TextFormField(
// //             controller: _titleCtrl,
// //             onChanged: (v) => widget.draft.titleEn = v,
// //             decoration: const InputDecoration(
// //               labelText: 'Pack title (English)*',
// //               hintText: 'e.g. Wild Friday Night',
// //             ),
// //             textCapitalization: TextCapitalization.words,
// //           ).animate(delay: 60.ms).fadeIn(),

// //           const SizedBox(height: 16),

// //           TextFormField(
// //             controller: _descCtrl,
// //             onChanged: (v) => widget.draft.descriptionEn = v,
// //             maxLines: 3,
// //             maxLength: 500,
// //             decoration: const InputDecoration(
// //               labelText: 'Description (optional)',
// //               counterText: '',
// //             ),
// //           ).animate(delay: 80.ms).fadeIn(),

// //           const SizedBox(height: 16),

// //           // Game type
// //           DropdownButtonFormField<String>(
// //             value: widget.draft.gameType,
// //             decoration: const InputDecoration(labelText: 'Game type'),
// //             items: const [
// //               DropdownMenuItem(
// //                 value: 'truth_or_dare',
// //                 child: Text('🎯 Truth or Dare'),
// //               ),
// //               DropdownMenuItem(
// //                 value: 'never_have_i_ever',
// //                 child: Text('🍹 Never Have I Ever'),
// //               ),
// //               DropdownMenuItem(value: 'meme_game', child: Text('😂 Meme Game')),
// //             ],
// //             onChanged: (v) => setState(() {
// //               widget.draft.gameType = v ?? 'truth_or_dare';
// //               widget.draft.categoryId =
// //                   null; // reset category when game changes
// //             }),
// //           ).animate(delay: 100.ms).fadeIn(),

// //           const SizedBox(height: 16),

// //           // Category picker
// //           _CategoryPicker(
// //             gameType: widget.draft.gameType,
// //             selectedId: widget.draft.categoryId,
// //             onSelected: (id) => setState(() => widget.draft.categoryId = id),
// //           ).animate(delay: 110.ms).fadeIn(),

// //           const SizedBox(height: 16),

// //           // Price
// //           Row(
// //             children: [
// //               Expanded(
// //                 child: TextFormField(
// //                   initialValue: widget.draft.priceMru.toString(),
// //                   keyboardType: TextInputType.number,
// //                   decoration: const InputDecoration(
// //                     labelText: 'Price (MRU)',
// //                     hintText: '0 for free',
// //                     suffixText: 'MRU',
// //                   ),
// //                   onChanged: (v) =>
// //                       widget.draft.priceMru = int.tryParse(v) ?? 0,
// //                 ),
// //               ),
// //               const SizedBox(width: 12),
// //               Row(
// //                 children: [
// //                   Text(
// //                     'Spicy 🌶️',
// //                     style: Theme.of(context).textTheme.bodyMedium,
// //                   ),
// //                   const SizedBox(width: 8),
// //                   Switch(
// //                     value: widget.draft.allowSpicy,
// //                     onChanged: (v) =>
// //                         setState(() => widget.draft.allowSpicy = v),
// //                   ),
// //                 ],
// //               ),
// //             ],
// //           ).animate(delay: 120.ms).fadeIn(),

// //           const SizedBox(height: 32),

// //           JButton(
// //             label: 'Continue →',
// //             onPressed: widget.draft.hasTitle ? widget.onNext : null,
// //             icon: Icons.arrow_forward_rounded,
// //           ).animate(delay: 140.ms).fadeIn(),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // ── Step 2: Cover ─────────────────────────────────────────────────────────────
// // class _CoverStep extends StatefulWidget {
// //   const _CoverStep({
// //     required this.draft,
// //     required this.onNext,
// //     required this.onBack,
// //   });
// //   final PackDraft draft;
// //   final VoidCallback onNext;
// //   final VoidCallback onBack;

// //   @override
// //   State<_CoverStep> createState() => _CoverStepState();
// // }

// // class _CoverStepState extends State<_CoverStep> {
// //   bool _isUploading = false;

// //   Future<void> _pickAndUpload() async {
// //     final picker = ImagePicker();
// //     final picked = await picker.pickImage(
// //       source: ImageSource.gallery,
// //       maxWidth: 1024,
// //       maxHeight: 1024,
// //       imageQuality: 85,
// //     );
// //     if (picked == null) return;

// //     setState(() => _isUploading = true);
// //     try {
// //       final url = await PackUploadService.instance.uploadCoverImage(
// //         File(picked.path),
// //       );
// //       setState(() {
// //         widget.draft.coverImagePath = picked.path;
// //         widget.draft.coverImageUrl = url;
// //         _isUploading = false;
// //       });
// //     } catch (e) {
// //       setState(() => _isUploading = false);
// //       if (mounted) context.showErrorSnackBar('Upload failed: $e');
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;

// //     return Padding(
// //       padding: const EdgeInsets.all(24),
// //       child: Column(
// //         children: [
// //           Text(
// //             'Cover image',
// //             style: theme.textTheme.titleLarge?.copyWith(
// //               fontWeight: FontWeight.w700,
// //             ),
// //           ).animate().fadeIn(),
// //           const SizedBox(height: 8),
// //           Text(
// //             'Add an attractive cover to increase pack visibility.',
// //             style: theme.textTheme.bodyMedium?.copyWith(
// //               color: theme.colorScheme.onSurfaceVariant,
// //             ),
// //           ).animate(delay: 40.ms).fadeIn(),

// //           const SizedBox(height: 32),

// //           // Cover preview
// //           GestureDetector(
// //                 onTap: _isUploading ? null : _pickAndUpload,
// //                 child: Container(
// //                   width: 220,
// //                   height: 220,
// //                   decoration: BoxDecoration(
// //                     color: theme.colorScheme.surfaceContainerHighest,
// //                     borderRadius: BorderRadius.circular(20),
// //                     border: Border.all(
// //                       color: theme.colorScheme.outline,
// //                       width: 2,
// //                       strokeAlign: BorderSide.strokeAlignOutside,
// //                     ),
// //                   ),
// //                   child: _isUploading
// //                       ? const Center(child: CircularProgressIndicator())
// //                       : widget.draft.coverImagePath != null
// //                       ? ClipRRect(
// //                           borderRadius: BorderRadius.circular(18),
// //                           child: Image.file(
// //                             File(widget.draft.coverImagePath!),
// //                             fit: BoxFit.cover,
// //                           ),
// //                         )
// //                       : Column(
// //                           mainAxisAlignment: MainAxisAlignment.center,
// //                           children: [
// //                             Icon(
// //                               Icons.add_photo_alternate_outlined,
// //                               size: 48,
// //                               color: theme.colorScheme.onSurfaceVariant,
// //                             ),
// //                             const SizedBox(height: 8),
// //                             Text(
// //                               'Tap to add cover',
// //                               style: theme.textTheme.bodyMedium?.copyWith(
// //                                 color: theme.colorScheme.onSurfaceVariant,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                 ),
// //               )
// //               .animate(delay: 80.ms)
// //               .fadeIn()
// //               .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

// //           const Spacer(),

// //           Row(
// //             children: [
// //               Expanded(
// //                 child: OutlinedButton(
// //                   onPressed: widget.onBack,
// //                   child: const Text('Back'),
// //                 ),
// //               ),
// //               const SizedBox(width: 12),
// //               Expanded(
// //                 child: JButton(
// //                   label: 'Continue →',
// //                   onPressed: widget.draft.coverImageUrl != null
// //                       ? widget.onNext
// //                       : null,
// //                 ),
// //               ),
// //             ],
// //           ).animate(delay: 120.ms).fadeIn(),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // ── Step 3: Cards ─────────────────────────────────────────────────────────────

// // String _cardTypeEmoji(CardType t) => switch (t) {
// //   CardType.truth => '🤔',
// //   CardType.dare => '🔥',
// //   CardType.statement => '🍹',
// //   CardType.prompt => '😂',
// // };

// // String _cardTypeLabel(CardType t) => switch (t) {
// //   CardType.truth => 'Truth',
// //   CardType.dare => 'Dare',
// //   CardType.statement => 'Statement',
// //   CardType.prompt => 'Prompt',
// // };

// // Color _cardTypeColor(CardType t) => switch (t) {
// //   CardType.truth => AppColors.truthColor,
// //   CardType.dare => AppColors.dareColor,
// //   CardType.statement => AppColors.tealGreen,
// //   CardType.prompt => AppColors.purple,
// // };

// // class _CardsStep extends StatefulWidget {
// //   const _CardsStep({
// //     required this.draft,
// //     required this.packId,
// //     required this.onNext,
// //     required this.onBack,
// //   });
// //   final PackDraft draft;
// //   final String? packId;
// //   final VoidCallback onNext;
// //   final VoidCallback onBack;

// //   @override
// //   State<_CardsStep> createState() => _CardsStepState();
// // }

// // class _CardsStepState extends State<_CardsStep> {
// //   final _contentCtrl = TextEditingController();
// //   late CardType _type;
// //   CardDifficulty _difficulty = CardDifficulty.mild;
// //   bool _isSaving = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     // Set default card type based on game type
// //     _type = _defaultTypeForGame(widget.draft.gameType);
// //   }

// //   CardType _defaultTypeForGame(String gameType) {
// //     switch (gameType) {
// //       case 'never_have_i_ever':
// //         return CardType.statement;
// //       case 'meme_game':
// //         return CardType.prompt;
// //       default:
// //         return CardType.truth; // truth_or_dare
// //     }
// //   }

// //   List<(CardType, String, Color)> _typesForGame(String gameType) {
// //     switch (gameType) {
// //       case 'never_have_i_ever':
// //         return [(CardType.statement, 'Statement 🍹', AppColors.tealGreen)];
// //       case 'meme_game':
// //         return [(CardType.prompt, 'Prompt 😂', AppColors.purple)];
// //       default:
// //         return [
// //           (CardType.truth, 'Truth 🤔', AppColors.truthColor),
// //           (CardType.dare, 'Dare 🔥', AppColors.dareColor),
// //         ];
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     _contentCtrl.dispose();
// //     super.dispose();
// //   }

// //   void _addCard() {
// //     final text = _contentCtrl.text.trim();
// //     if (text.isEmpty) return;
// //     setState(() {
// //       widget.draft.cards.add(
// //         CardDraft(contentEn: text, type: _type, difficulty: _difficulty),
// //       );
// //       _contentCtrl.clear();
// //     });
// //   }

// //   Future<void> _saveAndContinue() async {
// //     if (widget.packId == null) return;
// //     if (widget.draft.cards.isEmpty) return;

// //     setState(() => _isSaving = true);
// //     try {
// //       await PackRepository.instance.addCards(
// //         widget.packId!,
// //         widget.draft.cards,
// //       );
// //       widget.onNext();
// //     } catch (e) {
// //       if (mounted) context.showErrorSnackBar('Failed to save cards: $e');
// //     } finally {
// //       setState(() => _isSaving = false);
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     final cards = widget.draft.cards;

// //     return Column(
// //       children: [
// //         // Card input area
// //         Padding(
// //           padding: const EdgeInsets.all(16),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Row(
// //                 children: [
// //                   Text(
// //                     '${cards.length} / 20+ cards',
// //                     style: theme.textTheme.titleSmall?.copyWith(
// //                       fontWeight: FontWeight.w700,
// //                     ),
// //                   ),
// //                   const Spacer(),
// //                   Text(
// //                     cards.length < 20
// //                         ? '${20 - cards.length} more needed'
// //                         : '✅ Minimum reached',
// //                     style: TextStyle(
// //                       fontSize: 12,
// //                       color: cards.length >= 20
// //                           ? AppColors.successGreen
// //                           : AppColors.warningAmber,
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(height: 8),

// //               // Type + difficulty selectors — adapts to game type
// //               Row(
// //                 children: [
// //                   ..._typesForGame(widget.draft.gameType).map((t) {
// //                     final (type, label, color) = t;
// //                     return Padding(
// //                       padding: const EdgeInsets.only(right: 8),
// //                       child: _TypeButton(
// //                         label: label,
// //                         isSelected: _type == type,
// //                         color: color,
// //                         onTap: () => setState(() => _type = type),
// //                       ),
// //                     );
// //                   }),
// //                   const SizedBox(width: 4),
// //                   DropdownButton<CardDifficulty>(
// //                     value: _difficulty,
// //                     underline: const SizedBox.shrink(),
// //                     items: CardDifficulty.values
// //                         .map(
// //                           (d) =>
// //                               DropdownMenuItem(value: d, child: Text(d.name)),
// //                         )
// //                         .toList(),
// //                     onChanged: (d) => setState(() => _difficulty = d!),
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(height: 8),

// //               Row(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Expanded(
// //                     child: TextField(
// //                       controller: _contentCtrl,
// //                       maxLines: 2,
// //                       decoration: const InputDecoration(
// //                         hintText: 'Card content…',
// //                         isDense: true,
// //                       ),
// //                       onSubmitted: (_) => _addCard(),
// //                     ),
// //                   ),
// //                   const SizedBox(width: 8),
// //                   IconButton.filled(
// //                     onPressed: _addCard,
// //                     icon: const Icon(Icons.add_rounded),
// //                     style: IconButton.styleFrom(
// //                       backgroundColor: AppColors.navyBlue,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ],
// //           ),
// //         ),

// //         const Divider(height: 1),

// //         // Card list
// //         Expanded(
// //           child: cards.isEmpty
// //               ? const Center(child: Text('Add your first card above!'))
// //               : ListView.separated(
// //                   padding: const EdgeInsets.all(12),
// //                   itemCount: cards.length,
// //                   separatorBuilder: (_, __) => const SizedBox(height: 6),
// //                   itemBuilder: (_, i) {
// //                     final card = cards[i];
// //                     final color = _cardTypeColor(card.type);
// //                     return Container(
// //                       padding: const EdgeInsets.all(10),
// //                       decoration: BoxDecoration(
// //                         color: color.withOpacity(0.06),
// //                         borderRadius: BorderRadius.circular(8),
// //                         border: Border.all(color: color.withOpacity(0.2)),
// //                       ),
// //                       child: Row(
// //                         children: [
// //                           Container(
// //                             padding: const EdgeInsets.symmetric(
// //                               horizontal: 6,
// //                               vertical: 2,
// //                             ),
// //                             decoration: BoxDecoration(
// //                               color: color.withOpacity(0.15),
// //                               borderRadius: BorderRadius.circular(4),
// //                             ),
// //                             child: Row(
// //                               mainAxisSize: MainAxisSize.min,
// //                               children: [
// //                                 Text(
// //                                   _cardTypeEmoji(card.type),
// //                                   style: const TextStyle(fontSize: 12),
// //                                 ),
// //                                 const SizedBox(width: 3),
// //                                 Text(
// //                                   _cardTypeLabel(card.type),
// //                                   style: TextStyle(
// //                                     fontSize: 11,
// //                                     fontWeight: FontWeight.w700,
// //                                     color: color,
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                           const SizedBox(width: 8),
// //                           Expanded(
// //                             child: Text(
// //                               card.contentEn,
// //                               style: theme.textTheme.bodySmall,
// //                             ),
// //                           ),
// //                           IconButton(
// //                             icon: const Icon(Icons.close_rounded, size: 16),
// //                             onPressed: () => setState(() => cards.removeAt(i)),
// //                             visualDensity: VisualDensity.compact,
// //                             padding: EdgeInsets.zero,
// //                           ),
// //                         ],
// //                       ),
// //                     ).animate(delay: (i * 15).ms).fadeIn();
// //                   },
// //                 ),
// //         ),

// //         // Bottom bar
// //         Padding(
// //           padding: const EdgeInsets.all(16),
// //           child: Row(
// //             children: [
// //               Expanded(
// //                 child: OutlinedButton(
// //                   onPressed: widget.onBack,
// //                   child: const Text('Back'),
// //                 ),
// //               ),
// //               const SizedBox(width: 12),
// //               Expanded(
// //                 child: JButton(
// //                   label: 'Continue →',
// //                   onPressed: cards.length >= 20 ? _saveAndContinue : null,
// //                   isLoading: _isSaving,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }

// // class _TypeButton extends StatelessWidget {
// //   const _TypeButton({
// //     required this.label,
// //     required this.isSelected,
// //     required this.color,
// //     required this.onTap,
// //   });
// //   final String label;
// //   final bool isSelected;
// //   final Color color;
// //   final VoidCallback onTap;

// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// //         decoration: BoxDecoration(
// //           color: isSelected ? color : color.withOpacity(0.08),
// //           borderRadius: BorderRadius.circular(8),
// //         ),
// //         child: Text(
// //           label,
// //           style: TextStyle(
// //             color: isSelected ? Colors.white : color,
// //             fontWeight: FontWeight.w700,
// //             fontSize: 13,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ── Step 4: Publish ───────────────────────────────────────────────────────────
// // // ── Step 4 (Meme only): Reactions ─────────────────────────────────────────────
// // class _ReactionsStep extends StatefulWidget {
// //   const _ReactionsStep({
// //     required this.draft,
// //     required this.packId,
// //     required this.onNext,
// //     required this.onBack,
// //   });
// //   final PackDraft draft;
// //   final String? packId;
// //   final VoidCallback onNext;
// //   final VoidCallback onBack;

// //   @override
// //   State<_ReactionsStep> createState() => _ReactionsStepState();
// // }

// // class _ReactionsStepState extends State<_ReactionsStep> {
// //   bool _isSaving = false;

// //   Future<void> _pickAndUpload() async {
// //     if (widget.draft.reactionImageUrls.length >= 30) {
// //       context.showErrorSnackBar('Maximum 30 reaction images reached');
// //       return;
// //     }
// //     final picker = ImagePicker();
// //     final picked = await picker.pickMultiImage(imageQuality: 85);
// //     if (picked.isEmpty || !mounted) return;

// //     final remaining = 30 - widget.draft.reactionImageUrls.length;
// //     final toUpload = picked.take(remaining).toList();

// //     setState(() => _isSaving = true);
// //     try {
// //       for (final xfile in toUpload) {
// //         final file = File(xfile.path);
// //         final url = await PackUploadService.instance.uploadCardImage(file);
// //         setState(() => widget.draft.reactionImageUrls.add(url));
// //       }
// //     } catch (e) {
// //       if (mounted) context.showErrorSnackBar('Upload failed: $e');
// //     } finally {
// //       if (mounted) setState(() => _isSaving = false);
// //     }
// //   }

// //   Future<void> _saveAndContinue() async {
// //     if (widget.packId == null) {
// //       widget.onNext();
// //       return;
// //     }
// //     setState(() => _isSaving = true);
// //     try {
// //       await PackRepository.instance.savePackReactions(
// //         widget.packId!,
// //         widget.draft.reactionImageUrls,
// //       );
// //       widget.onNext();
// //     } catch (e) {
// //       if (mounted) context.showErrorSnackBar('Failed to save reactions: $e');
// //     } finally {
// //       if (mounted) setState(() => _isSaving = false);
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     final reactions = widget.draft.reactionImageUrls;

// //     return Column(
// //       children: [
// //         Padding(
// //           padding: const EdgeInsets.all(16),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Row(
// //                 children: [
// //                   Text(
// //                     '${reactions.length} / 30 reaction images',
// //                     style: theme.textTheme.titleSmall?.copyWith(
// //                       fontWeight: FontWeight.w700,
// //                     ),
// //                   ),
// //                   const Spacer(),
// //                   Text(
// //                     reactions.isEmpty
// //                         ? 'Optional — skip to use defaults'
// //                         : '${30 - reactions.length} slots remaining',
// //                     style: TextStyle(
// //                       fontSize: 12,
// //                       color: theme.colorScheme.onSurfaceVariant,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(height: 4),
// //               Text(
// //                 'Players will use these images as reactions during the game. '
// //                 'Add up to 30. If none, default stickers are used.',
// //                 style: theme.textTheme.bodySmall?.copyWith(
// //                   color: theme.colorScheme.onSurfaceVariant,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),

// //         Expanded(
// //           child: reactions.isEmpty
// //               ? Center(
// //                   child: Column(
// //                     mainAxisSize: MainAxisSize.min,
// //                     children: [
// //                       Icon(
// //                         Icons.image_outlined,
// //                         size: 64,
// //                         color: theme.colorScheme.onSurfaceVariant,
// //                       ),
// //                       const SizedBox(height: 8),
// //                       Text(
// //                         'No reaction images yet',
// //                         style: theme.textTheme.bodyMedium?.copyWith(
// //                           color: theme.colorScheme.onSurfaceVariant,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 )
// //               : GridView.builder(
// //                   padding: const EdgeInsets.symmetric(horizontal: 12),
// //                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //                     crossAxisCount: 4,
// //                     mainAxisSpacing: 8,
// //                     crossAxisSpacing: 8,
// //                     childAspectRatio: 1,
// //                   ),
// //                   itemCount: reactions.length,
// //                   itemBuilder: (_, i) {
// //                     return Stack(
// //                       children: [
// //                         ClipRRect(
// //                           borderRadius: BorderRadius.circular(8),
// //                           child: Image.network(
// //                             reactions[i],
// //                             width: double.infinity,
// //                             height: double.infinity,
// //                             fit: BoxFit.cover,
// //                             errorBuilder: (_, __, ___) =>
// //                                 const Icon(Icons.broken_image),
// //                           ),
// //                         ),
// //                         Positioned(
// //                           top: 2,
// //                           right: 2,
// //                           child: GestureDetector(
// //                             onTap: () => setState(() => reactions.removeAt(i)),
// //                             child: Container(
// //                               decoration: const BoxDecoration(
// //                                 color: Colors.black54,
// //                                 shape: BoxShape.circle,
// //                               ),
// //                               child: const Icon(
// //                                 Icons.close_rounded,
// //                                 color: Colors.white,
// //                                 size: 16,
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     );
// //                   },
// //                 ),
// //         ),

// //         Padding(
// //           padding: const EdgeInsets.all(16),
// //           child: Column(
// //             children: [
// //               if (reactions.length < 30)
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: OutlinedButton.icon(
// //                     onPressed: _isSaving ? null : _pickAndUpload,
// //                     icon: _isSaving
// //                         ? const SizedBox(
// //                             width: 16,
// //                             height: 16,
// //                             child: CircularProgressIndicator(strokeWidth: 2),
// //                           )
// //                         : const Icon(Icons.add_photo_alternate_rounded),
// //                     label: Text(_isSaving ? 'Uploading...' : 'Add Images'),
// //                   ),
// //                 ),
// //               const SizedBox(height: 8),
// //               Row(
// //                 children: [
// //                   Expanded(
// //                     child: OutlinedButton(
// //                       onPressed: widget.onBack,
// //                       child: const Text('Back'),
// //                     ),
// //                   ),
// //                   const SizedBox(width: 12),
// //                   Expanded(
// //                     child: FilledButton(
// //                       onPressed: _isSaving ? null : _saveAndContinue,
// //                       child: Text(reactions.isEmpty ? 'Skip' : 'Continue'),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ],
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }

// // // ── Step 4/5: Publish ──────────────────────────────────────────────────────────
// // class _PublishStep extends StatelessWidget {
// //   const _PublishStep({
// //     required this.draft,
// //     required this.packId,
// //     required this.isSaving,
// //     required this.onPublish,
// //     required this.onBack,
// //   });
// //   final PackDraft draft;
// //   final String? packId;
// //   final bool isSaving;
// //   final VoidCallback onPublish;
// //   final VoidCallback onBack;

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     final canPublish = draft.canPublish && packId != null;

// //     return SingleChildScrollView(
// //       padding: const EdgeInsets.all(24),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(
// //             'Ready to publish?',
// //             style: theme.textTheme.headlineSmall?.copyWith(
// //               fontWeight: FontWeight.w800,
// //             ),
// //           ).animate().fadeIn(),
// //           const SizedBox(height: 8),
// //           Text(
// //             'Review your pack before submitting for moderation.',
// //             style: theme.textTheme.bodyMedium?.copyWith(
// //               color: theme.colorScheme.onSurfaceVariant,
// //             ),
// //           ).animate(delay: 40.ms).fadeIn(),

// //           const SizedBox(height: 24),

// //           // Summary card
// //           Container(
// //             padding: const EdgeInsets.all(18),
// //             decoration: BoxDecoration(
// //               color: theme.colorScheme.surfaceContainerHighest,
// //               borderRadius: BorderRadius.circular(16),
// //             ),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 _SummaryRow(label: 'Title', value: draft.titleEn, icon: '📦'),
// //                 _SummaryRow(
// //                   label: 'Game type',
// //                   value: draft.gameType,
// //                   icon: '🎮',
// //                 ),
// //                 _SummaryRow(
// //                   label: 'Cards',
// //                   value:
// //                       '${draft.cards.length} (${draft.truthCount}T + ${draft.dareCount}D)',
// //                   icon: '🃏',
// //                 ),
// //                 _SummaryRow(
// //                   label: 'Price',
// //                   value: draft.priceMru == 0 ? 'Free' : '${draft.priceMru} MRU',
// //                   icon: '💰',
// //                 ),
// //                 _SummaryRow(
// //                   label: 'Spicy content',
// //                   value: draft.allowSpicy ? 'Allowed' : 'No',
// //                   icon: '🌶',
// //                 ),
// //               ],
// //             ),
// //           ).animate(delay: 80.ms).fadeIn(),

// //           const SizedBox(height: 16),

// //           // Rules reminder
// //           Container(
// //             padding: const EdgeInsets.all(14),
// //             decoration: BoxDecoration(
// //               color: AppColors.infoBlue.withOpacity(0.08),
// //               borderRadius: BorderRadius.circular(12),
// //               border: Border.all(color: AppColors.infoBlue.withOpacity(0.25)),
// //             ),
// //             child: const Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   '📋 Important rules:',
// //                   style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
// //                 ),
// //                 SizedBox(height: 6),
// //                 Text(
// //                   '• Packs cannot be edited after publishing.\n'
// //                   '• You must purchase your own pack to use it in games.\n'
// //                   '• Moderation review takes 1–3 business days.',
// //                   style: TextStyle(fontSize: 13, height: 1.6),
// //                 ),
// //               ],
// //             ),
// //           ).animate(delay: 100.ms).fadeIn(),

// //           const SizedBox(height: 32),

// //           Row(
// //             children: [
// //               Expanded(
// //                 child: OutlinedButton(
// //                   onPressed: onBack,
// //                   child: const Text('Back'),
// //                 ),
// //               ),
// //               const SizedBox(width: 12),
// //               Expanded(
// //                 child: JButton(
// //                   label: 'Submit for Review',
// //                   onPressed: canPublish ? onPublish : null,
// //                   isLoading: isSaving,
// //                   icon: Icons.send_rounded,
// //                 ),
// //               ),
// //             ],
// //           ).animate(delay: 120.ms).fadeIn(),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _SummaryRow extends StatelessWidget {
// //   const _SummaryRow({
// //     required this.label,
// //     required this.value,
// //     required this.icon,
// //   });
// //   final String label;
// //   final String value;
// //   final String icon;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 4),
// //       child: Row(
// //         children: [
// //           Text(icon, style: const TextStyle(fontSize: 16)),
// //           const SizedBox(width: 10),
// //           Text(
// //             '$label: ',
// //             style: context.textTheme.bodySmall?.copyWith(
// //               color: context.colorScheme.onSurfaceVariant,
// //             ),
// //           ),
// //           Expanded(
// //             child: Text(
// //               value,
// //               style: context.textTheme.bodySmall?.copyWith(
// //                 fontWeight: FontWeight.w600,
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/buttons/j_button.dart';
// import '../../data/pack_repository.dart';
// import '../../data/pack_upload_service.dart';
// import '../../data/pack_upload_service.dart';
// import '../../domain/pack_entity.dart';
// import '../pack_provider.dart';

// /// Multi-step pack creation flow.
// /// Steps: 1. Info  2. Cover  3. Cards  4. Review & Publish
// class CreatePackScreen extends StatefulWidget {
//   const CreatePackScreen({super.key, this.existingPackId, this.existingPack});
//   final String? existingPackId;
//   final PackEntity? existingPack;

//   @override
//   State<CreatePackScreen> createState() => _CreatePackScreenState();
// }

// class _CreatePackScreenState extends State<CreatePackScreen> {
//   late final PackDraft _draft;
//   int _step = 0;
//   bool _isSaving = false;
//   late String? _savedPackId;

//   static const _steps = ['Info', 'Cover', 'Cards', 'Publish'];

//   @override
//   void initState() {
//     super.initState();
//     _savedPackId = widget.existingPackId;
//     // Pre-fill draft from existing pack
//     final p = widget.existingPack;
//     if (p != null) {
//       _draft = PackDraft(
//         titleEn: p.titleFor('en'),
//         titleAr: p.titleFor('ar'),
//         titleFr: p.titleFor('fr'),
//         descriptionEn: p.descriptionFor('en'),
//         gameType: p.gameType,
//         language: p.language,
//         priceMru: p.priceMru,
//         categoryId: p.categoryId,
//         allowSpicy: p.hasSpicy,
//         coverImageUrl: p.coverImageUrl,
//         cards: [],
//       );
//       // Jump to cards step if basic info already saved
//       _step = _savedPackId != null ? 2 : 0;
//     } else {
//       _draft = PackDraft();
//     }
//   }

//   // static const _steps     = ['Info', 'Cover', 'Cards', 'Publish'];
//   static const _stepsMeme = ['Info', 'Cover', 'Cards', 'Reactions', 'Publish'];
//   List<String> get _activeSteps =>
//       _draft.gameType == 'meme_game' ? _stepsMeme : _steps;

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       onPopInvokedWithResult: (_, __) {
//         if (mounted) context.read<PackProvider>().loadCreatedPacks();
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text('Create Pack — ${_activeSteps[_step]}'),
//           bottom: PreferredSize(
//             preferredSize: const Size.fromHeight(4),
//             child: LinearProgressIndicator(
//               value: (_step + 1) / _activeSteps.length,
//               minHeight: 4,
//               color: AppColors.navyBlue,
//               backgroundColor: context.colorScheme.surfaceContainerHighest,
//             ),
//           ),
//         ),
//         body: AnimatedSwitcher(
//           duration: const Duration(milliseconds: 250),
//           child: KeyedSubtree(
//             key: ValueKey(_step),
//             child: switch (_step) {
//               0 => _InfoStep(draft: _draft, onNext: _nextStep),
//               1 => _CoverStep(
//                 draft: _draft,
//                 onNext: _nextStep,
//                 onBack: _prevStep,
//               ),
//               2 => _CardsStep(
//                 draft: _draft,
//                 packId: _savedPackId,
//                 onNext: _nextStep,
//                 onBack: _prevStep,
//               ),
//               3 when _draft.gameType == 'meme_game' => _ReactionsStep(
//                 draft: _draft,
//                 packId: _savedPackId,
//                 onNext: _nextStep,
//                 onBack: _prevStep,
//               ),
//               _ => _PublishStep(
//                 draft: _draft,
//                 packId: _savedPackId,
//                 isSaving: _isSaving,
//                 onPublish: _submit,
//                 onBack: _prevStep,
//               ),
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   void _nextStep() {
//     if (_step == 0 && _savedPackId == null) {
//       _saveDraft();
//     } else {
//       setState(() => _step = (_step + 1).clamp(0, _activeSteps.length - 1));
//     }
//   }

//   void _prevStep() =>
//       setState(() => _step = (_step - 1).clamp(0, _activeSteps.length - 1));

//   Future<void> _saveDraft() async {
//     setState(() => _isSaving = true);
//     try {
//       final packs = context.read<PackProvider>();
//       final userId = packs.currentUserId;
//       if (userId == null) throw Exception('Not logged in');

//       PackEntity pack;
//       if (_savedPackId == null) {
//         pack = await PackRepository.instance.createPackDraft(_draft, userId);
//         _savedPackId = pack.id;
//       } else {
//         pack = await PackRepository.instance.updatePackDraft(
//           _savedPackId!,
//           _draft,
//         );
//       }
//       setState(() {
//         _isSaving = false;
//         _step = 1;
//       });
//     } catch (e) {
//       setState(() => _isSaving = false);
//       if (mounted) context.showErrorSnackBar('Failed to save: $e');
//     }
//   }

//   Future<void> _submit() async {
//     if (_savedPackId == null) return;
//     setState(() => _isSaving = true);
//     try {
//       await PackRepository.instance.submitForReview(_savedPackId!);
//       if (mounted) {
//         context.read<PackProvider>().loadCreatedPacks();
//         context.showSnackBar(
//           'Pack submitted for review! You\'ll be notified when approved.',
//         );
//         context.pop();
//       }
//     } catch (e) {
//       setState(() => _isSaving = false);
//       if (mounted) context.showErrorSnackBar('Submission failed: $e');
//     }
//   }
// }

// // ── Step 1: Info ──────────────────────────────────────────────────────────────

// // ── Category picker ───────────────────────────────────────────────────────────
// class _CategoryPicker extends StatefulWidget {
//   const _CategoryPicker({
//     required this.gameType,
//     required this.selectedId,
//     required this.onSelected,
//   });
//   final String gameType;
//   final String? selectedId;
//   final ValueChanged<String?> onSelected;
//   @override
//   State<_CategoryPicker> createState() => _CategoryPickerState();
// }

// class _CategoryPickerState extends State<_CategoryPicker> {
//   List<PackCategory>? _cats;
//   bool _loading = false;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   @override
//   void didUpdateWidget(_CategoryPicker old) {
//     super.didUpdateWidget(old);
//     if (old.gameType != widget.gameType) _load();
//   }

//   Future<void> _load() async {
//     setState(() {
//       _loading = true;
//       _cats = null;
//     });
//     try {
//       final all = await PackRepository.instance.getCategories();
//       if (mounted)
//         setState(() {
//           _cats = all;
//           _loading = false;
//         });
//     } catch (_) {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) return const LinearProgressIndicator();
//     final cats = _cats;
//     if (cats == null || cats.isEmpty) return const SizedBox.shrink();
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Category (optional)',
//           style: Theme.of(context).textTheme.labelMedium?.copyWith(
//             color: Theme.of(context).colorScheme.onSurfaceVariant,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Wrap(
//           spacing: 8,
//           runSpacing: 6,
//           children: [
//             // None option
//             ChoiceChip(
//               label: const Text('None'),
//               selected: widget.selectedId == null,
//               onSelected: (_) => widget.onSelected(null),
//             ),
//             ...cats.map(
//               (c) => ChoiceChip(
//                 avatar: Text(c.icon),
//                 label: Text(c.nameJson['en'] as String? ?? c.slug),
//                 selected: widget.selectedId == c.id,
//                 onSelected: (_) =>
//                     widget.onSelected(widget.selectedId == c.id ? null : c.id),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// class _InfoStep extends StatefulWidget {
//   const _InfoStep({required this.draft, required this.onNext});
//   final PackDraft draft;
//   final VoidCallback onNext;

//   @override
//   State<_InfoStep> createState() => _InfoStepState();
// }

// class _InfoStepState extends State<_InfoStep> {
//   late final TextEditingController _titleCtrl;
//   late final TextEditingController _descCtrl;

//   @override
//   void initState() {
//     super.initState();
//     _titleCtrl = TextEditingController(text: widget.draft.titleEn);
//     _descCtrl = TextEditingController(text: widget.draft.descriptionEn);
//   }

//   @override
//   void dispose() {
//     _titleCtrl.dispose();
//     _descCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Pack information',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.w700,
//             ),
//           ).animate().fadeIn(),
//           const SizedBox(height: 24),

//           TextFormField(
//             controller: _titleCtrl,
//             onChanged: (v) => widget.draft.titleEn = v,
//             decoration: const InputDecoration(
//               labelText: 'Pack title (English)*',
//               hintText: 'e.g. Wild Friday Night',
//             ),
//             textCapitalization: TextCapitalization.words,
//           ).animate(delay: 60.ms).fadeIn(),

//           const SizedBox(height: 16),

//           TextFormField(
//             controller: _descCtrl,
//             onChanged: (v) => widget.draft.descriptionEn = v,
//             maxLines: 3,
//             maxLength: 500,
//             decoration: const InputDecoration(
//               labelText: 'Description (optional)',
//               counterText: '',
//             ),
//           ).animate(delay: 80.ms).fadeIn(),

//           const SizedBox(height: 16),

//           // Game type
//           DropdownButtonFormField<String>(
//             value: widget.draft.gameType,
//             decoration: const InputDecoration(labelText: 'Game type'),
//             items: const [
//               DropdownMenuItem(
//                 value: 'truth_or_dare',
//                 child: Text('🎯 Truth or Dare'),
//               ),
//               DropdownMenuItem(
//                 value: 'never_have_i_ever',
//                 child: Text('🍹 Never Have I Ever'),
//               ),
//               DropdownMenuItem(value: 'meme_game', child: Text('😂 Meme Game')),
//             ],
//             onChanged: (v) => setState(() {
//               widget.draft.gameType = v ?? 'truth_or_dare';
//               widget.draft.categoryId =
//                   null; // reset category when game changes
//             }),
//           ).animate(delay: 100.ms).fadeIn(),

//           const SizedBox(height: 16),

//           // Category picker
//           _CategoryPicker(
//             gameType: widget.draft.gameType,
//             selectedId: widget.draft.categoryId,
//             onSelected: (id) => setState(() => widget.draft.categoryId = id),
//           ).animate(delay: 110.ms).fadeIn(),

//           const SizedBox(height: 16),

//           // Price
//           Row(
//             children: [
//               Expanded(
//                 child: TextFormField(
//                   initialValue: widget.draft.priceMru.toString(),
//                   keyboardType: TextInputType.number,
//                   decoration: const InputDecoration(
//                     labelText: 'Price (MRU)',
//                     hintText: '0 for free',
//                     suffixText: 'MRU',
//                   ),
//                   onChanged: (v) =>
//                       widget.draft.priceMru = int.tryParse(v) ?? 0,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Row(
//                 children: [
//                   Text(
//                     'Spicy 🌶️',
//                     style: Theme.of(context).textTheme.bodyMedium,
//                   ),
//                   const SizedBox(width: 8),
//                   Switch(
//                     value: widget.draft.allowSpicy,
//                     onChanged: (v) =>
//                         setState(() => widget.draft.allowSpicy = v),
//                   ),
//                 ],
//               ),
//             ],
//           ).animate(delay: 120.ms).fadeIn(),

//           const SizedBox(height: 16),

//           // Min players
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Minimum players: \${widget.draft.minPlayers}',
//                 style: theme.textTheme.bodyMedium,
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'Who can play this pack?',
//                 style: theme.textTheme.bodySmall?.copyWith(
//                   color: theme.colorScheme.onSurfaceVariant,
//                 ),
//               ),
//               Slider(
//                 value: widget.draft.minPlayers.toDouble(),
//                 min: 2,
//                 max: 10,
//                 divisions: 8,
//                 label: '\${widget.draft.minPlayers} players',
//                 onChanged: (v) =>
//                     setState(() => widget.draft.minPlayers = v.round()),
//               ),
//             ],
//           ).animate(delay: 125.ms).fadeIn(),

//           const SizedBox(height: 32),

//           JButton(
//             label: 'Continue →',
//             onPressed: widget.draft.hasTitle ? widget.onNext : null,
//             icon: Icons.arrow_forward_rounded,
//           ).animate(delay: 140.ms).fadeIn(),
//         ],
//       ),
//     );
//   }
// }

// // ── Step 2: Cover ─────────────────────────────────────────────────────────────
// class _CoverStep extends StatefulWidget {
//   const _CoverStep({
//     required this.draft,
//     required this.onNext,
//     required this.onBack,
//   });
//   final PackDraft draft;
//   final VoidCallback onNext;
//   final VoidCallback onBack;

//   @override
//   State<_CoverStep> createState() => _CoverStepState();
// }

// class _CoverStepState extends State<_CoverStep> {
//   bool _isUploading = false;

//   Future<void> _pickAndUpload() async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(
//       source: ImageSource.gallery,
//       maxWidth: 1024,
//       maxHeight: 1024,
//       imageQuality: 85,
//     );
//     if (picked == null) return;

//     setState(() => _isUploading = true);
//     try {
//       final url = await PackUploadService.instance.uploadCoverImage(
//         File(picked.path),
//       );
//       setState(() {
//         widget.draft.coverImagePath = picked.path;
//         widget.draft.coverImageUrl = url;
//         _isUploading = false;
//       });
//     } catch (e) {
//       setState(() => _isUploading = false);
//       if (mounted) context.showErrorSnackBar('Upload failed: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;

//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         children: [
//           Text(
//             'Cover image',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.w700,
//             ),
//           ).animate().fadeIn(),
//           const SizedBox(height: 8),
//           Text(
//             'Add an attractive cover to increase pack visibility.',
//             style: theme.textTheme.bodyMedium?.copyWith(
//               color: theme.colorScheme.onSurfaceVariant,
//             ),
//           ).animate(delay: 40.ms).fadeIn(),

//           const SizedBox(height: 32),

//           // Cover preview
//           GestureDetector(
//                 onTap: _isUploading ? null : _pickAndUpload,
//                 child: Container(
//                   width: 220,
//                   height: 220,
//                   decoration: BoxDecoration(
//                     color: theme.colorScheme.surfaceContainerHighest,
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                       color: theme.colorScheme.outline,
//                       width: 2,
//                       strokeAlign: BorderSide.strokeAlignOutside,
//                     ),
//                   ),
//                   child: _isUploading
//                       ? const Center(child: CircularProgressIndicator())
//                       : widget.draft.coverImagePath != null
//                       ? ClipRRect(
//                           borderRadius: BorderRadius.circular(18),
//                           child: Image.file(
//                             File(widget.draft.coverImagePath!),
//                             fit: BoxFit.cover,
//                           ),
//                         )
//                       : Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.add_photo_alternate_outlined,
//                               size: 48,
//                               color: theme.colorScheme.onSurfaceVariant,
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Tap to add cover',
//                               style: theme.textTheme.bodyMedium?.copyWith(
//                                 color: theme.colorScheme.onSurfaceVariant,
//                               ),
//                             ),
//                           ],
//                         ),
//                 ),
//               )
//               .animate(delay: 80.ms)
//               .fadeIn()
//               .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

//           const Spacer(),

//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: widget.onBack,
//                   child: const Text('Back'),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: JButton(
//                   label: 'Continue →',
//                   onPressed: widget.draft.coverImageUrl != null
//                       ? widget.onNext
//                       : null,
//                 ),
//               ),
//             ],
//           ).animate(delay: 120.ms).fadeIn(),
//         ],
//       ),
//     );
//   }
// }

// // ── Step 3: Cards ─────────────────────────────────────────────────────────────

// String _cardTypeEmoji(CardType t) => switch (t) {
//   CardType.truth => '🤔',
//   CardType.dare => '🔥',
//   CardType.statement => '🍹',
//   CardType.prompt => '😂',
// };

// String _cardTypeLabel(CardType t) => switch (t) {
//   CardType.truth => 'Truth',
//   CardType.dare => 'Dare',
//   CardType.statement => 'Statement',
//   CardType.prompt => 'Prompt',
// };

// Color _cardTypeColor(CardType t) => switch (t) {
//   CardType.truth => AppColors.truthColor,
//   CardType.dare => AppColors.dareColor,
//   CardType.statement => AppColors.tealGreen,
//   CardType.prompt => AppColors.purple,
// };

// class _CardsStep extends StatefulWidget {
//   const _CardsStep({
//     required this.draft,
//     required this.packId,
//     required this.onNext,
//     required this.onBack,
//   });
//   final PackDraft draft;
//   final String? packId;
//   final VoidCallback onNext;
//   final VoidCallback onBack;

//   @override
//   State<_CardsStep> createState() => _CardsStepState();
// }

// class _CardsStepState extends State<_CardsStep> {
//   final _contentCtrl = TextEditingController();
//   late CardType _type;
//   CardDifficulty _difficulty = CardDifficulty.mild;
//   bool _isSaving = false;

//   @override
//   void initState() {
//     super.initState();
//     // Set default card type based on game type
//     _type = _defaultTypeForGame(widget.draft.gameType);
//   }

//   CardType _defaultTypeForGame(String gameType) {
//     switch (gameType) {
//       case 'never_have_i_ever':
//         return CardType.statement;
//       case 'meme_game':
//         return CardType.prompt;
//       default:
//         return CardType.truth; // truth_or_dare
//     }
//   }

//   List<(CardType, String, Color)> _typesForGame(String gameType) {
//     switch (gameType) {
//       case 'never_have_i_ever':
//         return [(CardType.statement, 'Statement 🍹', AppColors.tealGreen)];
//       case 'meme_game':
//         return [(CardType.prompt, 'Prompt 😂', AppColors.purple)];
//       default:
//         return [
//           (CardType.truth, 'Truth 🤔', AppColors.truthColor),
//           (CardType.dare, 'Dare 🔥', AppColors.dareColor),
//         ];
//     }
//   }

//   @override
//   void dispose() {
//     _contentCtrl.dispose();
//     super.dispose();
//   }

//   void _addCard() {
//     final text = _contentCtrl.text.trim();
//     if (text.isEmpty) return;
//     setState(() {
//       widget.draft.cards.add(
//         CardDraft(contentEn: text, type: _type, difficulty: _difficulty),
//       );
//       _contentCtrl.clear();
//     });
//   }

//   Future<void> _saveAndContinue() async {
//     if (widget.packId == null) return;
//     if (widget.draft.cards.isEmpty) return;

//     setState(() => _isSaving = true);
//     try {
//       await PackRepository.instance.addCards(
//         widget.packId!,
//         widget.draft.cards,
//       );
//       widget.onNext();
//     } catch (e) {
//       if (mounted) context.showErrorSnackBar('Failed to save cards: $e');
//     } finally {
//       setState(() => _isSaving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final cards = widget.draft.cards;

//     return Column(
//       children: [
//         // Card input area
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Text(
//                     '${cards.length} / 20+ cards',
//                     style: theme.textTheme.titleSmall?.copyWith(
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const Spacer(),
//                   Text(
//                     cards.length < 20
//                         ? '${20 - cards.length} more needed'
//                         : '✅ Minimum reached',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: cards.length >= 20
//                           ? AppColors.successGreen
//                           : AppColors.warningAmber,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),

//               // Type + difficulty selectors — adapts to game type
//               Row(
//                 children: [
//                   ..._typesForGame(widget.draft.gameType).map((t) {
//                     final (type, label, color) = t;
//                     return Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: _TypeButton(
//                         label: label,
//                         isSelected: _type == type,
//                         color: color,
//                         onTap: () => setState(() => _type = type),
//                       ),
//                     );
//                   }),
//                   const SizedBox(width: 4),
//                   DropdownButton<CardDifficulty>(
//                     value: _difficulty,
//                     underline: const SizedBox.shrink(),
//                     items: CardDifficulty.values
//                         .where(
//                           (d) =>
//                               d != CardDifficulty.spicy ||
//                               widget.draft.allowSpicy,
//                         )
//                         .map(
//                           (d) => DropdownMenuItem(
//                             value: d,
//                             child: Text(
//                               d == CardDifficulty.spicy ? '🌶 spicy' : d.name,
//                             ),
//                           ),
//                         )
//                         .toList(),
//                     onChanged: (d) => setState(() => _difficulty = d!),
//                   ),
//                   if (!widget.draft.allowSpicy)
//                     Padding(
//                       padding: const EdgeInsets.only(left: 4),
//                       child: Tooltip(
//                         message:
//                             'Enable spicy content in pack settings to add spicy cards',
//                         child: Icon(
//                           Icons.info_outline_rounded,
//                           size: 14,
//                           color: Theme.of(context).colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 8),

//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _contentCtrl,
//                       maxLines: 2,
//                       decoration: const InputDecoration(
//                         hintText: 'Card content…',
//                         isDense: true,
//                       ),
//                       onSubmitted: (_) => _addCard(),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   IconButton.filled(
//                     onPressed: _addCard,
//                     icon: const Icon(Icons.add_rounded),
//                     style: IconButton.styleFrom(
//                       backgroundColor: AppColors.navyBlue,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),

//         const Divider(height: 1),

//         // Card list
//         Expanded(
//           child: cards.isEmpty
//               ? const Center(child: Text('Add your first card above!'))
//               : ListView.separated(
//                   padding: const EdgeInsets.all(12),
//                   itemCount: cards.length,
//                   separatorBuilder: (_, __) => const SizedBox(height: 6),
//                   itemBuilder: (_, i) {
//                     final card = cards[i];
//                     final color = _cardTypeColor(card.type);
//                     return Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: color.withOpacity(0.06),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: color.withOpacity(0.2)),
//                       ),
//                       child: Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: color.withOpacity(0.15),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   _cardTypeEmoji(card.type),
//                                   style: const TextStyle(fontSize: 12),
//                                 ),
//                                 const SizedBox(width: 3),
//                                 Text(
//                                   _cardTypeLabel(card.type),
//                                   style: TextStyle(
//                                     fontSize: 11,
//                                     fontWeight: FontWeight.w700,
//                                     color: color,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               card.contentEn,
//                               style: theme.textTheme.bodySmall,
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.close_rounded, size: 16),
//                             onPressed: () => setState(() => cards.removeAt(i)),
//                             visualDensity: VisualDensity.compact,
//                             padding: EdgeInsets.zero,
//                           ),
//                         ],
//                       ),
//                     ).animate(delay: (i * 15).ms).fadeIn();
//                   },
//                 ),
//         ),

//         // Bottom bar
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: widget.onBack,
//                   child: const Text('Back'),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: JButton(
//                   label: 'Continue →',
//                   onPressed: cards.length >= 20 ? _saveAndContinue : null,
//                   isLoading: _isSaving,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _TypeButton extends StatelessWidget {
//   const _TypeButton({
//     required this.label,
//     required this.isSelected,
//     required this.color,
//     required this.onTap,
//   });
//   final String label;
//   final bool isSelected;
//   final Color color;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         decoration: BoxDecoration(
//           color: isSelected ? color : color.withOpacity(0.08),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: isSelected ? Colors.white : color,
//             fontWeight: FontWeight.w700,
//             fontSize: 13,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ── Step 4: Publish ───────────────────────────────────────────────────────────
// // ── Step 4 (Meme only): Reactions ─────────────────────────────────────────────
// class _ReactionsStep extends StatefulWidget {
//   const _ReactionsStep({
//     required this.draft,
//     required this.packId,
//     required this.onNext,
//     required this.onBack,
//   });
//   final PackDraft draft;
//   final String? packId;
//   final VoidCallback onNext;
//   final VoidCallback onBack;

//   @override
//   State<_ReactionsStep> createState() => _ReactionsStepState();
// }

// class _ReactionsStepState extends State<_ReactionsStep> {
//   bool _isSaving = false;

//   Future<void> _pickAndUpload() async {
//     if (widget.draft.reactionImageUrls.length >= 30) {
//       context.showErrorSnackBar('Maximum 30 reaction images reached');
//       return;
//     }
//     final picker = ImagePicker();
//     final picked = await picker.pickMultiImage(imageQuality: 85);
//     if (picked.isEmpty || !mounted) return;

//     final remaining = 30 - widget.draft.reactionImageUrls.length;
//     final toUpload = picked.take(remaining).toList();

//     setState(() => _isSaving = true);
//     try {
//       for (final xfile in toUpload) {
//         final file = File(xfile.path);
//         final url = await PackUploadService.instance.uploadCardImage(file);
//         setState(() => widget.draft.reactionImageUrls.add(url));
//       }
//     } catch (e) {
//       if (mounted) context.showErrorSnackBar('Upload failed: $e');
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }

//   Future<void> _saveAndContinue() async {
//     if (widget.packId == null) {
//       widget.onNext();
//       return;
//     }
//     setState(() => _isSaving = true);
//     try {
//       await PackRepository.instance.savePackReactions(
//         widget.packId!,
//         widget.draft.reactionImageUrls,
//       );
//       widget.onNext();
//     } catch (e) {
//       if (mounted) context.showErrorSnackBar('Failed to save reactions: $e');
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final reactions = widget.draft.reactionImageUrls;

//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Text(
//                     '${reactions.length} / 30 reaction images',
//                     style: theme.textTheme.titleSmall?.copyWith(
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const Spacer(),
//                   Text(
//                     reactions.isEmpty
//                         ? 'Optional — skip to use defaults'
//                         : '${30 - reactions.length} slots remaining',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: theme.colorScheme.onSurfaceVariant,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'Players will use these images as reactions during the game. '
//                 'Add up to 30. If none, default stickers are used.',
//                 style: theme.textTheme.bodySmall?.copyWith(
//                   color: theme.colorScheme.onSurfaceVariant,
//                 ),
//               ),
//             ],
//           ),
//         ),

//         Expanded(
//           child: reactions.isEmpty
//               ? Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.image_outlined,
//                         size: 64,
//                         color: theme.colorScheme.onSurfaceVariant,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'No reaction images yet',
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           color: theme.colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               : GridView.builder(
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 4,
//                     mainAxisSpacing: 8,
//                     crossAxisSpacing: 8,
//                     childAspectRatio: 1,
//                   ),
//                   itemCount: reactions.length,
//                   itemBuilder: (_, i) {
//                     return Stack(
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: Image.network(
//                             reactions[i],
//                             width: double.infinity,
//                             height: double.infinity,
//                             fit: BoxFit.cover,
//                             errorBuilder: (_, __, ___) =>
//                                 const Icon(Icons.broken_image),
//                           ),
//                         ),
//                         Positioned(
//                           top: 2,
//                           right: 2,
//                           child: GestureDetector(
//                             onTap: () => setState(() => reactions.removeAt(i)),
//                             child: Container(
//                               decoration: const BoxDecoration(
//                                 color: Colors.black54,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: const Icon(
//                                 Icons.close_rounded,
//                                 color: Colors.white,
//                                 size: 16,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//         ),

//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               if (reactions.length < 30)
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton.icon(
//                     onPressed: _isSaving ? null : _pickAndUpload,
//                     icon: _isSaving
//                         ? const SizedBox(
//                             width: 16,
//                             height: 16,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           )
//                         : const Icon(Icons.add_photo_alternate_rounded),
//                     label: Text(_isSaving ? 'Uploading...' : 'Add Images'),
//                   ),
//                 ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: widget.onBack,
//                       child: const Text('Back'),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: FilledButton(
//                       onPressed: _isSaving ? null : _saveAndContinue,
//                       child: Text(reactions.isEmpty ? 'Skip' : 'Continue'),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ── Step 4/5: Publish ──────────────────────────────────────────────────────────
// class _PublishStep extends StatelessWidget {
//   const _PublishStep({
//     required this.draft,
//     required this.packId,
//     required this.isSaving,
//     required this.onPublish,
//     required this.onBack,
//   });
//   final PackDraft draft;
//   final String? packId;
//   final bool isSaving;
//   final VoidCallback onPublish;
//   final VoidCallback onBack;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final canPublish = draft.canPublish && packId != null;

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Ready to publish?',
//             style: theme.textTheme.headlineSmall?.copyWith(
//               fontWeight: FontWeight.w800,
//             ),
//           ).animate().fadeIn(),
//           const SizedBox(height: 8),
//           Text(
//             'Review your pack before submitting for moderation.',
//             style: theme.textTheme.bodyMedium?.copyWith(
//               color: theme.colorScheme.onSurfaceVariant,
//             ),
//           ).animate(delay: 40.ms).fadeIn(),

//           const SizedBox(height: 24),

//           // Summary card
//           Container(
//             padding: const EdgeInsets.all(18),
//             decoration: BoxDecoration(
//               color: theme.colorScheme.surfaceContainerHighest,
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _SummaryRow(label: 'Title', value: draft.titleEn, icon: '📦'),
//                 _SummaryRow(
//                   label: 'Game type',
//                   value: draft.gameType,
//                   icon: '🎮',
//                 ),
//                 _SummaryRow(
//                   label: 'Cards',
//                   value:
//                       '${draft.cards.length} (${draft.truthCount}T + ${draft.dareCount}D)',
//                   icon: '🃏',
//                 ),
//                 _SummaryRow(
//                   label: 'Price',
//                   value: draft.priceMru == 0 ? 'Free' : '${draft.priceMru} MRU',
//                   icon: '💰',
//                 ),
//                 _SummaryRow(
//                   label: 'Spicy content',
//                   value: draft.allowSpicy ? 'Allowed' : 'No',
//                   icon: '🌶',
//                 ),
//               ],
//             ),
//           ).animate(delay: 80.ms).fadeIn(),

//           const SizedBox(height: 16),

//           // Rules reminder
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               color: AppColors.infoBlue.withOpacity(0.08),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: AppColors.infoBlue.withOpacity(0.25)),
//             ),
//             child: const Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '📋 Important rules:',
//                   style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
//                 ),
//                 SizedBox(height: 6),
//                 Text(
//                   '• Packs cannot be edited after publishing.\n'
//                   '• You must purchase your own pack to use it in games.\n'
//                   '• Moderation review takes 1–3 business days.',
//                   style: TextStyle(fontSize: 13, height: 1.6),
//                 ),
//               ],
//             ),
//           ).animate(delay: 100.ms).fadeIn(),

//           const SizedBox(height: 32),

//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: onBack,
//                   child: const Text('Back'),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: JButton(
//                   label: 'Submit for Review',
//                   onPressed: canPublish ? onPublish : null,
//                   isLoading: isSaving,
//                   icon: Icons.send_rounded,
//                 ),
//               ),
//             ],
//           ).animate(delay: 120.ms).fadeIn(),
//         ],
//       ),
//     );
//   }
// }

// class _SummaryRow extends StatelessWidget {
//   const _SummaryRow({
//     required this.label,
//     required this.value,
//     required this.icon,
//   });
//   final String label;
//   final String value;
//   final String icon;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Text(icon, style: const TextStyle(fontSize: 16)),
//           const SizedBox(width: 10),
//           Text(
//             '$label: ',
//             style: context.textTheme.bodySmall?.copyWith(
//               color: context.colorScheme.onSurfaceVariant,
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: context.textTheme.bodySmall?.copyWith(
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../data/pack_repository.dart';
import '../../data/pack_upload_service.dart';
import '../../data/pack_upload_service.dart';
import '../../domain/pack_entity.dart';
import '../pack_provider.dart';

/// Multi-step pack creation flow.
/// Steps: 1. Info  2. Cover  3. Cards  4. Review & Publish
class CreatePackScreen extends StatefulWidget {
  const CreatePackScreen({super.key, this.existingPackId, this.existingPack});
  final String? existingPackId;
  final PackEntity? existingPack;

  @override
  State<CreatePackScreen> createState() => _CreatePackScreenState();
}

class _CreatePackScreenState extends State<CreatePackScreen> {
  late final PackDraft _draft;
  int _step = 0;
  bool _isSaving = false;
  late String? _savedPackId;

  @override
  void initState() {
    super.initState();
    _savedPackId = widget.existingPackId;
    // Pre-fill draft from existing pack
    final p = widget.existingPack;
    if (p != null) {
      final titles = Map<String, String>.from(p.titleJson);
      final descriptions = Map<String, String>.from(p.descriptionJson ?? {});
      final selectedLanguages = p.availableLanguages.isNotEmpty
          ? p.availableLanguages
          : (titles.keys.isNotEmpty ? titles.keys.toList() : ['en']);
      _draft = PackDraft(
        titles: titles,
        descriptions: descriptions,
        selectedLanguages: selectedLanguages,
        gameType: p.gameType,
        language: p.language,
        priceMru: p.priceMru,
        categoryId: p.categoryId,
        allowSpicy: p.hasSpicy,
        coverImageUrl: p.coverImageUrl,
        cards: [],
        minAge: p.minAge,
        maxAge: p.maxAge,
        genderRestriction: p.genderRestriction,
        suggestedPunishments: List<String>.from(p.suggestedPunishments),
      );
      // Jump to cards step if basic info already saved
      _step = _savedPackId != null ? _activeSteps.indexOf('Cards') : 0;
    } else {
      _draft = PackDraft();
    }
  }

  // Order: general info (incl. cover) -> languages -> names & descriptions
  // -> audience -> cards -> [reactions | punishments, game-type specific]
  // -> publish. "Cards" always sits at a fixed index (4) regardless of game
  // type since only what comes *after* it varies.
  static const _baseSteps = [
    'General Info',
    'Languages',
    'Names & Descriptions',
    'Audience',
    'Cards',
  ];
  List<String> get _activeSteps => [
    ..._baseSteps,
    if (_draft.gameType == 'meme_game') 'Reactions',
    if (_draft.gameType == 'truth_or_dare') 'Punishments',
    'Publish',
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, __) {
        if (mounted) context.read<PackProvider>().loadCreatedPacks();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Create Pack — ${_activeSteps[_step]}'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_step + 1) / _activeSteps.length,
              minHeight: 4,
              color: AppColors.navyBlue,
              backgroundColor: context.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: switch (_activeSteps[_step]) {
              'General Info' => _GeneralInfoStep(
                draft: _draft,
                onNext: _nextStep,
              ),
              'Languages' => _LanguageStep(draft: _draft, onNext: _nextStep),
              'Names & Descriptions' => _NamesStep(
                draft: _draft,
                onNext: _nextStep,
              ),
              'Audience' => _AudienceStep(draft: _draft, onNext: _nextStep),
              'Cards' => _CardsStep(
                draft: _draft,
                packId: _savedPackId,
                onNext: _nextStep,
                onBack: _prevStep,
              ),
              'Reactions' => _ReactionsStep(
                draft: _draft,
                packId: _savedPackId,
                onNext: _nextStep,
                onBack: _prevStep,
              ),
              'Punishments' => _PunishmentsStep(
                draft: _draft,
                onNext: _nextStep,
                onBack: _prevStep,
              ),
              _ => _PublishStep(
                draft: _draft,
                packId: _savedPackId,
                isSaving: _isSaving,
                onPublish: _submit,
                onBack: _prevStep,
              ),
            },
          ),
        ),
      ),
    );
  }

  // Steps that edit fields directly on `_draft` and must persist them via
  // createPackDraft/updatePackDraft before moving on. General Info and
  // Languages are excluded deliberately: General Info happens before a
  // title exists (the backend create route 400s without one) and Languages
  // only sets selectedLanguages, so neither has anything persistable yet.
  // Cards/Reactions are excluded because they persist through their own
  // per-item API calls keyed on _savedPackId, not through this draft
  // object.
  static const _saveOnAdvanceSteps = {
    'Names & Descriptions',
    'Audience',
    'Punishments',
  };

  void _nextStep() {
    if (_saveOnAdvanceSteps.contains(_activeSteps[_step])) {
      _saveDraft();
    } else {
      setState(() => _step = (_step + 1).clamp(0, _activeSteps.length - 1));
    }
  }

  void _prevStep() =>
      setState(() => _step = (_step - 1).clamp(0, _activeSteps.length - 1));

  Future<void> _saveDraft() async {
    final targetStep = (_step + 1).clamp(0, _activeSteps.length - 1);
    setState(() => _isSaving = true);
    try {
      final packs = context.read<PackProvider>();
      final userId = packs.currentUserId;
      if (userId == null) throw Exception('Not logged in');

      PackEntity pack;
      if (_savedPackId == null) {
        pack = await PackRepository.instance.createPackDraft(_draft, userId);
        _savedPackId = pack.id;
      } else {
        pack = await PackRepository.instance.updatePackDraft(
          _savedPackId!,
          _draft,
        );
      }
      // The Node API's create/update routes don't carry this field yet, so
      // it's linked via a direct client write once a pack id exists — see
      // linkPendingCategorySuggestion.
      if (_draft.pendingCategorySuggestionId != null) {
        await PackRepository.instance.linkPendingCategorySuggestion(
          _savedPackId!,
          _draft.pendingCategorySuggestionId!,
        );
      }
      setState(() {
        _isSaving = false;
        _step = targetStep;
      });
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) context.showErrorSnackBar('Failed to save: $e');
    }
  }

  Future<bool> _confirmSubmissionFee() async {
    // The fee is admin-configurable via app_settings (never hardcoded) —
    // submit_pack_for_review always charges the live server-side value
    // regardless of what's shown here; this fetch is purely so the dialog
    // text is accurate.
    int fee = 300;
    try {
      fee = await PackRepository.instance.getPackExtraCreationFee();
    } catch (_) {
      // Best-effort only — fall back to the last-known default and let the
      // RPC charge whatever the real server-side value actually is.
    }
    if (!mounted) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Additional submission fee'),
        content: Text(
          'You\'ve reached your 2 free pack submissions this month (or '
          'submitted within the last 15 days). Submitting this pack now '
          'will cost $fee MRU from your wallet balance. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Pay $fee MRU & submit'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  /// [payFee] true skips straight to a paid submission (used on retry after
  /// the server itself reported fee_required) — otherwise runs the
  /// non-authoritative pre-check first purely to decide whether to show the
  /// confirmation dialog before calling the RPC, which always re-verifies
  /// the real limit server-side regardless of what the pre-check found.
  Future<void> _submit({bool payFee = false}) async {
    if (_savedPackId == null) return;

    if (!payFee) {
      try {
        if (await PackRepository.instance.wouldPackSubmissionNeedFee()) {
          if (!mounted) return;
          if (!await _confirmSubmissionFee()) return;
          payFee = true;
        }
      } catch (_) {
        // Pre-check is best-effort only — fall through and let the RPC's
        // own authoritative check decide (may still surface fee_required
        // below, handled the same way as a fresh confirmation).
      }
    }

    setState(() => _isSaving = true);
    try {
      await PackRepository.instance.submitForReview(
        _savedPackId!,
        payFee: payFee,
      );
      if (mounted) {
        context.read<PackProvider>().loadCreatedPacks();
        context.showSnackBar(
          'Pack submitted for review! You\'ll be notified when approved.',
        );
        context.pop();
      }
    } on PaymentFailure catch (e) {
      setState(() => _isSaving = false);
      if (e.code == 'fee_required' && mounted) {
        // The pre-check missed it (race) — the server has now confirmed a
        // fee is actually required, so ask once more and submit paid.
        if (await _confirmSubmissionFee()) await _submit(payFee: true);
      } else if (mounted) {
        context.showErrorSnackBar(e.message);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) context.showErrorSnackBar('Submission failed: $e');
    }
  }
}

// ── Category picker ───────────────────────────────────────────────────────────
class _CategoryPicker extends StatefulWidget {
  const _CategoryPicker({
    required this.gameType,
    required this.selectedId,
    required this.onSelected,
    this.pendingSuggestionId,
    this.onSuggested,
  });
  final String gameType;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final String? pendingSuggestionId;
  final ValueChanged<String>? onSuggested;
  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  List<PackCategory>? _cats;
  bool _loading = false;
  Map<String, dynamic>? _suggestion;

  @override
  void initState() {
    super.initState();
    _load();
    _loadSuggestion();
  }

  @override
  void didUpdateWidget(_CategoryPicker old) {
    super.didUpdateWidget(old);
    if (old.gameType != widget.gameType) _load();
    if (old.pendingSuggestionId != widget.pendingSuggestionId) {
      _loadSuggestion();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _cats = null;
    });
    try {
      final all = await PackRepository.instance.getCategories();
      if (mounted)
        setState(() {
          _cats = all;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSuggestion() async {
    final id = widget.pendingSuggestionId;
    if (id == null) {
      if (mounted) setState(() => _suggestion = null);
      return;
    }
    try {
      final row = await PackRepository.instance.getCategorySuggestion(id);
      if (mounted) setState(() => _suggestion = row);
    } catch (_) {
      // Best-effort status display only.
    }
  }

  Future<void> _showSuggestDialog() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suggest a new category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(hintText: 'e.g. Office Party'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Submit for review'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().length < 2) return;
    try {
      final id = await PackRepository.instance.suggestCategory(name.trim());
      widget.onSuggested?.call(id);
      if (mounted) {
        context.showSnackBar('Category submitted for admin review.');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to suggest category: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LinearProgressIndicator();
    final cats = _cats;

    if (widget.pendingSuggestionId != null) {
      final status = _suggestion?['status'] as String?;
      final name = _suggestion?['suggested_name'] as String? ?? '…';
      final reason = _suggestion?['rejection_reason'] as String?;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category (optional)',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (status == 'rejected') ...[
            Text(
              'Suggested category "$name" was rejected'
              '${reason != null && reason.isNotEmpty ? ': $reason' : '.'}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => widget.onSelected(null),
                  child: const Text('Pick existing category'),
                ),
                OutlinedButton(
                  onPressed: _showSuggestDialog,
                  child: const Text('Suggest again'),
                ),
              ],
            ),
          ] else
            Chip(
              avatar: const Icon(Icons.hourglass_top, size: 16),
              label: Text('"$name" — pending admin review'),
            ),
        ],
      );
    }

    if (cats == null || cats.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category (optional)',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            // None option
            ChoiceChip(
              label: const Text('None'),
              selected: widget.selectedId == null,
              onSelected: (_) => widget.onSelected(null),
            ),
            ...cats.map(
              (c) => ChoiceChip(
                avatar: Text(c.icon),
                label: Text(c.nameJson['en'] as String? ?? c.slug),
                selected: widget.selectedId == c.id,
                onSelected: (_) =>
                    widget.onSelected(widget.selectedId == c.id ? null : c.id),
              ),
            ),
            if (widget.onSuggested != null)
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Suggest new'),
                onPressed: _showSuggestDialog,
              ),
          ],
        ),
      ],
    );
  }
}

// ── Step 2: Languages ────────────────────────────────────────────────────────
// Select every language the pack will be authored in before names/
// descriptions/cards, so _NamesStep can generate the right number of
// name/description fields and _CardsStep the right number of card-content
// fields.
class _LanguageStep extends StatefulWidget {
  const _LanguageStep({required this.draft, required this.onNext});
  final PackDraft draft;
  final VoidCallback onNext;

  @override
  State<_LanguageStep> createState() => _LanguageStepState();
}

class _LanguageStepState extends State<_LanguageStep> {
  // Fallback flags only — the *available* languages themselves always come
  // from the pack_languages table via _loadLanguages(), never hardcoded. A
  // code with no entry here just falls back to a generic flag emoji, it's
  // never excluded from the list.
  static const _flagEmoji = {
    'en': '🇬🇧',
    'ar': '🇸🇦',
    'fr': '🇫🇷',
    'es': '🇪🇸',
    'de': '🇩🇪',
    'pt': '🇵🇹',
    'tr': '🇹🇷',
    'ru': '🇷🇺',
  };

  List<(String, String)> _langs = [];

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    try {
      final langs = await PackRepository.instance.getAvailableLanguages();
      if (!mounted) return;
      setState(() {
        _langs = [
          for (final l in langs)
            (l.code, '${_flagEmoji[l.code] ?? '🏳️'} ${l.name}'),
        ];
      });
    } catch (_) {
      // Never block the form on this, and never silently fall back to a
      // fixed hardcoded set — just show whatever's already selected.
      if (mounted) {
        setState(() {
          _langs = [
            for (final code in widget.draft.selectedLanguages)
              (code, '${_flagEmoji[code] ?? '🏳️'} ${code.toUpperCase()}'),
          ];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final draft = widget.draft;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Languages',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            'Select every language you\'ll provide a pack name, description, '
            'and cards in. You can pick more than one.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ).animate(delay: 40.ms).fadeIn(),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final lang in _langs)
                FilterChip(
                  label: Text(lang.$2),
                  selected: draft.selectedLanguages.contains(lang.$1),
                  onSelected: (on) => setState(() {
                    if (on) {
                      if (!draft.selectedLanguages.contains(lang.$1)) {
                        draft.selectedLanguages.add(lang.$1);
                      }
                    } else if (draft.selectedLanguages.length > 1) {
                      // Must keep at least one language.
                      draft.selectedLanguages.remove(lang.$1);
                      draft.titles.remove(lang.$1);
                      draft.descriptions.remove(lang.$1);
                    }
                    // Set language field: 'multi' if >1, else single lang.
                    draft.language = draft.selectedLanguages.length > 1
                        ? 'multi'
                        : draft.selectedLanguages.first;
                  }),
                ),
            ],
          ).animate(delay: 60.ms).fadeIn(),
          const SizedBox(height: 32),
          JButton(
            label: 'Continue →',
            onPressed: draft.selectedLanguages.isNotEmpty
                ? widget.onNext
                : null,
            icon: Icons.arrow_forward_rounded,
          ).animate(delay: 100.ms).fadeIn(),
        ],
      ),
    );
  }
}

// ── Step 1: General info (game type, category, price, spicy, min players,
// cover image) ───────────────────────────────────────────────────────────────
class _GeneralInfoStep extends StatefulWidget {
  const _GeneralInfoStep({required this.draft, required this.onNext});
  final PackDraft draft;
  final VoidCallback onNext;

  @override
  State<_GeneralInfoStep> createState() => _GeneralInfoStepState();
}

class _GeneralInfoStepState extends State<_GeneralInfoStep> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await PackUploadService.instance.uploadCoverImage(
        File(picked.path),
      );
      setState(() {
        widget.draft.coverImagePath = picked.path;
        widget.draft.coverImageUrl = url;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) context.showErrorSnackBar('Upload failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final draft = widget.draft;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pack information',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 24),

          // Game type
          DropdownButtonFormField<String>(
            initialValue: draft.gameType,
            decoration: const InputDecoration(labelText: 'Game type'),
            items: const [
              DropdownMenuItem(
                value: 'truth_or_dare',
                child: Text('🎯 Truth or Dare'),
              ),
              DropdownMenuItem(
                value: 'never_have_i_ever',
                child: Text('🍹 Never Have I Ever'),
              ),
              DropdownMenuItem(value: 'meme_game', child: Text('😂 Meme Game')),
            ],
            onChanged: (v) => setState(() {
              draft.gameType = v ?? 'truth_or_dare';
              draft.categoryId = null; // reset category when game changes
            }),
          ).animate(delay: 60.ms).fadeIn(),

          const SizedBox(height: 16),

          // Category picker
          _CategoryPicker(
            gameType: draft.gameType,
            selectedId: draft.categoryId,
            pendingSuggestionId: draft.pendingCategorySuggestionId,
            onSelected: (id) => setState(() {
              draft.categoryId = id;
              draft.pendingCategorySuggestionId = null;
            }),
            onSuggested: (id) => setState(() {
              draft.categoryId = null;
              draft.pendingCategorySuggestionId = id;
            }),
          ).animate(delay: 80.ms).fadeIn(),

          const SizedBox(height: 16),

          // Price
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: draft.priceMru.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (MRU)',
                    hintText: '0 for free',
                    suffixText: 'MRU',
                  ),
                  onChanged: (v) => draft.priceMru = int.tryParse(v) ?? 0,
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Text(
                    'Spicy 🌶️',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: draft.allowSpicy,
                    onChanged: (v) => setState(() => draft.allowSpicy = v),
                  ),
                ],
              ),
            ],
          ).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 16),

          // Min players
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Minimum players: ${draft.minPlayers}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Who can play this pack?',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Slider(
                value: draft.minPlayers.toDouble(),
                min: 2,
                max: 10,
                divisions: 8,
                label: '${draft.minPlayers} players',
                onChanged: (v) =>
                    setState(() => draft.minPlayers = v.round()),
              ),
            ],
          ).animate(delay: 110.ms).fadeIn(),

          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),

          Text(
            'Cover image',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate(delay: 115.ms).fadeIn(),
          const SizedBox(height: 4),
          Text(
            'Add an attractive cover to increase pack visibility.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ).animate(delay: 115.ms).fadeIn(),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
                  onTap: _isUploading ? null : _pickAndUpload,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                    child: _isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : draft.coverImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              File(draft.coverImagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to add cover',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                  ),
                )
                .animate(delay: 120.ms)
                .fadeIn()
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
          ),

          const SizedBox(height: 32),

          JButton(
            label: 'Continue →',
            onPressed: draft.coverImageUrl != null ? widget.onNext : null,
            icon: Icons.arrow_forward_rounded,
          ).animate(delay: 140.ms).fadeIn(),
        ],
      ),
    );
  }
}

// ── Step 3: Names & descriptions ────────────────────────────────────────────
class _NamesStep extends StatefulWidget {
  const _NamesStep({required this.draft, required this.onNext});
  final PackDraft draft;
  final VoidCallback onNext;

  @override
  State<_NamesStep> createState() => _NamesStepState();
}

class _NamesStepState extends State<_NamesStep> {
  late final Map<String, TextEditingController> _titleCtrls;
  late final Map<String, TextEditingController> _descCtrls;

  static const _langNames = {
    'en': 'English',
    'ar': 'Arabic',
    'fr': 'French',
    'es': 'Spanish',
    'de': 'German',
    'pt': 'Portuguese',
    'tr': 'Turkish',
    'ru': 'Russian',
  };

  String _langLabel(String code) => _langNames[code] ?? code.toUpperCase();

  @override
  void initState() {
    super.initState();
    // A fresh _NamesStepState is created every time _step changes (the
    // AnimatedSwitcher above is keyed on _step), so this always reflects
    // whatever selectedLanguages the Language step left behind — no need
    // to react to changes after the fact.
    _titleCtrls = {
      for (final lang in widget.draft.selectedLanguages)
        lang: TextEditingController(text: widget.draft.titles[lang] ?? ''),
    };
    _descCtrls = {
      for (final lang in widget.draft.selectedLanguages)
        lang: TextEditingController(
          text: widget.draft.descriptions[lang] ?? '',
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _titleCtrls.values) {
      c.dispose();
    }
    for (final c in _descCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final draft = widget.draft;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Names & descriptions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            'One name and description per language you selected.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ).animate(delay: 40.ms).fadeIn(),
          const SizedBox(height: 24),

          for (final lang in draft.selectedLanguages) ...[
            TextFormField(
              controller: _titleCtrls[lang],
              onChanged: (v) => draft.titles[lang] = v,
              decoration: InputDecoration(
                labelText: 'Pack name (${_langLabel(lang)})*',
                hintText: 'e.g. Wild Friday Night',
              ),
              textCapitalization: TextCapitalization.words,
            ).animate(delay: 60.ms).fadeIn(),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrls[lang],
              onChanged: (v) => draft.descriptions[lang] = v,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Description (${_langLabel(lang)}, optional)',
                counterText: '',
              ),
            ).animate(delay: 80.ms).fadeIn(),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 16),

          JButton(
            label: 'Continue →',
            onPressed: draft.hasTitle ? widget.onNext : null,
            icon: Icons.arrow_forward_rounded,
          ).animate(delay: 120.ms).fadeIn(),
        ],
      ),
    );
  }
}

// ── Step 4: Audience restrictions ───────────────────────────────────────────
class _AudienceStep extends StatefulWidget {
  const _AudienceStep({required this.draft, required this.onNext});
  final PackDraft draft;
  final VoidCallback onNext;

  @override
  State<_AudienceStep> createState() => _AudienceStepState();
}

class _AudienceStepState extends State<_AudienceStep> {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final draft = widget.draft;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audience',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            'Restrict who this pack is meant for. Not enforced when '
            'joining a room yet — saved with the pack for later use.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ).animate(delay: 40.ms).fadeIn(),
          const SizedBox(height: 24),

          Text(
            'Age',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate(delay: 60.ms).fadeIn(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option
                  in const <(String, int?, int?)>[
                    ('Everyone', null, null),
                    ('18+', 18, null),
                    ('21+', 21, null),
                  ])
                ChoiceChip(
                  label: Text(option.$1),
                  selected:
                      draft.minAge == option.$2 && draft.maxAge == option.$3,
                  onSelected: (_) => setState(() {
                    draft.minAge = option.$2;
                    draft.maxAge = option.$3;
                  }),
                ),
            ],
          ).animate(delay: 80.ms).fadeIn(),
          const SizedBox(height: 24),

          Text(
            'Gender',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option
                  in const <(String, String)>[
                    ('Everyone', 'everyone'),
                    ('Male only', 'male'),
                    ('Female only', 'female'),
                  ])
                ChoiceChip(
                  label: Text(option.$1),
                  selected: draft.genderRestriction == option.$2,
                  onSelected: (_) =>
                      setState(() => draft.genderRestriction = option.$2),
                ),
            ],
          ).animate(delay: 120.ms).fadeIn(),

          const SizedBox(height: 32),

          JButton(
            label: 'Continue →',
            onPressed: widget.onNext,
            icon: Icons.arrow_forward_rounded,
          ).animate(delay: 140.ms).fadeIn(),
        ],
      ),
    );
  }
}

// ── Step 5: Cards ─────────────────────────────────────────────────────────────

String _cardTypeEmoji(CardType t) => switch (t) {
  CardType.truth => '🤔',
  CardType.dare => '🔥',
  CardType.statement => '🍹',
  CardType.prompt => '😂',
};

String _cardTypeLabel(CardType t) => switch (t) {
  CardType.truth => 'Truth',
  CardType.dare => 'Dare',
  CardType.statement => 'Statement',
  CardType.prompt => 'Prompt',
};

Color _cardTypeColor(CardType t) => switch (t) {
  CardType.truth => AppColors.truthColor,
  CardType.dare => AppColors.dareColor,
  CardType.statement => AppColors.tealGreen,
  CardType.prompt => AppColors.purple,
};

class _CardsStep extends StatefulWidget {
  const _CardsStep({
    required this.draft,
    required this.packId,
    required this.onNext,
    required this.onBack,
  });
  final PackDraft draft;
  final String? packId;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<_CardsStep> createState() => _CardsStepState();
}

class _CardsStepState extends State<_CardsStep> {
  late CardType _type;
  CardDifficulty _difficulty = CardDifficulty.mild;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Set default card type based on game type
    _type = _defaultTypeForGame(widget.draft.gameType);
  }

  CardType _defaultTypeForGame(String gameType) {
    switch (gameType) {
      case 'never_have_i_ever':
        return CardType.statement;
      case 'meme_game':
        return CardType.prompt;
      default:
        return CardType.truth; // truth_or_dare
    }
  }

  List<(CardType, String, Color)> _typesForGame(String gameType) {
    switch (gameType) {
      case 'never_have_i_ever':
        return [(CardType.statement, 'Statement 🍹', AppColors.tealGreen)];
      case 'meme_game':
        return [(CardType.prompt, 'Prompt 😂', AppColors.purple)];
      default:
        return [
          (CardType.truth, 'Truth 🤔', AppColors.truthColor),
          (CardType.dare, 'Dare 🔥', AppColors.dareColor),
        ];
    }
  }

  Future<void> _saveAndContinue() async {
    if (widget.packId == null) return;
    if (widget.draft.cards.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await PackRepository.instance.addCards(
        widget.packId!,
        widget.draft.cards,
      );
      widget.onNext();
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to save cards: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cards = widget.draft.cards;

    return Column(
      children: [
        // Card input area
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${cards.length} / 20+ cards',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    cards.length < 20
                        ? '${20 - cards.length} more needed'
                        : '✅ Minimum reached',
                    style: TextStyle(
                      fontSize: 12,
                      color: cards.length >= 20
                          ? AppColors.successGreen
                          : AppColors.warningAmber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Type + difficulty selectors — adapts to game type
              Row(
                children: [
                  ..._typesForGame(widget.draft.gameType).map((t) {
                    final (type, label, color) = t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _TypeButton(
                        label: label,
                        isSelected: _type == type,
                        color: color,
                        onTap: () => setState(() => _type = type),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  DropdownButton<CardDifficulty>(
                    value: _difficulty,
                    underline: const SizedBox.shrink(),
                    items: CardDifficulty.values
                        .where(
                          (d) =>
                              d != CardDifficulty.spicy ||
                              widget.draft.allowSpicy,
                        )
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              d == CardDifficulty.spicy ? '🌶 spicy' : d.name,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (d) => setState(() => _difficulty = d!),
                  ),
                  if (!widget.draft.allowSpicy)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Tooltip(
                        message:
                            'Enable spicy content in pack settings to add spicy cards',
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Multi-language card input — show field per selected language
              _MultiLangCardInput(
                draft: widget.draft,
                onAdd: (CardDraft card) => setState(() {
                  widget.draft.cards.add(card);
                }),
                type: _type,
                difficulty: _difficulty,
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Card list
        Expanded(
          child: cards.isEmpty
              ? const Center(child: Text('Add your first card above!'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final card = cards[i];
                    final color = _cardTypeColor(card.type);
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _cardTypeEmoji(card.type),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _cardTypeLabel(card.type),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              card.contentEn,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () => setState(() => cards.removeAt(i)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ).animate(delay: (i * 15).ms).fadeIn();
                  },
                ),
        ),

        // Bottom bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: JButton(
                  label: 'Continue →',
                  onPressed: cards.length >= 20 ? _saveAndContinue : null,
                  isLoading: _isSaving,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Multi-language card input ──────────────────────────────────────────────────
class _MultiLangCardInput extends StatefulWidget {
  const _MultiLangCardInput({
    required this.draft,
    required this.onAdd,
    required this.type,
    required this.difficulty,
  });
  final PackDraft draft;
  final void Function(CardDraft) onAdd;
  final CardType type;
  final CardDifficulty difficulty;
  @override
  State<_MultiLangCardInput> createState() => _MultiLangCardInputState();
}

class _MultiLangCardInputState extends State<_MultiLangCardInput> {
  final _enCtrl = TextEditingController();
  final _arCtrl = TextEditingController();
  final _frCtrl = TextEditingController();

  @override
  void dispose() {
    _enCtrl.dispose();
    _arCtrl.dispose();
    _frCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final langs = widget.draft.selectedLanguages;
    // Validate all selected languages have content
    final missing = langs
        .where(
          (l) => switch (l) {
            'ar' => _arCtrl.text.trim().isEmpty,
            'fr' => _frCtrl.text.trim().isEmpty,
            _ => _enCtrl.text.trim().isEmpty,
          },
        )
        .toList();
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill content in: ${missing.join(', ')}'),
        ),
      );
      return;
    }
    widget.onAdd(
      CardDraft(
        contentEn: _enCtrl.text.trim(),
        contentAr: _arCtrl.text.trim(),
        contentFr: _frCtrl.text.trim(),
        type: widget.type,
        difficulty: widget.difficulty,
      ),
    );
    _enCtrl.clear();
    _arCtrl.clear();
    _frCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final langs = widget.draft.selectedLanguages;
    final langLabels = {'en': '🇬🇧 EN', 'ar': '🇸🇦 AR', 'fr': '🇫🇷 FR'};
    final ctrls = {'en': _enCtrl, 'ar': _arCtrl, 'fr': _frCtrl};
    return Column(
      children: [
        for (final lang in langs) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      langLabels[lang] ?? lang,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: ctrls[lang],
                  maxLines: 2,
                  textDirection: lang == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: lang == 'ar'
                        ? 'محتوى البطاقة…'
                        : lang == 'fr'
                        ? 'Contenu de la carte…'
                        : 'Card content…',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: IconButton.filled(
            onPressed: _add,
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(backgroundColor: AppColors.navyBlue),
          ),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Step 6 (Truth or Dare only): Punishments ────────────────────────────────
// Mirrors _CardsStep's layout deliberately (input area with a live counter,
// scrollable list of added items, fixed Back/Continue bar) so this feels
// like the same kind of "add multiple things" flow the creator just used
// for cards. Completely optional — the only constraint is >=10 if any are
// added, matching packs_suggested_punishments_check server-side.
class _PunishmentsStep extends StatefulWidget {
  const _PunishmentsStep({
    required this.draft,
    required this.onNext,
    required this.onBack,
  });
  final PackDraft draft;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<_PunishmentsStep> createState() => _PunishmentsStepState();
}

class _PunishmentsStepState extends State<_PunishmentsStep> {
  final _inputCtrl = TextEditingController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.draft.suggestedPunishments.add(text);
      _inputCtrl.clear();
    });
  }

  Future<void> _edit(int index) async {
    final ctrl = TextEditingController(
      text: widget.draft.suggestedPunishments[index],
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit punishment'),
        content: TextField(controller: ctrl, autofocus: true, maxLines: 2),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      setState(() => widget.draft.suggestedPunishments[index] = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final punishments = widget.draft.suggestedPunishments;
    final canContinue = punishments.isEmpty || punishments.length >= 10;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Punishments (optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Shown to a player who skips or refuses a card, if the room '
                'owner chooses to use pack punishments instead of live '
                'player submissions.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${punishments.length} punishment'
                    '${punishments.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (punishments.isNotEmpty)
                    Text(
                      punishments.length >= 10
                          ? '✅ Minimum reached'
                          : '${10 - punishments.length} more needed',
                      style: TextStyle(
                        fontSize: 12,
                        color: punishments.length >= 10
                            ? AppColors.successGreen
                            : AppColors.warningAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _inputCtrl,
                      decoration: const InputDecoration(
                        labelText: 'e.g. Do 10 pushups',
                      ),
                      onFieldSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _add,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        Expanded(
          child: punishments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Optional — add some, or skip straight to Publish.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: punishments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    return Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: const Text(
                              '🎯',
                              style: TextStyle(fontSize: 16),
                            ),
                            title: Text(punishments[i]),
                            onTap: () => _edit(i),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () =>
                                  setState(() => punishments.removeAt(i)),
                            ),
                          ),
                        )
                        .animate(delay: (i * 15).ms)
                        .fadeIn();
                  },
                ),
        ),

        if (punishments.isNotEmpty && punishments.length < 10)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Add ${10 - punishments.length} more (minimum 10) or remove '
              'them all.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: JButton(
                  label: 'Continue →',
                  onPressed: canContinue ? widget.onNext : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Step 6 (Meme only): Reactions ─────────────────────────────────────────────
class _ReactionsStep extends StatefulWidget {
  const _ReactionsStep({
    required this.draft,
    required this.packId,
    required this.onNext,
    required this.onBack,
  });
  final PackDraft draft;
  final String? packId;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<_ReactionsStep> createState() => _ReactionsStepState();
}

class _ReactionsStepState extends State<_ReactionsStep> {
  bool _isSaving = false;

  Future<void> _pickAndUpload() async {
    if (widget.draft.reactionImageUrls.length >= 30) {
      context.showErrorSnackBar('Maximum 30 reaction images reached');
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty || !mounted) return;

    final remaining = 30 - widget.draft.reactionImageUrls.length;
    final toUpload = picked.take(remaining).toList();

    setState(() => _isSaving = true);
    try {
      for (final xfile in toUpload) {
        final file = File(xfile.path);
        final url = await PackUploadService.instance.uploadCardImage(file);
        setState(() => widget.draft.reactionImageUrls.add(url));
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAndContinue() async {
    if (widget.packId == null) {
      widget.onNext();
      return;
    }
    setState(() => _isSaving = true);
    try {
      await PackRepository.instance.savePackReactions(
        widget.packId!,
        widget.draft.reactionImageUrls,
      );
      widget.onNext();
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to save reactions: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final reactions = widget.draft.reactionImageUrls;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${reactions.length} / 30 reaction images',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    reactions.isEmpty
                        ? 'Optional — skip to use defaults'
                        : '${30 - reactions.length} slots remaining',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Players will use these images as reactions during the game. '
                'Add up to 30. If none, default stickers are used.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: reactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No reaction images yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: reactions.length,
                  itemBuilder: (_, i) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            reactions[i],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => setState(() => reactions.removeAt(i)),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (reactions.length < 30)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickAndUpload,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate_rounded),
                    label: Text(_isSaving ? 'Uploading...' : 'Add Images'),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveAndContinue,
                      child: Text(reactions.isEmpty ? 'Skip' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Step 7: Publish ────────────────────────────────────────────────────────────
class _PublishStep extends StatelessWidget {
  const _PublishStep({
    required this.draft,
    required this.packId,
    required this.isSaving,
    required this.onPublish,
    required this.onBack,
  });
  final PackDraft draft;
  final String? packId;
  final bool isSaving;
  final VoidCallback onPublish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final canPublish = draft.canPublish && packId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to publish?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            'Review your pack before submitting for moderation.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ).animate(delay: 40.ms).fadeIn(),

          const SizedBox(height: 24),

          // Summary card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryRow(
                  label: 'Title',
                  value: draft.titles[draft.selectedLanguages.first] ?? '',
                  icon: '📦',
                ),
                _SummaryRow(
                  label: 'Game type',
                  value: draft.gameType,
                  icon: '🎮',
                ),
                _SummaryRow(
                  label: 'Cards',
                  value:
                      '${draft.cards.length} (${draft.truthCount}T + ${draft.dareCount}D)',
                  icon: '🃏',
                ),
                _SummaryRow(
                  label: 'Price',
                  value: draft.priceMru == 0 ? 'Free' : '${draft.priceMru} MRU',
                  icon: '💰',
                ),
                _SummaryRow(
                  label: 'Spicy content',
                  value: draft.allowSpicy ? 'Allowed' : 'No',
                  icon: '🌶',
                ),
              ],
            ),
          ).animate(delay: 80.ms).fadeIn(),

          const SizedBox(height: 16),

          // Rules reminder
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.infoBlue.withOpacity(0.25)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 Important rules:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                SizedBox(height: 6),
                Text(
                  '• Packs cannot be edited after publishing.\n'
                  '• You must purchase your own pack to use it in games.\n'
                  '• Moderation review takes 1–3 business days.',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: JButton(
                  label: 'Submit for Review',
                  onPressed: canPublish ? onPublish : null,
                  isLoading: isSaving,
                  icon: Icons.send_rounded,
                ),
              ),
            ],
          ).animate(delay: 120.ms).fadeIn(),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
