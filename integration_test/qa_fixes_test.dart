import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sarv_authenticator/data/account.dart';
import 'package:sarv_authenticator/data/backup_service.dart';
import 'package:sarv_authenticator/ui/progress_dialog.dart';
import 'package:sarv_authenticator/ui/scan_screen.dart';
import 'package:sarv_authenticator/ui/theme.dart';

/// Runs on a real device / simulator: these flows depend on platform code
/// (the camera plugin, real key-derivation timing) that unit tests cannot
/// exercise.
///
/// The scanner test expects the camera to be unavailable — denied permission
/// on Android, or the iOS simulator, which has no camera.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const service = BackupService();
  final accounts = [
    const Account(
      id: '1',
      issuer: 'GitHub',
      account: 'ankur.d@sarv.com',
      secretBase32: 'JBSWY3DPEHPK3PXP',
    ),
  ];

  Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
    for (var attempt = 0;
        attempt < 100 && finder.evaluate().isEmpty;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsOneWidget);
  }

  /// Runs [task] behind the real loader and returns the longest stall of the UI
  /// isolate meanwhile, in ms: the widest gap between 8 ms timer ticks. A long
  /// stall is a frozen loader.
  Future<int> runAndMeasureLongestStall(
    WidgetTester tester,
    Future<Object?> Function() task,
  ) async {
    late BuildContext screenContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AppTokens.light, Brightness.light),
        home: Builder(
          builder: (context) {
            screenContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final sinceTick = Stopwatch()..start();
    var longestStall = 0;
    final ticker = Timer.periodic(const Duration(milliseconds: 8), (_) {
      longestStall = max(longestStall, sinceTick.elapsedMilliseconds);
      sinceTick.reset();
    });
    final work = runWithProgress(
      screenContext,
      message: 'Working…',
      task: task,
    );
    await pumpUntilFound(tester, find.byType(CircularProgressIndicator));
    final stopwatch = Stopwatch()..start();
    await tester.runAsync(() => work);
    ticker.cancel();
    debugPrint(
      'task took ${stopwatch.elapsedMilliseconds} ms, '
      'longest UI stall $longestStall ms',
    );
    await tester.pumpAndSettle();
    expect(find.text('Working…'), findsNothing);
    return longestStall;
  }

  testWidgets('Bug 1: Go back leaves the camera-unavailable screen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AppTokens.light, Brightness.light),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ScanScreen()),
            ),
            child: const Text('Open scanner'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open scanner'));
    await pumpUntilFound(tester, find.text('Go back'));

    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();

    expect(find.byType(ScanScreen), findsNothing);
    expect(find.text('Open scanner'), findsOneWidget);
  });

  testWidgets('Bug 2: export loader stays live while encrypting',
      (tester) async {
    final longestStall = await runAndMeasureLongestStall(
      tester,
      () => service.writeEncryptedBackup(accounts: accounts, passphrase: 'pw'),
    );
    expect(longestStall, lessThan(100));
  });

  testWidgets('Bug 3: import loader stays live while decrypting',
      (tester) async {
    final path = await tester.runAsync(
      () => service.writeEncryptedBackup(accounts: accounts, passphrase: 'pw'),
    );
    final contents = await tester.runAsync(
      () => File(path!).readAsString(),
    );
    final longestStall = await runAndMeasureLongestStall(
      tester,
      () => service.decrypt(contents: contents!, passphrase: 'pw'),
    );
    expect(longestStall, lessThan(100));
  });
}
