import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_page_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_date_range_calendar.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/home/home_dashboard_widgets.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/layout/content_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/statistics/statistics_dashboard_widgets.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/statistics/statistics_tab_views.dart';

/// 统计分析页：筛选 + 控制条 + 五类 Tab 内容（毛玻璃风格）
class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(currencyCodeProvider);
    final filter = ref.watch(statisticsFilterProvider);
    final pageState = ref.watch(statisticsPageProvider);
    final reportAsync = ref.watch(statisticsFullReportProvider);
    final accountsAsync = ref.watch(statisticsAccountsProvider);
    final booksAsync = ref.watch(bookListProvider);
    final supportsDailyTrend =
        reportAsync.valueOrNull?.supportsDailyTrend ?? true;

    return ContentPanel(
      padding: const EdgeInsets.all(16),
      child: accountsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => const Center(child: Text('加载失败')),
        data: (accounts) => booksAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, __) => const Center(child: Text('加载失败')),
          data: (books) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatisticsFilterToolbar(
                  filter: filter,
                  accounts: accounts,
                  books: books,
                  rangeLabel: reportAsync.maybeWhen(
                    data: (r) => formatStatisticsRange(r.start, r.end),
                    orElse: () => filter.periodLabel(),
                  ),
                  onPeriodChanged: (p) =>
                      ref.read(statisticsFilterProvider.notifier).setPeriod(p),
                  onCustomRange: () => _pickCustomRange(context, ref),
                  onTypeChanged: (type) => ref
                      .read(statisticsFilterProvider.notifier)
                      .setTransactionType(type),
                  onAccountChanged: (id) => ref
                      .read(statisticsFilterProvider.notifier)
                      .setAccountId(id),
                  onBookChanged: (id) => ref
                      .read(statisticsFilterProvider.notifier)
                      .setBookId(id),
                  onKeywordChanged: (kw) => ref
                      .read(statisticsFilterProvider.notifier)
                      .setKeyword(kw),
                  onRefresh: () =>
                      ref.read(transactionRefreshProvider.notifier).state++,
                ),
                const SizedBox(height: 14),
                StatisticsControlStrip(
                  pageState: pageState,
                  supportsDailyTrend: supportsDailyTrend,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: reportAsync.when(
                    skipLoadingOnReload: true,
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (_, __) =>
                        const Center(child: Text('加载统计数据失败')),
                    data: (report) {
                      final assetSummary =
                          AssetSummary.fromAccounts(accounts);
                      return StatisticsTabContent(
                        pageState: pageState,
                        report: report,
                        accounts: accounts,
                        assetSummary: assetSummary,
                        currencyCode: currencyCode,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final filter = ref.read(statisticsFilterProvider);
    final picked = await showAppDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialRange: DateTimeRange(
        start: filter.customStart ?? DateTime(now.year, now.month, 1),
        end: filter.customEnd ?? now,
      ),
    );
    if (picked != null && context.mounted) {
      ref.read(statisticsFilterProvider.notifier).setCustomRange(
            picked.start,
            picked.end,
          );
    }
  }
}
