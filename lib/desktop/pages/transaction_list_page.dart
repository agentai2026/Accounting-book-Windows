import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/add_transaction_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/layout/content_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_album_view.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_calendar_view.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_detail_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_grouped_list.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/dialogs/ai_image_recognition_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/dialogs/transaction_import_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_page_widgets.dart';

class TransactionListPage extends ConsumerStatefulWidget {
  const TransactionListPage({
    super.key,
    this.initialView,
  });

  final TransactionDetailView? initialView;

  @override
  ConsumerState<TransactionListPage> createState() =>
      _TransactionListPageState();
}

class _TransactionListPageState extends ConsumerState<TransactionListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialView != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(transactionFilterProvider.notifier)
            .setView(widget.initialView!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.read(transactionRefreshProvider.notifier).state++;
  }

  Future<void> _addTransaction() async {
    final saved = await showAddTransactionDialog(context);
    if (saved == true && mounted) {
      _refresh();
    }
  }

  Future<void> _importTransactions() async {
    await showTransactionImportDialog(context, ref);
  }

  Future<void> _aiRecognize() async {
    await showAiImageRecognitionDialog(context);
    if (mounted) _refresh();
  }

  Future<void> _openDetail(TransactionRowData row) async {
    final changed = await showTransactionDetailDialog(context, row: row);
    if (changed == true && mounted) {
      _refresh();
    }
  }

  Future<void> _confirmDelete(TransactionRowData row) async {
    final confirmed = await showGlassDialog<bool>(
      context: context,
      builder: (context) => GlassAlertDialog(
        title: const Text('删除账单'),
        content: Text('确定删除 ${row.amountText} 的账单吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final service = await ref.read(bookkeepingServiceProvider.future);
    final id = row.transaction.id;
    if (id == null) return;

    final result = await service.deleteTransaction(id);
    if (!mounted) return;

    result.when(
      success: (_) {
        _refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(transactionFilterProvider);
    final rowsAsync = ref.watch(transactionListProvider);
    final countAsync = ref.watch(transactionCountProvider);
    final summaryAsync = ref.watch(transactionPeriodSummaryProvider);
    final currencyCode = ref.watch(currencyCodeProvider);

    if (_searchController.text != filter.keyword) {
      _searchController.text = filter.keyword;
    }

    final summary = summaryAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const PeriodSummary(expenseCents: 0, incomeCents: 0),
    );
    final totalCount = countAsync.maybeWhen(data: (c) => c, orElse: () => 0);

    return ContentPanel(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TransactionFilterSidebar(filter: filter),
          VerticalDivider(width: 1, color: AppThemeColors.border(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TransactionPageHeader(
                  view: filter.view,
                  searchController: _searchController,
                  onSearchChanged: (value) => ref
                      .read(transactionFilterProvider.notifier)
                      .setKeyword(value),
                  onRefresh: _refresh,
                  onAdd: _addTransaction,
                  onAiRecognize: _aiRecognize,
                  onImport: _importTransactions,
                ),
                const SizedBox(height: 16),
                TransactionSummaryCards(
                  summary: summary,
                  transactionCount: totalCount,
                  currencyCode: currencyCode,
                ),
                const SizedBox(height: 12),
                TransactionRangeNavigator(filter: filter),
                TransactionActiveFiltersBar(filter: filter),
                const SizedBox(height: 12),
                Expanded(
                  child: GlassSurface(
                    borderRadius: BorderRadius.circular(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: switch (filter.view) {
                        TransactionDetailView.list => rowsAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                            error: (e, _) =>
                                Center(child: Text('加载失败: $e')),
                            data: (rows) {
                              if (rows.isEmpty) {
                                return TransactionListEmptyPanel(
                                  onAdd: _addTransaction,
                                  onImport: _importTransactions,
                                );
                              }
                              return TransactionGroupedList(
                                rows: rows,
                                currencyCode: currencyCode,
                                onTap: _openDetail,
                                onDelete: _confirmDelete,
                              );
                            },
                          ),
                        TransactionDetailView.calendar =>
                          TransactionCalendarView(
                            currencyCode: currencyCode,
                            onTap: _openDetail,
                            onDelete: _confirmDelete,
                          ),
                        TransactionDetailView.album =>
                          const TransactionAlbumView(),
                      },
                    ),
                  ),
                ),
                TransactionPaginationBar(
                  filter: filter,
                  countAsync: countAsync,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
