import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/otpauth_uri.dart';
import '../data/account.dart';
import 'theme.dart';

/// Camera QR scanner. On a successful `otpauth://` scan it pops back the parsed
/// [Account]; the caller persists it. Keeps all camera I/O at this edge.
///
/// The [MobileScanner] widget owns its controller here, so it manages the camera
/// across app-lifecycle changes itself (`useAppLifecycleState`, on by default).
/// That is what fixes the first-run permission race: the preview starts before
/// the OS permission is granted, and the widget restarts the camera once the
/// permission dialog closes and the app resumes — no manual observer needed.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled || !mounted) return;
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;

    try {
      final account = Account.fromOtpauth(parseOtpauthUri(raw));
      _handled = true;
      Navigator.of(context).pop(account);
    } catch (_) {
      // Not a valid otpauth QR — keep scanning silently.
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan QR code'),
      ),
      body: MobileScanner(
        onDetect: _onDetect,
        errorBuilder: (context, error) => _ScanError(error: error),
        // The reticle goes in overlayBuilder, which the scanner only draws over
        // a live preview. Stacked on top of the scanner instead, it also covered
        // the permission-denied screen and swallowed taps on its "Go back"
        // button, which sits inside the reticle's 240x240 centre.
        overlayBuilder: (context, constraints) => Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: tokens.brand, width: 3),
              borderRadius: BorderRadius.circular(AppTokens.rXl),
            ),
          ),
        ),
      ),
    );
  }
}

/// Branded replacement for mobile_scanner's default error glyph (the bare "!").
/// Shown when the camera cannot start — most often a denied permission.
class _ScanError extends StatelessWidget {
  const _ScanError({required this.error});

  final MobileScannerException error;

  bool get _isPermission =>
      error.errorCode == MobileScannerErrorCode.permissionDenied;

  @override
  Widget build(BuildContext context) {
    final message = _isPermission
        ? 'Camera access is off. Allow camera access in Settings to scan a QR '
            'code, or go back and add the account with a setup key instead.'
        : 'The camera could not start. Go back and add the account with a setup '
            'key instead.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 56,
              color: Colors.white70,
            ),
            const SizedBox(height: AppTokens.space4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTokens.fontSans,
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: AppTokens.space5),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              label: const Text(
                'Go back',
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
