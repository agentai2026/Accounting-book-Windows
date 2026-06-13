import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

class IncomeExpenseTrendChart extends StatelessWidget {
  const IncomeExpenseTrendChart({
    super.key,
    required this.points,
    this.currencyCode = 'CNY',
    this.height = 200,
  });

  final List<DailyTrendPoint> points;
  final String currencyCode;
  final double height;

  bool get _hasData =>
      points.any((p) => p.expenseCents > 0 || p.incomeCents > 0);

  @override
  Widget build(BuildContext context) {
    if (!_hasData) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '暂无数据',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ),
      );
    }

    final maxYuan = points.fold<double>(0, (max, p) {
      final expense = p.expenseCents / 100;
      final income = p.incomeCents / 100;
      return [max, expense, income].reduce((a, b) => a > b ? a : b);
    });
    final maxY = maxYuan <= 0 ? 100.0 : maxYuan * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendDot(color: AppColors.expense, label: '支出'),
            const SizedBox(width: 16),
            _LegendDot(color: AppColors.income, label: '收入'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.divider,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        '¥${value.toInt()}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= points.length) {
                        return const SizedBox.shrink();
                      }
                      if (index % 5 != 0 && index != points.length - 1) {
                        return const SizedBox.shrink();
                      }
                      final day = points[index].date.day;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '$day日',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textHint,
                                  ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < points.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 2,
                    barRods: [
                      BarChartRodData(
                        toY: points[i].expenseCents / 100,
                        color: AppColors.expense.withValues(alpha: 0.85),
                        width: 4,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                      BarChartRodData(
                        toY: points[i].incomeCents / 100,
                        color: AppColors.income.withValues(alpha: 0.85),
                        width: 4,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ],
                  ),
              ],
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final point = points[group.x.toInt()];
                    final isExpense = rodIndex == 0;
                    final cents =
                        isExpense ? point.expenseCents : point.incomeCents;
                    if (cents == 0) return null;
                    return BarTooltipItem(
                      '${isExpense ? '支出' : '收入'}\n${MoneyUtils.format(cents, currencyCode: currencyCode)}',
                      TextStyle(
                        color: isExpense ? AppColors.expense : AppColors.income,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
