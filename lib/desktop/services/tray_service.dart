import 'dart:io';

import 'package:ezbookkeeping_desktop/core/constants/app_constants.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/desktop/services/desktop_action_bus.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/app_icon_utils.dart';
import 'package:system_tray/system_tray.dart';

class TrayService {
  TrayService._();

  static final TrayService instance = TrayService._();

  final SystemTray _tray = SystemTray();
  final Menu _menu = Menu();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || !Platform.isWindows) return;

    try {
      final iconPath = await _resolveIconPath();
      await _tray.initSystemTray(
        iconPath: iconPath,
        toolTip: AppConstants.appName,
      );

      await _menu.buildFrom([
        MenuItemLabel(
          label: '显示主窗口',
          onClicked: (_) => DesktopActionBus.instance.emit(DesktopAction.showWindow),
        ),
        MenuItemLabel(
          label: '记一笔',
          onClicked: (_) =>
              DesktopActionBus.instance.emit(DesktopAction.showAddTransaction),
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: '退出',
          onClicked: (_) => DesktopActionBus.instance.emit(DesktopAction.quitApp),
        ),
      ]);

      await _tray.setContextMenu(_menu);

      _tray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick ||
            eventName == kSystemTrayEventDoubleClick) {
          DesktopActionBus.instance.emit(DesktopAction.showWindow);
        }
      });

      _initialized = true;
      appLogger.i('系统托盘已初始化');
    } catch (e, stack) {
      appLogger.w('系统托盘初始化失败', error: e, stackTrace: stack);
    }
  }

  Future<String> _resolveIconPath() async {
    return AppIconUtils.materializeWindowsIco(fileName: 'qingjizhang_tray.ico');
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    try {
      await _tray.destroy();
    } catch (_) {}
    _initialized = false;
  }
}
