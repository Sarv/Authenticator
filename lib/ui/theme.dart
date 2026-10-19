import 'package:flutter/material.dart';

/// Sarv design tokens, transcribed verbatim from `sarv_theme/design-system.css`.
///
/// This is the ONLY file permitted to hold literal token values — it is the
/// Flutter mirror of the `:root` / `.dark` custom-property blocks. Everything
/// else in the app references [AppTokens] / Theme, never a raw hex.
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.ink,
    required this.muted,
    required this.brand,
    required this.brandSoft,
    required this.accent,
    required this.success,
    required this.danger,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color ink;
  final Color muted;
  final Color brand;
  final Color brandSoft;
  final Color accent;
  final Color success;
  final Color danger;

  // ---- Spacing scale (--space-*) ----
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 32;

  // ---- Radii (--r-*) ----
  static const double rSm = 6;
  static const double rMd = 8;
  static const double rLg = 12;
  static const double rXl = 16;
  static const double rPill = 999;

  // ---- Type families (fonts.css) ----
  static const String fontSans = 'PlusJakartaSans';
  static const String fontMono = 'JetBrainsMono';

  static const AppTokens light = AppTokens(
    bg: Color(0xFFF7F8FB), // --color-slate-50
    surface: Color(0xFFFFFFFF), // --surface
    surface2: Color(0xFFF7F8FB), // --surface-2
    border: Color(0xFFE6E9F1), // --border
    ink: Color(0xFF0B1530), // --ink
    muted: Color(0xFF6B7691), // --muted
    brand: Color(0xFF3069B0), // --brand (brand-500)
    brandSoft: Color(0xFFEAF2FA), // --brand-soft (brand-50)
    accent: Color(0xFFE56910), // --accent (accent-500)
    success: Color(0xFF10936A), // --color-success-500
    danger: Color(0xFFD94A4A), // --color-danger-500
  );

  static const AppTokens dark = AppTokens(
    bg: Color(0xFF0B0F1A),
    surface: Color(0xFF131826),
    surface2: Color(0xFF181E30),
    border: Color(0xFF232838),
    ink: Color(0xFFF7F8FB),
    muted: Color(0xFF9AA3BC),
    brand: Color(0xFF5B92D2),
    brandSoft: Color(0x245B92D2), // rgba(91,146,210,.14)
    accent: Color(0xFFFF8533),
    success: Color(0xFF10936A),
    danger: Color(0xFFD94A4A),
  );

  @override
  AppTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? ink,
    Color? muted,
    Color? brand,
    Color? brandSoft,
    Color? accent,
    Color? success,
    Color? danger,
  }) =>
      AppTokens(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surface2: surface2 ?? this.surface2,
        border: border ?? this.border,
        ink: ink ?? this.ink,
        muted: muted ?? this.muted,
        brand: brand ?? this.brand,
        brandSoft: brandSoft ?? this.brandSoft,
        accent: accent ?? this.accent,
        success: success ?? this.success,
        danger: danger ?? this.danger,
      );

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// Builds a Material theme wired to [AppTokens] for the given brightness.
ThemeData buildAppTheme(AppTokens tokens, Brightness brightness) {
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: tokens.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: tokens.brand,
      secondary: tokens.accent,
      surface: tokens.surface,
      error: tokens.danger,
    ),
    extensions: [tokens],
    textTheme: base.textTheme.apply(
      fontFamily: AppTokens.fontSans,
      bodyColor: tokens.ink,
      displayColor: tokens.ink,
    ),
  );
}

/// Convenience accessor so widgets read `context.tokens.brand`.
extension TokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
