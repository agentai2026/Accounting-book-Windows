import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

class BudgetRing extends StatelessWidget {
  const BudgetRing({
    super.key,
    required this.progress,
    required this.label,
    required this.spentText,
    required this.budgetText,
    this.size = 120,
    this.isOverBudget = false,
    this.rawProgress,
  });

  /// 0~1，用于绘制环形进度
  final double progress;

  /// 未截断的实际进度，如 2.64 表示 264%
  final double? rawProgress;

  final String label;
  final String spentText;
  final String budgetText;
  final double size;
  final bool isOverBudget;

  double get _actualProgress => rawProgress ?? progress;

  String get _centerPercentText {
    final percent = (_actualProgress * 100).clamp(0, 999);
    if (percent >= 100 && isOverBudget) {
      return '${percent.toStringAsFixed(0)}%';
    }
    return '${percent.toStringAsFixed(0)}%';
  }

  String get _centerLabelText {
    if (isOverBudget) return '已超支';
    if (label.isNotEmpty && label.length <= 4) return label;
    return '已用';
  }

  @override
  Widget build(BuildContext context) {
    final color = isOverBudget ? AppColors.expense : AppColors.primary;
    final ringProgress = progress.clamp(0.0, 1.0);
    final strokeWidth = size >= 110 ? 9.0 : 7.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _BudgetRingPainter(
              progress: ringProgress,
              color: color,
              trackColor: AppColors.divider,
              strokeWidth: strokeWidth,
              isOverBudget: isOverBudget,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(strokeWidth + 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _centerPercentText,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                              height: 1.1,
                            ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _centerLabelText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.1,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            spentText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isOverBudget ? AppColors.expense : AppColors.textPrimary,
                ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '预算 $budgetText',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}

class _BudgetRingPainter extends CustomPainter {
  const _BudgetRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.isOverBudget,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final bool isOverBudget;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );

    if (isOverBudget && progress >= 1) {
      final markerPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.55;
      canvas.drawCircle(center, radius - strokeWidth * 0.35, markerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.isOverBudget != isOverBudget;
  }
}
