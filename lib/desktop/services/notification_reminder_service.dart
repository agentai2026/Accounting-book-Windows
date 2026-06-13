import 'dart:async';
import 'dart:io';

import 'package:local_notifier/local_notifier.dart';

import 'package:ezbookkeeping_desktop/core/constants/app_constants.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';

/// 每日记账提醒（桌面端本地通知）。
class NotificationReminderService {
  NotificationReminderService._();

  static final NotificationReminderService instance =
      NotificationReminderService._();

  Timer? _timer;
  DateTime? _lastFiredDay;
  bool _initialized = false;
  SettingsState Function()? _readSettings;

  Future<void> initialize() async {
    if (_initialized) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        await localNotifier.setup(appName: AppConstants.appName);
      } catch (_) {}
    }
    _initialized = true;
  }

  void syncFromSettings(
    SettingsState settings, {
    SettingsState Function()? readSettings,
  }) {
    _readSettings = readSettings;
    _timer?.cancel();
    _timer = null;
    if (!settings.reminderEnabled) return;

    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      final current = _readSettings?.call() ?? settings;
      _checkAndNotify(current);
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkAndNotify(SettingsState settings) async {
    if (!settings.reminderEnabled) return;

    final now = DateTime.now();
    if (now.hour != settings.reminderHour ||
        now.minute != settings.reminderMinute) {
      return;
    }

    final today = DateTime(now.year, now.month, now.day);
    if (_lastFiredDay == today) return;
    _lastFiredDay = today;

    await _showReminder(settings);
  }

  Future<void> _showReminder(SettingsState settings) async {
    if (!_initialized) {
      await initialize();
    }

    final notification = LocalNotification(
      identifier: 'ezb_daily_reminder',
      title: '记账提醒',
      subtitle: AppConstants.appName,
      body: '${_soundStyleHint(settings.notificationSoundStyle)} · 别忘了记录今天的收支哦',
      silent: !settings.notificationSoundEnabled,
    );

    try {
      await notification.show();
    } catch (_) {}
  }

  /// 设置页「试听」用。
  Future<void> preview(SettingsState settings) async {
    if (!_initialized) {
      await initialize();
    }

    final notification = LocalNotification(
      identifier: 'ezb_reminder_preview',
      title: '记账提醒预览',
      body: _soundStyleHint(settings.notificationSoundStyle),
      silent: !settings.notificationSoundEnabled,
    );

    try {
      await notification.show();
    } catch (_) {}
  }

  String _soundStyleHint(NotificationSoundStyle style) {
    return switch (style) {
      NotificationSoundStyle.drum => '鼓点风格提醒音',
      NotificationSoundStyle.morning => '清晨风格提醒音',
      NotificationSoundStyle.cave => '洞穴风格提醒音',
    };
  }
}
