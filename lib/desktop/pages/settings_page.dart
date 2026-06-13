import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/settings_page_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/layout/content_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/settings/settings_nav_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/settings/settings_sub_pages.dart';

/// 设置页：左侧导航 + 右侧子页面
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(settingsPageProvider);
    final busy = ref.watch(settingsBusyProvider);
    final pageAnimation = ref.watch(
      settingsProvider.select((s) => s.pageAnimationEnabled),
    );

    final subPage = SettingsSubPage(section: section);

    return ContentPanel(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsNavPanel(),
              const SizedBox(width: 16),
              Expanded(
                child: pageAnimation
                    ? AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        layoutBuilder: (currentChild, _) =>
                            currentChild ?? const SizedBox.shrink(),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                        child: KeyedSubtree(
                          key: ValueKey<SettingsSection>(section),
                          child: subPage,
                        ),
                      )
                    : subPage,
              ),
            ],
          ),
          if (busy)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.08),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
