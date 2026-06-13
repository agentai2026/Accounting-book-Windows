import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/loan.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/loan_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/empty_state.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/forms/loan_form_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/layout/content_panel.dart';

class LoansPage extends ConsumerStatefulWidget {
  const LoansPage({super.key});

  @override
  ConsumerState<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends ConsumerState<LoansPage> {
  LoanType _tab = LoanType.borrow;

  int _sumAmount(Iterable<Loan> loans) =>
      loans.fold(0, (sum, loan) => sum + loan.amount);

  int _sumUnpaid(Iterable<Loan> loans) => loans
      .where((loan) => !loan.isRepaid)
      .fold(0, (sum, loan) => sum + loan.amount);

  Future<void> _openForm({Loan? loan, LoanType? initialType}) async {
    await showLoanFormDialog(
      context,
      loan: loan,
      initialType: initialType ?? _tab,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode = ref.watch(currencyCodeProvider);
    final loansAsync = ref.watch(loanListProvider);

    return ContentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '借贷管理',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                tooltip: '添加债务',
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: loansAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => const EmptyState(message: '加载借贷记录失败'),
              data: (loans) {
                final borrowLoans =
                    loans.where((l) => l.type == LoanType.borrow).toList();
                final lendLoans =
                    loans.where((l) => l.type == LoanType.lend).toList();
                final filtered =
                    _tab == LoanType.borrow ? borrowLoans : lendLoans;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: '借入',
                            totalAmount: _sumAmount(borrowLoans),
                            unpaidAmount: _sumUnpaid(borrowLoans),
                            currencyCode: currencyCode,
                            accentColor: AppColors.expense,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: '借出',
                            totalAmount: _sumAmount(lendLoans),
                            unpaidAmount: _sumUnpaid(lendLoans),
                            currencyCode: currencyCode,
                            accentColor: AppColors.income,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<LoanType>(
                      segments: LoanType.values
                          .map(
                            (type) => ButtonSegment(
                              value: type,
                              label: Text(loanTypeLabel(type)),
                            ),
                          )
                          .toList(),
                      selected: {_tab},
                      onSelectionChanged: (selection) {
                        setState(() => _tab = selection.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const EmptyState(
                              message: '暂无数据',
                              icon: Icons.inventory_2_outlined,
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) => _LoanTile(
                                loan: filtered[index],
                                currencyCode: currencyCode,
                                onEdit: () =>
                                    _openForm(loan: filtered[index]),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.totalAmount,
    required this.unpaidAmount,
    required this.currencyCode,
    required this.accentColor,
  });

  final String title;
  final int totalAmount;
  final int unpaidAmount;
  final String currencyCode;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeColors.panelFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemeColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '总金额: ${MoneyUtils.format(totalAmount, currencyCode: currencyCode)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppThemeColors.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '待还: ${MoneyUtils.format(unpaidAmount, currencyCode: currencyCode)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppThemeColors.textSecondary(context),
                ),
          ),
        ],
      ),
    );
  }
}

class _LoanTile extends ConsumerWidget {
  const _LoanTile({
    required this.loan,
    required this.currencyCode,
    required this.onEdit,
  });

  final Loan loan;
  final String currencyCode;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color =
        loan.type == LoanType.lend ? AppColors.income : AppColors.expense;

    return Material(
      color: loan.isRepaid
          ? AppThemeColors.panelFill(context).withValues(alpha: 0.65)
          : AppThemeColors.panelFill(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppThemeColors.border(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          loan.person,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppThemeColors.textPrimary(context),
                              ),
                        ),
                        if (loan.isRepaid) ...[
                          const SizedBox(width: 8),
                          Text(
                            '已结清',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppThemeColors.textHint(context)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${DateFormat('yyyy/MM/dd').format(loan.date)}${loan.dueDate != null ? ' · 结束 ${DateFormat('yyyy/MM/dd').format(loan.dueDate!)}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppThemeColors.textSecondary(context),
                          ),
                    ),
                    if (loan.description != null &&
                        loan.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          loan.description!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                MoneyUtils.format(loan.amount, currencyCode: currencyCode),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) async {
                  final service = await ref.read(loanServiceProvider.future);
                  switch (action) {
                    case 'edit':
                      onEdit();
                    case 'toggle':
                      final result = await service.toggleRepaid(loan);
                      if (context.mounted) {
                        result.when(
                          success: (_) => refreshLoans(ref),
                          failure: (e) => ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(e.message))),
                        );
                      }
                    case 'delete':
                      final result = await service.deleteLoan(loan.id!);
                      if (context.mounted) {
                        result.when(
                          success: (_) => refreshLoans(ref),
                          failure: (e) => ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(e.message))),
                        );
                      }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('编辑')),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(loan.isRepaid ? '标记未结清' : '标记已结清'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
