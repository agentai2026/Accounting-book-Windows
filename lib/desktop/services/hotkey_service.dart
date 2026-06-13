import 'dart:io';

import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/desktop/services/desktop_action_bus.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class HotkeyService {
  HotkeyService._();

  static final HotkeyService instance = HotkeyService._();

  HotKey? _quickAddHotKey;
  bool _initialized = false;

  Future<void> registerDefaults() async {
    if (_initialized || !Platform.isWindows) return;

    try {
      await hotKeyManager.unregisterAll();

      _quickAddHotKey = HotKey(
        key: PhysicalKeyboardKey.keyA,
        modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
        scope: HotKeyScope.system,
      );

      await hotKeyManager.register(
        _quickAddHotKey!,
        keyDownHandler: (_) {
          DesktopActionBus.instance.emit(DesktopAction.showAddTransaction);
        },
      );

      _initialized = true;
      appLogger.i('全局快捷键 Ctrl+Shift+A 已注册');
    } catch (e, stack) {
      appLogger.w('全局快捷键注册失败', error: e, stackTrace: stack);
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    try {
      await hotKeyManager.unregisterAll();
    } catch (_) {}
    _initialized = false;
  }
}
