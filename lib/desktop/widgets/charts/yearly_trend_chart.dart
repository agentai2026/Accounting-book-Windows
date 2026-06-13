import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

/// 首页 12 个月收入/支出柱状图（与 ezBookkeeping 参考 UI 一致）
class YearlyTrendChart extends StatelessWidget {
  const YearlyTrendChart({
    super.key,
    required this.points,
    this.currencyCode = 'CNY',
  });

  final List<MonthlyTrendPoint> points;
  final String currencyCode;

  static const _incomeColor = Color(0xFFC04848);
  static const _expenseColor = Color(0xFF1B8C7E);

  bool get _hasData =>
      points.any((p) => p.expenseCents > 0 || p.incomeCents > 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '收入与支出趋势',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: !_hasData
              ? Center(
                  child: Text(
                    '暂无数据',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                )
              : BarChart(
                  BarChartData(
                maxY: _maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _maxY / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(
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
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${points[index].month.month}月',
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
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: points[i].incomeCents / 100,
                          color: _incomeColor.withValues(alpha: 0.9),
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                        BarChartRodData(
                          toY: points[i].expenseCents / 100,
                          color: _expenseColor.withValues(alpha: 0.9),
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
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
                      final isIncome = rodIndex == 0;
                      final cents =
                          isIncome ? point.incomeCents : point.expenseCents;
                      if (cents == 0) return null;
                      return BarTooltipItem(
                        '${isIncome ? '收入' : '支出'}\n${MoneyUtils.formatSpaced(cents, currencyCode: currencyCode)}',
                        TextStyle(
                          color: isIncome ? _incomeColor : _expenseColor,
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _LegendDot(color: _incomeColor, label: '收入'),
            SizedBox(width: 24),
            _LegendDot(color: _expenseColor, label: '支出'),
          ],
        ),
      ],
    );
  }

  double get _maxY {
    final maxYuan = points.fold<double>(0, (max, p) {
      final expense = p.expenseCents / 100;
      final income = p.incomeCents / 100;
      return [max, expense, income].reduce((a, b) => a > b ? a : b);
    });
    return maxYuan <= 0 ? 100.0 : maxYuan * 1.25;
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
            shape: BoxShape.circle,
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

String formatHomePeriodLabel(DateTime start, DateTime end) {
  if (start.year == end.year && start.month == end.month && start.day == end.day) {
    return DateFormat('yyyy年M月d日', 'zh_CN').format(start);
  }
  if (start.year == end.year) {
    return '${start.month}月${start.day}日-${end.month}月${end.day}日';
  }
  return '${DateFormat('yyyy/M/d').format(start)}-${DateFormat('yyyy/M/d').format(end)}';
}
