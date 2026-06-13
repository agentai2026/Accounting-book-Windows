import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/budget.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/loan_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';

Future<bool?> showBudgetFormDialog(BuildContext context, {Budget? budget}) {
  return showGlassDialog<bool>(
    context: context,
    builder: (context) => BudgetFormDialog(budget: budget),
  );
}

class BudgetFormDialog extends ConsumerStatefulWidget {
  const BudgetFormDialog({super.key, this.budget});
  final Budget? budget;

  @override
  ConsumerState<BudgetFormDialog> createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends ConsumerState<BudgetFormDialog> {
  late final TextEditingController _amountController;
  late BudgetPeriodType _periodType;
  int? _categoryId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.budget == null
          ? ''
          : (widget.budget!.amount / 100).toStringAsFixed(2),
    );
    _periodType = widget.budget?.periodType ?? BudgetPeriodType.monthly;
    _categoryId = widget.budget?.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bookId = ref.read(activeBookIdProvider);
    if (bookId == null) return;
    setState(() => _submitting = true);
    final service = await ref.read(budgetServiceProvider.future);
    final amount = MoneyUtils.parseToCents(_amountController.text);
    final result = widget.budget == null
        ? await service.createBudget(
            bookId: bookId,
            amountCents: amount,
            periodType: _periodType,
            categoryId: _categoryId,
          )
        : await service.updateBudget(
            budget: widget.budget!,
            amountCents: amount,
            periodType: _periodType,
            categoryId: _categoryId,
          );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (_) {
        refreshBudgets(ref);
        Navigator.pop(context, true);
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider(CategoryType.expense));

    return GlassAlertDialog(
      title: Text(widget.budget == null ? '添加预算' : '编辑预算'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: '预算金额（元）',
              controller: _amountController,
              hint: '请输入金额',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            AppSelectField<BudgetPeriodType>(
              label: '周期',
              value: _periodType,
              options: [
                for (final t in BudgetPeriodType.values)
                  AppSelectOption(
                    value: t,
                    label: budgetPeriodLabel(t),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _periodType = v);
              },
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (categories) => AppSelectField<int?>(
                label: '分类（可选）',
                value: _categoryId,
                options: [
                  const AppSelectOption(value: null, label: '总预算'),
                  for (final c in categories)
                    if (c.id != null)
                      AppSelectOption(value: c.id, label: c.name),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(widget.budget == null ? '添加' : '保存'),
        ),
      ],
    );
  }
}
