import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sarv_authenticator/data/account.dart';
import 'package:sarv_authenticator/data/account_store.dart';
import 'package:sarv_authenticator/data/app_lock.dart';
import 'package:sarv_authenticator/data/backup_service.dart';
import 'package:sarv_authenticator/data/theme_controller.dart';
import 'package:sarv_authenticator/ui/settings_screen.dart';
import 'package:sarv_authenticator/ui/theme.dart';

/// Drives the real Settings backup flows against the platform: real
/// encryption, real Keychain/Keystore storage and the native share sheet.
/// Only the file picker is stubbed, because a native picker cannot be driven
/// from a Flutter test.
///
/// Export runs last: the share sheet it opens stays up until dismissed.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const demoAccount = Account(
    id: '1',
    issuer: 'GitHub',
    account: 'ankur.d@sarv.com',
    secretBase32: 'JBSWY3DPEHPK3PXP',
  );

  Future<AccountStore> openSettings(
    WidgetTester tester, {
    required BackupService backup,
    required List<Account> accounts,
  }) async {
    final store = AccountStore();
    await tester.runAsync(() async {
      await store.load();
      await Future.wait(
        store.accounts.map((account) => store.remove(account.id)),
      );
      await Future.wait(accounts.map(store.add));
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AppTokens.light, Brightness.light),
        home: SettingsScreen(
          lock: AppLock(),
          store: store,
          theme: ThemeController(),
          backup: backup,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> enterPassphrase(
    WidgetTester tester, {
    required bool confirm,
  }) async {
    await tester.enterText(find.widgetWithText(TextField, 'Passphrase'), 'pw');
    if (confirm) {
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm passphrase'),
        'pw',
      );
    }
    await tester.tap(find.text('Continue'));
  }

  /// Pumps real time until [finder] matches or [timeout] passes; key
  /// derivation and platform calls run outside the fake test clock.
  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline) && finder.evaluate().isEmpty) {
      await tester
          .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
  }

  testWidgets('import decrypts a real backup and saves its accounts',
      (tester) async {
    const service = BackupService();
    final contents = await tester.runAsync(() async {
      final path = await service.writeEncryptedBackup(
        accounts: [demoAccount],
        passphrase: 'pw',
      );
      return File(path).readAsString();
    });
    final store = await openSettings(
      tester,
      backup: _PickedBackup(contents!),
      accounts: [],
    );

    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();
    await enterPassphrase(tester, confirm: false);
    await pumpUntil(tester, find.byType(SnackBar));

    expect(find.text('Imported 1 account'), findsOneWidget);
    expect(store.accounts.single.secretBase32, demoAccount.secretBase32);
  });

  testWidgets('export opens the share sheet without an error', (tester) async {
    await openSettings(
      tester,
      backup: const BackupService(),
      accounts: [demoAccount],
    );

    await tester.tap(find.text('Export encrypted backup'));
    await tester.pumpAndSettle();
    await enterPassphrase(tester, confirm: true);
    // Let the loader appear, then give encryption and the share call time to
    // fail if they will.
    await pumpUntil(
      tester,
      find.text('Encrypting backup…'),
      timeout: const Duration(seconds: 2),
    );
    await pumpUntil(
      tester,
      find.textContaining('Export failed'),
      timeout: const Duration(seconds: 15),
    );

    expect(find.textContaining('Export failed'), findsNothing);
    await tester.pump(const Duration(seconds: 1)); // loader's close animation
    expect(find.text('Encrypting backup…'), findsNothing);
  });
}

/// Real backup service whose picker returns a fixed file's contents.
class _PickedBackup extends BackupService {
  const _PickedBackup(this.contents);

  final String contents;

  @override
  Future<String?> pickBackup() async => contents;
}
