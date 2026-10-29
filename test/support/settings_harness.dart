import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarv_authenticator/data/account.dart';
import 'package:sarv_authenticator/data/account_store.dart';
import 'package:sarv_authenticator/data/app_lock.dart';
import 'package:sarv_authenticator/data/backup_service.dart';
import 'package:sarv_authenticator/data/theme_controller.dart';
import 'package:sarv_authenticator/ui/settings_screen.dart';
import 'package:sarv_authenticator/ui/theme.dart';

/// App lock with scripted answers, so Settings needs no platform calls.
/// [authenticateResult] is what the biometric prompt returns; each prompt is
/// counted in [authenticateCalls]. Set [heldPrompt] to keep the prompt open
/// until the test completes it.
class FakeLock implements AppLock {
  FakeLock({
    this.available = false,
    this.enabled = false,
    this.authenticateResult = true,
  });

  final bool available;
  bool enabled;
  bool authenticateResult;
  int authenticateCalls = 0;
  Completer<bool>? heldPrompt;

  @override
  bool isPrompting = false;

  @override
  Future<bool> get isAvailable async => available;
  @override
  Future<bool> isEnabled() async => enabled;
  @override
  Future<void> setEnabled(bool value) async => enabled = value;
  @override
  Future<Duration> autoLockDelay() async => Duration.zero;
  @override
  Future<void> setAutoLockDelay(Duration delay) async {}
  @override
  Future<bool> authenticate() async {
    authenticateCalls++;
    isPrompting = true;
    try {
      return await (heldPrompt?.future ?? Future.value(authenticateResult));
    } finally {
      isPrompting = false;
    }
  }
}

/// Pumps the real Settings screen with in-memory storage.
Future<void> openSettings(
  WidgetTester tester, {
  AppLock? lock,
  BackupService backup = const BackupService(),
  List<Account> accounts = const [],
}) async {
  FlutterSecureStorage.setMockInitialValues({});
  final store = AccountStore();
  await Future.wait(accounts.map(store.add));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(AppTokens.light, Brightness.light),
      home: SettingsScreen(
        lock: lock ?? FakeLock(),
        store: store,
        theme: ThemeController(),
        backup: backup,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
