// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:jma3a/Failures.dart';
// import 'package:provider/provider.dart';
// import '../../../../core/di/service_locator.dart';
// import '../../../../core/errors/failures.dart';
// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/providers/auth_provider.dart';
// import '../../domain/room_entity.dart';

// class JoinCodeDialog extends StatefulWidget {
//   const JoinCodeDialog({super.key});

//   @override
//   State<JoinCodeDialog> createState() => _JoinCodeDialogState();
// }

// class _JoinCodeDialogState extends State<JoinCodeDialog> {
//   final _ctrl = TextEditingController();
//   bool _isJoining = false;
//   bool _isPending = false;
//   String? _error;

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   Future<void> _join() async {
//     final code = _ctrl.text.trim().toUpperCase();
//     if (code.length != 6) {
//       setState(() => _error = 'Code must be 6 characters');
//       return;
//     }
//     setState(() {
//       _isJoining = true;
//       _error = null;
//     });
//     try {
//       final userId = context.read<AuthProvider>().currentUser!.id;
//       final room = await sl.roomRepository.joinByCode(
//         userId: userId,
//         inviteCode: code,
//       );
//       if (mounted) Navigator.pop(context, room);
//     } on PendingApprovalFailure {
//       // Room requires approval — show pending state
//       if (mounted)
//         setState(() {
//           _isJoining = false;
//           _isPending = true;
//         });
//     } catch (e) {
//       if (mounted)
//         setState(() {
//           _isJoining = false;
//           _error = e is Failure ? e.message : 'Invalid code or room not found';
//         });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;

//     // Pending approval state
//     if (_isPending) {
//       return AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text('⏳', style: TextStyle(fontSize: 48)),
//             const SizedBox(height: 16),
//             Text(
//               'Request Sent!',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Your join request has been sent. You\'ll be notified once the host approves it.',
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//         actions: [
//           FilledButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       );
//     }

//     return AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       title: Text(
//         context.l10n.roomsJoinCode,
//         style: theme.textTheme.titleLarge?.copyWith(
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             context.l10n.roomsEnterCode,
//             style: theme.textTheme.bodyMedium?.copyWith(
//               color: theme.colorScheme.onSurfaceVariant,
//             ),
//           ),
//           const SizedBox(height: 16),
//           TextFormField(
//             controller: _ctrl,
//             autofocus: true,
//             maxLength: 6,
//             textCapitalization: TextCapitalization.characters,
//             textAlign: TextAlign.center,
//             inputFormatters: [
//               FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
//               _UpperCaseFormatter(),
//             ],
//             onFieldSubmitted: (_) => _join(),
//             decoration: InputDecoration(
//               hintText: context.l10n.roomsCodeHint,
//               counterText: '',
//               errorText: _error,
//             ),
//             style: theme.textTheme.headlineSmall?.copyWith(
//               fontWeight: FontWeight.w700,
//               letterSpacing: 8,
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: Text(context.l10n.cancel),
//         ),
//         FilledButton(
//           onPressed: _isJoining ? null : _join,
//           child: _isJoining
//               ? const SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
//               : Text(context.l10n.roomsJoin),
//         ),
//       ],
//     );
//   }
// }

// class _UpperCaseFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) =>
//       n.copyWith(text: n.text.toUpperCase());
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../domain/room_entity.dart';

class JoinCodeDialog extends StatefulWidget {
  const JoinCodeDialog({super.key, this.prefillCode, this.invitedBy});

  /// If set, the dialog pre-fills the code and auto-submits.
  final String? prefillCode;

  /// If set, the player was directly invited by this userId — skip approval.
  final String? invitedBy;

  @override
  State<JoinCodeDialog> createState() => _JoinCodeDialogState();
}

class _JoinCodeDialogState extends State<JoinCodeDialog> {
  late final TextEditingController _ctrl;
  bool _isJoining = false;
  bool _isPending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.prefillCode ?? '');
    // Auto-join when a code is pre-filled (came from deep link / invite)
    if (widget.prefillCode != null && widget.prefillCode!.length == 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _join());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Code must be 6 characters');
      return;
    }
    setState(() {
      _isJoining = true;
      _error = null;
    });
    try {
      final userId = context.read<AuthProvider>().currentUser!.id;
      final room = await sl.roomRepository.joinByCode(
        userId: userId,
        inviteCode: code,
        invitedBy: widget.invitedBy,
      ); // bypass approval if invited
      if (mounted) Navigator.pop(context, room);
    } on PendingApprovalFailure {
      if (mounted)
        setState(() {
          _isJoining = false;
          _isPending = true;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _isJoining = false;
          _error = e is Failure ? e.message : 'Invalid code or room not found';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    // Pending approval state
    if (_isPending) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏳', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Request Sent!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your join request has been sent. You\'ll be notified once the host approves it.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        context.l10n.roomsJoinCode,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.roomsEnterCode,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ctrl,
            autofocus: true,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              _UpperCaseFormatter(),
            ],
            onFieldSubmitted: (_) => _join(),
            decoration: InputDecoration(
              hintText: context.l10n.roomsCodeHint,
              counterText: '',
              errorText: _error,
            ),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _isJoining ? null : _join,
          child: _isJoining
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(context.l10n.roomsJoin),
        ),
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) =>
      n.copyWith(text: n.text.toUpperCase());
}
