import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/display_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/forms/account_form_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/account/account_list_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/layout/content_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/forms/default_accounts_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/home/home_dashboard_widgets.dart';

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  int? _selectedAccountId;
  bool _hideAmount = false;

  int? _resolveSelectedId(List<Account> accounts) {
    if (accounts.isEmpty) return null;
    if (_selectedAccountId != null &&
        accounts.any((a) => a.id == _selectedAccountId)) {
      return _selectedAccountId;
    }
    return accounts.first.id;
  }

  Account? _selectedAccount(List<Account> accounts) {
    final id = _resolveSelectedId(accounts);
    if (id == null) return null;
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode = ref.watch(currencyCodeProvider);
    final accountsAsync = ref.watch(accountListProvider);

    return ContentPanel(
      child: accountsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => Center(
          child: Text(
            '加载账户失败',
            style: TextStyle(color: AppThemeColors.textHint(context)),
          ),
        ),
        data: (accounts) {
          final summary = AssetSummary.fromAccounts(accounts);
          final selected = _selectedAccount(accounts);
          final selectedId = _resolveSelectedId(accounts);
          final isEmpty = accounts.isEmpty;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountSidebarPanel(
                accounts: accounts,
                summary: summary,
                currencyCode: currencyCode,
                selectedAccountId: selectedId,
                hideAmount: _hideAmount,
                onAccountSelected: (id) {
                  setState(() => _selectedAccountId = id);
                },
                emptyListWidget:
                    isEmpty ? const AccountSidebarEmptyHint() : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AccountDetailCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DetailHeader(
                        onAdd: () => _openForm(context),
                        onRefresh: () => refreshAccounts(ref),
                        onRecalculateBalances: () =>
                            _recalculateBalances(context, ref),
                        onEdit: selected == null
                            ? null
                            : () => _openForm(context, account: selected),
                        onDelete: selected == null
                            ? null
                            : () => _confirmDelete(context, ref, selected),
                      ),
                      const SizedBox(height: 20),
                      if (selected == null)
                        Expanded(
                          child: isEmpty
                              ? AccountEmptyState(
                                  onAddDefaults: () =>
                                      _openDefaultAccounts(context),
                                  onAddManual: () => _openForm(context),
                                )
                              : Center(
                                  child: Text(
                                    '没有可用的账户',
                                    style: TextStyle(
                                      color: AppThemeColors.textHint(context),
                                    ),
                                  ),
                                ),
                        )
                      else
                        Expanded(
                          child: _AccountDetailBody(
                            account: selected,
                            currencyCode: currencyCode,
                            hideAmount: _hideAmount,
                            onToggleVisibility: () {
                              setState(() => _hideAmount = !_hideAmount);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _recalculateBalances(BuildContext context, WidgetRef ref) async {
    final bookId = ref.read(activeBookIdProvider);
    if (bookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未找到账本')),
      );
      return;
    }

    final confirmed = await showGlassDialog<bool>(
      context: context,
      builder: (context) => GlassAlertDialog(
        title: const Text('修复账户余额'),
        content: const Text(
          '将根据导入元数据、付款方式（payer）或备注中的支付关键词，'
          '修正历史账单错挂的账户，再按全部账单重算各账户余额。'
          '适用于早期导入、无 @src 元数据的账单。是否继续？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('修复并重算'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final service = await ref.read(bookkeepingServiceProvider.future);
    final result =
        await service.repairAndRecalculateAccountBalances(bookId: bookId);

    if (!context.mounted) return;

    result.when(
      success: (data) {
        refreshAccounts(ref);
        ref.read(transactionRefreshProvider.notifier).state++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已修正 ${data.repaired} 笔账单账户归属，'
              '并重算 ${data.accountCount} 个账户余额',
            ),
          ),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  Future<void> _openForm(BuildContext context, {Account? account}) async {
    final saved = await showAccountFormDialog(context, account: account);
    if (saved == true && mounted) {
      refreshAccounts(ref);
    }
  }

  Future<void> _openDefaultAccounts(BuildContext context) async {
    final accounts = ref.read(accountListProvider).valueOrNull ?? [];
    final existingNames = accounts.map((a) => a.name).toSet();
    final saved = await showDefaultAccountsDialog(
      context,
      existingNames: existingNames,
    );
    if (saved && mounted) {
      refreshAccounts(ref);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final confirmed = await showGlassDialog<bool>(
      context: context,
      builder: (context) => GlassAlertDialog(
        title: const Text('删除账户'),
        content: Text('确定删除账户「${account.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final service = await ref.read(accountServiceProvider.future);
    final result = await service.deleteAccount(account.id!);

    if (!context.mounted) return;

    result.when(
      success: (_) {
        setState(() {
          if (_selectedAccountId == account.id) {
            _selectedAccountId = null;
          }
        });
        refreshAccounts(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('账户已删除')),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.onAdd,
    required this.onRefresh,
    required this.onRecalculateBalances,
    this.onEdit,
    this.onDelete,
  });

  final VoidCallback onAdd;
  final VoidCallback onRefresh;
  final VoidCallback onRecalculateBalances;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '账户列表',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 16),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('添加'),
        ),
        IconButton(
          tooltip: '刷新',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 20),
          color: AppColors.textSecondary,
        ),
        const Spacer(),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          onSelected: (value) {
            switch (value) {
              case 'recalculate':
                onRecalculateBalances();
              case 'edit':
                onEdit?.call();
              case 'delete':
                onDelete?.call();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'recalculate',
              child: Row(
                children: [
                  Icon(Icons.calculate_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('修复账户余额'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              enabled: onEdit != null,
              child: const Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('编辑账户'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              enabled: onDelete != null,
              child: const Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: AppColors.expense),
                  SizedBox(width: 8),
                  Text('删除账户', style: TextStyle(color: AppColors.expense)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountDetailBody extends StatelessWidget {
  const _AccountDetailBody({
    required this.account,
    required this.currencyCode,
    required this.hideAmount,
    required this.onToggleVisibility,
  });

  final Account account;
  final String currencyCode;
  final bool hideAmount;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: buildAccountIconWidget(
                  account.icon,
                  color: AppColors.primary,
                  size: 24,
                  fallbackType: account.type,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (account.type != AccountType.none)
                    Text(
                      accountTypeLabel(account.type),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AccountBalanceRow(
          balanceCents: account.balance,
          currencyCode: currencyCode,
          hideAmount: hideAmount,
          onToggleVisibility: onToggleVisibility,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _InfoTile(
                  label: '币种',
                  value: account.currency,
                ),
                _InfoTile(
                  label: '账户类型',
                  value: accountTypeLabel(account.type),
                ),
                _InfoTile(
                  label: '排序',
                  value: '${account.sortOrder}',
                ),
                _InfoTile(
                  label: '创建时间',
                  value: AppDateUtils.formatDateTime(account.createdAt),
                ),
                _InfoTile(
                  label: '更新时间',
                  value: AppDateUtils.formatDateTime(account.updatedAt),
                ),
                const SizedBox(height: 8),
                Text(
                  '余额随记账自动更新，如需调整期初余额请使用「编辑账户」',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppThemeColors.fieldFill(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemeColors.border(context)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemeColors.textSecondary(context),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemeColors.textPrimary(context),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
