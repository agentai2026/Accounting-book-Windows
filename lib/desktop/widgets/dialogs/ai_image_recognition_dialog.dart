import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pasteboard/pasteboard.dart';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/receipt_scene.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/services/receipt_recognition_service.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/ai_entry_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/transaction_draft_submitter.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/add_transaction_dialog.dart';

final receiptRecognitionServiceProvider = Provider<ReceiptRecognitionService>(
  (ref) => ReceiptRecognitionService(),
);

Future<bool?> showAiImageRecognitionDialog(BuildContext context) {
  return showGlassDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AiImageRecognitionDialog(),
  );
}

class AiImageRecognitionDialog extends ConsumerStatefulWidget {
  const AiImageRecognitionDialog({super.key});

  @override
  ConsumerState<AiImageRecognitionDialog> createState() =>
      _AiImageRecognitionDialogState();
}

class _AiImageRecognitionDialogState
    extends ConsumerState<AiImageRecognitionDialog> {
  Uint8List? _imageBytes;
  String? _fileName;
  bool _dragging = false;
  bool _recognizing = false;
  ReceiptScene? _forceScene;
  TransactionType? _forceType;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sceneIndex = ref.read(settingsProvider).aiDefaultSceneIndex;
      if (sceneIndex >= 0) {
        final scenes = ReceiptScene.values
            .where((s) => s != ReceiptScene.unknown)
            .toList(growable: false);
        if (sceneIndex < scenes.length) {
          setState(() => _forceScene = scenes[sceneIndex]);
        }
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: '选择收据或交易图片',
      type: FileType.image,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.single;
    if (file.bytes != null) {
      await _loadImage(file.bytes!, file.name);
      return;
    }

    final path = file.path;
    if (path == null) return;
    await _loadImage(await File(path).readAsBytes(), file.name);
  }

  Future<void> _loadImage(Uint8List bytes, String name) async {
    setState(() {
      _imageBytes = bytes;
      _fileName = name;
    });
  }

  Future<void> _pasteImage() async {
    try {
      final image = await Pasteboard.image;
      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('剪贴板中没有图片')),
          );
        }
        return;
      }
      await _loadImage(image, 'clipboard.png');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('粘贴失败: $e')),
        );
      }
    }
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    if (details.files.isEmpty) return;
    final file = details.files.first;
    final path = file.path;
    if (path == null) return;
    final bytes = await File(path).readAsBytes();
    await _loadImage(bytes, file.name);
  }

  Future<void> _recognize() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一张图片')),
      );
      return;
    }

    final aiSettings = ref.read(settingsProvider);
    if (!aiSettings.aiAutoBookkeepingEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI 自动记账已在设置中关闭')),
      );
      return;
    }

    final bookId = ref.read(activeBookIdProvider);
    if (bookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择账本')),
      );
      return;
    }

    setState(() => _recognizing = true);

    final categories = await ref.read(allCategoriesProvider.future);
    final accounts = await ref.read(accountListForBookProvider(bookId).future);
    final service = ref.read(receiptRecognitionServiceProvider);

    final result = await service.recognize(
      imageBytes: _imageBytes!,
      fileName: _fileName ?? 'receipt.png',
      categories: categories,
      accounts: accounts,
      forceScene: _forceScene,
      forceType: _forceType,
      expenseIncomeOnly: aiSettings.aiExpenseIncomeOnly,
      enhanceOcrCrops: aiSettings.aiEnhanceOcr,
      autoMatchCategory: aiSettings.aiAutoCategory,
    );

    if (!mounted) return;
    setState(() => _recognizing = false);

    await result.when(
      success: (outcome) async {
        Navigator.of(context).pop(false);
        if (!context.mounted) return;

        if (aiSettings.aiLowConfidenceWarn && outcome.lowConfidence) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('识别置信度较低，请仔细核对金额与分类'),
            ),
          );
        }

        final duplicateBlocked =
            aiSettings.aiDuplicateCheck && outcome.duplicateSuspected;
        if (duplicateBlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('检测到可能与近期账单重复，请确认是否再次入账'),
            ),
          );
        }

        final canAutoEnter = !duplicateBlocked &&
            shouldAutoEnterAi(
              strategy: aiSettings.aiEntryStrategy,
              level: outcome.autoEntryLevel,
            );

        if (canAutoEnter) {
          final submit = await submitTransactionFromDraft(
            ref,
            draft: outcome.draft,
          );
          if (!context.mounted) return;
          if (submit.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '已自动入账：${outcome.sceneLabel} · ${_typeLabel(outcome.draft.type)}',
                ),
              ),
            );
            return;
          }
          if (!submit.missingRequired && submit.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(submit.errorMessage!)),
            );
          }
        }

        await showAddTransactionDialog(
          context,
          draft: outcome.draft,
        );
        if (!context.mounted) return;
        final dateHint = outcome.draft.date == null
            ? '未能识别交易时间，请务必手动填写'
            : '请核对后添加';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已识别为「${outcome.sceneLabel} · ${_typeLabel(outcome.draft.type)}」'
              '${outcome.draft.date != null ? ' · ${AppDateUtils.formatDateTime(outcome.draft.date!)}' : ''}，$dateHint',
            ),
          ),
        );
      },
      failure: (error) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.keyV, control: true): _PasteIntent(),
            SingleActivator(LogicalKeyboardKey.keyV, meta: true): _PasteIntent(),
          },
          child: Actions(
            actions: {
              _PasteIntent: CallbackAction<_PasteIntent>(
                onInvoke: (_) {
                  _pasteImage();
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              focusNode: _focusNode,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: const Text(
                      '本地AI识图',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: DropTarget(
                      onDragEntered: (_) => setState(() => _dragging = true),
                      onDragExited: (_) => setState(() => _dragging = false),
                      onDragDone: _handleDrop,
                      child: InkWell(
                        onTap: _recognizing ? null : _pickImage,
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 220,
                          decoration: BoxDecoration(
                            color: _dragging
                                ? AppColors.selectedBackground
                                : AppColors.panelBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _dragging
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: _dragging ? 2 : 1,
                            ),
                          ),
                          child: _imageBytes == null
                              ? _buildPlaceholder()
                              : _buildPreview(),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Text(
                      '使用本机 OCR 识别截图内容，无需联网。仅识别支出或收入，识别不准时可手动指定类型或场景。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: AppSelectField<ReceiptScene?>(
                      label: '识别场景',
                      value: _forceScene,
                      isDense: true,
                      enabled: !_recognizing,
                      options: [
                        const AppSelectOption(
                          value: null,
                          label: '自动识别（推荐）',
                        ),
                        for (final scene in ReceiptScene.values)
                          if (scene != ReceiptScene.unknown)
                            AppSelectOption(value: scene, label: scene.label),
                      ],
                      onChanged: _recognizing
                          ? null
                          : (value) => setState(() => _forceScene = value),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: AppSelectField<TransactionType?>(
                      label: '交易类型',
                      value: _forceType,
                      isDense: true,
                      enabled: !_recognizing,
                      options: const [
                        AppSelectOption(
                          value: null,
                          label: '自动识别（推荐）',
                        ),
                        AppSelectOption(
                          value: TransactionType.expense,
                          label: '支出',
                        ),
                        AppSelectOption(
                          value: TransactionType.income,
                          label: '收入',
                        ),
                      ],
                      onChanged: _recognizing
                          ? null
                          : (value) => setState(() => _forceType = value),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton(
                          onPressed: _recognizing ? null : _recognize,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 40),
                          ),
                          child: _recognizing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('识别'),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: _recognizing
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: const Text(
                            '取消',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 40,
              color: AppColors.textHint.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              '您可以拖拽、粘贴或点击选择收据或交易图片',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.memory(
            _imageBytes!,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
            ),
            onPressed: _recognizing
                ? null
                : () => setState(() {
                      _imageBytes = null;
                      _fileName = null;
                    }),
            icon: const Icon(Icons.close, size: 18),
          ),
        ),
        if (_fileName != null)
          Positioned(
            left: 12,
            bottom: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  _fileName!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _typeLabel(TransactionType? type) {
    return switch (type) {
      TransactionType.expense => '支出',
      TransactionType.income => '收入',
      TransactionType.transfer => '转账',
      null => '未知',
    };
  }
}

class _PasteIntent extends Intent {
  const _PasteIntent();
}
