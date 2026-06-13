import 'dart:io';
import 'dart:typed_data';

import 'package:ezbookkeeping_desktop/core/constants/database_constants.dart';
import 'package:ezbookkeeping_desktop/core/database/database_helper.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/encrypt_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupService {
  BackupService(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  static const encryptedBackupExtension = '.ezb';
  static const plainBackupExtension = '.db';

  Future<String> getBackupDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = p.join(
      directory.path,
      DatabaseConstants.dbFolderName,
      'backups',
    );
    await Directory(backupDir).create(recursive: true);
    return backupDir;
  }

  Future<Result<String>> createBackup({
    bool encrypt = false,
    String? password,
  }) async {
    try {
      if (encrypt && (password == null || password.isEmpty)) {
        return Result.failure(
          const AppException('请先设置备份密码', code: 'BACKUP_PASSWORD_REQUIRED'),
        );
      }

      final dbPath = await _databaseHelper.getDatabasePath();
      final backupDir = await getBackupDirectory();
      final stamp = AppDateUtils.formatDateTime(DateTime.now())
          .replaceAll('/', '')
          .replaceAll(':', '')
          .replaceAll(' ', '_');

      if (encrypt) {
        final plainBytes = await File(dbPath).readAsBytes();
        final encrypted = await EncryptUtils.encryptBytes(
          Uint8List.fromList(plainBytes),
          password!,
        );
        final destPath = p.join(backupDir, 'backup_$stamp$encryptedBackupExtension');
        await File(destPath).writeAsBytes(encrypted, flush: true);
        return Result.success(destPath);
      }

      final destPath = p.join(backupDir, 'backup_$stamp$plainBackupExtension');
      await File(dbPath).copy(destPath);
      return Result.success(destPath);
    } catch (e, stack) {
      appLogger.e('备份失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('备份失败: $e', code: 'BACKUP_ERROR'),
      );
    }
  }

  Future<void> pruneOldBackups({required int retentionDays}) async {
    if (retentionDays <= 0) return;
    try {
      final listResult = await listBackups();
      final files = listResult.when(
        success: (items) => items.whereType<File>().toList(),
        failure: (_) => <File>[],
      );
      final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
      for (final file in files) {
        final modified = await file.lastModified();
        if (modified.isBefore(cutoff)) {
          await file.delete();
        }
      }
    } catch (e, stack) {
      appLogger.w('清理过期备份失败', error: e, stackTrace: stack);
    }
  }

  Future<Result<List<FileSystemEntity>>> listBackups() async {
    try {
      final backupDir = await getBackupDirectory();
      final dir = Directory(backupDir);
      if (!await dir.exists()) return Result.success([]);
      final files = dir
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith(plainBackupExtension) ||
                f.path.endsWith(encryptedBackupExtension),
          )
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      return Result.success(files);
    } catch (e, stack) {
      appLogger.e('读取备份列表失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('读取备份列表失败: $e', code: 'BACKUP_ERROR'),
      );
    }
  }

  bool isEncryptedBackupPath(String backupPath) {
    return backupPath.toLowerCase().endsWith(encryptedBackupExtension);
  }

  Future<Result<String>> restoreBackup(
    String backupPath, {
    String? password,
  }) async {
    try {
      final dbPath = await _databaseHelper.getDatabasePath();
      await _databaseHelper.close();

      if (isEncryptedBackupPath(backupPath)) {
        if (password == null || password.isEmpty) {
          return Result.failure(
            const AppException('需要备份密码', code: 'BACKUP_PASSWORD_REQUIRED'),
          );
        }
        final encrypted = await File(backupPath).readAsBytes();
        final plain = await EncryptUtils.decryptBytes(
          Uint8List.fromList(encrypted),
          password,
        );
        await File(dbPath).writeAsBytes(plain, flush: true);
        return Result.success(dbPath);
      }

      await File(backupPath).copy(dbPath);
      return Result.success(dbPath);
    } on FormatException catch (e) {
      appLogger.e('恢复备份失败', error: e);
      return Result.failure(
        AppException('密码错误或备份文件损坏', code: 'BACKUP_DECRYPT_ERROR'),
      );
    } catch (e, stack) {
      appLogger.e('恢复备份失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('恢复备份失败: $e', code: 'BACKUP_ERROR'),
      );
    }
  }
}
