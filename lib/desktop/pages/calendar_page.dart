import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/pages/transaction_list_page.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';

/// 保留 /calendar 路由，实际展示交易详情页的日历视图。
class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const TransactionListPage(
      initialView: TransactionDetailView.calendar,
    );
  }
}
