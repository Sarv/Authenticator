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

const _demoAccount = Account(
  id: '1',
  issuer: 'GitHub',
  account: 'ankur.d@sarv.com',
  secretBase32: 'JBSWY3DPEHPK3PXP',
);

/// Lock that reports no device support, so Settings needs no platform calls.
class _NoLock implements AppLock {
  @override
  Future<bool> get isAvailable async => false;
  @override
  Future<bool> isEnabled() async => false;
  @override
  Future<Duration> autoLockDelay() async => Duration.zero;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records what Settings hands to the platform layer instead of opening
/// native sheets.
class _RecordingBackup implements BackupService {
  _RecordingBackup({this.pickedContents});

  final String? pickedContents;
  Rect? sharedOrigin;
  String? sharedPath;

  @override
  Future<String> writeEncryptedBackup({
    required List<Account> accounts,
    required String passphrase,
  }) async =>
      '/tmp/backup.json';

  @override
  Future<void> share(String path, {required Rect origin}) async {
    sharedPath = path;
    sharedOrigin = origin;
  }

  @override
  Future<String?> pickBackup() async => pickedContents;

  @override
  Future<List<Account>> decrypt({
    required String contents,
    required String passphrase,
  }) async =>
      [_demoAccount];
}

Future<void> _openSettings(
  WidgetTester tester, {
  required BackupService backup,
  required List<Account> accounts,
}) async {
  FlutterSecureStorage.setMockInitialValues({});
  final store = AccountStore();
  await Future.wait(accounts.map(store.add));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(AppTokens.light, Brightness.light),
      home: SettingsScreen(
        lock: _NoLock(),
        store: store,
        theme: ThemeController(),
        backup: backup,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enterPassphrase(
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
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('export anchors the share sheet to the export row',
      (tester) async {
    final backup = _RecordingBackup();
    await _openSettings(tester, backup: backup, accounts: [_demoAccount]);

    final exportRow = find.text('Export encrypted backup');
    final rowCentre = tester.getCenter(exportRow);
    await tester.tap(exportRow);
    await tester.pumpAndSettle();
    await _enterPassphrase(tester, confirm: true);

    // iOS rejects a zero or off-screen origin ("sharePositionOrigin: argument
    // must be set"), so it must be a real rect covering the tapped row.
    final origin = backup.sharedOrigin!;
    final screen =
        Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(backup.sharedPath, '/tmp/backup.json');
    expect(origin.isEmpty, isFalse);
    expect(
      screen.contains(origin.topLeft) &&
          screen.contains(origin.bottomRight - const Offset(1, 1)),
      isTrue,
    );
    expect(origin.contains(rowCentre), isTrue);
    expect(find.textContaining('Export failed'), findsNothing);
  });

  testWidgets('import adds the accounts from the picked backup',
      (tester) async {
    final backup = _RecordingBackup(pickedContents: '{}');
    await _openSettings(tester, backup: backup, accounts: []);

    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();
    await _enterPassphrase(tester, confirm: false);

    expect(find.text('Imported 1 account'), findsOneWidget);
    expect(find.textContaining('Import failed'), findsNothing);
  });

  testWidgets('cancelling the picker imports nothing and shows no error',
      (tester) async {
    final backup = _RecordingBackup();
    await _openSettings(tester, backup: backup, accounts: []);

    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();
    await _enterPassphrase(tester, confirm: false);

    expect(find.byType(SnackBar), findsNothing);
  });
}
