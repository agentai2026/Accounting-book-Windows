import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';
import 'package:ezbookkeeping_desktop/desktop/services/backup_scheduler_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupSchedulerService.isBackupDue', () {
    test('off 周期永不触发', () {
      expect(
        BackupSchedulerService.isBackupDue(
          BackupCycle.off,
          DateTime(2020, 1, 1),
        ),
        isFalse,
      );
    });

    test('首次备份（无历史记录）应触发', () {
      expect(
        BackupSchedulerService.isBackupDue(
          BackupCycle.daily,
          DateTime.fromMillisecondsSinceEpoch(0),
        ),
        isTrue,
      );
    });

    test('daily 同一天不重复备份', () {
      final todayMorning = DateTime.now().subtract(const Duration(hours: 2));
      expect(
        BackupSchedulerService.isBackupDue(BackupCycle.daily, todayMorning),
        isFalse,
      );
    });

    test('daily 跨天应触发', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(
        BackupSchedulerService.isBackupDue(BackupCycle.daily, yesterday),
        isTrue,
      );
    });

    test('weekly 同一周不重复备份', () {
      final earlierThisWeek = DateTime.now().subtract(const Duration(days: 1));
      expect(
        BackupSchedulerService.isBackupDue(
          BackupCycle.weekly,
          earlierThisWeek,
        ),
        isFalse,
      );
    });

    test('weekly 跨周应触发', () {
      final lastWeek = DateTime.now().subtract(const Duration(days: 8));
      expect(
        BackupSchedulerService.isBackupDue(
          BackupCycle.weekly,
          lastWeek,
        ),
        isTrue,
      );
    });
  });
}
