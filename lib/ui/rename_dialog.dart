import 'package:flutter/material.dart';
import 'theme.dart';

/// The edited issuer/account pair returned by [showRenameDialog].
class RenameResult {
  const RenameResult({required this.issuer, required this.account});
  final String issuer;
  final String account;
}

/// Prompts to rename an account's issuer and label. Returns null on cancel.
/// Secrets and OTP settings are untouched — only the display text changes.
Future<RenameResult?> showRenameDialog(
  BuildContext context, {
  required String issuer,
  required String account,
}) {
  final issuerController = TextEditingController(text: issuer);
  final accountController = TextEditingController(text: account);
  final tokens = context.tokens;

  return showDialog<RenameResult>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: tokens.surface,
      title: const Text('Rename account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: issuerController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Issuer'),
          ),
          const SizedBox(height: AppTokens.space3),
          TextField(
            controller: accountController,
            decoration: const InputDecoration(labelText: 'Account'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(
            RenameResult(
              issuer: issuerController.text.trim(),
              account: accountController.text.trim(),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
