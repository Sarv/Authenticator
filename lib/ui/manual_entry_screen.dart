import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/base32.dart';
import '../core/totp.dart';
import '../data/account.dart';
import 'theme.dart';

/// Manual enrollment for services that show a setup key instead of a QR code.
/// Lets the user enter issuer/account/secret and pick the algorithm, digit
/// count and period — the same parameters a QR's otpauth URI carries. Pops back
/// the built [Account] (or null if cancelled).
class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _issuer = TextEditingController();
  final _account = TextEditingController();
  final _secret = TextEditingController();

  OtpAlgorithm _algorithm = OtpAlgorithm.sha1;
  int _digits = 6;
  int _period = 30;
  String? _secretError;

  @override
  void dispose() {
    _issuer.dispose();
    _account.dispose();
    _secret.dispose();
    super.dispose();
  }

  void _save() {
    // Secrets are Base32, case-insensitive, often shown with spaces in groups.
    final normalized = _secret.text.replaceAll(' ', '').toUpperCase();
    if (normalized.isEmpty) {
      setState(() => _secretError = 'Enter the setup key');
      return;
    }
    try {
      final decoded = base32Decode(normalized);
      if (decoded.isEmpty) throw const FormatException('empty');
    } catch (_) {
      setState(() => _secretError = 'Not a valid Base32 setup key');
      return;
    }

    Navigator.of(context).pop(
      Account.create(
        issuer: _issuer.text.trim(),
        account: _account.text.trim(),
        secretBase32: normalized,
        digits: _digits,
        period: _period,
        algorithm: _algorithm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: tokens.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        title: Text(
          'Enter setup key',
          style: TextStyle(
            fontFamily: AppTokens.fontSans,
            fontWeight: FontWeight.w700,
            color: tokens.ink,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space4),
        children: [
          _Field(controller: _issuer, label: 'Issuer', hint: 'e.g. GitHub'),
          const SizedBox(height: AppTokens.space3),
          _Field(
            controller: _account,
            label: 'Account',
            hint: 'e.g. ankur.d@sarv.com',
          ),
          const SizedBox(height: AppTokens.space3),
          _Field(
            controller: _secret,
            label: 'Setup key (Base32)',
            hint: 'JBSW Y3DP EHPK 3PXP',
            mono: true,
            errorText: _secretError,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z2-7 ]')),
            ],
          ),
          const SizedBox(height: AppTokens.space6),
          const _SelectorLabel('Algorithm'),
          SegmentedButton<OtpAlgorithm>(
            segments: const [
              ButtonSegment(value: OtpAlgorithm.sha1, label: Text('SHA1')),
              ButtonSegment(value: OtpAlgorithm.sha256, label: Text('SHA256')),
              ButtonSegment(value: OtpAlgorithm.sha512, label: Text('SHA512')),
            ],
            selected: {_algorithm},
            onSelectionChanged: (s) => setState(() => _algorithm = s.first),
          ),
          const SizedBox(height: AppTokens.space5),
          const _SelectorLabel('Digits'),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 6, label: Text('6')),
              ButtonSegment(value: 8, label: Text('8')),
            ],
            selected: {_digits},
            onSelectionChanged: (s) => setState(() => _digits = s.first),
          ),
          const SizedBox(height: AppTokens.space5),
          const _SelectorLabel('Period (seconds)'),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 30, label: Text('30')),
              ButtonSegment(value: 60, label: Text('60')),
            ],
            selected: {_period},
            onSelectionChanged: (s) => setState(() => _period = s.first),
          ),
          const SizedBox(height: AppTokens.space7),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tokens.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppTokens.space4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.rMd),
                ),
              ),
              onPressed: _save,
              child: const Text('Add account'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.mono = false,
    this.errorText,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool mono;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: inputFormatters,
      style: mono ? const TextStyle(fontFamily: AppTokens.fontMono) : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
      ),
    );
  }
}

class _SelectorLabel extends StatelessWidget {
  const _SelectorLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space2),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTokens.fontSans,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: tokens.ink,
        ),
      ),
    );
  }
}
