import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';

const _keyLastScheduledBackupMs = 'last_scheduled_backup_ms';

typedef ScheduledBackupRunner = Future<bool> Function();

/// 按 [BackupCycle] 在应用运行期间定时创建备份。
class BackupSchedulerService {
  BackupSchedulerService._();

  static final BackupSchedulerService instance = BackupSchedulerService._();

  Timer? _timer;
  ScheduledBackupRunner? _runBackup;
  SettingsState Function()? _readSettings;

  void syncFromSettings(
    SettingsState settings, {
    required ScheduledBackupRunner runBackup,
    SettingsState Function()? readSettings,
  }) {
    _runBackup = runBackup;
    _readSettings = readSettings;
    _timer?.cancel();
    _timer = null;

    if (settings.backupCycle == BackupCycle.off) return;

    _timer = Timer.periodic(const Duration(minutes: 15), (_) {
      unawaited(_maybeRunBackup());
    });

    unawaited(_maybeRunBackup());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _runBackup = null;
    _readSettings = null;
  }

  Future<void> _maybeRunBackup() async {
    final runner = _runBackup;
    if (runner == null) return;

    final settings = _readSettings?.call();
    if (settings == null || settings.backupCycle == BackupCycle.off) return;

    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_keyLastScheduledBackupMs) ?? 0;
    final lastBackup = DateTime.fromMillisecondsSinceEpoch(lastMs);

    if (!_isBackupDue(settings.backupCycle, lastBackup)) return;

    try {
      final succeeded = await runner();
      if (!succeeded) return;
      await prefs.setInt(
        _keyLastScheduledBackupMs,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  @visibleForTesting
  static bool isBackupDue(BackupCycle cycle, DateTime lastBackup) {
    return _isBackupDue(cycle, lastBackup);
  }

  static bool _isBackupDue(BackupCycle cycle, DateTime lastBackup) {
    final now = DateTime.now();
    if (lastBackup.millisecondsSinceEpoch <= 0) return true;

    return switch (cycle) {
      BackupCycle.off => false,
      BackupCycle.daily => _startOfDay(lastBackup).isBefore(_startOfDay(now)),
      BackupCycle.weekly =>
        _startOfWeek(lastBackup).isBefore(_startOfWeek(now)),
    };
  }

  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _startOfWeek(DateTime date) =>
      AppDateUtils.startOfWeek(date, weekStartsOn: DateTime.monday);
}
