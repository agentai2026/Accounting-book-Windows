import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/constants/category_icon_catalog.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

/// 分类图标网格选择器
class CategoryIconGridPanel extends ConsumerWidget {
  const CategoryIconGridPanel({
    super.key,
    required this.selectedKey,
    required this.onSelected,
    this.accentColor = AppColors.primary,
  });

  final String selectedKey;
  final ValueChanged<String> onSelected;
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = ref.watch(settingsIconColumnCountProvider);
    final scale = ref.watch(settingsIconScaleProvider);

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: kCategoryIconCatalog.length,
          itemBuilder: (context, index) {
            final option = kCategoryIconCatalog[index];
            final selected = option.key == selectedKey;
            return Material(
              color: selected ? AppColors.selectedBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: () => onSelected(option.key),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.transparent,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: buildCategoryIconWidget(
                      option.key,
                      context: context,
                      color: selected ? accentColor : AppColors.textPrimary,
                      size: 20 * scale,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
