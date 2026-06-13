import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ezbookkeeping_desktop/desktop/pages/accounts_page.dart';
import 'package:ezbookkeeping_desktop/desktop/pages/add_transaction_page.dart';
import 'package:ezbookkeeping_desktop/desktop/pages/books_page.dart';
import 'package:ezbookkeeping_desktop/desktop/pages/budgets_page.dart';
import 'package:ezbookkeeping_desktop/desktop/pages/calendar_page.dart';
import 'package:ezbookkeeping_desktop/desktop/pages/categories_page.dart';
import 'package:ezbookkeeping_desktop/desktop/pages/exchange_rates_page.dart';
import 'package:ezbookkeeping_desktop/desktop/pages/home_page.dart';
import 'package:ezbookkeeping_desktop/desktop/pages/loans_page.dart';
import 'package:ezbookkeeping_desktop/desktop/pages/reimbursements_page.dart';
import 'package:ezbookkeeping_desktop/desktop/pages/scheduled_transactions_page.dart';
import 'package:ezbookkeeping_desktop/desktop/pages/settings_page.dart';
import 'package:ezbookkeeping_desktop/desktop/pages/statistics_page.dart';
import 'package:ezbookkeeping_desktop/desktop/pages/transaction_search_page.dart';
import 'package:ezbookkeeping_desktop/desktop/pages/transaction_list_page.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/layout/app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionListPage(),
          ),
          GoRoute(
            path: '/add',
            name: 'add',
            builder: (context, state) => const AddTransactionPage(),
          ),
          GoRoute(
            path: '/calendar',
            name: 'calendar',
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: '/statistics',
            name: 'statistics',
            builder: (context, state) => const StatisticsPage(),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const TransactionSearchPage(),
          ),
          GoRoute(
            path: '/reimbursements',
            name: 'reimbursements',
            builder: (context, state) => const ReimbursementsPage(),
          ),
          GoRoute(
            path: '/accounts',
            name: 'accounts',
            builder: (context, state) => const AccountsPage(),
          ),
          GoRoute(
            path: '/books',
            name: 'books',
            builder: (context, state) => const BooksPage(),
          ),
          GoRoute(
            path: '/categories',
            name: 'categories',
            builder: (context, state) => const CategoriesPage(),
          ),
          GoRoute(
            path: '/budgets',
            name: 'budgets',
            builder: (context, state) => const BudgetsPage(),
          ),
          GoRoute(
            path: '/loans',
            name: 'loans',
            builder: (context, state) => const LoansPage(),
          ),
          GoRoute(
            path: '/scheduled',
            name: 'scheduled',
            builder: (context, state) => const ScheduledTransactionsPage(),
          ),
          GoRoute(
            path: '/exchange-rates',
            name: 'exchange-rates',
            builder: (context, state) => const ExchangeRatesPage(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});
