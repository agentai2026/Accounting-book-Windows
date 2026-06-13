import 'dart:io';

import 'package:ezbookkeeping_desktop/core/constants/database_constants.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 自定义壁纸：复制到应用数据目录，仅存相对路径
class BackgroundImageService {
  static const allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp'};

  Future<String> resolveAbsolutePath(String relativePath) async {
    final root = await _dataRootDirectory();
    return p.join(root, relativePath);
  }

  Future<bool> exists(String relativePath) async {
    if (relativePath.isEmpty) return false;
    final absolute = await resolveAbsolutePath(relativePath);
    return File(absolute).exists();
  }

  Future<Result<String>> importFromFile(String sourceAbsolutePath) async {
    try {
      final source = File(sourceAbsolutePath);
      if (!await source.exists()) {
        return Result.failure(
          const AppException('图片文件不存在', code: 'BG_IMAGE_NOT_FOUND'),
        );
      }

      var ext = p.extension(sourceAbsolutePath).toLowerCase();
      if (ext.isEmpty || !allowedExtensions.contains(ext)) {
        ext = '.jpg';
      }

      final root = await _dataRootDirectory();
      const relativeDir = 'backgrounds';
      final absoluteDir = p.join(root, relativeDir);
      await Directory(absoluteDir).create(recursive: true);

      final fileName =
          'wallpaper_${DateTime.now().millisecondsSinceEpoch}$ext';
      final relativePath =
          p.join(relativeDir, fileName).replaceAll(r'\', '/');
      await source.copy(p.join(root, relativePath));
      return Result.success(relativePath);
    } catch (e, stack) {
      appLogger.e('导入壁纸失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('导入壁纸失败: $e', code: 'BG_IMAGE_IMPORT_ERROR'),
      );
    }
  }

  Future<void> deleteIfExists(String relativePath) async {
    if (relativePath.isEmpty) return;
    try {
      final absolute = await resolveAbsolutePath(relativePath);
      final file = File(absolute);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, stack) {
      appLogger.w('删除壁纸文件失败', error: e, stackTrace: stack);
    }
  }

  Future<String> _dataRootDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final folderPath = p.join(directory.path, DatabaseConstants.dbFolderName);
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folderPath;
  }
}
