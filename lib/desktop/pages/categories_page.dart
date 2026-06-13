import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/forms/category_form_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/category/category_list_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/layout/content_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/forms/default_categories_dialog.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  CategoryType _selectedType = CategoryType.expense;
  int? _selectedRootId;
  String _searchKeyword = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchKeyword = '';
    _searchController.clear();
  }

  List<Category> _rootsOfType(List<Category> categories) {
    return categories
        .where((c) => c.type == _selectedType && c.parentId == null)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<Category> _childrenOfRoot(List<Category> categories, int rootId) {
    return categories
        .where((c) => c.parentId == rootId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Map<int, int> _childCountByRoot(List<Category> categories, List<Category> roots) {
    return {
      for (final root in roots)
        if (root.id != null)
          root.id!: _childrenOfRoot(categories, root.id!).length,
    };
  }

  List<Category> _allSubcategoriesOfType(List<Category> categories) {
    return categories
        .where((c) => c.type == _selectedType && c.parentId != null)
        .toList();
  }

  Map<int, String> _rootNamesById(List<Category> categories) {
    return {
      for (final c in categories)
        if (c.id != null && c.parentId == null) c.id!: c.name,
    };
  }

  List<Category> _filterDisplayedChildren({
    required List<Category> categories,
    required List<Category> children,
  }) {
    final keyword = _searchKeyword.trim();
    if (keyword.isEmpty) return children;

    return _allSubcategoriesOfType(categories)
        .where((c) => c.name.toLowerCase().contains(keyword.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  int? _resolveRootId(List<Category> roots) {
    if (roots.isEmpty) return null;
    if (_selectedRootId != null &&
        roots.any((c) => c.id == _selectedRootId)) {
      return _selectedRootId;
    }
    return roots.first.id;
  }

  Category? _selectedRoot(List<Category> roots) {
    final id = _resolveRootId(roots);
    if (id == null) return null;
    for (final root in roots) {
      if (root.id == id) return root;
    }
    return null;
  }

  Set<String> _existingRootNames(List<Category> roots) {
    return roots.map((c) => c.name).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return ContentPanel(
      child: categoriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => const Center(
          child: Text(
            '加载分类失败',
            style: TextStyle(color: AppColors.textHint),
          ),
        ),
        data: (categories) {
          final roots = _rootsOfType(categories);
          final selectedRoot = _selectedRoot(roots);
          final selectedRootId = _resolveRootId(roots);
          final children = selectedRootId == null
              ? <Category>[]
              : _childrenOfRoot(categories, selectedRootId);
          final filteredChildren = _filterDisplayedChildren(
            categories: categories,
            children: children,
          );
          final isEmpty = roots.isEmpty;
          final isSearching = _searchKeyword.trim().isNotEmpty;
          final childCountByRoot = _childCountByRoot(categories, roots);
          final rootNames = _rootNamesById(categories);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CategoryNavigationPanel(
                selectedType: _selectedType,
                onTypeChanged: (type) {
                  setState(() {
                    _selectedType = type;
                    _selectedRootId = null;
                    _clearSearch();
                  });
                },
                rootCategories: roots,
                selectedRootId: selectedRootId,
                childCountByRootId: childCountByRoot,
                onRootSelected: (id) {
                  setState(() => _selectedRootId = id);
                },
                emptyListWidget:
                    isEmpty ? const CategorySidebarEmptyHint() : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CategoryDetailCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CategoryDetailHeader(
                        selectedType: _selectedType,
                        selectedRoot: isEmpty ? null : selectedRoot,
                        childCount: children.length,
                        searchController: _searchController,
                        onSearchChanged: (value) {
                          setState(() => _searchKeyword = value);
                        },
                        onAddChild: () => _openForm(
                          context,
                          parentId: selectedRootId,
                        ),
                        onAddPrimary: () => _openForm(context),
                        onRefresh: () => refreshCategories(ref),
                        onEditRoot: selectedRoot == null ||
                                isSystemCategory(selectedRoot)
                            ? null
                            : () => _openForm(
                                  context,
                                  category: selectedRoot,
                                ),
                        onDeleteRoot: selectedRoot == null ||
                                isSystemCategory(selectedRoot)
                            ? null
                            : () => _confirmDelete(context, selectedRoot),
                      ),
                      const SizedBox(height: 16),
                      if (isEmpty)
                        Expanded(
                          child: CategoryEmptyState(
                            type: _selectedType,
                            onAddDefaults: () => _openDefaultCategories(
                              context,
                              roots,
                            ),
                            onAddManual: () => _openForm(context),
                          ),
                        )
                      else ...[
                        CategoryTableHeader(showParentColumn: isSearching),
                        Expanded(
                          child: _buildChildList(
                            context: context,
                            children: children,
                            filteredChildren: filteredChildren,
                            isSearching: isSearching,
                            selectedRoot: selectedRoot,
                            selectedRootId: selectedRootId,
                            rootNames: rootNames,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChildList({
    required BuildContext context,
    required List<Category> children,
    required List<Category> filteredChildren,
    required bool isSearching,
    required Category? selectedRoot,
    required int? selectedRootId,
    required Map<int, String> rootNames,
  }) {
    if (isSearching && filteredChildren.isEmpty) {
      return CategorySearchEmptyHint(keyword: _searchKeyword.trim());
    }

    if (children.isEmpty && !isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.subdirectory_arrow_right,
              size: 40,
              color: AppColors.textHint.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Text(
              '「${selectedRoot?.name ?? ''}」下暂无子分类',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: selectedRootId == null
                  ? null
                  : () => _openForm(
                        context,
                        parentId: selectedRootId,
                      ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加子分类'),
            ),
          ],
        ),
      );
    }

    final listChildren = isSearching ? filteredChildren : children;

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
        child: isSearching
            ? ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: listChildren.length,
                itemBuilder: (context, index) {
                  final category = listChildren[index];
                  return CategoryTableRow(
                    key: ValueKey('child-search-${category.id}'),
                    category: category,
                    index: index,
                    isSystem: isSystemCategory(category),
                    enableDrag: false,
                    parentName: category.parentId == null
                        ? null
                        : rootNames[category.parentId],
                    onTap: () => _openForm(context, category: category),
                  );
                },
              )
            : ReorderableListView.builder(
                padding: EdgeInsets.zero,
                buildDefaultDragHandles: false,
                itemCount: listChildren.length,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex--;
                  final reordered = List<Category>.from(children);
                  final item = reordered.removeAt(oldIndex);
                  reordered.insert(newIndex, item);
                  await _reorderChildren(
                    orderedIds: [
                      for (final category in reordered)
                        if (category.id != null) category.id!,
                    ],
                  );
                },
                itemBuilder: (context, index) {
                  final category = listChildren[index];
                  return CategoryTableRow(
                    key: ValueKey('child-${category.id}'),
                    category: category,
                    index: index,
                    isSystem: isSystemCategory(category),
                    onTap: () => _openForm(context, category: category),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    Category? category,
    int? parentId,
  }) async {
    final saved = await showCategoryFormDialog(
      context,
      category: category,
      initialType: _selectedType,
      initialParentId: parentId ?? category?.parentId,
      onDelete: category == null
          ? null
          : () => _confirmDelete(context, category),
    );
    if (saved == true && mounted) {
      refreshCategories(ref);
    }
  }

  Future<void> _openDefaultCategories(
    BuildContext context,
    List<Category> roots,
  ) async {
    final saved = await showDefaultCategoriesDialog(
      context,
      type: _selectedType,
      existingRootNames: _existingRootNames(roots),
    );
    if (saved && mounted) {
      setState(() => _selectedRootId = null);
      refreshCategories(ref);
    }
  }

  Future<void> _reorderChildren({required List<int> orderedIds}) async {
    final service = await ref.read(categoryServiceProvider.future);
    final result = await service.reorderCategories(orderedIds);
    result.when(
      success: (_) => refreshCategories(ref),
      failure: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message)),
          );
        }
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Category category,
  ) async {
    final confirmed = await showGlassDialog<bool>(
      context: context,
      builder: (context) => GlassAlertDialog(
        title: const Text('删除分类'),
        content: Text('确定删除分类「${category.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final service = await ref.read(categoryServiceProvider.future);
    final result = await service.deleteCategory(category.id!);

    if (!mounted) return;

    result.when(
      success: (_) {
        if (_selectedRootId == category.id) {
          setState(() => _selectedRootId = null);
        }
        refreshCategories(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分类已删除')),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }
}
