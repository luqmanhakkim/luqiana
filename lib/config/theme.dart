import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1B6CA8);
  static const Color primaryDark = Color(0xFF0D3B6E);
  static const Color primaryLight = Color(0xFF4A9FD4);
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

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle(
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
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }
}
