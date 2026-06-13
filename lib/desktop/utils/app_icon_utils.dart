import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// 将打包内的 .ico 释放到临时目录，供 Windows 窗口/托盘使用。
abstract final class AppIconUtils {
  static const assetIcoPath = 'assets/icons/tray.ico';
  static const assetPngPath = 'assets/icons/app_icon.png';

  static Future<String> materializeWindowsIco({String fileName = 'qingjizhang_app.ico'}) async {
    final byteData = await rootBundle.load(assetIcoPath);
    final file = File(p.join(Directory.systemTemp.path, fileName));
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file.path;
  }
}
