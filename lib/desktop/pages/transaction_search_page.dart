import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/widgets/search/transaction_search_widgets.dart';

/// 搜索筛选页：左筛选 / 中列表 / 右详情（三栏布局）
class TransactionSearchPage extends ConsumerWidget {
  const TransactionSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: TransactionSearchThreeColumnLayout(),
    );
  }
}
