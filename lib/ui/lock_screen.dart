import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_logo.dart';
import 'theme.dart';

/// Translucent lock overlay. It blurs and dims whatever is behind it (the code
/// list) while the app is locked, so codes are unreadable but the app's shape
/// stays recognisable behind the unlock prompt. Meant to be stacked on top of
/// the content by [AuthGate]; it fills the stack.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key, required this.onUnlock, this.authenticating = false});

  final VoidCallback onUnlock;
  final bool authenticating;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Positioned.fill(
      child: BackdropFilter(
        // Strong enough that 6-digit codes behind it are unreadable.
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          type: MaterialType.transparency,
          // Opaque-to-hit-testing scrim blocks taps reaching the list beneath.
          child: Container(
            color: tokens.bg.withValues(alpha: 0.72),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.space7),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo(size: 96),
                      const SizedBox(height: AppTokens.space6),
                      Text(
                        'Sarv Authenticator',
                        style: TextStyle(
                          fontFamily: AppTokens.fontSans,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space2),
                      Text(
                        'Locked for your security',
                        style: TextStyle(
                          fontFamily: AppTokens.fontSans,
                          fontSize: 13,
                          color: tokens.muted,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space7),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: tokens.brand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppTokens.space4,),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTokens.rMd),
                            ),
                          ),
                          onPressed: authenticating ? null : onUnlock,
                          icon: authenticating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white,),
                                )
                              : const Icon(Icons.fingerprint),
                          label: Text(
                              authenticating ? 'Authenticating...' : 'Unlock',),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
