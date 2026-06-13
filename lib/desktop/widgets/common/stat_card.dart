import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PeriodStatCard extends StatelessWidget {
  const PeriodStatCard({
    super.key,
    required this.title,
    required this.expense,
    required this.income,
    required this.periodLabel,
  });

  final String title;
  final String expense;
  final String income;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const Spacer(),
                Icon(
                  Icons.more_horiz,
                  size: 18,
                  color: AppColors.textHint,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              expense,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.expense,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              income,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.income,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              periodLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
