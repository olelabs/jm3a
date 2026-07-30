import 'package:flutter/material.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../data/pack_repository.dart';

/// Supported cities for physical pack delivery. A small, easy-to-extend
/// const list — add a city here and it immediately shows up in the
/// searchable City field below, no other changes needed.
const List<String> _kCities = [
  'Nouakchott',
  'Nouadhibou',
  'Rosso',
  'Kaédi',
  'Zouérat',
  'Kiffa',
  'Atar',
  'Néma',
  'Sélibaby',
  'Aleg',
  'Boutilimit',
  'Akjoujt',
];

/// Requests a printed physical copy of a pack the caller already owns.
/// Pops `true` on success so the caller can show a confirmation snackbar.
class PhysicalPackRequestSheet extends StatefulWidget {
  const PhysicalPackRequestSheet({super.key, required this.packId});
  final String packId;

  @override
  State<PhysicalPackRequestSheet> createState() =>
      _PhysicalPackRequestSheetState();
}

class _PhysicalPackRequestSheetState extends State<PhysicalPackRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Captured from Autocomplete's fieldViewBuilder — Autocomplete owns and
  // persists this controller across its own rebuilds (fieldViewBuilder is
  // called with the same instance each time), so reading .text from it
  // directly at submit time is safe and needs no separate sync listener.
  TextEditingController? _cityAutocompleteCtrl;

  int _quantity = 1;
  int? _priceMru;
  bool _loadingPrice = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    PackRepository.instance.getPhysicalPackPrice().then((price) {
      if (mounted) {
        setState(() {
          _priceMru = price;
          _loadingPrice = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _loadingPrice = false);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _zoneCtrl.dispose();
    _notesCtrl.dispose();
    // Not disposed here — Autocomplete owns and disposes its own internal
    // controller; disposing it ourselves too would double-dispose.
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await PackRepository.instance.requestPhysicalPack(
        packId: widget.packId,
        recipientName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        city: (_cityAutocompleteCtrl?.text ?? '').trim(),
        zone: _zoneCtrl.text.trim(),
        quantity: _quantity,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Failure catch (e) {
      setState(() => _submitting = false);
      if (mounted) context.showErrorSnackBar(e.message);
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) context.showErrorSnackBar('Failed to request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final totalPrice = (_priceMru ?? 0) * _quantity;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Request Physical Copy',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loadingPrice
                      ? 'Loading price…'
                      : 'Fee: $totalPrice MRU (${_priceMru ?? 0} × $_quantity), '
                            'charged to your wallet balance.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Searchable city picker — type to filter _kCities, or
                    // just pick from the full list. Whatever's typed is
                    // what actually gets submitted (read from the captured
                    // controller at submit time), so it degrades gracefully
                    // even if nothing in the list matches exactly.
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue value) {
                          if (value.text.isEmpty) return _kCities;
                          final query = value.text.toLowerCase();
                          return _kCities.where(
                            (c) => c.toLowerCase().contains(query),
                          );
                        },
                        // Autocomplete already writes the selection into the
                        // field's own controller before this fires — no
                        // extra state to sync here.
                        onSelected: (_) {},
                        fieldViewBuilder:
                            (context, controller, focusNode, onSubmitted) {
                              _cityAutocompleteCtrl = controller;
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'City',
                                ),
                                validator: (v) =>
                                    (v?.trim().isEmpty ?? true)
                                    ? 'Required'
                                    : null,
                              );
                            },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _zoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Zone / District',
                          hintText: 'e.g. Tevragh Zeina',
                        ),
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Quantity', style: theme.textTheme.bodyMedium),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Text(
                      '$_quantity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _submitting || _loadingPrice ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Request'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
