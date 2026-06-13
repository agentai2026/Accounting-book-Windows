import 'dart:io';
import 'dart:typed_data';

import 'package:ezbookkeeping_desktop/core/constants/database_constants.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class TransactionImageService {
  TransactionImageService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<String> resolveAbsolutePath(String relativePath) async {
    final root = await _dataRootDirectory();
    return p.join(root, relativePath);
  }

  Future<Result<String>> saveImageBytes({
    required Uint8List bytes,
    required String fileName,
    DateTime? date,
  }) async {
    try {
      final root = await _dataRootDirectory();
      final stamp = date ?? DateTime.now();
      final relativeDir = p.join(
        'images',
        '${stamp.year}',
        stamp.month.toString().padLeft(2, '0'),
      );
      final absoluteDir = p.join(root, relativeDir);
      await Directory(absoluteDir).create(recursive: true);

      var ext = p.extension(fileName).toLowerCase();
      if (ext.isEmpty || ext.length > 5) {
        ext = '.jpg';
      }

      final savedName = '${_uuid.v4()}$ext';
      final relativePath = p.join(relativeDir, savedName).replaceAll(r'\', '/');
      final absolutePath = p.join(root, relativePath);
      await File(absolutePath).writeAsBytes(bytes);
      return Result.success(relativePath);
    } catch (e, stack) {
      appLogger.e('保存交易图片失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('保存交易图片失败: $e', code: 'IMAGE_SAVE_ERROR'),
      );
    }
  }

  Future<String> _dataRootDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final folderPath =
        p.join(directory.path, DatabaseConstants.dbFolderName);
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folderPath;
  }
}
