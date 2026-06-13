import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/scheduled_transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/services/backup_prompt_service.dart';
import 'package:ezbookkeeping_desktop/desktop/services/backup_scheduler_service.dart';
import 'package:ezbookkeeping_desktop/desktop/services/scheduled_transaction_runner_service.dart';
import 'package:ezbookkeeping_desktop/desktop/services/desktop_action_bus.dart';
import 'package:ezbookkeeping_desktop/desktop/services/hotkey_service.dart';
import 'package:ezbookkeeping_desktop/desktop/services/notification_reminder_service.dart';
import 'package:ezbookkeeping_desktop/desktop/services/tray_service.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/dialogs/scheduled_transaction_confirm_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/add_transaction_dialog.dart';
import 'package:ezbookkeeping_desktop/routes.dart';

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> with WindowListener {
  StreamSubscription<DesktopAction>? _actionSub;
  bool _privacyBlurred = false;

  bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          windowManager.addListener(this);
          await windowManager.setPreventClose(true);
        } catch (_) {}
        await TrayService.instance.initialize();
        await NotificationReminderService.instance.initialize();
        await _syncHotkeyRegistration();
        NotificationReminderService.instance.syncFromSettings(
          ref.read(settingsProvider),
          readSettings: () => ref.read(settingsProvider),
        );
        _syncBackupScheduler();
        _startScheduledTransactionRunner();
      });
    }
    _actionSub = DesktopActionBus.instance.stream.listen(_handleAction);
  }

  Future<bool> _runScheduledBackup() async {
    final settings = ref.read(settingsProvider);
    if (settings.backupCycle == BackupCycle.off) return false;
    if (settings.backupEncryptionEnabled &&
        settings.backupEncryptionPassword.isEmpty) {
      appLogger.w('定时备份跳过：已开启加密但未设置密码');
      return false;
    }
    try {
      final service = await ref.read(backupServiceProvider.future);
      final result = await service.createBackup(
        encrypt: settings.backupEncryptionEnabled,
        password: settings.backupEncryptionPassword.isEmpty
            ? null
            : settings.backupEncryptionPassword,
      );
      switch (result) {
        case Success(:final data):
          await service.pruneOldBackups(
            retentionDays: settings.backupRetentionDays,
          );
          await BackupPromptService.instance.notifyIfEnabled(
            settings: settings,
            backupPath: data,
          );
          return true;
        case Failure(:final error):
          appLogger.w('定时备份失败: ${error.message}');
          return false;
      }
    } catch (e, stack) {
      appLogger.w('定时备份失败', error: e, stackTrace: stack);
      return false;
    }
  }

  void _syncBackupScheduler() {
    BackupSchedulerService.instance.syncFromSettings(
      ref.read(settingsProvider),
      runBackup: _runScheduledBackup,
      readSettings: () => ref.read(settingsProvider),
    );
  }

  void _startScheduledTransactionRunner() {
    ScheduledTransactionRunnerService.instance.start(
      runner: _runDueScheduledTransactions,
    );
  }

  Future<int> _runDueScheduledTransactions() async {
    try {
      final service =
          await ref.read(scheduledTransactionServiceProvider.future);
      final dueCount = await service.countDue();
      if (dueCount <= 0) return 0;

      final context = rootNavigatorKey.currentContext;
      if (context == null || !context.mounted) return 0;

      final confirmed = await showScheduledTransactionConfirmDialog(
        context,
        dueCount: dueCount,
      );
      if (confirmed != true) return 0;

      final result = await service.executeDue();
      return result.when(
        success: (count) {
          if (count > 0) {
            ref.read(scheduledTransactionRefreshProvider.notifier).state++;
            ref.read(transactionRefreshProvider.notifier).state++;
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已自动入账 $count 条周期记账')),
              );
            }
          }
          return count;
        },
        failure: (error) {
          appLogger.w('周期记账执行失败: ${error.message}');
          return 0;
        },
      );
    } catch (e, stack) {
      appLogger.w('周期记账执行失败', error: e, stackTrace: stack);
      return 0;
    }
  }

  Future<void> _maybeAutoBackup() async {
    final settings = ref.read(settingsProvider);
    if (!settings.autoBackupEnabled) return;
    if (settings.backupEncryptionEnabled &&
        settings.backupEncryptionPassword.isEmpty) {
      appLogger.w('退出备份跳过：已开启加密但未设置密码');
      return;
    }
    try {
      final service = await ref.read(backupServiceProvider.future);
      final result = await service.createBackup(
        encrypt: settings.backupEncryptionEnabled,
        password: settings.backupEncryptionPassword.isEmpty
            ? null
            : settings.backupEncryptionPassword,
      );
      switch (result) {
        case Success(:final data):
          await service.pruneOldBackups(
            retentionDays: settings.backupRetentionDays,
          );
          await BackupPromptService.instance.notifyIfEnabled(
            settings: settings,
            backupPath: data,
          );
        case Failure(:final error):
          appLogger.w('退出备份失败: ${error.message}');
      }
    } catch (e, stack) {
      appLogger.w('退出备份失败', error: e, stackTrace: stack);
    }
  }

  Future<void> _syncHotkeyRegistration() async {
    final enabled = ref.read(settingsProvider).hotkeyEnabled;
    if (enabled) {
      await HotkeyService.instance.registerDefaults();
    } else {
      await HotkeyService.instance.dispose();
    }
  }

  @override
  void dispose() {
    _actionSub?.cancel();
    NotificationReminderService.instance.dispose();
    BackupSchedulerService.instance.dispose();
    ScheduledTransactionRunnerService.instance.dispose();
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowBlur() {
    if (ref.read(settingsProvider).privacyProtection) {
      setState(() => _privacyBlurred = true);
    }
  }

  @override
  void onWindowFocus() {
    if (_privacyBlurred) {
      setState(() => _privacyBlurred = false);
    }
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  Future<void> _handleAction(DesktopAction action) async {
    if (!_isDesktop && action == DesktopAction.quitApp) return;

    switch (action) {
      case DesktopAction.showWindow:
        await windowManager.show();
        await windowManager.focus();
      case DesktopAction.showAddTransaction:
        await windowManager.show();
        await windowManager.focus();
        final context = rootNavigatorKey.currentContext;
        if (context != null && context.mounted) {
          await showAddTransactionDialog(context);
        }
      case DesktopAction.quitApp:
        await _maybeAutoBackup();
        await HotkeyService.instance.dispose();
        await TrayService.instance.dispose();
        await windowManager.destroy();
        exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SettingsState>(settingsProvider, (previous, next) {
      if (previous?.reminderEnabled != next.reminderEnabled ||
          previous?.reminderHour != next.reminderHour ||
          previous?.reminderMinute != next.reminderMinute) {
        NotificationReminderService.instance.syncFromSettings(
          next,
          readSettings: () => ref.read(settingsProvider),
        );
      }
      if (previous?.backupCycle != next.backupCycle) {
        _syncBackupScheduler();
      }
      if (previous?.hotkeyEnabled != next.hotkeyEnabled) {
        unawaited(_syncHotkeyRegistration());
      }
      if (!next.privacyProtection && _privacyBlurred) {
        setState(() => _privacyBlurred = false);
      }
    });

    final privacyEnabled = ref.watch(settingsProvider).privacyProtection;

  // DesktopShell 在 MaterialApp 外层，需显式提供文字方向。
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.topLeft,
        children: [
          widget.child,
          if (privacyEnabled && _privacyBlurred)
            Positioned.fill(
              child: AbsorbPointer(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '隐私保护已启用',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '点击窗口以继续查看',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
