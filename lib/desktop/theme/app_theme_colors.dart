import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';

/// 随主题/毛玻璃背景自适应的前景色与面板色（避免深色模式下白底+白字）
abstract final class AppThemeColors {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textPrimary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return isDark(context)
        ? scheme.onSurface
        : AppColors.textPrimary;
  }

  static Color textSecondary(BuildContext context) {
    if (!isDark(context)) return AppColors.textSecondary;
    return Colors.white.withValues(alpha: 0.78);
  }

  static Color textHint(BuildContext context) =>
      isDark(context)
          ? Colors.white.withValues(alpha: 0.58)
          : AppColors.textHint;

  static Color cardFill(BuildContext context) =>
      isDark(context)
          ? GlassStyles.panelTint(context, light: 0.4, dark: 0.5)
          : AppColors.cardBackground;

  static Color panelFill(BuildContext context) =>
      GlassStyles.panelTint(context, light: 0.38, dark: 0.44);

  static Color fieldFill(BuildContext context) => GlassStyles.fieldFill(context);

  static Color border(BuildContext context) => GlassStyles.divider(context);

  static Color selectedBackground(BuildContext context) =>
      isDark(context)
          ? AppColors.primary.withValues(alpha: 0.26)
          : AppColors.selectedBackground;
}
