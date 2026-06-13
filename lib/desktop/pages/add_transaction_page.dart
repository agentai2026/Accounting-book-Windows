import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/add_transaction_dialog.dart';

/// 页面入口：打开添加交易对话框
class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openDialog());
  }

  Future<void> _openDialog() async {
    if (!mounted) return;
    await showAddTransactionDialog(context);
    if (mounted && context.canPop()) {
      context.pop();
    } else if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '正在打开记账窗口...',
        style: TextStyle(color: AppColors.textHint),
      ),
    );
  }
}

/// 从任意页面快捷打开记账对话框
Future<void> openAddTransaction(
  BuildContext context, {
  TransactionType type = TransactionType.expense,
}) {
  return showAddTransactionDialog(context, initialType: type);
}
