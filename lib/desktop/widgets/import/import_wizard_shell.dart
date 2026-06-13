import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/import/import_steps_bar.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/import/import_wizard_shared.dart';

/// 导入向导外壳：左侧步骤轨 + 右侧内容区
class ImportWizardShell extends StatelessWidget {
  const ImportWizardShell({
    super.key,
    required this.steps,
    required this.currentStepId,
    required this.body,
    required this.footer,
    this.loading = false,
    this.errorMessage,
    this.onDismissError,
    this.onClose,
  });

  final List<ImportWizardStep> steps;
  final String currentStepId;
  final Widget body;
  final Widget footer;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onDismissError;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      borderRadius: BorderRadius.circular(ImportWizardShared.dialogRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1280,
          minWidth: 960,
          minHeight: 680,
          maxHeight: 860,
        ),
        child: Column(
          children: [
            _TopBar(loading: loading, onClose: onClose),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassSurface(
                    borderRadius: BorderRadius.zero,
                    showShadow: false,
                    blurSigma: 40,
                    tintOpacity: Theme.of(context).brightness == Brightness.dark
                        ? 0.5
                        : 0.64,
                    child: SizedBox(
                      width: ImportWizardShared.railWidth,
                      child: ImportStepsRail(
                        steps: steps,
                        currentStepId: currentStepId,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    color: ImportWizardShared.glassDivider(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
                            child: _ErrorBanner(
                              message: errorMessage!,
                              onDismiss: onDismissError,
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              32,
                              errorMessage != null ? 16 : 28,
                              32,
                              12,
                            ),
                            child: body,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(32, 14, 32, 22),
                          decoration: BoxDecoration(
                            color: ImportWizardShared.glassTint(
                              context,
                              light: 0.18,
                              dark: 0.14,
                            ),
                            border: Border(
                              top: BorderSide(
                                color: ImportWizardShared.glassDivider(context),
                              ),
                            ),
                          ),
                          child: footer,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.loading, this.onClose});

  final bool loading;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: ImportWizardShared.glassTint(context, light: 0.2, dark: 0.14),
        border: Border(
          bottom: BorderSide(color: ImportWizardShared.glassDivider(context)),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          IconButton(
            tooltip: '关闭',
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: Icon(
              Icons.close,
              size: 20,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.expense.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.expense, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.expense,
                      height: 1.5,
                    ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 16),
                color: AppColors.expense,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}

class ImportWizardFooter extends StatelessWidget {
  const ImportWizardFooter({
    super.key,
    this.onCancel,
    this.onBack,
    this.primaryLabel = '下一步',
    this.onPrimary,
    this.primaryEnabled = true,
    this.primaryLoading = false,
    this.primaryColor,
    this.primaryHint,
  });

  final VoidCallback? onCancel;
  final VoidCallback? onBack;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryEnabled;
  final bool primaryLoading;
  final Color? primaryColor;
  final String? primaryHint;

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? AppColors.primary;

    return Row(
      children: [
        if (onCancel != null)
          TextButton(
            onPressed: onCancel,
            child: Text(
              '取消',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        if (onBack != null)
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('上一步'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
          ),
        const Spacer(),
        if (primaryHint != null && !primaryEnabled) ...[
          Text(
            primaryHint!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
          const SizedBox(width: 16),
        ],
        SizedBox(
          height: 40,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              disabledBackgroundColor: primary.withValues(alpha: 0.35),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: primaryEnabled && !primaryLoading ? onPrimary : null,
            child: primaryLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    primaryLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
