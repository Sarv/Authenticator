import 'dart:async';

import 'package:flutter/material.dart';
import 'data/account_store.dart';
import 'data/app_lock.dart';
import 'data/secure_display.dart';
import 'data/theme_controller.dart';
import 'ui/auth_gate.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Block screenshots / screen recording of 2FA codes (like Google Authenticator).
  await enableSecureDisplay();
  final store = AccountStore();
  final theme = ThemeController();
  // Paint the first frame (splash -> lock screen) immediately. The Keystore read
  // is off the critical path: the user must pass the lock before any account is
  // shown, and the store notifies its listeners once the load completes, so the
  // list fills in behind the lock with time to spare. The theme preference loads
  // the same way — the app renders in the system theme until it arrives.
  runApp(SarvAuthenticatorApp(store: store, lock: AppLock(), theme: theme));
  unawaited(store.load());
  unawaited(theme.load());
}

class SarvAuthenticatorApp extends StatelessWidget {
  const SarvAuthenticatorApp({
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
        title: 'Sarv Authenticator',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(AppTokens.light, Brightness.light),
        darkTheme: buildAppTheme(AppTokens.dark, Brightness.dark),
        themeMode: theme.mode,
        home: AuthGate(
          lock: lock,
          child: HomeScreen(store: store, lock: lock, theme: theme),
        ),
      ),
    );
  }
}
