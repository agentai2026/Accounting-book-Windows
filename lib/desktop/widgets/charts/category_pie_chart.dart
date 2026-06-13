import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

class CategoryPieChart extends ConsumerStatefulWidget {
  const CategoryPieChart({
    super.key,
    required this.items,
    this.currencyCode = 'CNY',
    this.height = 220,
    this.maxSlices = 6,
  });

  final List<CategoryBreakdownItem> items;
  final String currencyCode;
  final double height;
  final int maxSlices;

  @override
  ConsumerState<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends ConsumerState<CategoryPieChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  static const _palette = [
    AppColors.primary,
    AppColors.expense,
    AppColors.income,
    AppColors.transfer,
    Color(0xFFD4A574),
    Color(0xFF8B7EC8),
    AppColors.textHint,
  ];

  bool get _hasData =>
      widget.items.any((item) => item.amountCents > 0);

  List<_Slice> get _slices {
    if (!_hasData) return [];

    final visible = widget.items.take(widget.maxSlices - 1).toList();
    final otherAmount = widget.items
        .skip(widget.maxSlices - 1)
        .fold<int>(0, (sum, item) => sum + item.amountCents);
    final total =
        widget.items.fold<int>(0, (sum, item) => sum + item.amountCents);

    final slices = <_Slice>[
      for (var i = 0; i < visible.length; i++)
        _Slice(
          label: visible[i].categoryName,
          amountCents: visible[i].amountCents,
          percentage: total > 0 ? visible[i].amountCents / total * 100 : 0,
          color: _palette[i % _palette.length],
        ),
    ];

    if (otherAmount > 0) {
      slices.add(
        _Slice(
          label: '其他',
          amountCents: otherAmount,
          percentage: total > 0 ? otherAmount / total * 100 : 0,
          color: _palette.last,
        ),
      );
    }

    return slices;
  }

  @override
  Widget build(BuildContext context) {
    final rotate = ref.watch(settingsProvider).pieChartRotate;
    if (rotate && !_rotateController.isAnimating) {
      _rotateController.repeat();
    } else if (!rotate && _rotateController.isAnimating) {
      _rotateController.stop();
    }

    if (!_hasData) {
      return SizedBox(
        height: widget.height,
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

    final slices = _slices;

    return SizedBox(
      height: widget.height,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return PieChart(
                  PieChartData(
                    startDegreeOffset: rotate ? _rotateController.value * 360 : 0,
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                sections: [
                  for (final slice in slices)
                    PieChartSectionData(
                      value: slice.amountCents.toDouble(),
                      color: slice.color,
                      radius: 56,
                      title: slice.percentage >= 8
                          ? '${slice.percentage.toStringAsFixed(0)}%'
                          : '',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: slices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final slice = slices[index];
                return _LegendRow(
                  color: slice.color,
                  label: slice.label,
                  amount: MoneyUtils.format(
                    slice.amountCents,
                    currencyCode: widget.currencyCode,
                  ),
                  percentage: slice.percentage,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Slice {
  const _Slice({
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

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.amount,
    required this.percentage,
  });

  final Color color;
  final String label;
  final String amount;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textHint,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class CategoryRankingList extends StatelessWidget {
  const CategoryRankingList({
    super.key,
    required this.items,
    required this.accentColor,
    this.currencyCode = 'CNY',
  });

  final List<CategoryBreakdownItem> items;
  final Color accentColor;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            '暂无分类数据',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ),
      );
    }

    final maxAmount = items.first.amountCents;

    return Column(
      children: [
        for (final item in items.take(8))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      MoneyUtils.format(
                        item.amountCents,
                        currencyCode: currencyCode,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxAmount > 0 ? item.amountCents / maxAmount : 0,
                    minHeight: 6,
                    backgroundColor: AppColors.divider,
                    color: accentColor.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
