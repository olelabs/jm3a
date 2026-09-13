import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../deep_links.dart';

/// Item 7 (QR codes) — resolves a raw scanned string into the in-app
/// GoRouter location to navigate to, reusing the EXACT same parsers
/// DeepLinkService already uses for native App Links/custom-scheme URLs
/// (parseInviteLink/parseUsernameProfileLink/parseProfileLink — see
/// deep_links.dart) rather than re-implementing any of that matching or
/// validation logic. Returns null for anything that isn't a recognized
/// Jma3a room-invite or profile link — the caller must treat that as
/// "not a valid Jma3a QR code," never guess a destination.
///
/// Deliberately returns a ROUTE, not a direct join/navigation action:
/// pushing `/join?code=...` reuses JoinInviteScreen's own
/// RoomRepository.joinByCode call (the exact same authorization —
/// visibility/closed/capacity/approval — every other join path already
/// goes through), and pushing `/u/<username>`/`/user/<id>` reuses the
/// existing profile-resolution routes — this function never bypasses
/// any of that by joining/navigating directly itself.
String? resolveScannedQrRoute(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;

  final invite = parseInviteLink(uri);
  if (invite != null) {
    final invitedByParam = invite.invitedBy != null
        ? '&invited_by=${invite.invitedBy}'
        : '';
    return '/join?code=${invite.code}$invitedByParam';
  }

  final username = parseUsernameProfileLink(uri);
  if (username != null) return '/u/$username';

  final legacyProfile = parseProfileLink(uri);
  if (legacyProfile != null) return '/user/${legacyProfile.userId}';

  return null;
}

/// Camera-based QR scanner — the "Scan QR code" option alongside typing
/// a room code (item 7), and the destination for scanning a profile QR
/// too. A successful scan pushes the resolved route (see
/// [resolveScannedQrRoute]) and pops this screen; an unrecognized code
/// shows an inline error with a "Try Again" action rather than
/// navigating anywhere.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController();
  bool _handled = false;
  bool _showInvalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    // One-shot guard: MobileScanner keeps streaming frames (and can call
    // onDetect more than once for the same barcode batch) until the
    // camera is actually stopped below, and the pop+push transition below
    // takes a frame or two to complete — without this flag, a detection
    // event arriving during that window would resolve+navigate a second
    // time. Reset only by _tryAgain (invalid-code retry) — a fresh
    // scanner open always gets a fresh State/instance, so there is
    // nothing else to reset.
    if (_handled) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (raw == null) return;

    final route = resolveScannedQrRoute(raw);
    if (route == null) {
      setState(() => _showInvalid = true);
      return;
    }

    _handled = true;
    // Stop detection immediately — don't wait for dispose(), which only
    // runs once the pop/push transition below has fully completed.
    unawaited(_controller.stop());
    // A single atomic navigation (not a separate Navigator.pop() followed
    // by a GoRouter context.push()): mixing raw Navigator calls with
    // GoRouter's own imperative API on the same route risks GoRouter's
    // match list and the real Navigator falling out of sync across two
    // separate calls, which left this screen (and its still-scanning
    // camera) alive underneath the pushed destination — so Back from the
    // destination landed right back on a live scanner still pointed at
    // the same QR code, immediately re-triggering it. pushReplacement
    // removes this screen and lands the destination in its place in one
    // step, so Back goes straight to whichever screen opened the scanner.
    context.pushReplacement(route);
  }

  void _tryAgain() {
    setState(() {
      _showInvalid = false;
      _handled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(context.l10n.qrScanScreenTitle),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              color: Colors.black.withValues(alpha: 0.55),
              child: _showInvalid
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.qrScanInvalidCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _tryAgain,
                          child: Text(context.l10n.qrScanTryAgain),
                        ),
                      ],
                    )
                  : Text(
                      context.l10n.qrScanInstruction,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
