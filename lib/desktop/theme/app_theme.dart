import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.income,
      onSecondary: Colors.white,
      error: AppColors.expense,
      onError: Colors.white,
      surface: isDark
          ? const Color(0xFF1E1C1A).withValues(alpha: 0.62)
          : AppColors.cardBackground.withValues(alpha: 0.62),
      onSurface: isDark ? Colors.white : AppColors.textPrimary,
      surfaceContainerHighest:
          isDark ? const Color(0xFF2A2724) : AppColors.pageBackground,
      onSurfaceVariant: isDark ? Colors.white70 : AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: _textTheme(isDark),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      dividerColor: AppColors.divider,
      cardTheme: CardThemeData(
        color: isDark
            ? const Color(0xFF252220).withValues(alpha: 0.58)
            : AppColors.cardBackground.withValues(alpha: 0.58),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.88),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white70 : AppColors.textPrimary,
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.22)
                : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF2A2724).withValues(alpha: 0.58)
            : Colors.white.withValues(alpha: 0.58),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? const Color(0xFF2A2724).withValues(alpha: 0.58)
            : Colors.white.withValues(alpha: 0.58),
        selectedColor: AppColors.selectedBackground,
        labelStyle: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.transparent,
      ),
      menuTheme: GlassStyles.menuTheme(brightness),
      popupMenuTheme: GlassStyles.popupMenuTheme(brightness),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            isDark
                ? const Color(0xFF2A2724).withValues(alpha: 0.96)
                : const Color(0xFFFAF7F2).withValues(alpha: 0.96),
          ),
          elevation: const WidgetStatePropertyAll(12),
          shadowColor: WidgetStatePropertyAll(
            Colors.black.withValues(alpha: 0.2),
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ),
        textStyle: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : AppColors.divider.withValues(alpha: 0.55),
        space: 1,
      ),
    );
  }

  static TextTheme _textTheme(bool isDark) {
    final primary =
        isDark ? Colors.white.withValues(alpha: 0.92) : AppColors.textPrimary;
    final secondary =
        isDark ? Colors.white.withValues(alpha: 0.72) : AppColors.textSecondary;
    final hint =
        isDark ? Colors.white.withValues(alpha: 0.52) : AppColors.textHint;

    return TextTheme(
      titleLarge: TextStyle(
        color: primary,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      titleMedium: TextStyle(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleSmall: TextStyle(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      bodyLarge: TextStyle(color: primary, fontSize: 16),
      bodyMedium: TextStyle(color: primary, fontSize: 14),
      bodySmall: TextStyle(color: secondary, fontSize: 12),
      labelLarge: TextStyle(color: primary, fontSize: 14),
      labelMedium: TextStyle(color: secondary, fontSize: 12),
      labelSmall: TextStyle(color: hint, fontSize: 11),
    );
  }
}
