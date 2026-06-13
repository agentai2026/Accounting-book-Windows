import 'dart:io';

import 'package:path/path.dart' as p;

/// 在系统文件管理器中打开目录或定位文件。
class FileExplorerUtils {
  FileExplorerUtils._();

  static Future<bool> openFolder(String folderPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return false;

    try {
      if (Platform.isWindows) {
        await Process.start('explorer', [dir.path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [dir.path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [dir.path]);
      } else {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> revealFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;

    try {
      if (Platform.isWindows) {
        await Process.start('explorer', ['/select,${file.absolute.path}']);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', file.absolute.path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [p.dirname(file.absolute.path)]);
      } else {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
