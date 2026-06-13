import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/display_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';

Color categoryTypeColor(CategoryType type) {
  return switch (type) {
    CategoryType.expense => AppColors.expense,
    CategoryType.income => AppColors.income,
    CategoryType.transfer => AppColors.transfer,
  };
}

/// 左侧：类型切换 + 一级分类列表
class CategoryNavigationPanel extends StatelessWidget {
  const CategoryNavigationPanel({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.rootCategories,
    required this.selectedRootId,
    required this.onRootSelected,
    this.childCountByRootId = const {},
    this.emptyListWidget,
    this.width = 240,
  });

  final CategoryType selectedType;
  final ValueChanged<CategoryType> onTypeChanged;
  final List<Category> rootCategories;
  final int? selectedRootId;
  final ValueChanged<int> onRootSelected;
  final Map<int, int> childCountByRootId;
  final Widget? emptyListWidget;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GlassSurface(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
              child: _CategoryTypeSegmentBar(
                selectedType: selectedType,
                onTypeChanged: onTypeChanged,
              ),
            ),
            Divider(height: 1, color: GlassStyles.divider(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Row(
                children: [
                  Text(
                    '一级分类',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppThemeColors.textSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  if (rootCategories.isNotEmpty)
                    Text(
                      '${rootCategories.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppThemeColors.textHint(context),
                          ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: rootCategories.isEmpty
                  ? (emptyListWidget ?? const CategorySidebarEmptyHint())
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                      itemCount: rootCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, index) {
                        final category = rootCategories[index];
                        final childCount = category.id == null
                            ? 0
                            : childCountByRootId[category.id] ?? 0;
                        return _CategoryRootListTile(
                          category: category,
                          selected: category.id == selectedRootId,
                          childCount: childCount,
                          onTap: () {
                            if (category.id != null) {
                              onRootSelected(category.id!);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTypeSegmentBar extends StatelessWidget {
  const _CategoryTypeSegmentBar({
    required this.selectedType,
    required this.onTypeChanged,
  });

  final CategoryType selectedType;
  final ValueChanged<CategoryType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GlassStyles.panelTint(context, light: 0.22, dark: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: CategoryType.values.map((type) {
            final selected = type == selectedType;
            final color = categoryTypeColor(type);
            return Expanded(
              child: Material(
                color: selected
                    ? GlassStyles.fieldFill(context)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                elevation: selected ? 0.5 : 0,
                shadowColor: Colors.black12,
                child: InkWell(
                  onTap: () => onTypeChanged(type),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      categoryTypeLabel(type),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? color : AppThemeColors.textSecondary(context),
                          ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CategoryRootListTile extends StatelessWidget {
  const _CategoryRootListTile({
    required this.category,
    required this.selected,
    required this.childCount,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final int childCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = categoryIconColor(category.color);

    return Material(
      color: selected ? AppThemeColors.selectedBackground(context) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              buildCategoryIconWidget(
                category.icon,
                color: iconColor,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected
                            ? AppColors.primary
                            : AppThemeColors.textPrimary(context),
                      ),
                ),
              ),
              if (childCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : GlassStyles.panelTint(context, light: 0.2, dark: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$childCount',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppThemeColors.textHint(context),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 右侧详情白色卡片
class CategoryDetailCard extends StatelessWidget {
  const CategoryDetailCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

/// 右侧详情区顶栏
class CategoryDetailHeader extends StatelessWidget {
  const CategoryDetailHeader({
    super.key,
    required this.selectedType,
    required this.searchController,
    required this.onSearchChanged,
    required this.onAddChild,
    required this.onAddPrimary,
    required this.onRefresh,
    this.selectedRoot,
    this.childCount = 0,
    this.onEditRoot,
    this.onDeleteRoot,
  });

  final CategoryType selectedType;
  final Category? selectedRoot;
  final int childCount;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddChild;
  final VoidCallback onAddPrimary;
  final VoidCallback onRefresh;
  final VoidCallback? onEditRoot;
  final VoidCallback? onDeleteRoot;

  @override
  Widget build(BuildContext context) {
    final typeColor = categoryTypeColor(selectedType);
    final root = selectedRoot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (root != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryIconColor(root.color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: buildCategoryIconWidget(
                    root.icon,
                    color: categoryIconColor(root.color),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            root.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TypeChip(label: categoryTypeLabel(selectedType), color: typeColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$childCount 个子分类',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppThemeColors.textSecondary(context),
                          ),
                    ),
                  ],
                ),
              ),
            ] else
              Text(
                '交易分类',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            const SizedBox(width: 12),
            SizedBox(
              width: 200,
              height: 36,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: '搜索全部子分类',
                  hintStyle: TextStyle(
                    color: AppThemeColors.textHint(context),
                    fontSize: 13,
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton.icon(
              onPressed: root == null ? null : onAddChild,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加子分类'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onAddPrimary,
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: const Text('添加一级'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            IconButton(
              tooltip: '刷新',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 20),
              color: AppThemeColors.textSecondary(context),
            ),
            const Spacer(),
            if (onEditRoot != null)
              IconButton(
                tooltip: '编辑一级分类',
                onPressed: onEditRoot,
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppThemeColors.textSecondary(context),
              ),
            if (onDeleteRoot != null)
              IconButton(
                tooltip: '删除一级分类',
                onPressed: onDeleteRoot,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.expense,
              ),
          ],
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// 分类表格表头
class CategoryTableHeader extends StatelessWidget {
  const CategoryTableHeader({super.key, this.showParentColumn = false});

  final bool showParentColumn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: GlassStyles.panelTint(context, light: 0.24, dark: 0.16),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border.all(color: GlassStyles.divider(context)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 32),
          if (showParentColumn)
            Expanded(
              flex: 2,
              child: Text(
                '所属分类',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppThemeColors.textSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          Expanded(
            flex: showParentColumn ? 2 : 3,
            child: Text(
              '分类名称',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppThemeColors.textSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              '颜色',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppThemeColors.textSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '排序',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppThemeColors.textSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 分类表格行
class CategoryTableRow extends StatelessWidget {
  const CategoryTableRow({
    super.key,
    required this.category,
    required this.index,
    required this.isSystem,
    required this.onTap,
    this.enableDrag = true,
    this.parentName,
  });

  final Category category;
  final int index;
  final bool isSystem;
  final VoidCallback onTap;
  final bool enableDrag;
  final String? parentName;

  @override
  Widget build(BuildContext context) {
    final iconColor = categoryIconColor(category.color);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
          child: Row(
            children: [
              buildCategoryIconWidget(
                category.icon,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              if (parentName != null)
                Expanded(
                  flex: 2,
                  child: Text(
                    parentName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppThemeColors.textSecondary(context),
                        ),
                  ),
                ),
              Expanded(
                flex: parentName != null ? 2 : 3,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        category.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppThemeColors.textPrimary(context),
                            ),
                      ),
                    ),
                    if (isSystem) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppThemeColors.selectedBackground(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '系统',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category.color ?? '#888888',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppThemeColors.textHint(context),
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 48,
                child: Center(
                  child: !isSystem && enableDrag
                      ? ReorderableDragStartListener(
                          index: index,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: Icon(
                              Icons.drag_indicator,
                              color: AppThemeColors.textHint(context),
                              size: 20,
                            ),
                          ),
                        )
                      : const SizedBox(width: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 左侧一级分类为空时的轻量提示
class CategorySidebarEmptyHint extends StatelessWidget {
  const CategorySidebarEmptyHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 32,
              color: AppThemeColors.textHint(context).withValues(alpha: 0.45),
            ),
            const SizedBox(height: 10),
            Text(
              '暂无分类',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemeColors.textHint(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分类列表为空时的主区域空状态
class CategoryEmptyState extends StatelessWidget {
  const CategoryEmptyState({
    super.key,
    required this.type,
    required this.onAddDefaults,
    this.onAddManual,
  });

  final CategoryType type;
  final VoidCallback onAddDefaults;
  final VoidCallback? onAddManual;

  @override
  Widget build(BuildContext context) {
    final typeLabel = categoryTypeLabel(type);
    final color = categoryTypeColor(type);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 36,
                color: color.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '还没有$typeLabel分类',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '可从预设快速添加常用分类组，包含一级和二级分类',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemeColors.textSecondary(context),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddDefaults,
              icon: const Icon(Icons.playlist_add, size: 20),
              label: const Text('添加默认分类'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(168, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
            if (onAddManual != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onAddManual,
                child: const Text('手动添加分类'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 子分类搜索无结果
class CategorySearchEmptyHint extends StatelessWidget {
  const CategorySearchEmptyHint({super.key, required this.keyword});

  final String keyword;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 40,
            color: AppThemeColors.textHint(context).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            '未找到「$keyword」相关子分类',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppThemeColors.textHint(context),
                ),
          ),
        ],
      ),
    );
  }
}
