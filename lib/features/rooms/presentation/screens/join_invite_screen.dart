import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../profile/data/profile_repository.dart';

/// Landing screen for a room-invite deep link — reached via the `/join`
/// go_router route (see AppRouter), whether that came from the
/// https://jma3a.com/join Universal/App Link or the jma3a:// fallback
/// scheme (DeepLinkService normalizes both to the same route). Unlike the
/// old JoinCodeDialog-only flow, this is a full screen so it reads
/// naturally as a distinct "you've been invited" moment, and it shows who
/// sent the invite before joining.
class JoinInviteScreen extends StatefulWidget {
  const JoinInviteScreen({super.key, required this.code, this.invitedBy});

  final String code;
  final String? invitedBy;

  @override
  State<JoinInviteScreen> createState() => _JoinInviteScreenState();
}

class _JoinInviteScreenState extends State<JoinInviteScreen> {
  bool _isJoining = false;
  bool _isPending = false;
  String? _error;
  InviterInfo? _inviter;
  bool _loadingInviter = true;

  @override
  void initState() {
    super.initState();
    _loadInviter();
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

  Future<void> _loadInviter() async {
    final invitedBy = widget.invitedBy;
    if (invitedBy == null || invitedBy.isEmpty) {
      setState(() => _loadingInviter = false);
      return;
    }
    try {
      final inviter = await ProfileRepository.instance.getInviterInfo(
        invitedBy,
      );
      if (mounted) setState(() => _inviter = inviter);
    } catch (_) {
      // Non-critical — the join itself doesn't depend on this.
    } finally {
      if (mounted) setState(() => _loadingInviter = false);
    }
  }

  Future<void> _join() async {
    final code = widget.code.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = context.l10n.roomsInvalidCodeOrNotFound);
      return;
    }
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isJoining = true;
      _error = null;
    });
    try {
      final room = await sl.roomRepository.joinByCode(
        userId: userId,
        inviteCode: code,
        invitedBy: widget.invitedBy,
      );
      if (mounted) context.pushReplacement('/home/room/${room.id}');
    } on PendingApprovalFailure {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _isPending = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _error = e is Failure ? e.message : context.l10n.roomsInvalidCodeOrNotFound;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.roomsJoinCode)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loadingInviter)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_inviter != null)
                _InviterBanner(inviter: _inviter!),
              const SizedBox(height: 16),
              Text(
                widget.code.toUpperCase(),
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 24),
              if (_isPending) ...[
                const Text('⏳', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  l10n.roomsRequestSentTitle,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.roomsRequestSentBody,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(RouteNames.home),
                  child: Text(l10n.ok),
                ),
              ] else if (_error != null) ...[
                Text(
                  _error!,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Explicit minimumSize:Size.zero on both — the app-wide
                // OutlinedButton/FilledButton theme sets minimumSize:
                // Size(double.infinity, 52) (for full-width primary
                // CTAs); a Row gives an unbounded max width to
                // non-Expanded children, so two unwrapped themed buttons
                // side by side here throws "BoxConstraints forces an
                // infinite width" the instant a join fails and this
                // error state renders — i.e. exactly when a player is
                // trying to join a room via invite/code.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.go(RouteNames.home),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isJoining ? null : _join,
                      style: FilledButton.styleFrom(
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l10n.roomsJoin),
                    ),
                  ],
                ),
              ] else if (_isJoining)
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviterBanner extends StatelessWidget {
  const _InviterBanner({required this.inviter});
  final InviterInfo inviter;

  @override
  Widget build(BuildContext context) {
    final name = inviter.displayName ?? context.l10n.roomsJoinCode;
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundImage: inviter.avatarUrl != null
              ? NetworkImage(inviter.avatarUrl!)
              : null,
          child: inviter.avatarUrl == null
              ? const Icon(Icons.person_rounded, size: 32)
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.roomsInvitedByName(name),
          style: context.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
