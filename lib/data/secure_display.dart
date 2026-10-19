/// Screenshot / screen-recording protection — the same protection Google
/// Authenticator uses so live 2FA codes can't leak.
///
/// On Android this is enforced natively and unconditionally: `MainActivity`
/// sets `FLAG_SECURE` in `onCreate` (see android/.../MainActivity.kt), which
/// blocks screenshots and screen recording and blanks the recents preview.
/// Because it is set at the Activity level there is nothing to toggle from
/// Dart, so [enableSecureDisplay] is a no-op kept as the single call site the
/// rest of the app uses — if an iOS host project is added later, the iOS
/// app-switcher cover can be wired in here without touching callers.
Future<void> enableSecureDisplay() async {
  // Intentionally empty: Android protection is applied natively at startup.
}
