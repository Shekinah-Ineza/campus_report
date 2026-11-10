import 'package:flutter/material.dart';

/// Colours used across the app. Purple primary on a soft grey background,
/// with white rounded cards, following the course's sample UI.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF6C4CF1);
  static const primaryDark = Color(0xFF5235D6);
  static const primarySoft = Color(0xFFEDE9FE);
  static const background = Color(0xFFF6F6FB);
  static const card = Colors.white;
  static const ink = Color(0xFF1C1B29);
  static const muted = Color(0xFF7A7A8C);
  static const border = Color(0xFFE6E6EF);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build();

  // The design is light-only, so dark mode uses the same theme.
  static ThemeData get dark => _build();

  static ThemeData _build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: Colors.white,
    );
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

/// White rounded card with a soft shadow, used for most panels.
BoxDecoration cardDecoration({double radius = 16}) => BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(color: Color(0x0F1C1B29), blurRadius: 14, offset: Offset(0, 4)),
      ],
    );
