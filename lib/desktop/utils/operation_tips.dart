import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

/// 是否显示操作提示（帮助气泡、引导文案等）
bool operationTipsEnabledOf(BuildContext context) {
  try {
    return ProviderScope.containerOf(context)
        .read(settingsProvider)
        .operationTipsEnabled;
  } catch (_) {
    return true;
  }
}

/// 根据设置决定是否展示帮助 Tooltip
class SettingsHelpTooltip extends ConsumerWidget {
  const SettingsHelpTooltip({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(settingsProvider.select((s) => s.operationTipsEnabled))) {
      return const SizedBox.shrink();
    }
    return Tooltip(
      message: message,
      child: Icon(
        Icons.help_outline,
        size: 16,
        color: AppColors.textHint,
      ),
    );
  }
}
