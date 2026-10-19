import 'package:flutter/material.dart';
import 'theme.dart';

/// Prompts for a passphrase. With [confirm] true it requires the entry to be
/// typed twice (used for export); otherwise a single field (used for import).
/// Returns the passphrase, or null if cancelled.
Future<String?> showPassphraseDialog(
  BuildContext context, {
  required String title,
  required String message,
  required bool confirm,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PassphraseDialog(
      title: title,
      message: message,
      confirm: confirm,
    ),
  );
}

class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog({
    required this.title,
    required this.message,
    required this.confirm,
  });

  final String title;
  final String message;
  final bool confirm;

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final _passphrase = TextEditingController();
  final _repeat = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passphrase.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _passphrase.text;
    if (value.isEmpty) {
      setState(() => _error = 'Enter a passphrase');
      return;
    }
    if (widget.confirm && value != _repeat.text) {
      setState(() => _error = 'Passphrases do not match');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AlertDialog(
      backgroundColor: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.rLg),
      ),
      title: Text(
        widget.title,
        style: TextStyle(
          fontFamily: AppTokens.fontSans,
          fontWeight: FontWeight.w700,
          color: tokens.ink,
          fontSize: 16,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: TextStyle(
              fontFamily: AppTokens.fontSans,
              fontSize: 13,
              color: tokens.muted,
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          TextField(
            controller: _passphrase,
            obscureText: _obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Passphrase',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          if (widget.confirm) ...[
            const SizedBox(height: AppTokens.space3),
            TextField(
              controller: _repeat,
              obscureText: _obscure,
              decoration: const InputDecoration(labelText: 'Confirm passphrase'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppTokens.space2),
            Text(
              _error!,
              style: TextStyle(
                fontFamily: AppTokens.fontSans,
                fontSize: 12,
                color: tokens.danger,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: tokens.muted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: tokens.brand,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
