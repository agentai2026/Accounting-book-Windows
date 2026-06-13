import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/services/transaction_import_service.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/tag_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/dialogs/alipay_import_reconcile_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/import/transaction_import_wizard_dialog.dart';

Future<void> showTransactionImportDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final bookId = await resolveImportBookId(ref);
  if (bookId == null) {
    if (context.mounted) {
      _showSnackBar(context, '暂无账本，请先创建账本');
    }
    return;
  }

  if (!context.mounted) return;

  final importResult = await showTransactionImportWizard(context);
  if (importResult == null || !context.mounted) return;

  _refreshAfterImport(ref);

  final message = importResult.skipped > 0
      ? '成功导入 ${importResult.imported} 条，跳过 ${importResult.skipped} 条'
      : '成功导入 ${importResult.imported} 条交易';
  _showSnackBar(context, message);

  if (importResult.alipayOfficialSummary != null) {
    await showAlipayImportReconcileDialog(context, importResult);
  } else if (importResult.skipped > 0) {
    _showImportSkipReport(context, importResult);
  }
}

void _refreshAfterImport(WidgetRef ref) {
  ref.read(transactionRefreshProvider.notifier).state++;
  refreshAccounts(ref);
  refreshCategories(ref);
  refreshBooks(ref);
  refreshTags(ref);
}

void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

void _showImportSkipReport(
  BuildContext context,
  TransactionImportResult importResult,
) {
  final summary = importResult.skipReasons.entries
      .map((entry) => '${entry.key}：${entry.value} 条')
      .join('\n');
  final details = importResult.errors.take(20).join('\n');
  final hasMore = importResult.errors.length > 20;

  showGlassDialog<void>(
    context: context,
    builder: (context) => GlassAlertDialog(
      title: const Text('部分行未能导入'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summary.isNotEmpty) ...[
              Text(
                '跳过原因汇总：',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(summary),
              const SizedBox(height: 16),
            ],
            if (details.isNotEmpty) ...[
              Text(
                '明细：',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(details),
              if (hasMore)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('仅显示前 20 条明细'),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}
