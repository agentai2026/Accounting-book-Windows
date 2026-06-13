import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/scheduled_transaction.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/scheduled_transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/display_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/empty_state.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/ez_branded_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/forms/scheduled_transaction_form_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/layout/content_panel.dart';

class ScheduledTransactionsPage extends ConsumerWidget {
  const ScheduledTransactionsPage({super.key});

  Future<void> _openForm(BuildContext context) async {
    await showScheduledTransactionFormDialog(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(currencyCodeProvider);
    final itemsAsync = ref.watch(scheduledTransactionListProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return ContentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '周期记账',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                tooltip: '添加任务',
                onPressed: () => _openForm(context),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) =>
                  const EmptyState(message: '加载周期记账失败'),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    message:
                        '周期记账建立后，应用运行期间会自动检测到期任务，'
                        '如有到期任务将弹窗询问是否入账',
                    icon: Icons.event_repeat_outlined,
                    action: FilledButton(
                      onPressed: () => _openForm(context),
                      child: const Text('添加任务'),
                    ),
                  );
                }

                final categoryNames = categoriesAsync.maybeWhen(
                  data: (cats) => buildCategoryDisplayNameMap(cats),
                  orElse: () => const <int, String>{},
                );

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _ScheduledTile(
                    item: items[index],
                    currencyCode: currencyCode,
                    categoryName:
                        categoryNames[items[index].categoryId] ?? '未知分类',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduledTile extends ConsumerStatefulWidget {
  const _ScheduledTile({
    required this.item,
    required this.currencyCode,
    required this.categoryName,
  });

  final ScheduledTransaction item;
  final String currencyCode;
  final String categoryName;

  @override
  ConsumerState<_ScheduledTile> createState() => _ScheduledTileState();
}

class _ScheduledTileState extends ConsumerState<_ScheduledTile> {
  bool _showRuns = false;

  ScheduledTransaction get item => widget.item;

  Future<void> _runOnce() async {
    if (item.id == null) return;
    final service = await ref.read(scheduledTransactionServiceProvider.future);
    final result = await service.executeOne(item.id!, force: true);
    if (!mounted) return;
    result.when(
      success: (tx) {
        refreshScheduledTransactions(ref);
        refreshAccounts(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已入账 ${MoneyUtils.format(tx!.amount, currencyCode: widget.currencyCode)}',
            ),
          ),
        );
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      },
    );
  }

  Future<void> _togglePause() async {
    if (item.id == null) return;
    final service = await ref.read(scheduledTransactionServiceProvider.future);
    final result = await service.setPaused(item, !item.isPaused);
    if (!mounted) return;
    result.when(
      success: (_) => refreshScheduledTransactions(ref),
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      },
    );
  }

  Future<void> _delete() async {
    if (item.id == null) return;
    final confirmed = await showEzConfirmDialog(
      context,
      message: '确定删除这条周期记账规则吗？已生成的账单不会删除。',
      confirmLabel: '删除',
    );
    if (!confirmed || !mounted) return;

    final service = await ref.read(scheduledTransactionServiceProvider.future);
    final result = await service.delete(item.id!);
    if (!mounted) return;
    result.when(
      success: (_) => refreshScheduledTransactions(ref),
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      },
    );
  }

  Future<void> _edit() async {
    final changed = await showScheduledTransactionFormDialog(
      context,
      item: item,
    );
    if (changed == true && mounted) {
      refreshScheduledTransactions(ref);
    }
  }

  String _scheduleDetail() {
    final interval = scheduledIntervalLabel(
      frequency: item.frequency,
      intervalCount: item.intervalCount,
    );
    final extras = <String>[];
    if (item.frequency == ScheduledFrequency.weekly &&
        item.weekday != null) {
      extras.add(weekdayLabel(item.weekday!));
    }
    if (item.frequency == ScheduledFrequency.monthly &&
        item.dayOfMonth != null) {
      extras.add('${item.dayOfMonth}日');
    }
    if (extras.isEmpty) return interval;
    return '$interval · ${extras.join(' · ')}';
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = transactionTypeLabel(item.type);
    final nextText = AppDateUtils.formatDate(item.nextRunAt);
    final runCountAsync = item.id == null
        ? const AsyncValue<int>.data(0)
        : ref.watch(scheduledTransactionRunCountProvider(item.id!));
    final runsAsync = _showRuns && item.id != null
        ? ref.watch(scheduledTransactionRunsProvider(item.id!))
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.categoryName} · $typeLabel',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (item.isPaused)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('已暂停', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            MoneyUtils.format(item.amount, currencyCode: widget.currencyCode),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _scheduleDetail(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            '下次 $nextText'
            '${item.lastRunAt != null ? ' · 上次 ${AppDateUtils.formatDate(item.lastRunAt!)}' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
          runCountAsync.when(
            data: (count) => count > 0
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '已入账 $count 笔',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (item.description?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              item.description!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (item.id != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _showRuns = !_showRuns),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showRuns
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showRuns ? '收起执行记录' : '查看执行记录',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showRuns) ...[
              const SizedBox(height: 6),
              _RunsList(
                runsAsync: runsAsync,
                currencyCode: widget.currencyCode,
              ),
            ],
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _edit,
                child: const Text('编辑'),
              ),
              OutlinedButton(
                onPressed: item.isPaused ? null : _runOnce,
                child: const Text('执行一次'),
              ),
              OutlinedButton(
                onPressed: _togglePause,
                child: Text(item.isPaused ? '恢复' : '暂停'),
              ),
              TextButton(
                onPressed: _delete,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RunsList extends StatelessWidget {
  const _RunsList({
    required this.runsAsync,
    required this.currencyCode,
  });

  final AsyncValue<List<Transaction>>? runsAsync;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    if (runsAsync == null) {
      return const SizedBox(
        height: 32,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return runsAsync!.when(
      loading: () => const SizedBox(
        height: 32,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => Text(
        '加载执行记录失败',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textHint,
            ),
      ),
      data: (runs) {
        if (runs.isEmpty) {
          return Text(
            '暂无执行记录',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
          );
        }
        return Column(
          children: [
            for (final tx in runs)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      AppDateUtils.formatDate(tx.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      MoneyUtils.format(tx.amount, currencyCode: currencyCode),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
