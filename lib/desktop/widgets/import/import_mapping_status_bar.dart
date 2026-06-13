import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/services/import_column_mapping_config.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/import/import_wizard_shared.dart';

/// 列映射进度（精简横条）
class ImportMappingStatusBar extends StatelessWidget {
  const ImportMappingStatusBar({super.key, required this.mapping});

  final ImportColumnMappingConfig mapping;

  static const _required = [
    ImportColumnField.time,
    ImportColumnField.type,
    ImportColumnField.amount,
  ];

  @override
  Widget build(BuildContext context) {
    final done =
        _required.where((f) => mapping.fieldToColumn.containsKey(f)).length;
    final progress = done / _required.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ImportWizardShared.surfaceDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '必填字段',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '$done / ${_required.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: mapping.hasRequiredMapping
                          ? AppColors.income
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.divider,
              color: mapping.hasRequiredMapping
                  ? AppColors.income
                  : AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < _required.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(
                  child: _RequiredFieldItem(
                    label: _required[i].label,
                    mapped: mapping.fieldToColumn.containsKey(_required[i]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RequiredFieldItem extends StatelessWidget {
  const _RequiredFieldItem({
    required this.label,
    required this.mapped,
  });

  final String label;
  final bool mapped;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          mapped ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 16,
          color: mapped ? AppColors.income : AppColors.textHint,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: mapped ? AppColors.textPrimary : AppColors.textHint,
                  fontWeight: mapped ? FontWeight.w600 : FontWeight.normal,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
