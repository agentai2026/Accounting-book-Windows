import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/loan_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/forms/budget_form_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/charts/budget_ring.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/layout/content_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/empty_state.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(currencyCodeProvider);
    final budgetsAsync = ref.watch(budgetProgressListProvider);

    return ContentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('预算管理', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => showBudgetFormDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加预算'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: budgetsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (_, __) => const EmptyState(message: '加载预算失败'),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    message: '还没有设置预算',
                    icon: Icons.savings_outlined,
                    action: FilledButton(onPressed: () => showBudgetFormDialog(context), child: const Text('添加预算')),
                  );
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.panelBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Center(
                              child: BudgetRing(
                                progress: item.progress,
                                rawProgress: item.rawProgress,
                                label: '已用',
                                spentText: MoneyUtils.format(item.spentCents, currencyCode: currencyCode),
                                budgetText: MoneyUtils.format(item.budget.amount, currencyCode: currencyCode),
                                isOverBudget: item.isOverBudget,
                                size: 108,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => showBudgetFormDialog(context, budget: item.budget),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.expense),
                                onPressed: () => _delete(context, ref, item.budget.id!),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, int id) async {
    final service = await ref.read(budgetServiceProvider.future);
    final result = await service.deleteBudget(id);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        refreshBudgets(ref);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('预算已删除')));
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))),
    );
  }
}
