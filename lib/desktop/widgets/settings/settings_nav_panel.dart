import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/settings_page_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';

class SettingsNavPanel extends ConsumerWidget {
  const SettingsNavPanel({super.key});

  static const _sections = SettingsSection.values;

  static IconData _iconFor(SettingsSection section) => switch (section) {
        SettingsSection.personalization => Icons.brush_outlined,
        SettingsSection.background => Icons.wallpaper_outlined,
        SettingsSection.transaction => Icons.receipt_long_outlined,
        SettingsSection.display => Icons.display_settings_outlined,
        SettingsSection.aiAutoBookkeeping => Icons.auto_fix_high_outlined,
        SettingsSection.icons => Icons.emoji_emotions_outlined,
        SettingsSection.data => Icons.storage_outlined,
        SettingsSection.notificationFeedback => Icons.campaign_outlined,
        SettingsSection.general => Icons.tune_outlined,
        SettingsSection.about => Icons.info_outline,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(settingsPageProvider);
    final notifier = ref.read(settingsPageProvider.notifier);

    return SizedBox(
      width: 248,
      child: GlassSurface(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '设置',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Divider(height: 1, color: GlassStyles.divider(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                children: [
                  for (final section in _sections)
                    _NavItem(
                      icon: _iconFor(section),
                      title: section.title,
                      subtitle: section.subtitle,
                      selected: selected == section,
                      onTap: () => notifier.select(section),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: selected
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.35))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? AppColors.primary
                      : AppThemeColors.textSecondary(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? AppColors.primary
                                  : AppThemeColors.textPrimary(context),
                            ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppThemeColors.textHint(context),
                              height: 1.25,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
