import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/book.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/tag.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction.dart' as models;
import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/transaction_display_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/transaction_search_models.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/tag_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_search_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/search/search_anchored_popover.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/search/search_date_range_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/search/search_filter_popover.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/search/search_filter_styles.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/search/search_page_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/search/search_transaction_detail_panel.dart';

/// 三栏主布局
class TransactionSearchThreeColumnLayout extends ConsumerStatefulWidget {
  const TransactionSearchThreeColumnLayout({super.key});

  @override
  ConsumerState<TransactionSearchThreeColumnLayout> createState() =>
      _TransactionSearchThreeColumnLayoutState();
}

class _TransactionSearchThreeColumnLayoutState
    extends ConsumerState<TransactionSearchThreeColumnLayout> {
  late final TextEditingController _keywordController;
  late final TextEditingController _minAmountController;
  late final TextEditingController _maxAmountController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(transactionSearchProvider).draft;
    _keywordController = TextEditingController(text: draft.keyword);
    _minAmountController = TextEditingController(text: draft.minAmountText);
    _maxAmountController = TextEditingController(text: draft.maxAmountText);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(transactionSearchProvider).hasSearched) {
        ref.read(transactionSearchProvider.notifier).search();
      }
    });
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    ref.read(transactionSearchProvider.notifier).patchDraft(
          (d) => d.copyWith(
            keyword: _keywordController.text,
            minAmountText: _minAmountController.text,
            maxAmountText: _maxAmountController.text,
          ),
        );
  }

  void _runSearch() {
    _syncControllers();
    ref.read(transactionSearchProvider.notifier).search();
  }

  void _resetAll() {
    _keywordController.clear();
    _minAmountController.clear();
    _maxAmountController.clear();
    ref.read(transactionSearchProvider.notifier).reset();
    ref.read(transactionSearchProvider.notifier).search();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: SearchFilterStyles.panelWidth,
          child: _SearchFilterPanel(
            keywordController: _keywordController,
            minAmountController: _minAmountController,
            maxAmountController: _maxAmountController,
            onChanged: _syncControllers,
            onSearch: _runSearch,
            onReset: _resetAll,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(flex: 38, child: _SearchResultsColumn()),
        const SizedBox(width: 10),
        const Expanded(flex: 42, child: _SearchDetailColumn()),
      ],
    );
  }
}

// ─── 左栏：筛选面板 ───────────────────────────────────────────────

class _SearchFilterPanel extends ConsumerWidget {
  const _SearchFilterPanel({
    required this.keywordController,
    required this.minAmountController,
    required this.maxAmountController,
    required this.onChanged,
    required this.onSearch,
    required this.onReset,
  });

  final TextEditingController keywordController;
  final TextEditingController minAmountController;
  final TextEditingController maxAmountController;
  final VoidCallback onChanged;
  final VoidCallback onSearch;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(transactionSearchProvider).draft;
    final notifier = ref.read(transactionSearchProvider.notifier);
    final books = ref.watch(bookListProvider).valueOrNull ?? const <Book>[];
    final accounts =
        ref.watch(accountListProvider).valueOrNull ?? const <Account>[];
    final categories =
        ref.watch(allCategoriesProvider).valueOrNull ?? const <Category>[];
    final tags = ref.watch(tagListProvider).valueOrNull ?? const <Tag>[];

    return GlassSurface(
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: SearchPageColors.accent.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Text(
                  '搜索筛选',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onReset,
                  tooltip: '重置筛选',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: AppThemeColors.textHint(context).withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: GlassStyles.divider(context)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SearchDateRangeField(
                    startDate: draft.startDate,
                    endDate: draft.endDate,
                    onStartChanged: (date) => notifier.patchDraft(
                      (d) => date == null
                          ? d.copyWith(clearStartDate: true)
                          : d.copyWith(startDate: date),
                    ),
                    onEndChanged: (date) => notifier.patchDraft(
                      (d) => date == null
                          ? d.copyWith(clearEndDate: true)
                          : d.copyWith(endDate: date),
                    ),
                  ),
                  const SizedBox(height: SearchFilterStyles.sectionGap),
                  SearchFilterSection(
                    title: '金额',
                    child: Row(
                      children: [
                        Expanded(
                          child: SearchFilterTextField(
                            hint: '最低',
                            controller: minAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.,]'),
                              ),
                            ],
                            onChanged: onChanged,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '—',
                            style: TextStyle(
                              color: AppThemeColors.textHint(context),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SearchFilterTextField(
                            hint: '最高',
                            controller: maxAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.,]'),
                              ),
                            ],
                            onChanged: onChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SearchFilterStyles.sectionGap),
                  SearchFilterSection(
                    title: '备注',
                    child: SearchFilterTextField(
                      hint: '多个关键词可用空格分隔',
                      controller: keywordController,
                      onChanged: onChanged,
                    ),
                  ),
                  const SearchFilterPanelDivider(),
                  SearchFilterPopoverRow(
                    label: '账本',
                    popoverTitle: '选择账本',
                    popoverIcon: Icons.book_outlined,
                    itemIcon: Icons.book_outlined,
                    options: [
                      for (final b in books)
                        if (b.id != null) (id: b.id!, label: b.name),
                    ],
                    selectedIds: draft.bookIds,
                    onChanged: (ids) =>
                        notifier.patchDraft((d) => d.copyWith(bookIds: ids)),
                  ),
                  SearchFilterPopoverRow(
                    label: '账户',
                    popoverTitle: '选择账户',
                    popoverIcon: Icons.account_balance_wallet_outlined,
                    itemIcon: Icons.account_balance_wallet_outlined,
                    options: [
                      for (final a in accounts)
                        if (a.id != null) (id: a.id!, label: a.name),
                    ],
                    selectedIds: draft.accountIds,
                    onChanged: (ids) =>
                        notifier.patchDraft((d) => d.copyWith(accountIds: ids)),
                  ),
                  SearchReimburseFilterRow(
                    selected: draft.quickFilters,
                    onChanged: (filters) => notifier.patchDraft(
                      (d) => d.copyWith(quickFilters: filters),
                    ),
                  ),
                  SearchFilterPopoverRow(
                    label: '分类',
                    popoverTitle: '选择分类',
                    popoverIcon: Icons.category_outlined,
                    itemIcon: Icons.category_outlined,
                    options: [
                      for (final c in categories)
                        if (c.id != null) (id: c.id!, label: c.name),
                    ],
                    selectedIds: draft.categoryIds,
                    onChanged: (ids) =>
                        notifier.patchDraft((d) => d.copyWith(categoryIds: ids)),
                  ),
                  SearchFilterPopoverRow(
                    label: '标签',
                    popoverTitle: '选择标签',
                    popoverIcon: Icons.local_offer_outlined,
                    itemIcon: Icons.local_offer_outlined,
                    options: [
                      for (final t in tags)
                        if (t.id != null) (id: t.id!, label: t.name),
                    ],
                    selectedIds: draft.tagIds,
                    onChanged: (ids) =>
                        notifier.patchDraft((d) => d.copyWith(tagIds: ids)),
                  ),
                  const SearchFilterPanelDivider(),
                  SearchFilterSection(
                    title: '其他',
                    child: _OtherFilterGrid(
                      selected: draft.quickFilters,
                      onToggle: notifier.toggleQuickFilter,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: GlassStyles.divider(context)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppThemeColors.textSecondary(context),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.9),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('重置'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onSearch,
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text(
                      '搜索',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: SearchPageColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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

class _OtherFilterGrid extends StatelessWidget {
  const _OtherFilterGrid({
    required this.selected,
    required this.onToggle,
  });

  final Set<TransactionSearchQuickFilter> selected;
  final ValueChanged<TransactionSearchQuickFilter> onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final cellWidth = (constraints.maxWidth - spacing * 2) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final filter in TransactionSearchQuickFilter.values)
              SizedBox(
                width: cellWidth,
                child: _ToggleChip(
                  label: filter.label,
                  selected: selected.contains(filter),
                  onTap: () => onToggle(filter),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? SearchPageColors.chipSelectedBg.withValues(
              alpha: GlassStyles.isDark(context) ? 0.45 : 0.9,
            )
          : GlassStyles.fieldFill(context),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? SearchPageColors.accent.withValues(alpha: 0.85)
                  : GlassStyles.divider(context),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: selected
                  ? SearchPageColors.accent
                  : AppThemeColors.textSecondary(context),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 中栏：结果列表 ───────────────────────────────────────────────

DateTime? _monthFromFirstRow(List<TransactionRowData> rows) {
  if (rows.isEmpty) return null;
  final date = rows.first.transaction.date;
  return DateTime(date.year, date.month);
}

class _SearchResultsColumn extends ConsumerStatefulWidget {
  const _SearchResultsColumn();

  @override
  ConsumerState<_SearchResultsColumn> createState() =>
      _SearchResultsColumnState();
}

class _SearchResultsColumnState extends ConsumerState<_SearchResultsColumn> {
  DateTime? _visibleMonth;
  final _listKey = GlobalKey<_SearchTransactionListState>();

  void _onVisibleDayChanged(DateTime day) {
    final month = DateTime(day.year, day.month);
    if (_visibleMonth != null &&
        _visibleMonth!.year == month.year &&
        _visibleMonth!.month == month.month) {
      return;
    }
    setState(() => _visibleMonth = month);
  }

  void _resetVisibleMonth(List<TransactionRowData> rows) {
    final month = _monthFromFirstRow(rows);
    if (month == null) {
      if (_visibleMonth != null) setState(() => _visibleMonth = null);
      return;
    }
    if (_visibleMonth?.year != month.year || _visibleMonth?.month != month.month) {
      setState(() => _visibleMonth = month);
    }
  }

  Future<void> _jumpToDay(DateTime day) async {
    final notifier = ref.read(transactionSearchResultsProvider.notifier);
    final label = AppDateUtils.formatDateChinese(day);

    final exists = await notifier.hasTransactionsOnDay(day);
    if (!context.mounted) return;
    if (!exists) {
      final applied = ref.read(transactionSearchProvider).applied;
      final inRange = applied.isDayWithinAppliedRange(day);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            inRange ? '$label 暂无账单' : '$label 不在当前筛选日期范围内',
          ),
        ),
      );
      return;
    }

    final listState = _listKey.currentState;
    if (listState == null) return;

    var found = await listState.scrollToDay(
      day,
      loadMore: () => notifier.loadMore(),
    );

    if (!found) {
      await notifier.loadUntilContainsDay(day);
      if (!context.mounted) return;
      found = await listState.scrollToDay(day);
    }

    if (!found && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label 的账单已存在，定位失败请重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode = ref.watch(currencyCodeProvider);
    final resultsAsync = ref.watch(transactionSearchResultsProvider);
    final selectedId = ref.watch(transactionSearchProvider).selectedTransactionId;

    return GlassSurface(
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: resultsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: SearchPageColors.accent),
        ),
        error: (_, __) => const Center(child: Text('加载失败')),
        data: (bundle) {
          if (bundle.rows.isNotEmpty && _visibleMonth == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _resetVisibleMonth(bundle.rows);
            });
          }

          final monthAnchor = _visibleMonth ?? _monthFromFirstRow(bundle.rows);
          final monthSummary = monthAnchor == null
              ? bundle.summary
              : ref
                      .watch(
                        searchVisibleMonthSummaryProvider(
                          SearchMonthAnchor(
                            year: monthAnchor.year,
                            month: monthAnchor.month,
                          ),
                        ),
                      )
                      .maybeWhen(
                        data: (summary) => summary,
                        orElse: () => bundle.summary,
                      );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SearchMonthSummaryCard(
                summary: monthSummary,
                currencyCode: currencyCode,
                referenceDate: monthAnchor ?? DateTime.now(),
                onDaySelected: _jumpToDay,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: bundle.rows.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_outlined,
                              size: 48,
                              color: AppThemeColors.textHint(context).withValues(alpha: 0.45),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '没有匹配的账单',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppThemeColors.textHint(context),
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '调整筛选条件后点击搜索',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppThemeColors.textHint(context)
                                        .withValues(alpha: 0.75),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : _SearchTransactionList(
                        key: _listKey,
                        rows: bundle.rows,
                        currencyCode: currencyCode,
                        selectedId: selectedId,
                        hasMore: bundle.hasMore,
                        isLoadingMore: bundle.isLoadingMore,
                        onLoadMore: () => ref
                            .read(transactionSearchResultsProvider.notifier)
                            .loadMore(),
                        onVisibleDayChanged: _onVisibleDayChanged,
                        onRowsReplaced: _resetVisibleMonth,
                        onTap: (row) {
                          final date = row.transaction.date;
                          _onVisibleDayChanged(date);
                          ref
                              .read(transactionSearchProvider.notifier)
                              .selectTransaction(row.transaction.id);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _formatMonthSummaryAmount(int amountInCents) {
  return NumberFormat('#,##0.00').format(amountInCents.abs() / 100.0);
}

class _SearchMonthSummaryCard extends StatefulWidget {
  const _SearchMonthSummaryCard({
    required this.summary,
    required this.currencyCode,
    required this.referenceDate,
    required this.onDaySelected,
  });

  final PeriodSummary summary;
  final String currencyCode;
  final DateTime referenceDate;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<_SearchMonthSummaryCard> createState() => _SearchMonthSummaryCardState();
}

class _SearchMonthSummaryCardState extends State<_SearchMonthSummaryCard> {
  final _monthLink = LayerLink();

  void _openCalendar() {
    SearchAnchoredPopover.show(
      context: context,
      link: _monthLink,
      width: 320,
      child: SearchCalendarPanel(
        initial: widget.referenceDate,
        onSelected: (date) {
          SearchAnchoredPopover.dismiss();
          widget.onDaySelected(date);
        },
        onToday: () {
          SearchAnchoredPopover.dismiss();
          widget.onDaySelected(DateTime.now());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        '${widget.referenceDate.year}年${widget.referenceDate.month}月';
    final net = widget.summary.netCents;
    final balanceColor =
        net >= 0 ? SearchPageColors.incomeGreen : SearchPageColors.expenseRed;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: GlassStyles.panelTint(context, light: 0.28, dark: 0.38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlassStyles.divider(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompositedTransformTarget(
            link: _monthLink,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openCalendar,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: GlassStyles.fieldFill(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: GlassStyles.divider(context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppThemeColors.textPrimary(context),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 16,
                        color: SearchPageColors.accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MonthSummaryStatColumn(
                    barColor: SearchPageColors.expenseBar,
                    label: '支出',
                    amountText:
                        _formatMonthSummaryAmount(widget.summary.expenseCents),
                    valueColor: SearchPageColors.expenseRed,
                    icon: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 15,
                      color: SearchPageColors.expenseOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MonthSummaryStatColumn(
                    barColor: SearchPageColors.incomeBar,
                    label: '收入',
                    amountText:
                        _formatMonthSummaryAmount(widget.summary.incomeCents),
                    valueColor: SearchPageColors.incomeGreen,
                    icon: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: SearchPageColors.incomeBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.diamond_outlined,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MonthSummaryStatColumn(
                    barColor: SearchPageColors.incomeBar,
                    label: '结余',
                    amountText: _formatMonthSummaryAmount(net),
                    valueColor: balanceColor,
                    icon: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: SearchPageColors.balanceGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.more_horiz,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
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

class _MonthSummaryStatColumn extends StatelessWidget {
  const _MonthSummaryStatColumn({
    required this.barColor,
    required this.label,
    required this.amountText,
    required this.valueColor,
    required this.icon,
  });

  final Color barColor;
  final String label;
  final String amountText;
  final Color valueColor;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  icon,
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppThemeColors.textHint(context),
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amountText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        height: 1.1,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchTransactionList extends StatefulWidget {
  const _SearchTransactionList({
    super.key,
    required this.rows,
    required this.currencyCode,
    required this.selectedId,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onVisibleDayChanged,
    required this.onRowsReplaced,
    required this.onTap,
  });

  final List<TransactionRowData> rows;
  final String currencyCode;
  final int? selectedId;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final ValueChanged<DateTime> onVisibleDayChanged;
  final ValueChanged<List<TransactionRowData>> onRowsReplaced;
  final ValueChanged<TransactionRowData> onTap;

  @override
  State<_SearchTransactionList> createState() => _SearchTransactionListState();
}

class _SearchTransactionListState extends State<_SearchTransactionList> {
  final _scrollController = ScrollController();
  final _viewportKey = GlobalKey();
  final _dayHeaderKeys = <String, GlobalKey>{};

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _dayId(DateTime day) {
    final d = AppDateUtils.startOfDay(day);
    return '${d.year}-${d.month}-${d.day}';
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibleDay());
  }

  @override
  void didUpdateWidget(covariant _SearchTransactionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isNewSearch = _isNewSearchResult(oldWidget.rows, widget.rows);
    if (isNewSearch) {
      _dayHeaderKeys.clear();
      widget.onRowsReplaced(widget.rows);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibleDay());
  }

  bool _isNewSearchResult(
    List<TransactionRowData> oldRows,
    List<TransactionRowData> newRows,
  ) {
    if (oldRows.isEmpty || newRows.isEmpty) {
      return oldRows.length != newRows.length;
    }
    return oldRows.first.transaction.id != newRows.first.transaction.id ||
        newRows.length < oldRows.length;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  GlobalKey _keyForDay(DateTime day) {
    return _dayHeaderKeys.putIfAbsent(_dayId(day), GlobalKey.new);
  }

  List<DateTime> _sortedDays() {
    final groups = <DateTime, List<TransactionRowData>>{};
    for (final row in widget.rows) {
      final d = AppDateUtils.startOfDay(row.transaction.date);
      groups.putIfAbsent(d, () => []).add(row);
    }
    return groups.keys.toList()..sort((a, b) => b.compareTo(a));
  }

  bool _containsDay(DateTime day) {
    for (final row in widget.rows) {
      if (_sameDay(row.transaction.date, day)) return true;
    }
    return false;
  }

  DateTime? _oldestLoadedDay() {
    final days = _sortedDays();
    if (days.isEmpty) return null;
    return days.last;
  }

  double _estimateSectionHeight(DateTime day) {
    var count = 0;
    for (final row in widget.rows) {
      if (_sameDay(row.transaction.date, day)) count++;
    }
    return 46 + count * 68.0;
  }

  int _indexOfDay(List<DateTime> days, DateTime day) {
    for (var i = 0; i < days.length; i++) {
      if (_sameDay(days[i], day)) return i;
    }
    return -1;
  }

  double _estimateOffsetForDay(DateTime day) {
    final sortedDays = _sortedDays();
    final index = _indexOfDay(sortedDays, day);
    if (index < 0) return 0;

    var offset = 0.0;
    for (var i = 0; i < index; i++) {
      offset += _estimateSectionHeight(sortedDays[i]);
    }
    return offset;
  }

  Future<bool> _revealDayHeader(DateTime day) async {
    _keyForDay(day);
    for (var i = 0; i < 6; i++) {
      await WidgetsBinding.instance.endOfFrame;
      final key = _dayHeaderKeys[_dayId(day)];
      final ctx = key?.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: 0,
        );
        widget.onVisibleDayChanged(AppDateUtils.startOfDay(day));
        return true;
      }
    }
    return false;
  }

  /// 滚动到指定日期；若数据未加载会尝试 [loadMore]
  Future<bool> scrollToDay(
    DateTime day, {
    Future<void> Function()? loadMore,
  }) async {
    for (var attempt = 0; attempt < 40; attempt++) {
      if (_containsDay(day)) {
        if (!_scrollController.hasClients) {
          await WidgetsBinding.instance.endOfFrame;
        }
        if (_scrollController.hasClients) {
          final maxExtent = _scrollController.position.maxScrollExtent;
          final offset = _estimateOffsetForDay(day).clamp(0.0, maxExtent);
          if (offset <= 4) {
            await _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            );
          } else {
            await _scrollController.animateTo(
              offset,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            );
          }
        }
        return _revealDayHeader(day);
      }

      final oldest = _oldestLoadedDay();
      final canLoadMore = loadMore != null && widget.hasMore;
      if (canLoadMore &&
          oldest != null &&
          !AppDateUtils.startOfDay(day).isAfter(oldest)) {
        await loadMore();
        for (var i = 0; i < 8; i++) {
          await WidgetsBinding.instance.endOfFrame;
          if (_containsDay(day)) break;
        }
        continue;
      }
      break;
    }
    return false;
  }

  void _onScroll() {
    _updateVisibleDay();

    if (!widget.hasMore || widget.isLoadingMore) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 120) {
      widget.onLoadMore();
    }
  }

  void _updateVisibleDay() {
    final day = _resolveTopVisibleDay();
    if (day != null) widget.onVisibleDayChanged(day);
  }

  DateTime? _resolveTopVisibleDay() {
    final groups = <DateTime, List<TransactionRowData>>{};
    for (final row in widget.rows) {
      final d = AppDateUtils.startOfDay(row.transaction.date);
      groups.putIfAbsent(d, () => []).add(row);
    }
    final sortedDays = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    if (sortedDays.isEmpty) return null;

    final viewportBox =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null) return sortedDays.first;

    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
    var current = sortedDays.first;

    for (final day in sortedDays) {
      final key = _dayHeaderKeys[_dayId(day)];
      final ctx = key?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (top <= viewportTop + 12) {
        current = day;
      } else {
        break;
      }
    }

    return current;
  }

  @override
  Widget build(BuildContext context) {
    final groups = <DateTime, List<TransactionRowData>>{};
    for (final row in widget.rows) {
      final day = AppDateUtils.startOfDay(row.transaction.date);
      groups.putIfAbsent(day, () => []).add(row);
    }
    final sortedDays = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final footerCount =
        (widget.hasMore || widget.isLoadingMore) ? 1 : 0;

    return ListView.builder(
      key: _viewportKey,
      controller: _scrollController,
      itemCount: sortedDays.length + footerCount,
      itemBuilder: (context, index) {
        if (index >= sortedDays.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: widget.isLoadingMore
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SearchPageColors.accent,
                      ),
                    )
                  : Text(
                      '继续下滑加载更多',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppThemeColors.textHint(context),
                          ),
                    ),
            ),
          );
        }
        final day = sortedDays[index];
        final dayRows = groups[day]!;
        var income = 0;
        var expense = 0;
        for (final row in dayRows) {
          switch (row.transaction.type) {
            case TransactionType.income:
              income += row.transaction.amount;
            case TransactionType.expense:
              expense += row.transaction.amount;
            case TransactionType.transfer:
              break;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              key: _keyForDay(day),
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
              child: Row(
                children: [
                  Text(
                    '${day.month}月${day.day}日',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  if (income > 0)
                    Text(
                      '收入 ${MoneyUtils.formatSpaced(income, currencyCode: widget.currencyCode)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppThemeColors.textHint(context),
                      ),
                    ),
                  if (income > 0 && expense > 0) const SizedBox(width: 8),
                  if (expense > 0)
                    Text(
                      '支出 ${MoneyUtils.formatSpaced(expense, currencyCode: widget.currencyCode)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppThemeColors.textHint(context),
                      ),
                    ),
                ],
              ),
            ),
            for (final row in dayRows)
              _SearchTransactionTile(
                row: row,
                currencyCode: widget.currencyCode,
                selected: row.transaction.id == widget.selectedId,
                onTap: () => widget.onTap(row),
              ),
          ],
        );
      },
    );
  }
}

class _SearchTransactionTile extends StatelessWidget {
  const _SearchTransactionTile({
    required this.row,
    required this.currencyCode,
    required this.selected,
    required this.onTap,
  });

  final TransactionRowData row;
  final String currencyCode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = row.transaction;
    final timeText = DateFormat('HH:mm').format(t.date);
    final subtitle = _subtitle(t);
    final amountColor = switch (t.type) {
      TransactionType.expense => const Color(0xFFE57373),
      TransactionType.income => SearchPageColors.balanceGreen,
      TransactionType.transfer => AppColors.transfer,
    };
    final amountPrefix = switch (t.type) {
      TransactionType.expense => '-',
      TransactionType.income => '+',
      TransactionType.transfer => '',
    };

    return Material(
      color: selected
          ? SearchPageColors.chipSelectedBg.withValues(alpha: 0.65)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.panelBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  row.categoryIcon ?? Icons.label_outline,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle.isEmpty ? timeText : '$timeText $subtitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppThemeColors.textHint(context),
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountPrefix${MoneyUtils.formatSpaced(t.amount, currencyCode: currencyCode)}',
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 12,
                        color: AppThemeColors.textHint(context).withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        row.accountName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppThemeColors.textHint(context),
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(models.Transaction t) {
    final remark = TransactionDisplayUtils.resolveRemark(t);
    return remark == '—' ? '' : remark;
  }
}

// ─── 右栏：详情 ───────────────────────────────────────────────────

class _SearchDetailColumn extends ConsumerWidget {
  const _SearchDetailColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(transactionSearchProvider);
    final resultsAsync = ref.watch(transactionSearchResultsProvider);
    final selectedId = searchState.selectedTransactionId;

    return GlassSurface(
      borderRadius: BorderRadius.circular(14),
      child: selectedId == null
          ? const _SearchDetailEmpty()
          : resultsAsync.maybeWhen(
              data: (bundle) {
                TransactionRowData? row;
                for (final item in bundle.rows) {
                  if (item.transaction.id == selectedId) {
                    row = item;
                    break;
                  }
                }
                if (row != null) {
                  return SearchTransactionDetailPanel(row: row);
                }
                return _SearchDetailById(transactionId: selectedId);
              },
              orElse: () => _SearchDetailById(transactionId: selectedId),
            ),
    );
  }
}

class _SearchDetailById extends ConsumerWidget {
  const _SearchDetailById({required this.transactionId});

  final int transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowAsync = ref.watch(transactionRowByIdProvider(transactionId));
    return rowAsync.when(
      data: (row) => row == null
          ? const _SearchDetailEmpty()
          : SearchTransactionDetailPanel(row: row),
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: SearchPageColors.accent,
        ),
      ),
      error: (_, __) => const _SearchDetailEmpty(),
    );
  }
}

class _SearchDetailEmpty extends StatelessWidget {
  const _SearchDetailEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SearchEmptyIllustration(),
          const SizedBox(height: 20),
          Text(
            '请选择一条账单查看详情',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppThemeColors.textHint(context),
                ),
          ),
        ],
      ),
    );
  }
}

class _SearchEmptyIllustration extends StatelessWidget {
  const _SearchEmptyIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 120,
      child: CustomPaint(
        painter: _EmptyIllustrationPainter(),
      ),
    );
  }
}

class _EmptyIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final handPaint = Paint()
      ..color = const Color(0xFFFFE0B2)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = SearchPageColors.accent.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.55,
        size.width * 0.55,
        size.height * 0.65,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.75,
        size.width * 0.85,
        size.height * 0.45,
      );
    canvas.drawPath(path, linePaint);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.42, size.height * 0.72),
        width: 56,
        height: 36,
      ),
      handPaint,
    );

    final pencil = Paint()..color = SearchPageColors.accent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.58, size.height * 0.28, 10, 48),
        const Radius.circular(3),
      ),
      pencil,
    );
    canvas.drawCircle(
      Offset(size.width * 0.63, size.height * 0.24),
      6,
      Paint()..color = const Color(0xFFFFCC80),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
