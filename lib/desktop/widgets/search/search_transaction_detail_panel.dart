import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ezbookkeeping_desktop/core/constants/transaction_flag_tags.dart';
import 'package:ezbookkeeping_desktop/core/utils/transaction_accounting_flags.dart';
import 'package:ezbookkeeping_desktop/core/utils/transaction_display_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/budget_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_search_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/ez_branded_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/search/search_page_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_detail_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_image_preview.dart';

/// 搜索页右侧账单详情（参考移动端详情卡片）
class SearchTransactionDetailPanel extends ConsumerStatefulWidget {
  const SearchTransactionDetailPanel({super.key, required this.row});

  final TransactionRowData row;

  @override
  ConsumerState<SearchTransactionDetailPanel> createState() =>
      _SearchTransactionDetailPanelState();
}

class _SearchTransactionDetailPanelState
    extends ConsumerState<SearchTransactionDetailPanel> {
  bool _busy = false;

  Set<String> get _tagNameSet => widget.row.tagNames.toSet();

  Future<void> _openEdit() async {
    final changed = await showTransactionDetailDialog(context, row: widget.row);
    if (changed == true && mounted) {
      ref.read(transactionRefreshProvider.notifier).state++;
      ref.read(transactionSearchProvider.notifier).search();
    }
  }

  Future<void> _showImages() async {
    final images = widget.row.transaction.images;
    if (images == null || images.isEmpty) {
      await _openEdit();
      return;
    }

    if (!mounted) return;
    await showGlassDialog<void>(
      context: context,
      builder: (context) => GlassAlertDialog(
        maxWidth: 520,
        title: const Text('附件'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final path in images)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TransactionImagePreview(
                        relativePath: path,
                        width: 180,
                        height: 180,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openEdit();
            },
            child: const Text('编辑'),
          ),
        ],
      ),
    );
  }

  Future<void> _persistTagNames(Set<String> tagNames) async {
    final id = widget.row.transaction.id;
    if (id == null || _busy) return;

    setState(() => _busy = true);

    final tagService = await ref.read(tagServiceProvider.future);
    final tagIdsResult = await tagService.resolveTagIds(tagNames);
    List<int>? tagIds;
    tagIdsResult.when(
      success: (ids) => tagIds = ids,
      failure: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message)),
          );
        }
      },
    );
    if (tagIds == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }

    final service = await ref.read(bookkeepingServiceProvider.future);
    final result = await service.updateTransactionTags(
      transactionId: id,
      tagIds: tagIds!,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    result.when(
      success: (_) {
        ref.read(transactionRefreshProvider.notifier).state++;
        ref.read(transactionSearchProvider.notifier).search();
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  Future<void> _toggleExcludeFromIo(bool value) async {
    final next = Set<String>.from(_tagNameSet);
    if (value) {
      next.add(TransactionFlagTags.excludeFromIo);
    } else {
      next.remove(TransactionFlagTags.excludeFromIo);
    }
    await _persistTagNames(next);
  }

  Future<void> _toggleExcludeFromBudget(bool value) async {
    final next = Set<String>.from(_tagNameSet);
    if (value) {
      next.add(TransactionFlagTags.excludeFromBudget);
    } else {
      next.remove(TransactionFlagTags.excludeFromBudget);
    }
    await _persistTagNames(next);
  }

  Future<void> _delete() async {
    final id = widget.row.transaction.id;
    if (id == null) return;

    final confirmed = await showEzConfirmDialog(
      context,
      message: '确定删除这条账单吗？',
      confirmLabel: '删除',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final service = await ref.read(bookkeepingServiceProvider.future);
    final result = await service.deleteTransaction(id);
    if (!mounted) return;
    setState(() => _busy = false);

    result.when(
      success: (_) {
        ref.read(transactionRefreshProvider.notifier).state++;
        ref.read(transactionSearchProvider.notifier)
          ..search()
          ..selectTransaction(null);
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      },
    );
  }

  void _selectRelated(int? transactionId) {
    if (transactionId == null) return;
    ref.read(transactionSearchProvider.notifier).selectTransaction(transactionId);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final t = row.transaction;
    final books = ref.watch(bookListProvider).valueOrNull ?? [];
    String? bookName;
    for (final b in books) {
      if (b.id == t.bookId) {
        bookName = b.name;
        break;
      }
    }

    final remark = TransactionDisplayUtils.resolveRemark(t);
    final importSource = row.importSourceLabel;
    final payer = t.payer?.trim();
    final dateShort = DateFormat('MM-dd HH:mm').format(t.date);
    final dateFull = DateFormat('yyyy-MM-dd HH:mm').format(t.date);
    final recordTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(t.createdAt);
    final hasImages = t.images != null && t.images!.isNotEmpty;
    final tagNames = _tagNameSet;
    final displayTags = tagNames
        .where(
          (name) =>
              name != TransactionFlagTags.excludeFromIo &&
              name != TransactionFlagTags.excludeFromBudget,
        )
        .toList();
    final tagsText =
        displayTags.isEmpty ? null : displayTags.join('、');

    final budgets = ref.watch(budgetListProvider).valueOrNull ?? [];
    final budgetCategoryIds = budgets
        .where(
          (b) =>
              b.bookId == t.bookId &&
              b.deletedAt == null &&
              b.categoryId != null,
        )
        .map((b) => b.categoryId!)
        .toSet();
    final excludeFromIo = TransactionAccountingFlags.excludesFromIncomeExpense(
      t,
      tagNames: tagNames,
    );
    final excludeFromBudget = TransactionAccountingFlags.excludesFromBudget(
      t,
      budgetCategoryIds: budgetCategoryIds,
      tagNames: tagNames,
    );
    final canToggleIo = !TransactionAccountingFlags.isImportMetadataIoExcluded(t);
    final canToggleBudget = TransactionAccountingFlags.canToggleBudgetFlag(
      t,
      budgetCategoryIds: budgetCategoryIds,
    );

    final relatedAsync = t.id == null
        ? const AsyncValue<List<TransactionRowData>>.data([])
        : ref.watch(relatedTransactionRowsProvider(t.id!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailHeaderCard(
          row: row,
          dateShort: dateShort,
          remark: remark == '—' ? null : remark,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailListRow(
                  label: '账单分类',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SmallIconBadge(icon: row.categoryIcon),
                      const SizedBox(width: 6),
                      Text(row.categoryName),
                    ],
                  ),
                ),
                _DetailListRow(label: '账单日期', value: dateFull),
                _DetailListRow(
                  label: '收支账户',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 16,
                        color: AppThemeColors.textHint(context),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          row.accountName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _DetailListRow(
                  label: '备注',
                  value: remark,
                  showChevron: true,
                  onTap: _openEdit,
                ),
                if (payer != null && payer.isNotEmpty)
                  _DetailListRow(label: '付款人', value: payer),
                _DetailListRow(
                  label: '标签',
                  value: tagsText ?? '添加标签',
                  valueMuted: tagsText == null,
                  showChevron: tagsText == null,
                  onTap: _openEdit,
                ),
                _DetailListRow(
                  label: '附件',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 16,
                        color: AppThemeColors.textHint(context).withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(hasImages ? '${t.images!.length} 张' : '暂无附件'),
                    ],
                  ),
                  showChevron: hasImages,
                  onTap: hasImages ? _showImages : _openEdit,
                ),
                const _DetailDivider(),
                _DetailSwitchRow(
                  label: '不计入收支',
                  value: excludeFromIo,
                  enabled: canToggleIo && !_busy,
                  onChanged: canToggleIo ? _toggleExcludeFromIo : null,
                ),
                _DetailSwitchRow(
                  label: '不计入预算',
                  value: excludeFromBudget,
                  enabled: canToggleBudget && !_busy,
                  onChanged: canToggleBudget ? _toggleExcludeFromBudget : null,
                ),
                const _DetailDivider(),
                _DetailListRow(
                  label: '所属账本',
                  value: bookName ?? '—',
                ),
                _DetailListRow(
                  label: '地点信息',
                  value: (t.location?.trim().isNotEmpty == true)
                      ? t.location!.trim()
                      : '添加地点',
                  valueMuted: t.location?.trim().isEmpty != false,
                  showChevron: t.location?.trim().isEmpty != false,
                  onTap: _openEdit,
                ),
                _DetailListRow(label: '记录时间', value: recordTime),
                if (importSource != null)
                  _DetailListRow(label: '导入来源', value: importSource),
                _DetailListRow(
                  label: '记录方式',
                  value: TransactionDisplayUtils.resolveRecordMethodDetail(t),
                ),
                relatedAsync.when(
                  data: (relatedRows) {
                    if (relatedRows.isEmpty) {
                      return const _DetailListRow(
                        label: '关联账单',
                        value: '无关联',
                        valueMuted: true,
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DetailListRow(
                          label: '关联账单',
                          value: '${relatedRows.length} 笔',
                        ),
                        for (final related in relatedRows)
                          _RelatedTransactionRow(
                            row: related,
                            onTap: () =>
                                _selectRelated(related.transaction.id),
                          ),
                      ],
                    );
                  },
                  loading: () => const _DetailListRow(
                    label: '关联账单',
                    value: '加载中…',
                    valueMuted: true,
                  ),
                  error: (_, __) => const _DetailListRow(
                    label: '关联账单',
                    value: '无关联',
                    valueMuted: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _openEdit,
                  style: FilledButton.styleFrom(
                    backgroundColor: SearchPageColors.detailHeaderTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('编辑'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _delete,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5252),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('删除'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RelatedTransactionRow extends StatelessWidget {
  const _RelatedTransactionRow({
    required this.row,
    required this.onTap,
  });

  final TransactionRowData row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('yyyy/MM/dd').format(row.transaction.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
          child: Row(
            children: [
              const SizedBox(width: 72),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      row.categoryName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: AppThemeColors.textPrimary(context),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateText · ${row.amountText}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppThemeColors.textHint(context),
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppThemeColors.textHint(context).withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailHeaderCard extends StatelessWidget {
  const _DetailHeaderCard({
    required this.row,
    required this.dateShort,
    this.remark,
  });

  final TransactionRowData row;
  final String dateShort;
  final String? remark;

  @override
  Widget build(BuildContext context) {
    final amountColor = Colors.white;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: SearchPageColors.detailHeaderTeal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(
              row.categoryIcon ?? Icons.apps_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.categoryName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateShort,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
                if (remark != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    remark!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                row.amountText,
                style: TextStyle(
                  color: amountColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    row.accountName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailListRow extends StatelessWidget {
  const _DetailListRow({
    required this.label,
    this.value,
    this.trailing,
    this.valueMuted = false,
    this.showChevron = false,
    this.onTap,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final bool valueMuted;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: valueMuted
              ? AppThemeColors.textHint(context)
              : AppThemeColors.textPrimary(context),
          fontSize: 14,
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemeColors.textHint(context),
                        fontSize: 14,
                      ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: trailing ??
                      Text(
                        value ?? '',
                        textAlign: TextAlign.right,
                        style: valueStyle,
                      ),
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppThemeColors.textHint(context).withValues(alpha: 0.7),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSwitchRow extends StatelessWidget {
  const _DetailSwitchRow({
    required this.label,
    required this.value,
    this.enabled = true,
    this.onChanged,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemeColors.textHint(context),
                    fontSize: 14,
                  ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: SearchPageColors.detailHeaderTeal.withValues(
              alpha: 0.55,
            ),
            activeThumbColor: SearchPageColors.detailHeaderTeal,
          ),
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.border,
    );
  }
}

class _SmallIconBadge extends StatelessWidget {
  const _SmallIconBadge({this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(
        icon ?? Icons.label_outline,
        size: 13,
        color: AppColors.primary,
      ),
    );
  }
}
