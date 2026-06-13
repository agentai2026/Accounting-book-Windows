import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/constants/transaction_flag_tags.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/core/services/reimbursement_service.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/reimbursement_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/empty_state.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/layout/content_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_detail_dialog.dart';

class ReimbursementsPage extends ConsumerWidget {
  const ReimbursementsPage({super.key});

  Future<void> _markReimbursed(
    BuildContext context,
    WidgetRef ref,
    int transactionId,
  ) async {
    final service = await ref.read(reimbursementServiceProvider.future);
    final result = await service.markReimbursed(transactionId);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        refreshReimbursements(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已标记为已报销')),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  Future<void> _unmarkReimbursed(
    BuildContext context,
    WidgetRef ref,
    int transactionId,
  ) async {
    final service = await ref.read(reimbursementServiceProvider.future);
    final result = await service.unmarkReimbursed(transactionId);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        refreshReimbursements(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已撤销报销状态')),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    TransactionRowData row,
  ) async {
    final changed = await showTransactionDetailDialog(context, row: row);
    if (!context.mounted) return;
    if (changed == true) {
      refreshReimbursementsGlobally(ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(currencyCodeProvider);
    final tab = ref.watch(reimbursementTabProvider);
    final summaryAsync = ref.watch(reimbursementSummaryProvider);
    final listAsync = ref.watch(reimbursementListProvider);

    return ContentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '报销中心',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '管理标记为「可报销」的支出账单，标记已报销后会在账单上添加「${TransactionFlagTags.reimbursed}」标签',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppThemeColors.textSecondary(context),
                ),
          ),
          const SizedBox(height: 16),
          summaryAsync.when(
            loading: () => const SizedBox(
              height: 88,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (error, _) => SizedBox(
              height: 88,
              child: Center(
                child: Text(
                  '汇总加载失败: $error',
                  style: TextStyle(color: AppThemeColors.textSecondary(context)),
                ),
              ),
            ),
            data: (summary) => _SummaryCards(
              currencyCode: currencyCode,
              summary: summary,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<ReimbursementListTab>(
            segments: [
              for (final item in ReimbursementListTab.values)
                ButtonSegment(
                  value: item,
                  label: Text(item.label),
                ),
            ],
            selected: {tab},
            onSelectionChanged: (value) {
              ref.read(reimbursementTabProvider.notifier).state = value.first;
              ref.invalidate(reimbursementListProvider);
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => const EmptyState(message: '加载报销账单失败'),
              data: (bundle) {
                final rows = bundle.rows;
                if (rows.isEmpty) {
                  return EmptyState(
                    message: switch (tab) {
                      ReimbursementListTab.pending => '暂无待报销账单\n记一笔时可开启「报销」开关',
                      ReimbursementListTab.reimbursed => '暂无已报销记录',
                      ReimbursementListTab.all => '暂无可报销账单',
                    },
                    icon: Icons.receipt_long_outlined,
                  );
                }

                return ListView.separated(
                  itemCount: rows.length + (bundle.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index >= rows.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: bundle.isLoadingMore
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : TextButton.icon(
                                  onPressed: () => ref
                                      .read(reimbursementListProvider.notifier)
                                      .loadMore(),
                                  icon: const Icon(Icons.expand_more),
                                  label: const Text('加载更多'),
                                ),
                        ),
                      );
                    }

                    final row = rows[index];
                    final reimbursed = isTransactionReimbursed(row);
                    final tx = row.transaction;
                    final title = (tx.description?.trim().isNotEmpty == true)
                        ? tx.description!.trim()
                        : row.categoryName;

                    return GlassSurface(
                      borderRadius: BorderRadius.circular(14),
                      showShadow: false,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openDetail(context, ref, row),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _StatusChip(reimbursed: reimbursed),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${row.categoryName} · ${row.accountName}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppThemeColors.textHint(
                                              context,
                                            ),
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppDateUtils.formatDate(tx.date),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppThemeColors.textHint(
                                              context,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                row.amountText,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppColors.expense,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              if (tx.id != null)
                                reimbursed
                                    ? IconButton(
                                        tooltip: '撤销已报销',
                                        onPressed: () => _unmarkReimbursed(
                                          context,
                                          ref,
                                          tx.id!,
                                        ),
                                        icon: const Icon(
                                          Icons.undo_outlined,
                                          size: 20,
                                        ),
                                      )
                                    : IconButton(
                                        tooltip: '标记已报销',
                                        onPressed: () => _markReimbursed(
                                          context,
                                          ref,
                                          tx.id!,
                                        ),
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                          size: 20,
                                          color: AppColors.income,
                                        ),
                                      ),
                            ],
                          ),
                        ),
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
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.currencyCode,
    required this.summary,
  });

  final String currencyCode;
  final ReimbursementSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: '待报销',
            amount: MoneyUtils.format(
              summary.pendingCents,
              currencyCode: currencyCode,
            ),
            subtitle: '${summary.pendingCount} 笔',
            color: const Color(0xFF7B61FF),
            icon: Icons.pending_actions_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '已报销',
            amount: MoneyUtils.format(
              summary.reimbursedCents,
              currencyCode: currencyCode,
            ),
            subtitle: '${summary.reimbursedCount} 笔',
            color: AppColors.income,
            icon: Icons.task_alt_outlined,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String amount;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(14),
      showShadow: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemeColors.textSecondary(context),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    amount,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemeColors.textHint(context),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.reimbursed});

  final bool reimbursed;

  @override
  Widget build(BuildContext context) {
    final color = reimbursed ? AppColors.income : const Color(0xFF7B61FF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        reimbursed ? '已报销' : '待报销',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
