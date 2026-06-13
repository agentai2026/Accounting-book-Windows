import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/glass_constants.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';

/// 带毛玻璃背景的 [showDialog]
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    barrierColor: Colors.black.withValues(alpha: GlassConstants.barrierOpacity),
    builder: builder,
  );
}

/// 毛玻璃 Dialog 外壳
class GlassDialog extends StatelessWidget {
  const GlassDialog({
    super.key,
    required this.child,
    this.insetPadding = const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.tintOpacity,
    this.blurSigma,
  });

  final Widget child;
  final EdgeInsets insetPadding;
  final BorderRadius borderRadius;
  final double? tintOpacity;
  final double? blurSigma;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: insetPadding,
      backgroundColor: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.none,
      child: GlassSurface(
        borderRadius: borderRadius,
        tintOpacity: tintOpacity,
        blurSigma: blurSigma ?? GlassConstants.dialogBlurSigma,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: child,
        ),
      ),
    );
  }
}

/// 毛玻璃 AlertDialog 替代
class GlassAlertDialog extends StatelessWidget {
  const GlassAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.icon,
    this.contentPadding = const EdgeInsets.fromLTRB(24, 16, 24, 0),
    this.actionsPadding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
    this.insetPadding = const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
    this.maxWidth = 480,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final Widget? icon;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry actionsPadding;
  final EdgeInsets insetPadding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      insetPadding: insetPadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 12),
                  ],
                  if (title != null)
                    Expanded(
                      child: DefaultTextStyle(
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        child: title!,
                      ),
                    ),
                ],
              ),
            ),
            if (content != null)
              Padding(
                padding: contentPadding,
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.bodyMedium!,
                  child: content!,
                ),
              ),
            if (actions != null)
              Padding(
                padding: actionsPadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 列表选择项
class GlassListPickerItem<T> {
  const GlassListPickerItem({
    required this.value,
    required this.label,
    this.selected = false,
  });

  final T value;
  final String label;
  final bool selected;
}

/// 毛玻璃列表选择弹窗（替代 AlertDialog + ListView）
Future<T?> showGlassListPickerDialog<T>({
  required BuildContext context,
  required String title,
  required List<GlassListPickerItem<T>> items,
  double width = 320,
  double? height,
  double maxWidth = 480,
  List<Widget>? actions,
  bool barrierDismissible = true,
}) {
  return showGlassDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => GlassAlertDialog(
      maxWidth: maxWidth,
      title: Text(title),
      content: SizedBox(
        width: width,
        height: height,
        child: ListView(
          shrinkWrap: height == null,
          children: [
            for (final item in items)
              ListTile(
                title: Text(item.label),
                trailing: item.selected
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(dialogContext, item.value),
              ),
          ],
        ),
      ),
      actions: actions ??
          [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
          ],
    ),
  );
}
