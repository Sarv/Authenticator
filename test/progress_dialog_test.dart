import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarv_authenticator/ui/progress_dialog.dart';
import 'package:sarv_authenticator/ui/theme.dart';

/// Pumps a screen with one button that runs [task] behind the loader and
/// records the outcome in [outcome].
Future<void> _pumpLauncher(
  WidgetTester tester,
  Future<String> Function() task,
  List<String> outcome,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [AppTokens.light]),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            try {
              outcome.add(
                await runWithProgress(
                  context,
                  message: 'Working…',
                  task: task,
                ),
              );
            } catch (error) {
              outcome.add('error: $error');
            }
          },
          child: const Text('Start'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Start'));
  await tester.pump();
}

void main() {
  testWidgets('shows the loader until the task completes', (tester) async {
    final completer = Completer<String>();
    final outcome = <String>[];
    await _pumpLauncher(tester, () => completer.future, outcome);

    expect(find.text('Working…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete('done');
    await tester.pumpAndSettle();

    expect(find.text('Working…'), findsNothing);
    expect(outcome, ['done']);
  });

  testWidgets('closes the loader and rethrows when the task fails',
      (tester) async {
    final completer = Completer<String>();
    final outcome = <String>[];
    await _pumpLauncher(tester, () => completer.future, outcome);

    completer.completeError(StateError('boom'));
    await tester.pumpAndSettle();

    expect(find.text('Working…'), findsNothing);
    expect(outcome, ['error: Bad state: boom']);
  });

  testWidgets('back does not dismiss the loader', (tester) async {
    final completer = Completer<String>();
    await _pumpLauncher(tester, () => completer.future, []);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Working…'), findsOneWidget);
    completer.complete('done');
    await tester.pumpAndSettle();
  });
}
