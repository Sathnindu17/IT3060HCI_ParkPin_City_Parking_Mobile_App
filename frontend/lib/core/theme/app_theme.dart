import 'package:flutter/material.dart';
import 'package:parkpin/core/constants/app_colors.dart';

/// App-wide theme (colours and shapes from the Figma prototype).
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: c, width: w),
        );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        enabledBorder: border(AppColors.border, 1),
        focusedBorder: border(AppColors.primary, 1.4),
        errorBorder: border(AppColors.danger, 1),
        focusedErrorBorder: border(AppColors.danger, 1.4),
        disabledBorder: border(AppColors.border, 1),
        errorStyle: const TextStyle(fontSize: 11),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 0.5, space: 0),
    );
  }
}