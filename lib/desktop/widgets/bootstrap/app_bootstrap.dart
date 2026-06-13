import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/app.dart';
import 'package:ezbookkeeping_desktop/core/constants/app_constants.dart';
import 'package:ezbookkeeping_desktop/core/database/database_helper.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/file_explorer_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';

/// 启动引导：数据库就绪后才进入主应用
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _loading = true;
  bool _ready = false;
  Object? _error;
  String? _dbPath;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    setState(() {
      _loading = true;
      _ready = false;
      _error = null;
    });

    try {
      await DatabaseHelper.instance.close();
      _dbPath = await DatabaseHelper.instance.getDatabasePath();
      await DatabaseHelper.instance.database;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _ready = true;
      });
    } catch (e, stack) {
      appLogger.e('数据库初始化失败', error: e, stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return const ProviderScope(child: EzBookkeepingApp());
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _loading
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('正在初始化数据库…'),
                      ],
                    )
                  : _DatabaseErrorPanel(
                      error: _error,
                      dbPath: _dbPath,
                      onRetry: _initDatabase,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DatabaseErrorPanel extends StatelessWidget {
  const _DatabaseErrorPanel({
    required this.error,
    required this.dbPath,
    required this.onRetry,
  });

  final Object? error;
  final String? dbPath;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.expense,
            ),
            const SizedBox(height: 16),
            Text(
              '无法启动 ${AppConstants.appName}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              '数据库初始化失败，应用已停止加载以保护你的数据。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.expense.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                error?.toString() ?? '未知错误',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'Consolas',
                      height: 1.4,
                    ),
              ),
            ),
            if (dbPath != null) ...[
              const SizedBox(height: 12),
              Text(
                '数据文件：$dbPath',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
            if (dbPath != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => FileExplorerUtils.revealFile(dbPath!),
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('打开数据目录'),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '若问题持续，请检查磁盘空间与文件权限，或从备份恢复后重启应用。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
