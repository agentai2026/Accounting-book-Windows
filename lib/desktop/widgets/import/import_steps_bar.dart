import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

class ImportWizardStep {
  const ImportWizardStep({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

/// 左侧纵向步骤导航
class ImportStepsRail extends StatelessWidget {
  const ImportStepsRail({
    super.key,
    required this.steps,
    required this.currentStepId,
  });

  final List<ImportWizardStep> steps;
  final String currentStepId;

  @override
  Widget build(BuildContext context) {
    final currentIndex = steps.indexWhere((s) => s.id == currentStepId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
          child: Text(
            '导入交易',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '批量导入账单到默认账本',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                  height: 1.4,
                ),
          ),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return _RailStepTile(
                index: index + 1,
                step: step,
                isActive: index == currentIndex,
                isCompleted: index < currentIndex,
                isLast: index == steps.length - 1,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Row(
            children: [
              Icon(Icons.book_outlined, size: 15, color: AppColors.textHint),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '写入默认账本',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
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

class _RailStepTile extends StatelessWidget {
  const _RailStepTile({
    required this.index,
    required this.step,
    required this.isActive,
    required this.isCompleted,
    required this.isLast,
  });

  final int index;
  final ImportWizardStep step;
  final bool isActive;
  final bool isCompleted;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor = isActive || isCompleted
        ? AppColors.primary
        : AppColors.textHint.withValues(alpha: 0.45);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                _StepDot(
                  index: index,
                  color: dotColor,
                  filled: isCompleted,
                  active: isActive,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isCompleted
                          ? AppColors.primary.withValues(alpha: 0.35)
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.selectedBackground.withValues(alpha: 0.65)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? AppColors.primaryDark
                                : (isCompleted
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.color,
    required this.filled,
    required this.active,
  });

  final int index;
  final Color color;
  final bool filled;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 28 : 24,
      height: active ? 28 : 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.transparent,
        border: Border.all(color: color, width: active ? 2 : 1.5),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: filled
          ? const Icon(Icons.check, size: 13, color: Colors.white)
          : Text(
              '$index',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
    );
  }
}
