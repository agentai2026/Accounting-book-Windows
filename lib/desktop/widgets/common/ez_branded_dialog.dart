import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/constants/app_constants.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';

/// 轻记账 品牌确认对话框
Future<bool> showEzConfirmDialog(
  BuildContext context, {
  required String message,
  String confirmLabel = '确定',
  String cancelLabel = '取消',
}) async {
  final result = await showGlassDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return GlassDialog(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        cancelLabel,
                        style: const TextStyle(
                          color: AppColors.income,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
