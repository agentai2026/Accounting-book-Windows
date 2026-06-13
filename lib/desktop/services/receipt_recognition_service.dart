import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:mobile_ocr/mobile_ocr.dart';
import 'package:mobile_ocr/models/text_block.dart' as ocr;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:ezbookkeeping_desktop/core/ai/duplicate/duplicate_checker.dart';
import 'package:ezbookkeeping_desktop/core/ai/index.dart';
import 'package:ezbookkeeping_desktop/core/ai/parser/ocr_block_sorter.dart';
import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/ai_recognition_result.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction_form_draft.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/receipt_scene.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/ocr_params_rules.dart';
import 'package:ezbookkeeping_desktop/core/services/receipt_image_preprocessor.dart';
import 'package:ezbookkeeping_desktop/core/services/recognition_draft_formatter.dart';
import 'package:ezbookkeeping_desktop/core/utils/ai_match_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';

class ReceiptRecognitionOutcome {
  const ReceiptRecognitionOutcome({
    required this.draft,
    required this.sourceLabel,
    required this.sceneLabel,
    required this.confidence,
    this.lowConfidence = false,
    this.duplicateSuspected = false,
    this.autoEntryLevel = BillAutoEntryLevel.manual,
  });

  final TransactionFormDraft draft;
  final String sourceLabel;
  final String sceneLabel;
  final double confidence;
  final bool lowConfidence;
  final bool duplicateSuspected;
  final BillAutoEntryLevel autoEntryLevel;
}

class ReceiptRecognitionService {
  ReceiptRecognitionService({
    MobileOcr? mobileOcr,
    BillParser? billParser,
    BillRecognitionMapper? billMapper,
    RecognitionDraftFormatter? draftFormatter,
    ReceiptImagePreprocessor? imagePreprocessor,
  })  : _mobileOcr = mobileOcr ?? MobileOcr(),
        _billParser = billParser ?? BillParser(),
        _billMapper = billMapper ?? const BillRecognitionMapper(),
        _draftFormatter = draftFormatter ?? const RecognitionDraftFormatter(),
        _imagePreprocessor =
            imagePreprocessor ?? const ReceiptImagePreprocessor();

  final MobileOcr _mobileOcr;
  final BillParser _billParser;
  final BillRecognitionMapper _billMapper;
  final RecognitionDraftFormatter _draftFormatter;
  final ReceiptImagePreprocessor _imagePreprocessor;
  final OcrBlockSorter _blockSorter = const OcrBlockSorter();
  bool _ocrReady = false;

  Future<Result<ReceiptRecognitionOutcome>> recognize({
    required Uint8List imageBytes,
    required String fileName,
    required List<Category> categories,
    required List<Account> accounts,
    ReceiptScene? forceScene,
    TransactionType? forceType,
    bool expenseIncomeOnly = true,
    bool enhanceOcrCrops = true,
    bool autoMatchCategory = true,
    List<ExistingBillSummary> existingBills = const [],
  }) async {
    AiRecognitionResult? best;
    Bill? parsedBill;
    String? ocrText;
    String? ocrError;

    try {
      final blocks = await _recognizeBlocks(
        imageBytes,
        enhanceOcrCrops: enhanceOcrCrops,
      );
      final lines = _blockSorter.toLines(blocks);
      ocrText = _blockSorter.joinText(lines);
      appLogger.d('OCR 块数: ${blocks.length}');
      appLogger.d('OCR 文本:\n$ocrText');

      parsedBill = _billParser.parseBillFromOCR(
        blocks,
        options: BillParserOptions(
          expenseIncomeOnly: expenseIncomeOnly,
          forceScene: forceScene,
          forceType: forceType,
          existingBills: existingBills,
        ),
      );

      if (parsedBill != null) {
        best = _normalizeForAiRecognition(
          _billMapper.toRecognitionResult(parsedBill),
        );
        appLogger.d(
          '规则引擎: ${parsedBill.platform?.label ?? '未知'} '
          '置信度 ${parsedBill.confidence.toStringAsFixed(0)} '
          '级别 ${parsedBill.autoEntryLevel.name}',
        );
        appLogger.d('识别类型: ${best.type.name}');
      }
    } catch (e, stack) {
      ocrError = e.toString();
      appLogger.w('本地 OCR 失败', error: e, stackTrace: stack);
    }

    if (best == null) {
      final hint = ocrError != null
          ? '本机 OCR 初始化失败：$ocrError'
          : (ocrText == null || ocrText.trim().isEmpty)
              ? '未能从图片中识别文字，请换一张更清晰的截图'
              : '已识别文字但无法提取金额，请手动填写'
                  '${ocrText != null ? '\n识别内容：${ocrText.length > 200 ? '${ocrText.substring(0, 200)}…' : ocrText}' : ''}';
      return Result.failure(
        AppException(hint, code: 'RECOGNITION_FAILED'),
      );
    }

    final draft = _draftFormatter.formatDraft(
      draft: _toDraft(
        recognition: best,
        categories: categories,
        accounts: accounts,
        imageBytes: imageBytes,
        fileName: fileName,
        autoMatchCategory: autoMatchCategory,
      ),
      recognition: best,
    );

    return Result.success(
      ReceiptRecognitionOutcome(
        draft: draft,
        sourceLabel: '本机 OCR + 规则引擎',
        sceneLabel: best.scene.label,
        confidence: best.confidence,
        lowConfidence: best.lowConfidence,
        duplicateSuspected: parsedBill?.duplicateSuspected ?? false,
        autoEntryLevel: parsedBill?.autoEntryLevel ?? BillAutoEntryLevel.manual,
      ),
    );
  }

  Future<void> _ensureOcrReady() async {
    if (_ocrReady) return;
    final status = await _mobileOcr.prepareModels();
    if (!status.isReady) {
      _ocrReady = false;
      throw StateError(
        status.errorMessage ?? 'OCR 模型未就绪，请完全重启应用后再试',
      );
    }
    _ocrReady = true;
  }

  Future<List<OcrBlock>> _recognizeBlocks(
    Uint8List imageBytes, {
    required bool enhanceOcrCrops,
  }) async {
    await _ensureOcrReady();

    final decoded = img.decodeImage(imageBytes);

    // 1) 原图内存识别（手机截图最稳）
    if (decoded != null) {
      final original = await _detectBlocksFromImage(
        decoded,
        enhanceOcrCrops: enhanceOcrCrops,
      );
      appLogger.d('原图内存 OCR 块数: ${original.length}');
      if (original.isNotEmpty) return original;
      appLogger.d('原图 OCR 无结果，尝试预处理后识别');
    }

    // 2) 预处理后内存识别
    if (decoded != null) {
      try {
        final processed = _imagePreprocessor.process(decoded);
        final processedBlocks = await _detectBlocksFromImage(
          processed,
          enhanceOcrCrops: enhanceOcrCrops,
        );
        appLogger.d('预处理内存 OCR 块数: ${processedBlocks.length}');
        if (processedBlocks.isNotEmpty) return processedBlocks;
      } catch (e, stack) {
        appLogger.w('预处理后 detectTextFromImage 失败',
            error: e, stackTrace: stack);
      }
    }

    // 3) 临时文件识别（先原图，再预处理）
    appLogger.d('改用临时文件 OCR');
    final viaFile = await _recognizeBlocksViaTempFile(
      imageBytes,
      decoded,
      enhanceOcrCrops: enhanceOcrCrops,
    );
    appLogger.d('临时文件 OCR 块数: ${viaFile.length}');
    return viaFile;
  }

  Future<List<OcrBlock>> _detectBlocksFromImage(
    img.Image image, {
    required bool enhanceOcrCrops,
  }) async {
    final blocks = await _mobileOcr.detectTextFromImage(
      image: image,
      includeAllConfidenceScores: kReceiptOcrIncludeAllConfidenceScores,
      enhanceRecognitionCrops: enhanceOcrCrops,
      recognitionContrastBoost: kReceiptOcrRecognitionContrastBoost,
      recognitionBrightnessBoost: kReceiptOcrRecognitionBrightnessBoost,
    );
    return _toOcrBlocks(blocks);
  }

  Future<List<OcrBlock>> _recognizeBlocksViaTempFile(
    Uint8List imageBytes,
    img.Image? decoded, {
    required bool enhanceOcrCrops,
  }) async {
    final tempDir = await getTemporaryDirectory();

    Future<List<OcrBlock>> runFile(List<int> bytes) async {
      final tempFile = File(
        p.join(
          tempDir.path,
          'ezb_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      await tempFile.writeAsBytes(bytes);
      try {
        final blocks = await _mobileOcr.detectText(
          imagePath: tempFile.path,
          includeAllConfidenceScores: kReceiptOcrIncludeAllConfidenceScores,
          enhanceRecognitionCrops: enhanceOcrCrops,
          recognitionContrastBoost: kReceiptOcrRecognitionContrastBoost,
          recognitionBrightnessBoost: kReceiptOcrRecognitionBrightnessBoost,
        );
        return _toOcrBlocks(blocks);
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    }

    if (decoded != null) {
      final original = await runFile(img.encodeJpg(decoded));
      if (original.isNotEmpty) return original;

      final processed = _imagePreprocessor.process(decoded);
      final processedResult = await runFile(img.encodeJpg(processed));
      if (processedResult.isNotEmpty) return processedResult;
    }

    return runFile(imageBytes);
  }

  List<OcrBlock> _toOcrBlocks(List<ocr.TextBlock> blocks) {
    return blocks
        .map(
          (block) => OcrBlock(
            text: block.text,
            score: block.confidence,
            box: [
              block.boundingBox.left,
              block.boundingBox.top,
              block.boundingBox.right,
              block.boundingBox.bottom,
            ],
          ),
        )
        .toList(growable: false);
  }

  AiRecognitionResult _normalizeForAiRecognition(AiRecognitionResult raw) {
    var type = raw.type;
    if (type == TransactionType.transfer) {
      type = raw.tagNames.contains('收入')
          ? TransactionType.income
          : TransactionType.expense;
    }

    var categoryName = raw.categoryName;
    if (categoryName != null &&
        (categoryName.contains('转账') || categoryName == '银行转账')) {
      categoryName =
          type == TransactionType.income ? '其他收入' : '其他支出';
    }

    final tags = <String>[
      for (final tag in raw.tagNames)
        if (tag != '转账') tag,
    ];
    tags.removeWhere((tag) => tag == '支出' || tag == '收入');
    tags.add(type == TransactionType.income ? '收入' : '支出');

    var description = raw.description;
    if (description == '转账') {
      description = raw.payer;
    }

    return AiRecognitionResult(
      type: type,
      amountCents: raw.amountCents,
      categoryName: categoryName,
      description: description,
      payer: raw.payer,
      date: raw.date,
      accountName: raw.accountName,
      balanceCents: raw.balanceCents,
      scene: raw.scene,
      sceneScore: raw.sceneScore,
      tagNames: tags,
      confidence: raw.confidence,
      rawText: raw.rawText,
      currency: raw.currency,
      primaryCategory: raw.primaryCategory,
      secondaryCategory: raw.secondaryCategory,
      lowConfidence: raw.lowConfidence,
    );
  }

  TransactionFormDraft _toDraft({
    required AiRecognitionResult recognition,
    required List<Category> categories,
    required List<Account> accounts,
    required Uint8List imageBytes,
    required String fileName,
    bool autoMatchCategory = true,
  }) {
    final categoryId = autoMatchCategory
        ? matchCategoryIdByName(
            name: recognition.categoryName,
            categories: categories,
            transactionType: recognition.type,
          )
        : null;
    final accountId = matchAccountIdByName(
      name: recognition.accountName,
      accounts: accounts,
    );

    int? fromAccountId;
    int? toAccountId;
    switch (recognition.type) {
      case TransactionType.expense:
        fromAccountId =
            accountId ?? (accounts.isNotEmpty ? accounts.first.id : null);
      case TransactionType.income:
        toAccountId =
            accountId ?? (accounts.isNotEmpty ? accounts.first.id : null);
      case TransactionType.transfer:
        fromAccountId = accounts.isNotEmpty ? accounts.first.id : null;
        toAccountId = accounts.length > 1 ? accounts[1].id : fromAccountId;
    }

    return TransactionFormDraft(
      type: recognition.type,
      amountText: MoneyUtils.formatInputAmount(recognition.amountCents),
      categoryId: categoryId,
      categoryName: recognition.categoryName,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      accountName: recognition.accountName,
      date: recognition.date,
      description: recognition.description,
      payer: recognition.payer,
      tagNames: recognition.tagNames,
      imageBytes: imageBytes,
      imageFileName: fileName,
      expenseIncomeOnly: true,
      fromAi: true,
    );
  }
}
