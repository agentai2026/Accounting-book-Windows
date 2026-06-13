import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/category_icon_catalog.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

/// 手机端风格的圆形分类选择网格
class CategoryCircleGrid extends StatelessWidget {
  const CategoryCircleGrid({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    this.crossAxisCount = 6,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<Category> onSelected;
  final int crossAxisCount;

  List<Category> get _displayCategories {
    final roots = categories.where((c) => c.parentId == null).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (roots.isNotEmpty) return roots;
    final sorted = List<Category>.from(categories)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final items = _displayCategories.where((c) => c.id != null).toList();
    if (items.isEmpty) {
      return Text(
        '暂无分类',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textHint,
            ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 14,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final category = items[index];
        final selected = category.id == selectedId;
        return InkWell(
          onTap: () => onSelected(category),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.primary
                      : AppColors.panelBackground,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                alignment: Alignment.center,
                child: buildCategoryIconWidget(
                  category.icon,
                  context: context,
                  size: 22,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
