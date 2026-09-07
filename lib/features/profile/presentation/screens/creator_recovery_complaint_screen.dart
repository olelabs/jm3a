import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../data/profile_repository.dart';

/// Item 8: lets a creator whose verified status/privileges were
/// auto-removed (item 7, UserEntity.canSubmitCreatorRecoveryComplaint)
/// submit a complaint — reason, explanation, optional evidence — for admin
/// review. Approval restores everything atomically server-side
/// (handle_creator_recovery_complaint_decision trigger); this screen only
/// ever shows the current state, never assumes an outcome client-side.
class CreatorRecoveryComplaintScreen extends StatefulWidget {
  const CreatorRecoveryComplaintScreen({super.key});

  @override
  State<CreatorRecoveryComplaintScreen> createState() =>
      _CreatorRecoveryComplaintScreenState();
}

class _CreatorRecoveryComplaintScreenState
    extends State<CreatorRecoveryComplaintScreen> {
  static const _reasonCategories = [
    'resubscribed_late',
    'payment_issue',
    'unaware_of_expiry',
    'extenuating_circumstances',
    'other',
  ];

  bool _loading = true;
  bool _submitting = false;
  bool _uploadingEvidence = false;
  CreatorRecoveryComplaint? _latest;
  String? _error;

  String _reasonCategory = _reasonCategories.first;
  final _explanationCtrl = TextEditingController();
  final List<String> _evidenceUrls = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _explanationCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final latest = await ProfileRepository.instance
          .getLatestCreatorRecoveryComplaint(userId);
      if (mounted) setState(() => _latest = latest);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.errorUnexpected);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickEvidence() async {
    if (_evidenceUrls.length >= 5) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingEvidence = true);
    try {
      final bytes = await File(picked.path).readAsBytes();
      final url = await MediaUploadService.instance
          .uploadCreatorRecoveryEvidence(
            bytes: bytes,
            contentType: 'image/jpeg',
          );
      if (url != null && mounted) {
        setState(() => _evidenceUrls.add(url));
      } else if (mounted) {
        context.showErrorSnackBar(context.l10n.creatorRecoveryEvidenceUploadFailed);
      }
    } finally {
      if (mounted) setState(() => _uploadingEvidence = false);
    }
  }

  Future<void> _submit() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    final explanation = _explanationCtrl.text.trim();
    if (explanation.length < 20) {
      context.showErrorSnackBar(context.l10n.creatorRecoveryExplanationTooShort);
      return;
    }

    setState(() => _submitting = true);
    try {
      await ProfileRepository.instance.submitCreatorRecoveryComplaint(
        userId: userId,
        reasonCategory: _reasonCategory,
        explanation: explanation,
        evidenceUrls: _evidenceUrls,
      );
      if (mounted) {
        context.showSnackBar(context.l10n.creatorRecoverySubmitted);
        await _load();
      }
    } catch (_) {
      if (mounted) context.showErrorSnackBar(context.l10n.creatorRecoveryFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.creatorRecoveryTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : (_latest?.isPending ?? false)
          ? _PendingStatus(complaint: _latest!)
          : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final l10n = context.l10n;
    final rejected = _latest != null && _latest!.status == 'rejected';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (rejected) _RejectedNotice(complaint: _latest!),
        if (rejected) const SizedBox(height: 20),
        Text(
          l10n.creatorRecoveryIntro,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.creatorRecoveryReasonLabel,
          style: context.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _reasonCategory,
          items: _reasonCategories
              .map(
                (r) => DropdownMenuItem(
                  value: r,
                  child: Text(_reasonLabel(context, r)),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _reasonCategory = v ?? _reasonCategory),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.creatorRecoveryExplanationLabel,
          style: context.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _explanationCtrl,
          maxLines: 5,
          maxLength: 1000,
          decoration: InputDecoration(
            hintText: l10n.creatorRecoveryExplanationHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.creatorRecoveryEvidenceLabel,
          style: context.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final url in _evidenceUrls)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
            if (_evidenceUrls.length < 5)
              InkWell(
                onTap: _uploadingEvidence ? null : _pickEvidence,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    border: Border.all(color: context.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _uploadingEvidence
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.creatorRecoverySubmit),
        ),
      ],
    );
  }

  String _reasonLabel(BuildContext context, String category) => switch (category) {
    'resubscribed_late' => context.l10n.creatorRecoveryReasonResubscribedLate,
    'payment_issue' => context.l10n.creatorRecoveryReasonPaymentIssue,
    'unaware_of_expiry' => context.l10n.creatorRecoveryReasonUnawareOfExpiry,
    'extenuating_circumstances' =>
      context.l10n.creatorRecoveryReasonExtenuatingCircumstances,
    _ => context.l10n.creatorRecoveryReasonOther,
  };
}

class _PendingStatus extends StatelessWidget {
  const _PendingStatus({required this.complaint});
  final CreatorRecoveryComplaint complaint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top_rounded, size: 48),
            const SizedBox(height: 16),
            Text(
              l10n.creatorRecoveryPendingTitle,
              style: context.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.creatorRecoveryPendingBody,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectedNotice extends StatelessWidget {
  const _RejectedNotice({required this.complaint});
  final CreatorRecoveryComplaint complaint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.creatorRecoveryRejectedTitle,
            style: context.textTheme.titleSmall?.copyWith(
              color: context.colorScheme.onErrorContainer,
            ),
          ),
          if (complaint.adminNotes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            Text(
              complaint.adminNotes!,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
