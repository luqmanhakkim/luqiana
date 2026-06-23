import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Static brand colors (non-primary — these never change)
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  static const Color secondary = Color(0xFFF4A261);

  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F8);

  static const Color textPrimary = Color(0xFF1A1D23);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color divider = Color(0xFFE5E7EB);

  static const List<List<Color>> tripGradients = [
    [Color(0xFF1B6CA8), Color(0xFF4A9FD4)],
    [Color(0xFF0D9488), Color(0xFF2DD4BF)],
    [Color(0xFFEA580C), Color(0xFFFB923C)],
    [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    [Color(0xFF059669), Color(0xFF34D399)],
    [Color(0xFFBE185D), Color(0xFFF472B6)],
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme-aware color helpers (accessed via BuildContext extension)
// ─────────────────────────────────────────────────────────────────────────────

Color _darken(Color color, [double amount = 0.22]) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
      .toColor();
}

Color _lighten(Color color, [double amount = 0.15]) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
      .toColor();
}

extension AppThemeColors on BuildContext {
  /// The current primary brand color (from ThemeData.colorScheme).
  Color get appPrimary => Theme.of(this).colorScheme.primary;

  /// A darkened variant of the primary color (for gradient starts, app bars).
  Color get appPrimaryDark => _darken(Theme.of(this).colorScheme.primary);

  /// A lightened variant of the primary color (for gradient ends, highlights).
  Color get appPrimaryLight => _lighten(Theme.of(this).colorScheme.primary);
}

// ─────────────────────────────────────────────────────────────────────────────
// Dynamic theme factory
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static const Color _defaultPrimary = Color(0xFF1B6CA8);

  static ThemeData light([Color primary = _defaultPrimary]) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ).copyWith(primary: primary),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }
}
