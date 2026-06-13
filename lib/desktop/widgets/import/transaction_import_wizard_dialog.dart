import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/constants/import_file_types.dart';
import 'package:ezbookkeeping_desktop/core/models/import_preview_row.dart';
import 'package:ezbookkeeping_desktop/core/services/alipay_csv_summary_parser.dart';
import 'package:ezbookkeeping_desktop/core/services/import_column_mapping_config.dart';
import 'package:ezbookkeeping_desktop/core/services/import_mapping_resolver.dart';
import 'package:ezbookkeeping_desktop/core/services/import_raw_file_reader.dart';
import 'package:ezbookkeeping_desktop/core/services/transaction_import_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/text_file_encoding.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/ez_branded_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/import/import_check_data_step.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/import/import_define_column_step.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/import/import_result_step.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/import/import_steps_bar.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/import/import_upload_step.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/import/import_wizard_shell.dart';

enum _ImportWizardStepId {
  uploadFile,
  defineColumn,
  checkData,
  finalResult,
}

class TransactionImportWizardDialog extends ConsumerStatefulWidget {
  const TransactionImportWizardDialog({super.key});

  @override
  ConsumerState<TransactionImportWizardDialog> createState() =>
      _TransactionImportWizardDialogState();
}

class _TransactionImportWizardDialogState
    extends ConsumerState<TransactionImportWizardDialog> {
  _ImportWizardStepId _currentStep = _ImportWizardStepId.uploadFile;
  bool _submitting = false;

  String _selectedCategory = ImportFileCategories.paymentApp;
  String _fileType = 'alipay_app_csv';
  String _fileEncoding = ImportFileTypes.autoEncoding;
  String? _filePath;
  String? _fileName;
  List<int>? _fileBytes;
  String? _csvContent;
  String? _inlineError;

  List<List<String>> _rawRows = [];
  ImportColumnMappingConfig? _columnMapping;
  List<ImportPreviewRow> _previewRows = [];
  ImportParseResult? _parseResult;
  TransactionImportResult? _importResult;

  List<ImportWizardStep> get _steps => const [
        ImportWizardStep(
          id: 'uploadFile',
          title: '选择文件',
          subtitle: '来源与格式',
        ),
        ImportWizardStep(
          id: 'defineColumn',
          title: '映射列',
          subtitle: '对照表头',
        ),
        ImportWizardStep(
          id: 'checkData',
          title: '确认数据',
          subtitle: '勾选导入',
        ),
        ImportWizardStep(
          id: 'finalResult',
          title: '完成',
          subtitle: '导入结果',
        ),
      ];

  ImportFileTypeOption? get _selectedFileTypeOption =>
      ImportFileTypes.findByType(_fileType);

  bool get _isExcelFile {
    final ext = _fileExtension;
    return ext == 'xlsx' || ext == 'xls';
  }

  String? get _fileExtension {
    if (_fileName == null) return null;
    return _fileName!.split('.').last.toLowerCase();
  }

  bool get _canGoNextFromUpload => _filePath != null;

  bool get _canGoNextFromDefineColumn =>
      _columnMapping?.hasRequiredMapping ?? false;

  bool get _canImport =>
      _previewRows.any((row) => row.valid && row.selected);

  bool get _canGoBack =>
      _currentStep == _ImportWizardStepId.defineColumn ||
      _currentStep == _ImportWizardStepId.checkData;

  String? get _importSourceLabel {
    return PaymentImportFormats.groupForFileType(_fileType)?.label ??
        _selectedFileTypeOption?.label;
  }

  List<String> get _importHeaderLabels {
    final index = _columnMapping?.headerRowIndex;
    if (index == null || index < 0 || index >= _rawRows.length) {
      return const [];
    }
    return _rawRows[index];
  }

  @override
  Widget build(BuildContext context) {
    return ImportWizardShell(
      steps: _steps,
      currentStepId: _currentStep.name,
      loading: _submitting,
      errorMessage: _inlineError,
      onDismissError: () => setState(() => _inlineError = null),
      onClose: _submitting ? null : () => _close(false),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildStepContent(),
      ),
      footer: ImportWizardFooter(
        onCancel: _currentStep == _ImportWizardStepId.finalResult
            ? null
            : (_submitting ? null : () => _close(false)),
        onBack: _canGoBack && !_submitting ? _goBack : null,
        primaryLabel: _primaryButtonLabel,
        primaryEnabled: _primaryButtonEnabled,
        primaryLoading: _submitting &&
            _currentStep != _ImportWizardStepId.uploadFile &&
            _currentStep != _ImportWizardStepId.finalResult,
        primaryColor: _currentStep == _ImportWizardStepId.checkData
            ? AppColors.income
            : null,
        onPrimary: _submitting ? null : _onPrimaryAction,
        primaryHint: _primaryDisabledHint,
      ),
    );
  }

  String? get _primaryDisabledHint {
    if (_primaryButtonEnabled) return null;
    return switch (_currentStep) {
      _ImportWizardStepId.uploadFile => '请先选择或拖入账单文件',
      _ImportWizardStepId.defineColumn => '请映射交易时间、类型、金额',
      _ImportWizardStepId.checkData => '请至少勾选一条有效交易',
      _ => null,
    };
  }

  String get _primaryButtonLabel {
    return switch (_currentStep) {
      _ImportWizardStepId.uploadFile => '继续',
      _ImportWizardStepId.defineColumn => '预览数据',
      _ImportWizardStepId.checkData =>
        _submitting ? '导入中...' : '确认导入',
      _ImportWizardStepId.finalResult => '完成',
    };
  }

  bool get _primaryButtonEnabled {
    return switch (_currentStep) {
      _ImportWizardStepId.uploadFile => _canGoNextFromUpload,
      _ImportWizardStepId.defineColumn => _canGoNextFromDefineColumn,
      _ImportWizardStepId.checkData => _canImport,
      _ImportWizardStepId.finalResult => true,
    };
  }

  void _onPrimaryAction() {
    switch (_currentStep) {
      case _ImportWizardStepId.uploadFile:
        _loadRawFile();
      case _ImportWizardStepId.defineColumn:
        _parseWithMapping();
      case _ImportWizardStepId.checkData:
        _submitImport();
      case _ImportWizardStepId.finalResult:
        _close(true);
    }
  }

  void _goBack() {
    setState(() {
      _inlineError = null;
      _currentStep = switch (_currentStep) {
        _ImportWizardStepId.checkData => _ImportWizardStepId.defineColumn,
        _ImportWizardStepId.defineColumn => _ImportWizardStepId.uploadFile,
        _ => _currentStep,
      };
    });
  }

  Widget _buildStepContent() {
    return switch (_currentStep) {
      _ImportWizardStepId.uploadFile => ImportUploadStep(
          selectedCategory: _selectedCategory,
          fileType: _fileType,
          fileEncoding: _fileEncoding,
          fileName: _fileName,
          submitting: _submitting,
          onCategoryChanged: _onCategoryChanged,
          onFileTypeChanged: _onFileTypeChanged,
          onEncodingChanged: (v) => setState(() => _fileEncoding = v),
          onPickFile: _pickFile,
          onFileDropped: _onFileDropped,
          onClearFile: _clearFile,
          onHelp: _openHelp,
          onQuickPreset: _onQuickPreset,
        ),
      _ImportWizardStepId.defineColumn =>
        _columnMapping == null || _rawRows.isEmpty
            ? const Center(child: Text('没有可预览的数据，请返回上一步重新选择文件'))
            : ImportDefineColumnStep(
                key: const ValueKey('defineColumn'),
                rawRows: _rawRows,
                mapping: _columnMapping!,
                onMappingChanged: (mapping) =>
                    setState(() => _columnMapping = mapping),
              ),
      _ImportWizardStepId.checkData => ImportCheckDataStep(
          key: const ValueKey('checkData'),
          rows: _previewRows,
          fileName: _fileName,
          sourceLabel: _importSourceLabel,
          headerLabels: _importHeaderLabels,
          skippedByRule: _parseResult?.skippedByRule ?? 0,
          skipReasons: _parseResult?.skipReasons ?? const {},
          onChanged: (rows) => setState(() => _previewRows = rows),
        ),
      _ImportWizardStepId.finalResult => ImportResultStep(
          result: _importResult ??
              const TransactionImportResult(imported: 0, skipped: 0),
          fileName: _fileName,
        ),
    };
  }

  void _onCategoryChanged(String category) {
    final options = ImportFileTypes.byCategory(category);
    setState(() {
      _selectedCategory = category;
      _fileType = options.first.type;
      _clearFileState();
    });
  }

  void _onFileTypeChanged(String type) {
    setState(() {
      _fileType = type;
      _clearFileState();
    });
  }

  void _onQuickPreset(String category, String fileType) {
    setState(() {
      _selectedCategory = category;
      _fileType = fileType;
      _clearFileState();
    });
  }

  void _clearFileState() {
    _filePath = null;
    _fileName = null;
    _fileBytes = null;
    _rawRows = [];
    _columnMapping = null;
    _csvContent = null;
    _inlineError = null;
  }

  void _clearFile() {
    setState(_clearFileState);
  }

  Future<void> _pickFile() async {
    final option = _selectedFileTypeOption;
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: '选择导入文件',
      type: FileType.custom,
      allowedExtensions: option?.extensions ?? ['csv', 'xlsx', 'xls'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.single;
    if (file.bytes == null && file.path == null) {
      _showError('无法读取所选文件，请重试或换一份文件');
      return;
    }

    await _applyFile(
      name: file.name,
      path: file.path,
      bytes: file.bytes,
    );
  }

  Future<void> _onFileDropped(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      await _applyFile(
        name: file.name,
        path: file.path,
        bytes: bytes,
      );
    } catch (e) {
      _showError('读取拖放文件失败：$e');
    }
  }

  Future<void> _applyFile({
    required String name,
    String? path,
    List<int>? bytes,
  }) async {
    setState(() {
      _filePath = path ?? name;
      _fileName = name;
      _fileBytes = bytes;
      _rawRows = [];
      _columnMapping = null;
      _csvContent = null;
      _inlineError = null;
    });

    _autoSuggestFromFileName(name);
    _resolveFileTypeFromExtension(name);
  }

  void _resolveFileTypeFromExtension(String name) {
    final next = PaymentImportFormats.normalizeFileType(_fileType, name);
    if (next != _fileType) {
      setState(() => _fileType = next);
    }
  }

  void _autoSuggestFromFileName(String name) {
    final suggestedType = PaymentImportFormats.suggestFileTypeFromName(name);
    final label = PaymentImportFormats.suggestLabelFromName(name);

    if (suggestedType != null) {
      final option = ImportFileTypes.findByType(suggestedType);
      if (option != null) {
        setState(() {
          _selectedCategory = option.category;
          _fileType = suggestedType;
        });
        if (label != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已根据文件名识别为$label'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      return;
    }

    final lower = name.toLowerCase();
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Excel 文件：请确认左侧已选对应用类型'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _loadRawFile() async {
    final path = _filePath;
    if (path == null) {
      _showError('请先选择文件');
      return;
    }

    final fileType = _selectedFileTypeOption;
    if (fileType?.comingSoon == true) {
      _showError('「${fileType!.label}」专用解析即将支持。'
          '国内银行可先导出 CSV/Excel，选择「银行网银导出」或「自定义表格」导入');
      return;
    }

    setState(() => _submitting = true);

    try {
      final ext = _fileExtension;
      if (ext == 'xlsx' || ext == 'xls') {
        final bytes = await _readFileBytes(path);
        _rawRows = await ImportRawFileReader.readExcelBytes(bytes);
        _csvContent = null;
      } else {
        final bytes = await _readFileBytes(path);
        _csvContent = decodeTextBytes(bytes, encoding: _fileEncoding);
        _rawRows = ImportRawFileReader.parseCsvContent(_csvContent!);
      }

      if (_rawRows.isEmpty) {
        _showError('文件没有可预览的数据，请检查是否为空文件');
        return;
      }

      final mapping = ImportMappingResolver.resolve(_rawRows);

      if (!mounted) return;
      setState(() {
        _columnMapping = mapping;
        _inlineError = null;
      });

      if (mapping.hasRequiredMapping) {
        await _parseWithMapping(manageLoading: false);
      } else {
        setState(() => _currentStep = _ImportWizardStepId.defineColumn);
      }
    } catch (e) {
      _showError('读取文件失败：$e\n\n'
          '可尝试：① 文件分类选「支付应用对账单」；'
          '② 编码改为 GBK；③ 重新选择文件。');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _parseWithMapping({bool manageLoading = true}) async {
    final bookId = await resolveImportBookId(ref);
    if (bookId == null) {
      _showMessage('暂无账本，请先创建账本');
      return;
    }

    final mapping = _columnMapping;
    if (mapping == null || !mapping.hasRequiredMapping) {
      _showMessage('请映射交易时间、交易类型和金额列');
      return;
    }

    if (manageLoading) setState(() => _submitting = true);
    switchActiveBook(ref, bookId);

    final service = await ref.read(transactionImportServiceProvider.future);
    final alipaySummary = _csvContent != null
        ? AlipayCsvSummaryParser.parseFromContent(_csvContent!)
        : AlipayCsvSummaryParser.parseFromRows(_rawRows);

    final importPlatform =
        PaymentImportFormats.platformSourceForFileType(_fileType) ??
            PaymentImportFormats.detectPlatformFromRows(_rawRows);

    final result = await service.parseFromMappedRows(
      bookId: bookId,
      rawRows: _rawRows,
      mapping: mapping,
      alipayOfficialSummary: alipaySummary,
      importPlatform: importPlatform,
    );

    if (!mounted) return;
    if (manageLoading) setState(() => _submitting = false);

    result.when(
      success: (data) {
        if (data.rows.isEmpty) {
          final skipped = data.skippedByRule;
          if (!manageLoading) {
            setState(() => _currentStep = _ImportWizardStepId.defineColumn);
          }
          _showMessage(
            skipped > 0
                ? '共 $skipped 条被规则跳过（交易关闭/退款等），'
                    '没有可导入的有效数据。可在预览页查看「规则跳过」原因。'
                : '未能自动识别列映射，请在「映射列」步骤手动对照表头',
          );
          return;
        }
        setState(() {
          _parseResult = data;
          _previewRows = data.rows;
          _currentStep = _ImportWizardStepId.checkData;
          _inlineError = null;
        });
        if (!manageLoading && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已自动识别表头并解析，请核对后导入'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      failure: (error) {
        if (!manageLoading) {
          setState(() => _currentStep = _ImportWizardStepId.defineColumn);
        }
        _showMessage(error.message);
      },
    );
  }

  Future<void> _submitImport() async {
    final selected = _previewRows.where((row) => row.valid && row.selected);
    if (selected.isEmpty) {
      _showMessage('请至少选择一条有效数据');
      return;
    }

    final confirmed = await showEzConfirmDialog(
      context,
      message: '确定将 ${selected.length} 条交易导入默认账本吗？',
      confirmLabel: '导入',
    );
    if (!confirmed || !mounted) return;

    setState(() => _submitting = true);
    final service = await ref.read(transactionImportServiceProvider.future);
    final result = await service.commitPreviewRows(
      rows: _previewRows,
      alipayOfficialSummary: _parseResult?.alipayOfficialSummary,
      skippedByRule: _parseResult?.skippedByRule ?? 0,
      skipReasons: _parseResult?.skipReasons ?? const {},
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    result.when(
      success: (data) {
        setState(() {
          _importResult = data;
          _currentStep = _ImportWizardStepId.finalResult;
        });
      },
      failure: (error) => _showMessage(error.message),
    );
  }

  Future<void> _openHelp(String anchor) async {
    final url =
        'https://ezbookkeeping.mayswind.net/zh-Hans/export_and_import#$anchor';
    await showGlassDialog<void>(
      context: context,
      builder: (context) => GlassAlertDialog(
        title: const Text('如何导出账单'),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<List<int>> _readFileBytes(String path) async {
    if (_fileBytes != null && _fileBytes!.isNotEmpty) {
      return _fileBytes!;
    }
    return File(path).readAsBytes();
  }

  void _showError(String message) {
    setState(() => _inlineError = message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _close(bool completed) {
    Navigator.of(context).pop(completed ? _importResult : null);
  }

}

Future<TransactionImportResult?> showTransactionImportWizard(
  BuildContext context,
) {
  return showGlassDialog<TransactionImportResult?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const TransactionImportWizardDialog(),
  );
}
