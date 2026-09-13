import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../../../shared/widgets/overlays/branded_status_view.dart';

/// Resolves the public `/u/:username` profile link (see
/// AppConstants.publicProfileUrl) to the real profile — a genuine
/// registered GoRoute rather than a redirect-rewrite hack, so it works
/// uniformly for a cold-start App Link tap AND ordinary in-app
/// navigation, with no changes needed to the existing synchronous
/// GoRouter redirect (which the `/profile/<uuid>` legacy deep link
/// already depends on for other things and shouldn't be made more
/// complex than it already is).
///
/// Never itself shows the visitor anything but a brief loading state or a
/// not-found message; on success it replaces itself with the actual
/// [UserProfileScreen] so backing out from the resolved profile goes
/// straight to wherever the visitor came from, not back to a dead-end
/// "loading…" screen.
class UsernameProfileResolverScreen extends StatefulWidget {
  const UsernameProfileResolverScreen({super.key, required this.username});

  final String username;

  @override
  State<UsernameProfileResolverScreen> createState() =>
      _UsernameProfileResolverScreenState();
}

class _UsernameProfileResolverScreenState
    extends State<UsernameProfileResolverScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final user = await sl.profileRepository.getProfileByUsername(
        widget.username,
      );
      if (!mounted) return;
      if (user == null) {
        setState(() => _error = context.l10n.usernameProfileNotFound);
        return;
      }
      // A GoRouter pushReplacement, not a raw Navigator one: this screen
      // is itself reached as a real GoRoute (/u/:username), so handing
      // off via the Navigator directly leaves GoRouter's own idea of the
      // current location stuck on /u/:username even though the visible
      // top is now the real profile — the exact mismatch that let a
      // later platform-driven route push (or any other GoRouter
      // rebuild) resurrect this resolver screen from GoRouter's stale
      // state after the profile was popped. Same fix as
      // qr_scan_screen.dart's own pop+push -> pushReplacement change.
      context.pushReplacement('/user/${user.id}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = context.l10n.usernameProfileNotFound);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: _error!,
          onRetry: () {
            setState(() => _error = null);
            _resolve();
          },
        ),
      );
    }
    return BrandedStatusView(
      emoji: '👤',
      title: context.l10n.usernameProfileResolving,
    );
  }
}
