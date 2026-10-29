import 'dart:async';

import 'package:flutter/material.dart';
import 'data/account_store.dart';
import 'data/app_lock.dart';
import 'data/secure_display.dart';
import 'data/theme_controller.dart';
import 'ui/auth_gate.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

// Shows app-wide messages that don't belong to any one screen.
final _messenger = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Block screenshots / screen recording of 2FA codes. iOS still takes the
  // (blank) screenshot, so say why it came out empty.
  await enableSecureDisplay(
    switcherCover: AppTokens.light.brand,
    onScreenshot: () => _messenger.currentState
      ?..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Screenshots are blocked to protect your codes'),
        ),
      ),
  );
  final store = AccountStore();
  final theme = ThemeController();
  // Paint the first frame (splash -> lock screen) immediately. The Keystore read
  // is off the critical path: the user must pass the lock before any account is
  // shown, and the store notifies its listeners once the load completes, so the
  // list fills in behind the lock with time to spare. The theme preference loads
  // the same way — the app renders in the system theme until it arrives.
  runApp(SarvOtpApp(store: store, lock: AppLock(), theme: theme));
  unawaited(store.load());
  unawaited(theme.load());
}

class SarvOtpApp extends StatelessWidget {
  const SarvOtpApp({
    super.key,
    required this.store,
    required this.lock,
    required this.theme,
  });

  final AccountStore store;
  final AppLock lock;
  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: theme,
      builder: (context, _) => MaterialApp(
        title: 'Sarv OTP',
        scaffoldMessengerKey: _messenger,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(AppTokens.light, Brightness.light),
        darkTheme: buildAppTheme(AppTokens.dark, Brightness.dark),
        themeMode: theme.mode,
        // The gate wraps the Navigator, not the home route, so the lock screen
        // also covers Settings, the scanner and any dialog pushed on top.
        builder: (context, navigator) =>
            AuthGate(lock: lock, child: navigator!),
        home: HomeScreen(store: store, lock: lock, theme: theme),
      ),
    );
  }
}
