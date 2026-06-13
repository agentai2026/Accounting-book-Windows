import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/display_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/home/home_dashboard_widgets.dart';

/// 左侧资产摘要：净资产 / 总负债 / 总资产
class AccountAssetSummaryStrip extends StatelessWidget {
  const AccountAssetSummaryStrip({
    super.key,
    required this.summary,
    required this.currencyCode,
    required this.hideAmount,
  });

  final AssetSummary summary;
  final String currencyCode;
  final bool hideAmount;

  @override
  Widget build(BuildContext context) {
    final hidden = hideAmount ? '****' : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccountSummaryLine(
            label: '净资产',
            value: hidden ??
                MoneyUtils.formatSpaced(
                  summary.netAssetsCents,
                  currencyCode: currencyCode,
                ),
            valueColor: summary.netAssetsCents < 0
                ? AppColors.expense
                : AppColors.primary,
          ),
          const SizedBox(height: 10),
          AccountSummaryLine(
            label: '总负债',
            value: hidden ??
                MoneyUtils.formatSpaced(
                  summary.totalLiabilitiesCents,
                  currencyCode: currencyCode,
                ),
            valueColor: AppColors.income,
          ),
          const SizedBox(height: 10),
          AccountSummaryLine(
            label: '总资产',
            value: hidden ??
                MoneyUtils.formatSpaced(
                  summary.totalAssetsCents,
                  currencyCode: currencyCode,
                ),
            valueColor: AppThemeColors.textSecondary(context),
          ),
        ],
      ),
    );
  }
}

class AccountSummaryLine extends StatelessWidget {
  const AccountSummaryLine({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
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
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ),
      ],
    );
  }
}

/// 左侧账户列表项
class AccountSidebarListTile extends StatelessWidget {
  const AccountSidebarListTile({
    super.key,
    required this.account,
    required this.currencyCode,
    required this.selected,
    required this.hideAmount,
    required this.onTap,
  });

  final Account account;
  final String currencyCode;
  final bool selected;
  final bool hideAmount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppThemeColors.selectedBackground(context)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              buildAccountIconWidget(
                account.icon,
                color: selected
                    ? AppColors.primary
                    : AppThemeColors.textHint(context),
                size: 20,
                fallbackType: account.type,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected
                                ? AppColors.primary
                                : AppThemeColors.textPrimary(context),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hideAmount
                          ? '****'
                          : MoneyUtils.format(
                              account.balance,
                              currencyCode: currencyCode,
                            ),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppThemeColors.textHint(context),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 左侧栏：资产摘要 + 账户列表
class AccountSidebarPanel extends StatelessWidget {
  const AccountSidebarPanel({
    super.key,
    required this.accounts,
    required this.summary,
    required this.currencyCode,
    required this.selectedAccountId,
    required this.hideAmount,
    required this.onAccountSelected,
    this.width = 260,
    this.emptyListHint = '暂无账户',
    this.emptyListWidget,
  });

  final List<Account> accounts;
  final AssetSummary summary;
  final String currencyCode;
  final int? selectedAccountId;
  final bool hideAmount;
  final ValueChanged<int> onAccountSelected;
  final double width;
  final String emptyListHint;
  final Widget? emptyListWidget;

  @override
  Widget build(BuildContext context) {
    final sorted = List<Account>.from(accounts)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return SizedBox(
      width: width,
      child: GlassSurface(
        borderRadius: BorderRadius.circular(12),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AccountAssetSummaryStrip(
              summary: summary,
              currencyCode: currencyCode,
              hideAmount: hideAmount,
            ),
            const Divider(height: 1),
            Expanded(
              child: sorted.isEmpty
                  ? (emptyListWidget ??
                      Center(
                        child: Text(
                          emptyListHint,
                          style: TextStyle(
                            color: AppThemeColors.textHint(context),
                          ),
                        ),
                      ))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, index) {
                        final account = sorted[index];
                        return AccountSidebarListTile(
                          account: account,
                          currencyCode: currencyCode,
                          selected: account.id == selectedAccountId,
                          hideAmount: hideAmount,
                          onTap: () {
                            if (account.id != null) {
                              onAccountSelected(account.id!);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 左侧栏账户列表为空时的轻量提示
class AccountSidebarEmptyHint extends StatelessWidget {
  const AccountSidebarEmptyHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 32,
              color: AppColors.textHint.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 10),
            Text(
              '暂无账户',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 账户列表为空时的主区域空状态
class AccountEmptyState extends StatelessWidget {
  const AccountEmptyState({
    super.key,
    required this.onAddDefaults,
    this.onAddManual,
  });

  final VoidCallback onAddDefaults;
  final VoidCallback? onAddManual;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 36,
                color: AppColors.primary.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '还没有账户',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppThemeColors.textPrimary(context),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '可从预设快速添加现金、支付宝、微信等常用账户',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemeColors.textSecondary(context),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddDefaults,
              icon: const Icon(Icons.playlist_add, size: 20),
              label: const Text('添加默认账户'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(168, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
            if (onAddManual != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onAddManual,
                child: const Text('手动添加账户'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 右侧详情区白色卡片容器
class AccountDetailCard extends StatelessWidget {
  const AccountDetailCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

/// 余额行 + 显示/隐藏
class AccountBalanceRow extends StatelessWidget {
  const AccountBalanceRow({
    super.key,
    required this.balanceCents,
    required this.currencyCode,
    required this.hideAmount,
    required this.onToggleVisibility,
  });

  final int balanceCents;
  final String currencyCode;
  final bool hideAmount;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '余额',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemeColors.textSecondary(context),
              ),
        ),
        const SizedBox(width: 12),
        Text(
          hideAmount
              ? '****'
              : MoneyUtils.formatSpaced(balanceCents, currencyCode: currencyCode),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: balanceCents >= 0 ? AppColors.income : AppColors.expense,
              ),
        ),
        IconButton(
          tooltip: hideAmount ? '显示金额' : '隐藏金额',
          onPressed: onToggleVisibility,
          icon: Icon(
            hideAmount
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
