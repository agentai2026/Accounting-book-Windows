import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/glass_settings.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';

/// 全局毛玻璃配套样式（表单、菜单、内嵌面板）
class GlassStyles {
  GlassStyles._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color fieldFill(BuildContext context) {
    final alpha = GlassSettings.fieldFillAlpha(context);
    return isDark(context)
        ? Colors.black.withValues(alpha: alpha)
        : Colors.white.withValues(alpha: alpha);
  }

  static Color panelTint(
    BuildContext context, {
    double light = 0.4,
    double dark = 0.3,
  }) {
    final alpha = GlassSettings.inlinePanelAlpha(
      context,
      light: light,
      dark: dark,
    );
    return isDark(context)
        ? Colors.black.withValues(alpha: alpha)
        : Colors.white.withValues(alpha: alpha);
  }

  static Color overlayBackground(BuildContext context) => isDark(context)
      ? const Color(0xFF2A2724).withValues(alpha: 0.96)
      : const Color(0xFFFAF7F2).withValues(alpha: 0.96);

  static Color dropdownColor(BuildContext context) =>
      overlayBackground(context);

  static Color divider(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.12)
      : AppColors.divider.withValues(alpha: 0.55);

  static MenuStyle menuStyle(BuildContext context) => MenuStyle(
        backgroundColor: WidgetStateProperty.all(overlayBackground(context)),
        elevation: WidgetStateProperty.all(12),
        shadowColor:
            WidgetStateProperty.all(Colors.black.withValues(alpha: 0.2)),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark(context)
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 6),
        ),
      );

  static PopupMenuThemeData popupMenuTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return PopupMenuThemeData(
      color: isDark
          ? const Color(0xFF2A2724).withValues(alpha: 0.96)
          : const Color(0xFFFAF7F2).withValues(alpha: 0.96),
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }

  static MenuThemeData menuTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          isDark
              ? const Color(0xFF2A2724).withValues(alpha: 0.96)
              : const Color(0xFFFAF7F2).withValues(alpha: 0.96),
        ),
        elevation: WidgetStatePropertyAll(12),
        shadowColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: 0.2),
        ),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
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
    );
  }
}

/// 浮层选择器外壳（分类/账户等下拉面板）
class GlassPickerShell extends StatelessWidget {
  const GlassPickerShell({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: borderRadius,
      blurSigma: 40,
      tintOpacity: GlassStyles.isDark(context) ? 0.58 : 0.7,
      child: child,
    );
  }
}
