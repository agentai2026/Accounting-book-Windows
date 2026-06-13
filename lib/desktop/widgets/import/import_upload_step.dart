import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/constants/import_file_types.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/import/import_wizard_shared.dart';

/// 第一步：快捷来源 + 格式 + 拖放上传
class ImportUploadStep extends StatefulWidget {
  const ImportUploadStep({
    super.key,
    required this.selectedCategory,
    required this.fileType,
    required this.fileEncoding,
    required this.fileName,
    required this.submitting,
    required this.onCategoryChanged,
    required this.onFileTypeChanged,
    required this.onEncodingChanged,
    required this.onPickFile,
    required this.onFileDropped,
    required this.onClearFile,
    required this.onHelp,
    required this.onQuickPreset,
  });

  final String selectedCategory;
  final String fileType;
  final String fileEncoding;
  final String? fileName;
  final bool submitting;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onFileTypeChanged;
  final ValueChanged<String> onEncodingChanged;
  final VoidCallback onPickFile;
  final ValueChanged<XFile> onFileDropped;
  final VoidCallback onClearFile;
  final void Function(String anchor) onHelp;
  final void Function(String category, String fileType) onQuickPreset;

  @override
  State<ImportUploadStep> createState() => _ImportUploadStepState();
}

class _ImportUploadStepState extends State<ImportUploadStep> {
  bool _dragging = false;

  bool get _isExcel {
    final name = widget.fileName?.toLowerCase() ?? '';
    return name.endsWith('.xlsx') || name.endsWith('.xls');
  }

  ImportFileTypeOption? get _selectedOption =>
      ImportFileTypes.findByType(widget.fileType);

  /// 与 [ImportFileCategories.ordered] 一致：支付 / 银行 / 自定义
  static final _quickPresets = [
    _QuickPreset(
      label: ImportFileCategories.paymentApp,
      subtitle: '支付宝、微信、QQ 等',
      category: ImportFileCategories.paymentApp,
      defaultFileType: 'alipay_app_csv',
      fileTypes: PaymentImportFormats.allFileTypes,
      accent: AppColors.primary,
      icon: Icons.account_balance_wallet_outlined,
    ),
    _QuickPreset(
      label: ImportFileCategories.bankStatement,
      subtitle: '网银 CSV / Excel',
      category: ImportFileCategories.bankStatement,
      defaultFileType: 'bank_csv',
      fileTypes: ['bank_csv', 'bank_xlsx'],
      accent: Color(0xFF6B8CAE),
      icon: Icons.account_balance_outlined,
    ),
    _QuickPreset(
      label: ImportFileCategories.customTable,
      subtitle: 'CSV、TSV、Excel',
      category: ImportFileCategories.customTable,
      defaultFileType: 'custom_csv',
      fileTypes: [
        'custom_csv',
        'custom_tsv',
        'custom_xlsx',
        'custom_xls',
      ],
      accent: Color(0xFF8B7355),
      icon: Icons.grid_on_outlined,
    ),
  ];

  _QuickPreset? get _activePreset {
    for (final preset in _quickPresets) {
      if (preset.fileTypes.contains(widget.fileType)) return preset;
    }
    return null;
  }

  bool get _isPaymentApp =>
      widget.selectedCategory == ImportFileCategories.paymentApp;

  List<ImportFileTypeOption> get _visibleFormatOptions {
    if (_isPaymentApp) return const [];
    final active = _activePreset;
    if (active != null) {
      return ImportFileTypes.all
          .where((o) => active.fileTypes.contains(o.type))
          .toList();
    }
    return ImportFileTypes.byCategory(widget.selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final fileTypeOptions = _visibleFormatOptions;
    final selectedOption = _selectedOption;
    final activePreset = _activePreset;

    return Column(
      key: const ValueKey('uploadFile'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ImportStepHeader(
          title: '选择账单文件',
          description: '先选来源类型，再将导出的 CSV 或 Excel 拖入右侧区域。',
        ),
        const ImportSectionLabel('账单来源'),
        Row(
          children: [
            for (var i = 0; i < _quickPresets.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _QuickPresetCard(
                  preset: _quickPresets[i],
                  selected: _isPresetActive(_quickPresets[i]),
                  onTap: widget.submitting
                      ? null
                      : () => widget.onQuickPreset(
                            _quickPresets[i].category,
                            _quickPresets[i].defaultFileType,
                          ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: ImportWizardShared.surfaceDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ImportSectionLabel(
                        activePreset != null
                            ? '${activePreset.label} · 文件格式'
                            : '文件格式',
                      ),
                      Expanded(
                        child: _isPaymentApp
                            ? ListView.separated(
                                itemCount: PaymentImportFormats.groups.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (context, index) {
                                  final group =
                                      PaymentImportFormats.groups[index];
                                  return _FormatGroupTile(
                                    group: group,
                                    selected: group.fileTypes
                                        .contains(widget.fileType),
                                    onTap: widget.submitting
                                        ? null
                                        : () => widget.onFileTypeChanged(
                                              group.defaultFileType,
                                            ),
                                  );
                                },
                              )
                            : ListView.separated(
                                itemCount: fileTypeOptions.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (context, index) {
                                  final option = fileTypeOptions[index];
                                  return _FormatTile(
                                    option: option,
                                    selected: widget.fileType == option.type,
                                    onTap: widget.submitting ||
                                            option.comingSoon
                                        ? null
                                        : () => widget.onFileTypeChanged(
                                              option.type,
                                            ),
                                  );
                                },
                              ),
                      ),
                      if (selectedOption?.supportsEncoding == true &&
                          !_isExcel) ...[
                        const Divider(height: 24),
                        AppSelectField<String>(
                          label: '文本编码',
                          value: widget.fileEncoding,
                          isDense: true,
                          enabled: !widget.submitting,
                          options: [
                            for (final o in ImportFileTypes.encodingOptions)
                              AppSelectOption(value: o.value, label: o.label),
                          ],
                          onChanged: widget.submitting
                              ? null
                              : (v) {
                                  if (v != null) widget.onEncodingChanged(v);
                                },
                        ),
                      ],
                      if (selectedOption?.helpAnchor != null) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () =>
                                widget.onHelp(selectedOption!.helpAnchor!),
                            child: const Text('如何导出该账单？'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: DropTarget(
                  onDragEntered: (_) => setState(() => _dragging = true),
                  onDragExited: (_) => setState(() => _dragging = false),
                  onDragDone: (details) {
                    setState(() => _dragging = false);
                    if (details.files.isNotEmpty && !widget.submitting) {
                      widget.onFileDropped(details.files.first);
                    }
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.submitting ? null : widget.onPickFile,
                      borderRadius:
                          BorderRadius.circular(ImportWizardShared.cardRadius),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.all(28),
                        decoration: ImportWizardShared.dropZoneDecoration(
                          context,
                          active: _dragging,
                          hasFile: widget.fileName != null,
                        ),
                        child: widget.fileName == null
                            ? _EmptyDropContent(dragging: _dragging)
                            : _SelectedFileContent(
                                fileName: widget.fileName!,
                                formatLabel: selectedOption?.label ?? '文件',
                                onClear: widget.submitting
                                    ? null
                                    : widget.onClearFile,
                                onReselect: widget.submitting
                                    ? null
                                    : widget.onPickFile,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isPresetActive(_QuickPreset preset) {
    return preset.fileTypes.contains(widget.fileType);
  }
}

class _QuickPreset {
  const _QuickPreset({
    required this.label,
    required this.subtitle,
    required this.category,
    required this.defaultFileType,
    required this.fileTypes,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String subtitle;
  final String category;
  final String defaultFileType;
  final List<String> fileTypes;
  final Color accent;
  final IconData icon;
}

class _QuickPresetCard extends StatelessWidget {
  const _QuickPresetCard({
    required this.preset,
    required this.selected,
    this.onTap,
  });

  final _QuickPreset preset;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ImportWizardShared.cardRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? preset.accent.withValues(alpha: 0.08)
                : ImportWizardShared.glassTint(context, light: 0.24, dark: 0.16),
            borderRadius: BorderRadius.circular(ImportWizardShared.cardRadius),
            border: Border.all(
              color: selected
                  ? preset.accent.withValues(alpha: 0.55)
                  : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: preset.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(preset.icon, size: 18, color: preset.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: selected ? preset.accent : null,
                          ),
                    ),
                    Text(
                      preset.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatGroupTile extends StatelessWidget {
  const _FormatGroupTile({
    required this.group,
    required this.selected,
    this.onTap,
  });

  final PaymentImportGroup group;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.selectedBackground.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textHint,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                    ),
                    Text(
                      group.hint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatTile extends StatelessWidget {
  const _FormatTile({
    required this.option,
    required this.selected,
    this.onTap,
  });

  final ImportFileTypeOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = option.comingSoon || onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.selectedBackground.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
                color: disabled
                    ? AppColors.textHint
                    : (selected ? AppColors.primary : AppColors.textHint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                            color: disabled ? AppColors.textHint : null,
                          ),
                    ),
                    Text(
                      option.comingSoon
                          ? '即将支持'
                          : option.extensions.map((e) => '.$e').join('  '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDropContent extends StatelessWidget {
  const _EmptyDropContent({required this.dragging});

  final bool dragging;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: dragging ? 0.16 : 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            dragging ? Icons.download_rounded : Icons.upload_file_rounded,
            size: 32,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          dragging ? '松开即可上传' : '拖放文件到此处',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        const ImportHintText('或点击此区域浏览本地文件'),
        const SizedBox(height: 16),
        const ImportHintText('支持 .csv · .xlsx · .xls'),
      ],
    );
  }
}

class _SelectedFileContent extends StatelessWidget {
  const _SelectedFileContent({
    required this.fileName,
    required this.formatLabel,
    this.onClear,
    this.onReselect,
  });

  final String fileName;
  final String formatLabel;
  final VoidCallback? onClear;
  final VoidCallback? onReselect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.income.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.insert_drive_file_rounded,
            size: 32,
            color: AppColors.income,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          fileName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          formatLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (onReselect != null)
              OutlinedButton(
                onPressed: onReselect,
                child: const Text('更换文件'),
              ),
            if (onClear != null) ...[
              const SizedBox(width: 10),
              TextButton(
                onPressed: onClear,
                child: const Text('移除'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
