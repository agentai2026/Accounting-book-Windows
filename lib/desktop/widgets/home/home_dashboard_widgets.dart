import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_card.dart';

class AssetSummary {
  const AssetSummary({
    required this.totalAssetsCents,
    required this.totalLiabilitiesCents,
    required this.netAssetsCents,
    required this.accountCount,
  });

  final int totalAssetsCents;
  final int totalLiabilitiesCents;
  final int netAssetsCents;
  final int accountCount;

  static AssetSummary fromAccounts(List<Account> accounts) {
    var liabilities = 0;
    var assets = 0;

    for (final account in accounts) {
      final balance = account.balance;
      if (balance == 0) continue;

      if (account.type == AccountType.creditCard) {
        if (balance > 0) {
          liabilities += balance;
        } else {
          liabilities += balance.abs();
        }
        continue;
      }

      if (balance < 0) {
        liabilities += balance.abs();
      } else {
        assets += balance;
      }
    }

    return AssetSummary(
      totalAssetsCents: assets,
      totalLiabilitiesCents: liabilities,
      netAssetsCents: assets - liabilities,
      accountCount: accounts.length,
    );
  }
}

/// 顶部左侧：当月支出摘要卡片
class MonthlyExpenseSummaryCard extends StatelessWidget {
  const MonthlyExpenseSummaryCard({
    super.key,
    required this.monthTitle,
    required this.expenseText,
    required this.incomeText,
    required this.hideAmount,
    required this.onToggleVisibility,
    required this.onRefresh,
    required this.onViewDetails,
  });

  final String monthTitle;
  final String expenseText;
  final String incomeText;
  final bool hideAmount;
  final VoidCallback onToggleVisibility;
  final VoidCallback onRefresh;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      monthTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppThemeColors.textSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onRefresh,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.refresh,
                          size: 18,
                          color: AppThemeColors.textHint(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      hideAmount ? '****' : expenseText,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onToggleVisibility,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          hideAmount
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppThemeColors.textHint(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '当月收入 $incomeText',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemeColors.textSecondary(context),
                      ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onViewDetails,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('查看详情'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 110,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                Positioned(
                  right: 8,
                  bottom: 20,
                  child: Icon(
                    Icons.edit_outlined,
                    size: 52,
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 顶部右侧：资产概要卡片
class AssetOverviewCard extends StatelessWidget {
  const AssetOverviewCard({
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

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '资产概要',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppThemeColors.textPrimary(context),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '您已经记录了 ${summary.accountCount} 个账户',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppThemeColors.textSecondary(context),
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _AssetMetric(
                  label: '总资产',
                  value: hidden ??
                      MoneyUtils.formatSpaced(
                        summary.totalAssetsCents,
                        currencyCode: currencyCode,
                      ),
                  icon: Icons.account_balance_outlined,
                  iconColor: AppThemeColors.textHint(context),
                ),
              ),
              Expanded(
                child: _AssetMetric(
                  label: '总负债',
                  value: hidden ??
                      MoneyUtils.formatSpaced(
                        summary.totalLiabilitiesCents,
                        currencyCode: currencyCode,
                      ),
                  icon: Icons.credit_card_outlined,
                  iconColor: AppColors.income,
                ),
              ),
              Expanded(
                child: _AssetMetric(
                  label: '净资产',
                  value: hidden ??
                      MoneyUtils.formatSpaced(
                        summary.netAssetsCents,
                        currencyCode: currencyCode,
                      ),
                  icon: Icons.savings_outlined,
                  iconColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssetMetric extends StatelessWidget {
  const _AssetMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppThemeColors.textSecondary(context),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppThemeColors.textPrimary(context),
              ),
        ),
        const SizedBox(height: 12),
        Icon(icon, color: iconColor, size: 28),
      ],
    );
  }
}

/// 左下 2x2 周期统计卡片
class HomePeriodCard extends StatelessWidget {
  const HomePeriodCard({
    super.key,
    required this.title,
    required this.incomeText,
    required this.expenseText,
    required this.periodLabel,
    required this.iconLetter,
    this.icon = Icons.calendar_today_outlined,
    this.onTap,
  });

  final String title;
  final String incomeText;
  final String expenseText;
  final String periodLabel;
  final String iconLetter;
  final IconData icon;
  final VoidCallback? onTap;

  static const _incomeColor = Color(0xFFC04848);
  static const _expenseColor = Color(0xFF1B8C7E);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PeriodIconBadge(letter: iconLetter, icon: icon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppThemeColors.textPrimary(context),
                          ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppThemeColors.textHint(context),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                incomeText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _incomeColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                expenseText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _expenseColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                periodLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppThemeColors.textHint(context),
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodIconBadge extends StatelessWidget {
  const _PeriodIconBadge({
    required this.letter,
    required this.icon,
  });

  final String letter;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 22, color: AppColors.primary.withValues(alpha: 0.55)),
          Positioned(
            bottom: 4,
            child: Text(
              letter,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

