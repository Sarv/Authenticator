import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/base32.dart';
import '../core/totp.dart';
import '../data/account.dart';
import 'theme.dart';

/// One row in the codes list: avatar chip, issuer/account, the live 6-digit
/// code, and a countdown ring — the Google Authenticator layout, Sarv-themed.
/// Tapping copies the code; long-pressing opens the actions menu. Edit and
/// delete are reached by swiping the row (wired by the list in home_screen).
class AccountTile extends StatefulWidget {
  const AccountTile({super.key, required this.account, this.onMenu});

  final Account account;

  /// Opens the per-account actions menu (rename / remove). Triggered by a
  /// long-press now that the overflow button is gone.
  final VoidCallback? onMenu;

  @override
  State<AccountTile> createState() => _AccountTileState();
}

class _AccountTileState extends State<AccountTile> {
  late Timer _timer;
  String _code = '';
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _recompute();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _recompute());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _recompute() {
    final nowUtc = DateTime.now().toUtc();
    final secret = base32Decode(widget.account.secretBase32);
    setState(() {
      _code = generateTotp(
        secret: secret,
        atUtc: nowUtc,
        period: widget.account.period,
        digits: widget.account.digits,
        algorithm: widget.account.algorithm,
      );
      _remaining =
          secondsRemaining(atUtc: nowUtc, period: widget.account.period);
    });
  }

  String get _spacedCode {
    // Google Authenticator groups 6-digit codes as "123 456".
    if (_code.length == 6) {
      return '${_code.substring(0, 3)} ${_code.substring(3)}';
    }
    return _code;
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _code));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Code copied')));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final expiring = _remaining <= 5;
    final codeColor = expiring ? tokens.danger : tokens.brand;

    // The row spacing lives in the outer Padding, OUTSIDE the ink surface, and
    // the Material clips the tap highlight to the card's rounded rect — so the
    // splash can no longer bleed into the gap below as a stray grey box.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space3),
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.rLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _copy,
          onLongPress: widget.onMenu,
          child: Container(
            padding: const EdgeInsets.all(AppTokens.space4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.rLg),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              children: [
                _Avatar(initial: widget.account.initial),
                const SizedBox(width: AppTokens.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.account.issuer.isNotEmpty)
                        Text(
                          widget.account.issuer,
                          style: TextStyle(
                            fontFamily: AppTokens.fontSans,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tokens.ink,
                          ),
                        ),
                      Text(
                        widget.account.account,
                        style: TextStyle(
                          fontFamily: AppTokens.fontSans,
                          fontSize: 12,
                          color: tokens.muted,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space2),
                      Text(
                        _spacedCode,
                        style: TextStyle(
                          fontFamily: AppTokens.fontMono,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: codeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _CountdownRing(
                  remaining: _remaining,
                  period: widget.account.period,
                  color: codeColor,
                  track: tokens.border,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.brandSoft,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: AppTokens.fontSans,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: tokens.brand,
        ),
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.remaining,
    required this.period,
    required this.color,
    required this.track,
  });

  final int remaining;
  final int period;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(
        painter: _RingPainter(
          fraction: remaining / period,
          color: color,
          track: track,
        ),
        child: Center(
          child: Text(
            '$remaining',
            style: TextStyle(
              fontFamily: AppTokens.fontMono,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.color,
    required this.track,
  });

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    // Sweep shrinks clockwise from 12 o'clock as the window elapses.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.2832 * fraction,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.fraction != fraction || old.color != color;
}
