import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sarv_authenticator/data/account_store.dart';
import 'package:sarv_authenticator/data/app_lock.dart';
import 'package:sarv_authenticator/data/theme_controller.dart';
import 'package:sarv_authenticator/main.dart';
import 'package:sarv_authenticator/ui/auth_gate.dart';
import 'package:sarv_authenticator/ui/lock_screen.dart';

import 'support/settings_harness.dart';

/// Pumps the real app with the lock on and the first unlock already passed.
/// Later prompts fail, so a relock leaves the lock screen up.
Future<FakeLock> _openUnlockedApp(WidgetTester tester) async {
  FlutterSecureStorage.setMockInitialValues({});
  final lock = FakeLock(available: true, enabled: true);
  await tester.pumpWidget(
    SarvOtpApp(store: AccountStore(), lock: lock, theme: ThemeController()),
  );
  await tester.pumpAndSettle();
  expect(find.byType(LockScreen), findsNothing);
  lock.authenticateResult = false;
  return lock;
}

/// Plays the lifecycle states the OS reports when the user leaves and returns.
Future<void> _leaveAndReturn(
  WidgetTester tester,
  List<AppLifecycleState> away,
) async {
  [...away, AppLifecycleState.resumed]
      .forEach(tester.binding.handleAppLifecycleStateChanged);
  await tester.pumpAndSettle();
}

/// iOS app switcher: the app only goes inactive.
const _appSwitcher = [AppLifecycleState.inactive];

/// Home screen / another app: the app goes all the way to paused.
const _background = [
  AppLifecycleState.inactive,
  AppLifecycleState.hidden,
  AppLifecycleState.paused,
  AppLifecycleState.hidden,
  AppLifecycleState.inactive,
];

/// Whether a tap at [finder]'s centre would reach it rather than something
/// drawn over it.
bool _receivesTaps(WidgetTester tester, Finder finder) {
  final target = tester.renderObject(finder);
  final hit = tester.hitTestOnBinding(tester.getCenter(finder));
  return hit.path.any((entry) => entry.target == target);
}

class _HeldAuth extends LocalAuthentication {
  final prompt = Completer<bool>();

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<dynamic> authMessages = const [],
    AuthenticationOptions options = const AuthenticationOptions(),
  }) =>
      prompt.future;
}

void main() {
  group('startsAutoLockClock', () {
    test('paused and hidden start the clock everywhere', () {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        expect(startsAutoLockClock(AppLifecycleState.paused, platform), isTrue);
        expect(startsAutoLockClock(AppLifecycleState.hidden, platform), isTrue);
      }
    });

    test('inactive starts the clock on iOS only', () {
      expect(
        startsAutoLockClock(AppLifecycleState.inactive, TargetPlatform.iOS),
        isTrue,
      );
      expect(
        startsAutoLockClock(AppLifecycleState.inactive, TargetPlatform.android),
        isFalse,
      );
    });

    test('resumed never starts the clock', () {
      expect(
        startsAutoLockClock(AppLifecycleState.resumed, TargetPlatform.iOS),
        isFalse,
      );
    });
  });

  testWidgets(
    'returning from the iOS app switcher locks the app',
    (tester) async {
      final lock = await _openUnlockedApp(tester);

      await _leaveAndReturn(tester, _appSwitcher);

      expect(lock.authenticateCalls, 2);
      expect(find.byType(LockScreen), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'a transient inactive on Android does not lock',
    (tester) async {
      final lock = await _openUnlockedApp(tester);

      await _leaveAndReturn(tester, _appSwitcher);

      expect(lock.authenticateCalls, 1);
      expect(find.byType(LockScreen), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'going to the background locks the app',
    (tester) async {
      final lock = await _openUnlockedApp(tester);

      await _leaveAndReturn(tester, _background);

      expect(lock.authenticateCalls, 2);
      expect(find.byType(LockScreen), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'a biometric prompt from Settings does not relock the app',
    (tester) async {
      final lock = await _openUnlockedApp(tester);
      lock.heldPrompt = Completer<bool>();

      final prompt = lock.authenticate();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      lock.heldPrompt!.complete(true);
      await prompt;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(lock.authenticateCalls, 2);
      expect(find.byType(LockScreen), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'the lock screen covers Settings when the app relocks there',
    (tester) async {
      await _openUnlockedApp(tester);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      final exportRow = find.text('Export encrypted backup');
      expect(_receivesTaps(tester, exportRow), isTrue);

      await _leaveAndReturn(tester, _background);

      expect(find.byType(LockScreen), findsOneWidget);
      expect(_receivesTaps(tester, exportRow), isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  group('AppLock.isPrompting', () {
    test('is true only while the prompt is open', () async {
      final auth = _HeldAuth();
      final lock = AppLock(auth: auth);

      final result = lock.authenticate();
      expect(lock.isPrompting, isTrue);
      auth.prompt.complete(true);

      expect(await result, isTrue);
      expect(lock.isPrompting, isFalse);
    });

    test('clears when the prompt fails', () async {
      final auth = _HeldAuth();
      final lock = AppLock(auth: auth);

      final result = lock.authenticate();
      auth.prompt.completeError(Exception('no biometrics'));

      expect(await result, isFalse);
      expect(lock.isPrompting, isFalse);
    });
  });
}
