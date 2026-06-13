import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

class ExchangeRateSparklineChart extends StatelessWidget {
  const ExchangeRateSparklineChart({
    super.key,
    required this.rates,
    required this.isPositive,
  });

  final List<double> rates;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    if (rates.length < 2) {
      return const SizedBox(width: 88, height: 36);
    }

    final minRate = rates.reduce((a, b) => a < b ? a : b);
    final maxRate = rates.reduce((a, b) => a > b ? a : b);
    final range = (maxRate - minRate).abs();
    final padding = range == 0 ? maxRate.abs() * 0.02 : range * 0.15;
    final minY = minRate - padding;
    final maxY = maxRate + padding;
    final color = isPositive ? AppColors.income : AppColors.expense;

    return SizedBox(
      width: 88,
      height: 36,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (rates.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < rates.length; i++)
                  FlSpot(i.toDouble(), rates[i]),
              ],
              isCurved: true,
              curveSmoothness: 0.25,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
