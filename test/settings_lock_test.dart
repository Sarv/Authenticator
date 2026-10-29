import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/settings_harness.dart';

Future<void> _tapLockSwitch(WidgetTester tester) async {
  await tester.tap(find.byType(Switch));
  await tester.pumpAndSettle();
}

bool _switchIsOn(WidgetTester tester) =>
    tester.widget<Switch>(find.byType(Switch)).value;

void main() {
  testWidgets('turning the lock on asks for authentication', (tester) async {
    final lock = FakeLock(available: true);
    await openSettings(tester, lock: lock);

    await _tapLockSwitch(tester);

    expect(lock.authenticateCalls, 1);
    expect(lock.enabled, isTrue);
    expect(_switchIsOn(tester), isTrue);
  });

  testWidgets('turning the lock off asks for authentication', (tester) async {
    final lock = FakeLock(available: true, enabled: true);
    await openSettings(tester, lock: lock);

    await _tapLockSwitch(tester);

    expect(lock.authenticateCalls, 1);
    expect(lock.enabled, isFalse);
    expect(_switchIsOn(tester), isFalse);
  });

  testWidgets('a failed authentication keeps the lock on', (tester) async {
    final lock = FakeLock(
      available: true,
      enabled: true,
      authenticateResult: false,
    );
    await openSettings(tester, lock: lock);

    await _tapLockSwitch(tester);

    expect(lock.authenticateCalls, 1);
    expect(lock.enabled, isTrue);
    expect(_switchIsOn(tester), isTrue);
  });

  testWidgets('a failed authentication leaves the lock off', (tester) async {
    final lock = FakeLock(available: true, authenticateResult: false);
    await openSettings(tester, lock: lock);

    await _tapLockSwitch(tester);

    expect(lock.enabled, isFalse);
    expect(_switchIsOn(tester), isFalse);
  });
}
