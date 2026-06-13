import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/book.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/display_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';

const kAddDialogAmountColor = Color(0xFF2D8C7B);

InputDecoration addDialogFieldDecoration(
  BuildContext context, {
  bool focused = false,
  String? hintText,
  // 已废弃：请用 AppLabeledField / AppTextField 外置标签
  @Deprecated('Use AppLabeledField') String? labelText,
}) =>
    appFieldBoxDecoration(
      context,
      focused: focused,
      hintText: hintText,
    );

/// 交易标记标签名（退款/优惠通过标签持久化）
const kTransactionRefundTag = '退款';
const kTransactionDiscountTag = '优惠';

List<String> mergeTransactionFlagTags(
  Iterable<String> tagNames, {
  required bool refund,
  required bool discount,
}) {
  final names = tagNames
      .where((n) => n != kTransactionRefundTag && n != kTransactionDiscountTag)
      .toList();
  if (refund) names.add(kTransactionRefundTag);
  if (discount) names.add(kTransactionDiscountTag);
  return names;
}

/// 单个是/否开关表单项（报销 / 退款 / 优惠）
class TransactionToggleFormField extends StatelessWidget {
  const TransactionToggleFormField({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppLabeledField(
      label: label,
      child: InputDecorator(
        decoration: addDialogFieldDecoration(context),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ? '是' : '否',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: onChanged != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
              ),
            ),
            if (onChanged != null)
              Switch.adaptive(
                value: value,
                activeTrackColor: AppColors.primary,
                onChanged: onChanged,
              ),
          ],
        ),
      ),
    );
  }
}

/// 报销 / 退款 / 优惠 三个开关行
class TransactionFlagTogglesRow extends StatelessWidget {
  const TransactionFlagTogglesRow({
    super.key,
    required this.showReimbursable,
    required this.showRefund,
    required this.showDiscount,
    required this.isReimbursable,
    required this.isRefund,
    required this.isDiscount,
    this.onReimbursableChanged,
    this.onRefundChanged,
    this.onDiscountChanged,
  });

  final bool showReimbursable;
  final bool showRefund;
  final bool showDiscount;
  final bool isReimbursable;
  final bool isRefund;
  final bool isDiscount;
  final ValueChanged<bool>? onReimbursableChanged;
  final ValueChanged<bool>? onRefundChanged;
  final ValueChanged<bool>? onDiscountChanged;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    void addField(TransactionToggleFormField field) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(width: 16));
      }
      children.add(Expanded(child: field));
    }

    if (showReimbursable) {
      addField(
        TransactionToggleFormField(
          label: '报销',
          value: isReimbursable,
          onChanged: onReimbursableChanged,
        ),
      );
    }
    if (showRefund) {
      addField(
        TransactionToggleFormField(
          label: '退款',
          value: isRefund,
          onChanged: onRefundChanged,
        ),
      );
    }
    if (showDiscount) {
      addField(
        TransactionToggleFormField(
          label: '优惠',
          value: isDiscount,
          onChanged: onDiscountChanged,
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class AddDialogPickerField extends StatelessWidget {
  const AddDialogPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.expanded,
    required this.onTap,
    this.muted = false,
    this.trailingIcon,
    this.readOnly = false,
  });

  final String label;
  final String value;
  final bool expanded;
  final VoidCallback onTap;
  final bool muted;
  final IconData? trailingIcon;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    if (readOnly) {
      return AppLabeledField(
        label: label,
        child: InputDecorator(
          decoration: addDialogFieldDecoration(context),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: muted ? AppColors.textHint : AppColors.textPrimary,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    final icon = trailingIcon ??
        (expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down);

    return AppLabeledField(
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: addDialogFieldDecoration(
            context,
            focused: expanded,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color:
                            muted ? AppColors.textHint : AppColors.textPrimary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: AppColors.textHint, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// 根据锚点字段位置，在表单上层浮层展示面板（不被后续字段遮挡）
class AddDialogFloatingPanel extends StatelessWidget {
  const AddDialogFloatingPanel({
    super.key,
    required this.stackKey,
    required this.anchorKey,
    required this.child,
    this.panelHeightEstimate = 280,
    this.preferAbove,
  });

  final GlobalKey stackKey;
  final GlobalKey anchorKey;
  final Widget child;
  final double panelHeightEstimate;

  /// 为 null 时自动判断：下方空间不足则向上展开
  final bool? preferAbove;

  @override
  Widget build(BuildContext context) {
    final anchorContext = anchorKey.currentContext;
    final stackContext = stackKey.currentContext;
    if (anchorContext == null || stackContext == null) {
      return const SizedBox.shrink();
    }

    final anchorBox = anchorContext.findRenderObject() as RenderBox?;
    final stackBox = stackContext.findRenderObject() as RenderBox?;
    if (anchorBox == null ||
        stackBox == null ||
        !anchorBox.hasSize ||
        !stackBox.hasSize) {
      return const SizedBox.shrink();
    }

    final anchorGlobal = anchorBox.localToGlobal(Offset.zero);
    final stackGlobal = stackBox.localToGlobal(Offset.zero);
    final left = anchorGlobal.dx - stackGlobal.dx;
    final belowTop =
        anchorGlobal.dy - stackGlobal.dy + anchorBox.size.height + 2;
    final spaceBelow = stackBox.size.height - belowTop;
    final openAbove = preferAbove ?? (spaceBelow < panelHeightEstimate);
    final rawTop = openAbove
        ? anchorGlobal.dy -
            stackGlobal.dy -
            panelHeightEstimate -
            2
        : belowTop;
    final maxTop = (stackBox.size.height - panelHeightEstimate - 4)
        .clamp(0.0, double.infinity);
    final top = rawTop.clamp(0.0, maxTop);

    return Positioned(
      top: top,
      left: left,
      width: anchorBox.size.width,
      child: GlassPickerShell(child: child),
    );
  }
}

class CategoryPickerPanel extends StatefulWidget {
  const CategoryPickerPanel({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  State<CategoryPickerPanel> createState() => _CategoryPickerPanelState();
}

class _CategoryPickerPanelState extends State<CategoryPickerPanel> {
  final _searchController = TextEditingController();
  int? _activeRootId;

  @override
  void initState() {
    super.initState();
    _activeRootId = _resolveRootId(widget.selectedId);
  }

  @override
  void didUpdateWidget(CategoryPickerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      _activeRootId = _resolveRootId(widget.selectedId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int? _resolveRootId(int? selectedId) {
    if (selectedId == null) {
      return _roots.isEmpty ? null : _roots.first.id;
    }
    final selected = widget.categories.firstWhere(
      (c) => c.id == selectedId,
      orElse: () => widget.categories.first,
    );
    return selected.parentId ?? selected.id;
  }

  List<Category> get _roots {
    return widget.categories.where((c) => c.parentId == null).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<Category> _childrenOf(int? rootId) {
    if (rootId == null) return [];
    return widget.categories
        .where((c) => c.parentId == rootId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  bool _matches(Category category, String keyword) {
    if (keyword.isEmpty) return true;
    return category.name.toLowerCase().contains(keyword);
  }

  @override
  Widget build(BuildContext context) {
    final keyword = _searchController.text.trim().toLowerCase();
    final roots = _roots
        .where((r) => _matches(r, keyword) || _childrenOf(r.id).any((c) => _matches(c, keyword)))
        .toList();
    Category? activeRoot;
    for (final root in roots) {
      if (root.id == _activeRootId) {
        activeRoot = root;
        break;
      }
    }
    activeRoot ??= roots.isEmpty ? null : roots.first;
    final children = _childrenOf(activeRoot?.id)
        .where((c) => keyword.isEmpty || _matches(c, keyword) || _matches(activeRoot!, keyword))
        .toList();

    return GlassPickerShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '查找分类',
                filled: true,
                fillColor: GlassStyles.fieldFill(context),
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textHint),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: roots.length,
                    itemBuilder: (context, index) {
                      final root = roots[index];
                      final selected = root.id == activeRoot?.id;
                      return _PickerListTile(
                        icon: categoryIconData(root.icon),
                        label: root.name,
                        selected: selected,
                        onTap: () => setState(() => _activeRootId = root.id),
                      );
                    },
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: GlassStyles.divider(context),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: children.isEmpty ? 1 : children.length,
                    itemBuilder: (context, index) {
                      if (children.isEmpty) {
                        final root = activeRoot;
                        if (root != null) {
                          final selected = widget.selectedId == root.id;
                          return _PickerListTile(
                            icon: categoryIconData(root.icon),
                            label: root.name,
                            selected: selected,
                            onTap: () {
                              if (root.id != null) {
                                widget.onSelected(root.id!);
                              }
                            },
                          );
                        }
                      }
                      final child = children[index];
                      final selected = widget.selectedId == child.id;
                      return _PickerListTile(
                        icon: categoryIconData(child.icon),
                        label: child.name,
                        selected: selected,
                        onTap: () {
                          if (child.id != null) widget.onSelected(child.id!);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountPickerPanel extends StatefulWidget {
  const AccountPickerPanel({
    super.key,
    required this.accounts,
    required this.selectedId,
    required this.currencyCode,
    required this.onSelected,
    this.excludeId,
  });

  final List<Account> accounts;
  final int? selectedId;
  final String currencyCode;
  final ValueChanged<int> onSelected;
  final int? excludeId;

  @override
  State<AccountPickerPanel> createState() => _AccountPickerPanelState();
}

class _AccountPickerPanelState extends State<AccountPickerPanel> {
  final _searchController = TextEditingController();

  List<Account> get _filteredAccounts {
    return widget.accounts
        .where((a) => a.id != null && a.id != widget.excludeId)
        .toList();
  }

  List<Account> get _visibleAccounts {
    final keyword = _searchController.text.trim().toLowerCase();
    return _filteredAccounts.where((account) {
      if (keyword.isEmpty) return true;
      return account.name.toLowerCase().contains(keyword) ||
          accountTypeLabel(account.type).toLowerCase().contains(keyword);
    }).toList();
  }

  Account? get _selectedAccount {
    if (widget.selectedId == null) return null;
    for (final account in _filteredAccounts) {
      if (account.id == widget.selectedId) return account;
    }
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedAccount;
    final accounts = _visibleAccounts;

    return GlassPickerShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '查找账户',
                filled: true,
                fillColor: GlassStyles.fieldFill(context),
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textHint),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  child: ColoredBox(
                    color: GlassStyles.panelTint(context),
                    child: selected == null
                        ? Center(
                            child: Text(
                              '请选择账户',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textHint,
                                  ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  accountTypeIcon(selected.type),
                                  size: 36,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  selected.name,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  MoneyUtils.formatSpaced(
                                    selected.balance,
                                    currencyCode: widget.currencyCode,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: kAddDialogAmountColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: GlassStyles.divider(context),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return _PickerListTile(
                        icon: accountTypeIcon(account.type),
                        label: account.name,
                        subtitle: MoneyUtils.formatSpaced(
                          account.balance,
                          currencyCode: widget.currencyCode,
                        ),
                        selected: account.id == widget.selectedId,
                        onTap: () {
                          if (account.id != null) {
                            widget.onSelected(account.id!);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerListTile extends StatelessWidget {
  const _PickerListTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.selectedBackground : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20 *
                    (ProviderScope.containerOf(context)
                            .read(settingsIconScaleProvider)),
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String resolveCategoryDisplayText(
  List<Category> categories,
  int? selectedId,
) {
  if (selectedId == null) return '请选择分类';
  final nameMap = buildCategoryDisplayNameMap(categories);
  return nameMap[selectedId] ?? '请选择分类';
}

String resolveAccountDisplayText(List<Account> accounts, int? selectedId) {
  if (selectedId == null) return '请选择账户';
  for (final account in accounts) {
    if (account.id == selectedId) return account.name;
  }
  return '请选择账户';
}

class BookPickerPanel extends StatelessWidget {
  const BookPickerPanel({
    super.key,
    required this.books,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Book> books;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return GlassPickerShell(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: books.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: AppColors.divider,
            indent: 12,
            endIndent: 12,
          ),
          itemBuilder: (context, index) {
            final book = books[index];
            final selected = book.id == selectedId;
            return Material(
              color: selected ? AppColors.selectedBackground : Colors.transparent,
              child: InkWell(
                onTap: book.id == null ? null : () => onSelected(book.id!),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _bookColor(book.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          book.name,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                        ),
                      ),
                    ],
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

Color _bookColor(String hex) {
  if (hex.startsWith('#') && hex.length == 7) {
    final value = int.tryParse(hex.substring(1), radix: 16);
    if (value != null) return Color(0xFF000000 | value);
  }
  return AppColors.primary;
}

String resolveBookDisplayText(List<Book> books, int? selectedId) {
  if (selectedId == null) return '请选择账本';
  for (final book in books) {
    if (book.id == selectedId) return book.name;
  }
  return '请选择账本';
}

int? pickDefaultCategoryId(List<Category> categories) {
  final roots = categories.where((c) => c.parentId == null).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  for (final root in roots) {
    final children = categories
        .where((c) => c.parentId == root.id)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (children.isNotEmpty && children.first.id != null) {
      return children.first.id;
    }
    if (root.id != null && children.isEmpty) {
      return root.id;
    }
  }
  return categories.isEmpty ? null : categories.first.id;
}
