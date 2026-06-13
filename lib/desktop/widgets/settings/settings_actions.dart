import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/services/backup_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_reload.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_page_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/tag_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/services/backup_prompt_service.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/settings/backup_password_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/dialogs/transaction_import_dialog.dart';

/// 设置页共享异步操作
class SettingsActions {
  SettingsActions(this.ref, this.context);

  final WidgetRef ref;
  final BuildContext context;

  Future<void> _run(Future<void> Function() action) async {
    ref.read(settingsBusyProvider.notifier).state = true;
    try {
      await action();
    } finally {
      ref.read(settingsBusyProvider.notifier).state = false;
    }
  }

  void showResult(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> confirm({
    required String title,
    required String content,
    String confirmLabel = '确定',
    bool destructive = false,
  }) async {
    final result = await showGlassDialog<bool>(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: AppColors.expense)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> exportCsv() => _run(() async {
        final bookId = ref.read(activeBookIdProvider);
        if (bookId == null) return;
        final dir = await FilePicker.platform.getDirectoryPath(
          dialogTitle: '选择导出目录',
        );
        if (dir == null) return;

        final service = await ref.read(exportServiceProvider.future);
        final currency = ref.read(currencyCodeProvider);
        final fileName = service.suggestExportFileName('csv');
        final result = await service.exportTransactionsCsv(
          bookId: bookId,
          savePath: service.joinExportPath(dir, fileName),
          currencyCode: currency,
        );
        if (!context.mounted) return;
        showResult(result.when(
          success: (p) => 'CSV 已导出至 $p',
          failure: (e) => e.message,
        ));
      });

  Future<void> exportExcel() => _run(() async {
        final bookId = ref.read(activeBookIdProvider);
        if (bookId == null) return;
        final dir = await FilePicker.platform.getDirectoryPath(
          dialogTitle: '选择导出目录',
        );
        if (dir == null) return;

        final service = await ref.read(exportServiceProvider.future);
        final currency = ref.read(currencyCodeProvider);
        final fileName = service.suggestExportFileName('xlsx');
        final result = await service.exportTransactionsExcel(
          bookId: bookId,
          savePath: service.joinExportPath(dir, fileName),
          currencyCode: currency,
        );
        if (!context.mounted) return;
        showResult(result.when(
          success: (p) => 'Excel 已导出至 $p',
          failure: (e) => e.message,
        ));
      });

  Future<void> exportDatabase() => _run(() async {
        final dir = await FilePicker.platform.getDirectoryPath(
          dialogTitle: '选择导出目录',
        );
        if (dir == null) return;

        final service = await ref.read(exportServiceProvider.future);
        final fileName = service.suggestExportFileName('db');
        final result = await service.exportDatabaseCopy(
          service.joinExportPath(dir, fileName),
        );
        if (!context.mounted) return;
        showResult(result.when(
          success: (p) => '数据库已导出至 $p',
          failure: (e) => e.message,
        ));
      });

  Future<void> createBackup() => _run(() async {
        final settings = ref.read(settingsProvider);
        final service = await ref.read(backupServiceProvider.future);
        final result = await service.createBackup(
          encrypt: settings.backupEncryptionEnabled,
          password: settings.backupEncryptionPassword.isEmpty
              ? null
              : settings.backupEncryptionPassword,
        );
        if (!context.mounted) return;
        switch (result) {
          case Success(:final data):
            await BackupPromptService.instance.notifyIfEnabled(
              settings: settings,
              backupPath: data,
            );
            if (context.mounted) {
              showResult('备份已保存至 $data');
            }
          case Failure(:final error):
            showResult(error.message);
        }
      });

  Future<void> importSpreadsheet() => _run(() async {
        await showTransactionImportDialog(context, ref);
      });

  Future<void> importDatabase() => _run(() async {
        final picked = await FilePicker.platform.pickFiles(
          dialogTitle: '选择数据库文件',
          type: FileType.custom,
          allowedExtensions: ['db'],
        );
        if (picked == null || picked.files.single.path == null) return;

        final ok = await confirm(
          title: '导入数据库',
          content: '导入将覆盖当前所有数据，建议先备份。是否继续？',
          confirmLabel: '导入',
        );
        if (!ok) return;

        final service = await ref.read(exportServiceProvider.future);
        final result = await service.importDatabaseCopy(picked.files.single.path!);
        if (!context.mounted) return;
        switch (result) {
          case Success():
            await reloadDatabaseLayer(ref);
            if (context.mounted) {
              showResult('导入成功，数据已重新加载');
            }
          case Failure(:final error):
            showResult(error.message);
        }
      });

  Future<void> clearAllTransactions() => _run(() async {
        final ok = await confirm(
          title: '清空所有交易',
          content: '将删除全部交易记录，并回滚对应账户余额。\n'
              '账户、分类、账本等基础数据不会删除。\n\n'
              '此操作不可撤销，是否继续？',
          confirmLabel: '清空',
          destructive: true,
        );
        if (!ok) return;

        final service = await ref.read(bookkeepingServiceProvider.future);
        final result = await service.deleteAllTransactions();
        if (!context.mounted) return;

        result.when(
          success: (count) {
            ref.read(transactionRefreshProvider.notifier).state++;
            refreshAccounts(ref);
            showResult(count == 0 ? '当前没有交易记录' : '已清空 $count 条交易');
          },
          failure: (error) => showResult(error.message),
        );
      });

  Future<void> seedDemoTransactions() => _run(() async {
        final ok = await confirm(
          title: '生成演示交易',
          content: '将自动补齐默认账户、分类和标签，并生成约 100 条演示交易。\n'
              '数据包含支出、收入、转账，覆盖备注、标签、报销等字段。\n\n'
              '是否继续？',
          confirmLabel: '生成',
        );
        if (!ok) return;

        final service = await ref.read(demoTransactionSeedServiceProvider.future);
        final result = await service.seed(targetCount: 100);
        if (!context.mounted) return;

        result.when(
          success: (count) {
            ref.read(transactionRefreshProvider.notifier).state++;
            refreshAccounts(ref);
            refreshCategories(ref);
            refreshBooks(ref);
            refreshTags(ref);
            showResult('已成功生成 $count 条演示交易');
          },
          failure: (error) => showResult(error.message),
        );
      });

  Future<void> restoreBackup(String backupPath) => _run(() async {
        final service = await ref.read(backupServiceProvider.future);
        String? password;
        if (service.isEncryptedBackupPath(backupPath)) {
          password = await showBackupPasswordPromptDialog(
            context,
            title: '输入加密备份密码',
          );
          if (password == null || password.isEmpty) return;
        }

        final ok = await confirm(
          title: '恢复备份',
          content: service.isEncryptedBackupPath(backupPath)
              ? '将使用加密备份覆盖当前数据库，建议先导出备份。是否继续？'
              : '恢复将覆盖当前数据库，建议先导出备份。是否继续？',
          confirmLabel: '恢复',
          destructive: true,
        );
        if (!ok) return;

        final result = await service.restoreBackup(
          backupPath,
          password: password,
        );
        if (!context.mounted) return;
        switch (result) {
          case Success():
            await reloadDatabaseLayer(ref);
            if (context.mounted) {
              showResult('恢复成功，数据已重新加载');
            }
          case Failure(:final error):
            showResult(error.message);
        }
      });
}
