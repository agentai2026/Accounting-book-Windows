import 'package:local_notifier/local_notifier.dart';
import 'package:path/path.dart' as p;

import 'package:ezbookkeeping_desktop/core/constants/app_constants.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/services/notification_reminder_service.dart';

/// 备份完成后的系统通知（受 [SettingsState.showBackupPrompt] 控制）
class BackupPromptService {
  BackupPromptService._();

  static final BackupPromptService instance = BackupPromptService._();

  Future<void> notifyIfEnabled({
    required SettingsState settings,
    required String backupPath,
  }) async {
    if (!settings.showBackupPrompt) return;

    await NotificationReminderService.instance.initialize();

    final fileName = p.basename(backupPath);
    final notification = LocalNotification(
      identifier: 'ezb_backup_${DateTime.now().millisecondsSinceEpoch}',
      title: '备份完成',
      subtitle: AppConstants.appName,
      body: '数据已备份至 $fileName',
      silent: !settings.notificationSoundEnabled,
    );

    try {
      await notification.show();
    } catch (_) {}
  }
}
