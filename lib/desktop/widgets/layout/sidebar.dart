import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ezbookkeeping_desktop/core/constants/app_constants.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/glass_constants.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_brand_icon.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/add_transaction_dialog.dart';

class SidebarNavItem {
  const SidebarNavItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class SidebarNavGroup {
  const SidebarNavGroup({
    required this.title,
    required this.items,
  });

  final String title;
  final List<SidebarNavItem> items;
}

const kSidebarGroups = [
  SidebarNavGroup(
    title: '总览',
    items: [
      SidebarNavItem(
        label: '总览',
        icon: Icons.dashboard_outlined,
        route: '/',
      ),
    ],
  ),
  SidebarNavGroup(
    title: '交易数据',
    items: [
      SidebarNavItem(
        label: '交易详情',
        icon: Icons.receipt_long_outlined,
        route: '/transactions',
      ),
      SidebarNavItem(
        label: '统计分析',
        icon: Icons.pie_chart_outline,
        route: '/statistics',
      ),
      SidebarNavItem(
        label: '搜索筛选',
        icon: Icons.manage_search_outlined,
        route: '/search',
      ),
      SidebarNavItem(
        label: '报销中心',
        icon: Icons.receipt_long_outlined,
        route: '/reimbursements',
      ),
    ],
  ),
  SidebarNavGroup(
    title: '基础数据',
    items: [
      SidebarNavItem(
        label: '账户',
        icon: Icons.account_balance_wallet_outlined,
        route: '/accounts',
      ),
      SidebarNavItem(
        label: '交易分类',
        icon: Icons.category_outlined,
        route: '/categories',
      ),
      SidebarNavItem(
        label: '账本',
        icon: Icons.book_outlined,
        route: '/books',
      ),
      SidebarNavItem(
        label: '预算',
        icon: Icons.savings_outlined,
        route: '/budgets',
      ),
    ],
  ),
  SidebarNavGroup(
    title: '杂项',
    items: [
      SidebarNavItem(
        label: '借贷',
        icon: Icons.handshake_outlined,
        route: '/loans',
      ),
      SidebarNavItem(
        label: '周期记账',
        icon: Icons.event_repeat_outlined,
        route: '/scheduled',
      ),
      SidebarNavItem(
        label: '实时汇率',
        icon: Icons.currency_exchange_outlined,
        route: '/exchange-rates',
      ),
      SidebarNavItem(
        label: '设置',
        icon: Icons.settings_outlined,
        route: '/settings',
      ),
    ],
  ),
];

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return GlassSurface(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      showShadow: false,
      blurSigma: GlassConstants.blurSigma + 4,
      child: SizedBox(
        width: AppConstants.sidebarWidth,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const AppBrandIcon(),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppConstants.appName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppThemeColors.textPrimary(context),
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final group in kSidebarGroups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                    child: Text(
                      group.title,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppThemeColors.textHint(context),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                  for (final item in group.items)
                    _SidebarTile(
                      item: item,
                      isSelected: _isRouteSelected(currentRoute, item.route),
                      onTap: () => context.go(item.route),
                      onQuickAdd: item.route == '/transactions'
                          ? () => showAddTransactionDialog(context)
                          : null,
                    ),
                ],
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  bool _isRouteSelected(String current, String target) {
    if (target == '/') return current == '/';
    if (target == '/transactions') {
      return current.startsWith('/transactions') || current == '/calendar';
    }
    return current.startsWith(target);
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.onQuickAdd,
  });

  final SidebarNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: isSelected
                      ? Colors.white
                      : AppThemeColors.textSecondary(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppThemeColors.textPrimary(context),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                ),
                if (isSelected && onQuickAdd != null)
                  IconButton(
                    onPressed: onQuickAdd,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
