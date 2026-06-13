import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/calendar_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/lunar_display_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/empty_state.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_grouped_list.dart';

class TransactionCalendarView extends ConsumerWidget {
  const TransactionCalendarView({
    super.key,
    required this.onDelete,
    required this.onTap,
    required this.currencyCode,
  });

  final void Function(TransactionRowData row) onDelete;
  final void Function(TransactionRowData row) onTap;
  final String currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(calendarMonthProvider);
    final selectedDay = ref.watch(calendarSelectedDayProvider);
    final monthDataAsync = ref.watch(calendarMonthDataProvider);
    final settings = ref.watch(settingsProvider);
    final weekStartsOn = ref.watch(weekStartsOnProvider);

    final daysInMonth = AppDateUtils.endOfMonth(month).day;
    final startOffset = AppDateUtils.calendarGridStartOffset(
      month,
      weekStartsOn: weekStartsOn,
    );
    final weekdayLabels = AppDateUtils.weekdayLabels(weekStartsOn: weekStartsOn);
    final dayFontWeight = switch (settings.calendarFontWeight) {
      CalendarFontWeight.light => FontWeight.w300,
      CalendarFontWeight.normal => FontWeight.w500,
      CalendarFontWeight.bold => FontWeight.w700,
    };
    final dayFontSize = switch (settings.calendarFontSize) {
      CalendarFontSize.small => 12.0,
      CalendarFontSize.normal => 14.0,
      CalendarFontSize.large => 16.0,
    };

    final effectiveDay = selectedDay ??
        DateTime(
          month.year,
          month.month,
          DateTime.now().month == month.month && DateTime.now().year == month.year
              ? DateTime.now().day
              : 1,
        );

    final dayRowsAsync = ref.watch(transactionDayRowsProvider(effectiveDay));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: weekdayLabels
              .map(
                (w) => Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Expanded(
          flex: 3,
          child: monthDataAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (_, __) => const Center(child: Text('加载日历失败')),
            data: (points) {
              final map = {for (final p in points) p.date.day: p};
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.05,
                ),
                itemCount: startOffset + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < startOffset) {
                    return const SizedBox.shrink();
                  }
                  final day = index - startOffset + 1;
                  final date = DateTime(month.year, month.month, day);
                  final point = map[day];
                  final isSelected = effectiveDay.year == date.year &&
                      effectiveDay.month == date.month &&
                      effectiveDay.day == date.day;
                  final isToday = _isSameDay(date, DateTime.now());
                  final lunar = lunarDayShort(date);

                  return InkWell(
                    onTap: () =>
                        ref.read(calendarSelectedDayProvider.notifier).state =
                            date,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.selectedBackground : null,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected || isToday
                              ? AppColors.primary.withValues(alpha: 0.45)
                              : AppColors.border.withValues(alpha: 0.6),
                        ),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontWeight: isToday ? FontWeight.bold : dayFontWeight,
                              fontSize: dayFontSize,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (lunar.isNotEmpty)
                            Text(
                              lunar,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textHint,
                                    fontSize: 10,
                                  ),
                            ),
                          const Spacer(),
                          if (!settings.calendarSingleDay || isSelected) ...[
                          if (point != null && point.expenseCents > 0)
                            Text(
                              _formatCalendarAmount(
                                point.expenseCents,
                                currencyCode: currencyCode,
                                precise: settings.calendarPreciseAmount,
                              ),
                              style: const TextStyle(
                                color: TransactionListColors.expenseText,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (point != null && point.incomeCents > 0)
                            Text(
                              _formatCalendarAmount(
                                point.incomeCents,
                                currencyCode: currencyCode,
                                precise: settings.calendarPreciseAmount,
                              ),
                              style: const TextStyle(
                                color: TransactionListColors.incomeText,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          flex: 2,
          child: dayRowsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text('加载失败: $e')),
            data: (rows) {
              if (rows.isEmpty) {
                return const EmptyState(message: '没有交易数据');
              }
              return TransactionGroupedList(
                rows: rows,
                currencyCode: currencyCode,
                onTap: onTap,
                onDelete: onDelete,
                groupByDate: false,
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _formatCalendarAmount(
    int cents, {
    required String currencyCode,
    required bool precise,
  }) {
    if (precise) {
      return MoneyUtils.formatSpaced(cents, currencyCode: currencyCode);
    }
    final yuan = (cents.abs() / 100).round();
    if (yuan >= 10000) {
      return '${(yuan / 10000).toStringAsFixed(1)}万';
    }
    return '$yuan';
  }
}
