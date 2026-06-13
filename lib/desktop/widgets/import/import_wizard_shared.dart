import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

/// 导入向导共享视觉组件（适配全局毛玻璃）
class ImportWizardShared {
  ImportWizardShared._();

  static const dialogRadius = 14.0;
  static const cardRadius = 10.0;
  static const railWidth = 232.0;

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// 向导内嵌面板半透明叠色
  static Color glassTint(
    BuildContext context, {
    double light = 0.44,
    double dark = 0.34,
  }) {
    return _isDark(context)
        ? Colors.black.withValues(alpha: dark)
        : Colors.white.withValues(alpha: light);
  }

  static Color glassBorder(BuildContext context) {
    return _isDark(context)
        ? Colors.white.withValues(alpha: 0.24)
        : Colors.white.withValues(alpha: 0.9);
  }

  static Color glassDivider(BuildContext context) {
    return _isDark(context)
        ? Colors.white.withValues(alpha: 0.1)
        : AppColors.divider.withValues(alpha: 0.65);
  }

  static BoxDecoration surfaceDecoration(
    BuildContext context, {
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? glassTint(context),
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: glassBorder(context)),
    );
  }

  static BoxDecoration dropZoneDecoration(
    BuildContext context, {
    required bool active,
    required bool hasFile,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(cardRadius),
      color: active
          ? AppColors.selectedBackground.withValues(alpha: 0.5)
          : (hasFile
              ? glassTint(context, light: 0.36, dark: 0.28)
              : glassTint(context, light: 0.28, dark: 0.2)),
      border: Border.all(
        color: active
            ? AppColors.primary.withValues(alpha: 0.7)
            : glassBorder(context),
        width: active ? 1.5 : 1,
      ),
    );
  }
}

class ImportStepHeader extends StatelessWidget {
  const ImportStepHeader({
    super.key,
    required this.title,
    this.description,
    this.trailing,
  });

  final String title;
  final String? description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ImportSectionLabel extends StatelessWidget {
  const ImportSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class ImportHintText extends StatelessWidget {
  const ImportHintText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textHint,
            height: 1.45,
          ),
    );
  }
}
