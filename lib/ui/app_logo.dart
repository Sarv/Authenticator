import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Sarv OTP brand mark, theme-aware: it renders the dark-token
/// variant under a dark theme and the brand variant otherwise. Both SVGs are
/// the same artwork recoloured with the design system's light/dark tokens.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/authenticator-icon-dark.svg'
        : 'assets/authenticator-icon-light.svg';
    return SvgPicture.asset(asset, width: size, height: size);
  }
}
