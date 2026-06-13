import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_page_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

const _kInstantChartAnim = Duration.zero;

/// 与 AppColors 统一的图表色板
const _chartPalette = [
  AppColors.primary,
  AppColors.income,
  AppColors.expense,
  AppColors.transfer,
  Color(0xFFE2955D),
  Color(0xFF7BC67E),
  Color(0xFF5C6BC0),
  Color(0xFF8D6E63),
];

class StatisticsBreakdownSlice {
  const StatisticsBreakdownSlice({
    required this.label,
    required this.amountCents,
    required this.percentage,
    required this.color,
  });

  final String label;
  final int amountCents;
  final double percentage;
  final Color color;
}

List<StatisticsBreakdownSlice> buildSlicesFromCategories(
  List<CategoryBreakdownItem> items, {
  int maxSlices = 8,
}) {
  return _buildSlices(
    items.map((i) => (i.categoryName, i.amountCents)).toList(),
    maxSlices: maxSlices,
  );
}

List<StatisticsBreakdownSlice> buildSlicesFromAccounts(
  List<AccountBreakdownItem> items, {
  int maxSlices = 8,
}) {
  return _buildSlices(
    items.map((i) => (i.accountName, i.amountCents)).toList(),
    maxSlices: maxSlices,
  );
}

List<StatisticsBreakdownSlice> buildSlicesFromAccountFlow(
  List<AccountFlowItem> items, {
  int maxSlices = 8,
}) {
  return _buildSlices(
    items.map((i) => (i.accountName, i.amountCents)).toList(),
    maxSlices: maxSlices,
  );
}

List<StatisticsBreakdownSlice> _buildSlices(
  List<(String name, int amountCents)> items, {
  required int maxSlices,
}) {
  if (items.isEmpty) return [];
  final visible = items.take(maxSlices - 1).toList();
  final otherAmount = items
      .skip(maxSlices - 1)
      .fold<int>(0, (sum, item) => sum + item.$2);
  final total = items.fold<int>(0, (sum, item) => sum + item.$2);

  final slices = <StatisticsBreakdownSlice>[
    for (var i = 0; i < visible.length; i++)
      StatisticsBreakdownSlice(
        label: visible[i].$1,
        amountCents: visible[i].$2,
        percentage: total > 0 ? visible[i].$2 / total * 100 : 0,
        color: _chartPalette[i % _chartPalette.length],
      ),
  ];

  if (otherAmount > 0) {
    slices.add(
      StatisticsBreakdownSlice(
        label: '其他',
        amountCents: otherAmount,
        percentage: total > 0 ? otherAmount / total * 100 : 0,
        color: AppColors.textHint,
      ),
    );
  }
  return slices;
}

Widget _emptyChartPlaceholder() {
  return const Center(
    child: Text('暂无数据', style: TextStyle(color: AppColors.textHint)),
  );
}

double _niceMaxY(double rawMax) {
  if (rawMax <= 0) return 100;
  final padded = rawMax * 1.15;
  final magnitude = math.pow(10, (math.log(padded) / math.ln10).floor()).toDouble();
  final normalized = padded / magnitude;
  final nice = normalized <= 1
      ? 1
      : normalized <= 2
          ? 2
          : normalized <= 5
              ? 5
              : 10;
  return nice * magnitude;
}

String _compactAxisLabel(double yuan) {
  if (yuan >= 10000) {
    return '${(yuan / 10000).toStringAsFixed(yuan >= 100000 ? 0 : 1)}万';
  }
  if (yuan >= 1000) {
    return '${(yuan / 1000).toStringAsFixed(1)}k';
  }
  return yuan.toInt().toString();
}

FlGridData _defaultGrid(double interval) {
  return FlGridData(
    show: true,
    drawVerticalLine: false,
    horizontalInterval: interval,
    getDrawingHorizontalLine: (_) => const FlLine(
      color: AppColors.divider,
      strokeWidth: 1,
    ),
  );
}

/// 环形饼图：左侧图例 + 右侧图表 + 中心合计 + 触摸高亮
class StatisticsPieChart extends StatefulWidget {
  const StatisticsPieChart({
    super.key,
    required this.slices,
    this.currencyCode = 'CNY',
  });

  final List<StatisticsBreakdownSlice> slices;
  final String currencyCode;

  @override
  State<StatisticsPieChart> createState() => _StatisticsPieChartState();
}

class _StatisticsPieChartState extends State<StatisticsPieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.slices.isEmpty) return _emptyChartPlaceholder();

    final total = widget.slices.fold<int>(0, (s, i) => s + i.amountCents);

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.hasBoundedHeight &&
                constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 180.0;

        return SizedBox(
          height: boundedHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < widget.slices.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _RichLegendItem(
                          color: widget.slices[i].color,
                          label: widget.slices[i].label,
                          amount: MoneyUtils.format(
                            widget.slices[i].amountCents,
                            currencyCode: widget.currencyCode,
                          ),
                          percentage: widget.slices[i].percentage,
                          highlighted: _touchedIndex == i,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: LayoutBuilder(
                  builder: (context, chartBox) {
                    final side = math.min(
                          chartBox.maxWidth,
                          boundedHeight,
                        ) -
                        12;
                    final safeSide = side.clamp(88.0, 168.0);
                    final outerRadius = (safeSide / 2) - 6;
                    final centerRadius =
                        (outerRadius * 0.56).clamp(18.0, 56.0);

                    return Center(
                      child: SizedBox(
                        width: safeSide,
                        height: safeSide,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.hardEdge,
                          children: [
                            PieChart(
                              duration: _kInstantChartAnim,
                              PieChartData(
                                sectionsSpace: widget.slices.length > 1 ? 1.5 : 0,
                                centerSpaceRadius: centerRadius,
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, response) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          response?.touchedSection == null) {
                                        _touchedIndex = null;
                                        return;
                                      }
                                      _touchedIndex = response!
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                sections: [
                                  for (var i = 0; i < widget.slices.length; i++)
                                    _pieSection(
                                      slice: widget.slices[i],
                                      index: i,
                                      touched: _touchedIndex == i,
                                      outerRadius: outerRadius,
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(centerRadius * 0.15),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '合计',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.textHint,
                                          fontSize: 11,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      MoneyUtils.format(
                                        total,
                                        currencyCode: widget.currencyCode,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PieChartSectionData _pieSection({
    required StatisticsBreakdownSlice slice,
    required int index,
    required bool touched,
    required double outerRadius,
  }) {
    final baseRadius = touched ? outerRadius + 2 : outerRadius;
    return PieChartSectionData(
      value: slice.amountCents.toDouble().clamp(1, double.infinity),
      color: slice.color,
      radius: baseRadius,
      showTitle: touched,
      title: touched ? '${slice.percentage.toStringAsFixed(1)}%' : '',
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: touched ? 1 : 0.85),
        width: touched ? 2 : 1,
      ),
    );
  }
}

/// 水平条形图：轨道 + 渐变 + 金额 + 占比
class StatisticsBarChart extends StatelessWidget {
  const StatisticsBarChart({
    super.key,
    required this.slices,
    this.currencyCode = 'CNY',
  });

  final List<StatisticsBreakdownSlice> slices;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) return _emptyChartPlaceholder();

    final maxAmount = slices.fold<int>(
      0,
      (max, slice) => math.max(max, slice.amountCents),
    );

    return ListView.separated(
      itemCount: slices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final slice = slices[index];
        final ratio = maxAmount > 0 ? slice.amountCents / maxAmount : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: slice.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slice.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Text(
                  MoneyUtils.format(slice.amountCents, currencyCode: currencyCode),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: slice.color,
                      ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${slice.percentage.toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = math.max(
                  ratio * constraints.maxWidth,
                  slice.amountCents > 0 ? 6.0 : 0.0,
                );
                return Stack(
                  children: [
                    Container(
                      height: 10,
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: AppColors.divider.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Container(
                      height: 10,
                      width: barWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(
                          colors: [
                            slice.color.withValues(alpha: 0.75),
                            slice.color,
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// 雷达图：多色描边 + 半透明填充
class StatisticsRadarChart extends StatelessWidget {
  const StatisticsRadarChart({
    super.key,
    required this.slices,
  });

  final List<StatisticsBreakdownSlice> slices;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) return _emptyChartPlaceholder();

    final top = slices.take(6).toList();
    final maxAmount = top.fold<int>(
      0,
      (max, slice) => math.max(max, slice.amountCents),
    );
    final dataEntries = top
        .map(
          (slice) => RadarEntry(
            value: maxAmount > 0 ? slice.amountCents / maxAmount * 100 : 0,
          ),
        )
        .toList();

    return Column(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1.2,
            child: RadarChart(
              duration: _kInstantChartAnim,
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
                gridBorderData: const BorderSide(color: AppColors.divider, width: 1),
                tickBorderData: const BorderSide(color: AppColors.divider, width: 0.5),
                titleTextStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                titlePositionPercentageOffset: 0.15,
                getTitle: (index, angle) {
                  if (index >= top.length) return RadarChartTitle(text: '');
                  final label = top[index].label;
                  final short = label.length > 6 ? '${label.substring(0, 6)}…' : label;
                  return RadarChartTitle(text: short);
                },
                radarBorderData: const BorderSide(color: AppColors.border, width: 1),
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.primary.withValues(alpha: 0.25),
                    borderColor: AppColors.primary,
                    borderWidth: 2,
                    entryRadius: 3,
                    dataEntries: dataEntries,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final slice in top)
              _LegendItem(color: slice.color, label: slice.label),
          ],
        ),
      ],
    );
  }
}

class StatisticsBubbleTrendChart extends StatelessWidget {
  const StatisticsBubbleTrendChart({
    super.key,
    required this.points,
    required this.seriesLabel,
    this.currencyCode = 'CNY',
  });

  final List<MonthlyTrendPoint> points;
  final String seriesLabel;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final hasData = points.any((p) => p.expenseCents > 0);
    if (!hasData) return _emptyChartPlaceholder();

    final maxYuan = points.fold<double>(
      0,
      (max, p) => math.max(max, p.expenseCents / 100),
    );
    final maxY = _niceMaxY(maxYuan);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LegendItem(color: AppColors.expense, label: seriesLabel),
        const SizedBox(height: 12),
        Expanded(
          child: ScatterChart(
            duration: _kInstantChartAnim,
            ScatterChartData(
              minX: -0.5,
              maxX: 11.5,
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.divider,
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (_) => const FlLine(
                  color: AppColors.divider,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) => Text(
                      _compactAxisLabel(value),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textHint,
                            fontSize: 10,
                          ),
                    ),
                  ),
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
                      return Text(
                        '${points[index].month.month}月',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textHint,
                              fontSize: 10,
                            ),
                      );
                    },
                  ),
                ),
              ),
              scatterSpots: [
                for (var i = 0; i < points.length; i++)
                  if (points[i].expenseCents > 0)
                    ScatterSpot(
                      i.toDouble(),
                      points[i].expenseCents / 100,
                      dotPainter: FlDotCirclePainter(
                        color: AppColors.expense.withValues(alpha: 0.85),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                        radius: math.max(
                          6.0,
                          math.sqrt(points[i].expenseCents / 100) * 2.5,
                        ).clamp(6.0, 24.0),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class StatisticsAssetColumnChart extends StatelessWidget {
  const StatisticsAssetColumnChart({
    super.key,
    required this.points,
    required this.seriesLabel,
    this.currencyCode = 'CNY',
    this.color = AppColors.primary,
  });

  final List<MonthlyValuePoint> points;
  final String seriesLabel;
  final String currencyCode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasData = points.any((p) => p.valueCents > 0);
    if (!hasData) return _emptyChartPlaceholder();

    final maxYuan = points.fold<double>(
      0,
      (max, p) => math.max(max, p.valueCents / 100),
    );
    final maxY = _niceMaxY(maxYuan);
    final interval = maxY / 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LegendItem(color: color, label: seriesLabel),
        const SizedBox(height: 12),
        Expanded(
          child: BarChart(
            duration: _kInstantChartAnim,
            BarChartData(
              maxY: maxY,
              gridData: _defaultGrid(interval),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.textPrimary.withValues(alpha: 0.92),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (groupIndex < 0 || groupIndex >= points.length) return null;
                    return BarTooltipItem(
                      '${points[groupIndex].month.month}月\n${MoneyUtils.format(points[groupIndex].valueCents, currencyCode: currencyCode)}',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    interval: interval,
                    getTitlesWidget: (value, meta) => Text(
                      _compactAxisLabel(value),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textHint,
                            fontSize: 10,
                          ),
                    ),
                  ),
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
                      return Text(
                        '${points[index].month.month}月',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textHint,
                              fontSize: 10,
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
                    barRods: [
                      BarChartRodData(
                        toY: points[i].valueCents / 100,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            color.withValues(alpha: 0.65),
                            color,
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

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
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}

class _RichLegendItem extends StatelessWidget {
  const _RichLegendItem({
    required this.color,
    required this.label,
    required this.amount,
    required this.percentage,
    this.highlighted = false,
  });

  final Color color;
  final String label;
  final String amount;
  final double percentage;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: highlighted ? color : AppColors.textPrimary,
                      ),
                ),
                Text(
                  '$amount · ${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textHint,
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

/// 收支折线/柱状趋势
class StatisticsIncomeExpenseChart extends StatelessWidget {
  const StatisticsIncomeExpenseChart({
    super.key,
    required this.dailyPoints,
    required this.monthlyPoints,
    required this.monthly,
    required this.asBar,
    this.currencyCode = 'CNY',
  });

  final List<DailyTrendPoint> dailyPoints;
  final List<MonthlyTrendPoint> monthlyPoints;
  final bool monthly;
  final bool asBar;
  final String currencyCode;

  static const _expenseColor = AppColors.expense;
  static const _incomeColor = AppColors.income;

  bool get _hasData {
    if (monthly) {
      return monthlyPoints.any(
        (p) => p.expenseCents > 0 || p.incomeCents > 0,
      );
    }
    return dailyPoints.any((p) => p.expenseCents > 0 || p.incomeCents > 0);
  }

  int get _count => monthly ? monthlyPoints.length : dailyPoints.length;

  static const _legendHeight = 32.0;
  static const _defaultChartHeight = 240.0;
  static const _horizontalScrollThreshold = 36;

  @override
  Widget build(BuildContext context) {
    if (!_hasData) return _emptyChartPlaceholder();
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.hasBoundedHeight
            ? math.max(80.0, constraints.maxHeight - _legendHeight)
            : _defaultChartHeight;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                _LegendItem(color: _incomeColor, label: '收入'),
                SizedBox(width: 16),
                _LegendItem(color: _expenseColor, label: '支出'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: chartHeight,
              child: asBar
                  ? _buildBarChart(context, chartHeight)
                  : _buildLineChart(context, chartHeight),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLineChart(BuildContext context, double height) {
    final count = _count;
    final maxY = _maxY;
    final interval = maxY / 4;
    final showDots = count <= 31;

    final chart = LineChart(
            duration: _kInstantChartAnim,
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: _defaultGrid(interval),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) =>
                      AppColors.textPrimary.withValues(alpha: 0.92),
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final index = spot.x.toInt();
                      if (index < 0 || index >= count) return null;
                      final label = _xLabel(index);
                      final cents = spot.barIndex == 0
                          ? _incomeCentsAt(index)
                          : _expenseCentsAt(index);
                      final type = spot.barIndex == 0 ? '收入' : '支出';
                      return LineTooltipItem(
                        '$label\n$type ${MoneyUtils.format(cents, currencyCode: currencyCode)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
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
                    reservedSize: 52,
                    interval: interval,
                    getTitlesWidget: (value, meta) => Text(
                      _compactAxisLabel(value),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textHint,
                            fontSize: 10,
                          ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: math.max(1, count / 6).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= count) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        _xLabel(index),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textHint,
                              fontSize: 10,
                            ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < count; i++)
                      FlSpot(i.toDouble(), _incomeCentsAt(i) / 100),
                  ],
                  isCurved: count > 3,
                  curveSmoothness: 0.22,
                  color: _incomeColor,
                  barWidth: 2.5,
                  dotData: FlDotData(show: showDots, getDotPainter: (_, __, ___, ____) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: _incomeColor,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    );
                  }),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _incomeColor.withValues(alpha: 0.18),
                        _incomeColor.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < count; i++)
                      FlSpot(i.toDouble(), _expenseCentsAt(i) / 100),
                  ],
                  isCurved: count > 3,
                  curveSmoothness: 0.22,
                  color: _expenseColor,
                  barWidth: 2.5,
                  dotData: FlDotData(show: showDots, getDotPainter: (_, __, ___, ____) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: _expenseColor,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    );
                  }),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _expenseColor.withValues(alpha: 0.14),
                        _expenseColor.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );

    return _wrapTrendChart(
      height: height,
      pointCount: count,
      barWidth: monthly ? 12.0 : 5.0,
      groupsSpace: monthly ? 8.0 : 2.0,
      child: chart,
    );
  }

  Widget _buildBarChart(BuildContext context, double height) {
    final count = _count;
    final maxY = _maxY;
    final interval = maxY / 4;
    final barWidth = monthly ? 12.0 : 5.0;

    final chart = BarChart(
            duration: _kInstantChartAnim,
            BarChartData(
              maxY: maxY,
              gridData: _defaultGrid(interval),
              borderData: FlBorderData(show: false),
              groupsSpace: monthly ? 8 : 2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) =>
                      AppColors.textPrimary.withValues(alpha: 0.92),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (groupIndex < 0 || groupIndex >= count) return null;
                    final isIncome = rodIndex == 0;
                    final cents = isIncome
                        ? _incomeCentsAt(groupIndex)
                        : _expenseCentsAt(groupIndex);
                    if (cents <= 0) return null;
                    return BarTooltipItem(
                      '${_xLabel(groupIndex)}\n${isIncome ? '收入' : '支出'} ${MoneyUtils.format(cents, currencyCode: currencyCode)}',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
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
                    reservedSize: 52,
                    interval: interval,
                    getTitlesWidget: (value, meta) => Text(
                      _compactAxisLabel(value),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textHint,
                            fontSize: 10,
                          ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: math.max(1, count / 6).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= count) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        _xLabel(index),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textHint,
                              fontSize: 10,
                            ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < count; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY: _incomeCentsAt(i) / 100,
                        width: barWidth,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            _incomeColor.withValues(alpha: 0.7),
                            _incomeColor,
                          ],
                        ),
                      ),
                      BarChartRodData(
                        toY: _expenseCentsAt(i) / 100,
                        width: barWidth,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            _expenseColor.withValues(alpha: 0.7),
                            _expenseColor,
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );

    return _wrapTrendChart(
      height: height,
      pointCount: count,
      barWidth: barWidth,
      groupsSpace: monthly ? 8.0 : 2.0,
      child: chart,
    );
  }

  Widget _wrapTrendChart({
    required double height,
    required int pointCount,
    required double barWidth,
    required double groupsSpace,
    required Widget child,
  }) {
    if (pointCount <= _horizontalScrollThreshold) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: child,
      );
    }

    final slotWidth = barWidth * 2 + groupsSpace + 6;
    final scrollWidth = math.max(pointCount * slotWidth, 480.0);

    return SizedBox(
      height: height,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: scrollWidth,
            height: height,
            child: child,
          ),
        ),
      ),
    );
  }

  String _xLabel(int index) {
    if (monthly) return '${monthlyPoints[index].month.month}月';
    return '${dailyPoints[index].date.month}/${dailyPoints[index].date.day}';
  }

  int _incomeCentsAt(int index) {
    return monthly
        ? monthlyPoints[index].incomeCents
        : dailyPoints[index].incomeCents;
  }

  int _expenseCentsAt(int index) {
    return monthly
        ? monthlyPoints[index].expenseCents
        : dailyPoints[index].expenseCents;
  }

  double get _maxY {
    double max = 0;
    if (monthly) {
      for (final p in monthlyPoints) {
        max = math.max(max, p.expenseCents / 100);
        max = math.max(max, p.incomeCents / 100);
      }
    } else {
      for (final p in dailyPoints) {
        max = math.max(max, p.expenseCents / 100);
        max = math.max(max, p.incomeCents / 100);
      }
    }
    return _niceMaxY(max);
  }
}

List<T> sortBreakdown<T>({
  required List<T> items,
  required StatisticsSortOrder order,
  required int Function(T) amountOf,
  required String Function(T) nameOf,
  required int Function(T) sortOrderOf,
}) {
  final sorted = List<T>.from(items);
  switch (order) {
    case StatisticsSortOrder.amount:
      sorted.sort((a, b) => amountOf(b).compareTo(amountOf(a)));
    case StatisticsSortOrder.name:
      sorted.sort((a, b) => nameOf(a).compareTo(nameOf(b)));
    case StatisticsSortOrder.displayOrder:
      sorted.sort((a, b) {
        final orderCompare = sortOrderOf(a).compareTo(sortOrderOf(b));
        if (orderCompare != 0) return orderCompare;
        return nameOf(a).compareTo(nameOf(b));
      });
  }
  return sorted;
}
