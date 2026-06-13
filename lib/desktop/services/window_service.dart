import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ezbookkeeping_desktop/core/constants/app_constants.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/app_icon_utils.dart';
import 'package:window_manager/window_manager.dart';

class WindowService {
  WindowService._();

  static Future<void> initialize() async {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(
        AppConstants.defaultWindowWidth,
        AppConstants.defaultWindowHeight,
      ),
      minimumSize: Size(
        AppConstants.minWindowWidth,
        AppConstants.minWindowHeight,
      ),
      center: true,
      title: AppConstants.appName,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (Platform.isWindows) {
        try {
          final iconPath = await AppIconUtils.materializeWindowsIco();
          await windowManager.setIcon(iconPath);
        } catch (_) {}
      }
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
