import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';

/// 每月起始日（1–28）网格选择
Future<int?> showMonthStartDayPicker({
  required BuildContext context,
  required int currentDay,
}) {
  return showGlassDialog<int>(
    context: context,
    builder: (context) => _MonthStartDayPickerDialog(currentDay: currentDay),
  );
}

class _MonthStartDayPickerDialog extends StatefulWidget {
  const _MonthStartDayPickerDialog({required this.currentDay});

  final int currentDay;

  @override
  State<_MonthStartDayPickerDialog> createState() =>
      _MonthStartDayPickerDialogState();
}

class _MonthStartDayPickerDialogState extends State<_MonthStartDayPickerDialog> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentDay.clamp(1, 28);
  }

  @override
  Widget build(BuildContext context) {
    return GlassAlertDialog(
      title: const Text('每月起始日'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '记账周期从每月几号开始统计（1–28 日）',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.15,
              ),
              itemCount: 28,
              itemBuilder: (context, index) {
                final day = index + 1;
                final selected = day == _selected;
                return Material(
                  color: selected
                      ? AppColors.primary
                      : AppColors.panelBackground,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => setState(() => _selected = day),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border.withValues(alpha: 0.85),
                        ),
                      ),
                      child: Text(
                        day.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
