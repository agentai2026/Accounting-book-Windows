import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoryRefreshProvider = StateProvider<int>((ref) => 0);

final categoryListProvider =
    FutureProvider.family<List<Category>, CategoryType?>((ref, type) async {
  ref.watch(categoryRefreshProvider);
  ref.watch(transactionRefreshProvider);
  final dao = await ref.watch(categoryDaoProvider.future);
  return dao.getAll(type: type);
});

final allCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  ref.watch(categoryRefreshProvider);
  ref.watch(transactionRefreshProvider);
  final dao = await ref.watch(categoryDaoProvider.future);
  return dao.getAll();
});

void refreshCategories(WidgetRef ref) {
  ref.read(categoryRefreshProvider.notifier).state++;
}

List<Category> buildCategoryTree(List<Category> categories, CategoryType type) {
  final filtered =
      categories.where((category) => category.type == type).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final roots = filtered.where((c) => c.parentId == null).toList();
  final result = <Category>[];

  for (final root in roots) {
    result.add(root);
    final children = filtered
        .where((c) => c.parentId == root.id)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    result.addAll(children);
  }

  return result;
}

int categoryDepth(Category category, Map<int, Category> byId) {
  var depth = 0;
  var current = category;
  while (current.parentId != null && byId.containsKey(current.parentId)) {
    depth++;
    current = byId[current.parentId]!;
  }
  return depth;
}

bool isSystemCategory(Category category) {
  return category.type == CategoryType.transfer && category.parentId == null;
}

Map<int, String> buildCategoryDisplayNameMap(List<Category> categories) {
  final byId = {
    for (final category in categories)
      if (category.id != null) category.id!: category,
  };

  return {
    for (final entry in byId.entries)
      entry.key: _resolveCategoryDisplayName(entry.value, byId),
  };
}

String _resolveCategoryDisplayName(Category category, Map<int, Category> byId) {
  final parentId = category.parentId;
  if (parentId != null && byId.containsKey(parentId)) {
    return '${byId[parentId]!.name} > ${category.name}';
  }
  return category.name;
}
