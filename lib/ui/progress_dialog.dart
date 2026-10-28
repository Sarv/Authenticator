import 'package:flutter/material.dart';
import 'theme.dart';

/// Runs [task] behind a modal loader showing [message], and returns its result.
/// The loader cannot be dismissed by back or a barrier tap, and is closed
/// whether [task] succeeds or throws (the error is rethrown to the caller).
Future<T> runWithProgress<T>(
  BuildContext context, {
  required String message,
  required Future<T> Function() task,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ProgressDialog(message: message),
  );
  try {
    return await task();
  } finally {
    navigator.pop();
  }
}

class _ProgressDialog extends StatelessWidget {
  const _ProgressDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: tokens.brand,
              ),
            ),
            const SizedBox(width: AppTokens.space4),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: AppTokens.fontSans,
                  fontSize: 14,
                  color: tokens.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
