import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/display_utils.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<Category> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (categories.isEmpty) {
      return Text(
        '暂无分类',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '分类',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final selected = category.id == selectedId;
            return FilterChip(
              label: Text(category.name),
              selected: selected,
              avatar: buildCategoryIconWidget(
                category.icon,
                context: context,
                size: 18,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              onSelected: (_) => onSelected(category),
            );
          }).toList(),
        ),
      ],
    );
  }
}
