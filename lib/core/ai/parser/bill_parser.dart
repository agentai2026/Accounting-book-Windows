import 'package:uuid/uuid.dart';

import 'package:ezbookkeeping_desktop/core/ai/classifier/category_classifier.dart';
import 'package:ezbookkeeping_desktop/core/ai/confidence/confidence_scorer.dart';
import 'package:ezbookkeeping_desktop/core/ai/duplicate/duplicate_checker.dart';
import 'package:ezbookkeeping_desktop/core/ai/models/bill.dart';
import 'package:ezbookkeeping_desktop/core/ai/models/bill_platform.dart';
import 'package:ezbookkeeping_desktop/core/ai/models/ocr_block.dart';
import 'package:ezbookkeeping_desktop/core/ai/models/ocr_line.dart';
import 'package:ezbookkeeping_desktop/core/ai/normalize/text_normalizer.dart';
import 'package:ezbookkeeping_desktop/core/ai/parser/amount_parser.dart';
import 'package:ezbookkeeping_desktop/core/ai/parser/date_parser.dart';
import 'package:ezbookkeeping_desktop/core/ai/parser/merchant_parser.dart';
import 'package:ezbookkeeping_desktop/core/ai/parser/ocr_block_sorter.dart';
import 'package:ezbookkeeping_desktop/core/ai/parser/scene_detector.dart';
import 'package:ezbookkeeping_desktop/core/ai/parser/type_parser.dart';
import 'package:ezbookkeeping_desktop/core/models/ai_recognition_result.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/receipt_scene.dart';
import 'package:ezbookkeeping_desktop/core/services/receipt_text_parser.dart';

/// 规则引擎解析选项
class BillParserOptions {
  const BillParserOptions({
    this.expenseIncomeOnly = true,
    this.exifDateTime,
    this.existingBills = const [],
    this.forceScene,
    this.forceType,
  });

  /// AI 识图：仅支出/收入
  final bool expenseIncomeOnly;
  final String? exifDateTime;
  final List<ExistingBillSummary> existingBills;
  final ReceiptScene? forceScene;
  final TransactionType? forceType;
}

/// OCR 后处理规则引擎主入口
class BillParser {
  BillParser({
    TextNormalizer? normalizer,
    OcrBlockSorter? sorter,
    SceneDetector? sceneDetector,
    AmountParser? amountParser,
    MerchantParser? merchantParser,
    DateParser? dateParser,
    TypeParser? typeParser,
    CategoryClassifier? categoryClassifier,
    DuplicateChecker? duplicateChecker,
    ConfidenceScorer? confidenceScorer,
    ReceiptTextParser? paymentParser,
  })  : _normalizer = normalizer ?? const TextNormalizer(),
        _sorter = sorter ?? const OcrBlockSorter(),
        _sceneDetector = sceneDetector ?? const SceneDetector(),
        _amountParser = amountParser ?? const AmountParser(),
        _merchantParser = merchantParser ?? const MerchantParser(),
        _dateParser = dateParser ?? const DateParser(),
        _typeParser = typeParser ?? const TypeParser(),
        _categoryClassifier = categoryClassifier ?? CategoryClassifier(),
        _duplicateChecker = duplicateChecker ?? const DuplicateChecker(),
        _confidenceScorer = confidenceScorer ?? const ConfidenceScorer(),
        _paymentParser = paymentParser ?? const ReceiptTextParser();

  final TextNormalizer _normalizer;
  final OcrBlockSorter _sorter;
  final SceneDetector _sceneDetector;
  final AmountParser _amountParser;
  final MerchantParser _merchantParser;
  final DateParser _dateParser;
  final TypeParser _typeParser;
  final CategoryClassifier _categoryClassifier;
  final DuplicateChecker _duplicateChecker;
  final ConfidenceScorer _confidenceScorer;
  final ReceiptTextParser _paymentParser;

  static const _uuid = Uuid();

  /// 从 OCR 块列表生成账单（主流程）
  Bill? parseBillFromOCR(
    List<OcrBlock> blocks, {
    BillParserOptions options = const BillParserOptions(),
  }) {
    if (blocks.isEmpty) return null;

    final rawLines = _sorter.toLines(blocks);
    if (rawLines.isEmpty) return null;

    final lines = rawLines
        .map(
          (line) => AiOcrLine(
            text: _normalizer.normalize(line.text),
            score: line.score,
            boundingBox: line.boundingBox,
            index: line.index,
          ),
        )
        .toList(growable: false);

    final rawText = _sorter.joinText(lines);
    final scene = _sceneDetector.detect(rawText, lines);

    if (_shouldTryPaymentScreenshot(rawText, scene, options)) {
      final paymentBill = _parsePaymentScreenshot(
        rawText: rawText,
        scene: scene,
        options: options,
      );
      if (paymentBill != null) return paymentBill;
      if (_shouldAbortAfterPaymentParseFailure(rawText, scene, options)) {
        return null;
      }
    }

    return _parseReceiptBill(
      lines: lines,
      rawText: rawText,
      scene: scene,
      options: options,
    );
  }

  Bill? _parsePaymentScreenshot({
    required String rawText,
    required SceneDetectResult scene,
    required BillParserOptions options,
  }) {
    final result = _paymentParser.parseForRecognition(
          rawText,
          forceScene: options.forceScene,
          forceType: options.forceType,
        ) ??
        _paymentParser.parseLenientForRecognition(
          rawText,
          forceScene: options.forceScene,
          forceType: options.forceType,
        );

    if (result == null) return null;
    return _billFromRecognitionResult(
      result,
      platform: scene.platform,
      rawText: rawText,
      options: options,
    );
  }

  Bill? _parseReceiptBill({
    required List<AiOcrLine> lines,
    required String rawText,
    required SceneDetectResult scene,
    required BillParserOptions options,
  }) {
    final amountResult = _amountParser.extractAmount(lines);
    if (amountResult == null) return null;

    final merchant = _merchantParser.extractMerchant(lines);
    final dateResult = _dateParser.extractDate(
      lines,
      exifDateTime: options.exifDateTime,
    );

    var billType = _typeParser.extractType(
      lines,
      amountLineIndex: amountResult.lineIndex,
    );
    billType = normalizeBankTransferType(lines, billType);
    if (options.expenseIncomeOnly) {
      billType = billType == BillType.income
          ? BillType.income
          : BillType.expense;
    }

    final category = _categoryClassifier.classifyCategory(
      merchant: merchant,
      type: billType,
    );

    final breakdown = _confidenceScorer.score(
      amount: amountResult,
      merchant: merchant,
      date: dateResult,
      categoryMatched:
          category.matchedBy != CategoryMatchSource.defaultFallback,
    );

    final totalScore = breakdown.total;
    final dateStr = dateResult?.date ?? _todayString();
    final hash = _duplicateChecker.buildHash(
      merchant: merchant,
      amount: amountResult.amount,
      date: dateStr,
    );

    final bill = Bill(
      id: _uuid.v4(),
      type: billType,
      amount: amountResult.amount,
      merchant: merchant,
      category: category.appCategory,
      date: dateStr,
      time: dateResult?.time,
      platform: scene.platform == BillPlatform.unknown
          ? BillPlatform.receipt
          : scene.platform,
      confidence: totalScore,
      hash: hash,
      rawText: rawText,
      primaryCategory: category.primaryCategory,
      secondaryCategory: category.secondaryCategory,
      autoEntryLevel: _confidenceScorer.entryLevel(totalScore),
    );

    return _applyDuplicateCheck(bill, options, rawText);
  }

  Bill _billFromRecognitionResult(
    AiRecognitionResult result, {
    required BillPlatform platform,
    required String rawText,
    required BillParserOptions options,
  }) {
    var billType = _mapTransactionType(result.type);
    if (options.expenseIncomeOnly && billType == BillType.transfer) {
      billType = result.tagNames.contains('收入')
          ? BillType.income
          : BillType.expense;
    }

    final merchant = result.payer ?? '';
    final amount = result.amountCents / 100.0;
    final dateStr = result.date != null
        ? '${result.date!.year.toString().padLeft(4, '0')}-'
            '${result.date!.month.toString().padLeft(2, '0')}-'
            '${result.date!.day.toString().padLeft(2, '0')}'
        : _todayString();
    final timeStr = result.date != null
        ? '${result.date!.hour.toString().padLeft(2, '0')}:'
            '${result.date!.minute.toString().padLeft(2, '0')}'
        : null;

    final categoryName = result.categoryName ?? '其他支出';
    final score = (result.confidence * 100).clamp(0, 100).toDouble();

    final bill = Bill(
      id: _uuid.v4(),
      type: billType,
      amount: double.parse(amount.toStringAsFixed(2)),
      merchant: merchant,
      category: categoryName,
      date: dateStr,
      time: timeStr,
      platform: platform,
      confidence: score,
      hash: _duplicateChecker.buildHash(
        merchant: merchant,
        amount: amount,
        date: dateStr,
      ),
      rawText: rawText,
      primaryCategory: result.primaryCategory,
      secondaryCategory: result.secondaryCategory,
      autoEntryLevel: _confidenceScorer.entryLevel(score),
    );

    return _applyDuplicateCheck(bill, options, rawText);
  }

  Bill _applyDuplicateCheck(
    Bill bill,
    BillParserOptions options,
    String rawText,
  ) {
    if (options.existingBills.isEmpty) return bill;
    final dup = _duplicateChecker.checkDuplicate(
      candidate: bill,
      existing: options.existingBills,
      ocrRawText: rawText,
    );
    if (!dup.isDuplicate) return bill;
    return Bill(
      id: bill.id,
      type: bill.type,
      amount: bill.amount,
      merchant: bill.merchant,
      category: bill.category,
      date: bill.date,
      time: bill.time,
      platform: bill.platform,
      confidence: bill.confidence,
      hash: bill.hash,
      rawText: bill.rawText,
      primaryCategory: bill.primaryCategory,
      secondaryCategory: bill.secondaryCategory,
      duplicateSuspected: true,
      autoEntryLevel: BillAutoEntryLevel.confirm,
    );
  }

  BillType _mapTransactionType(TransactionType type) {
    return switch (type) {
      TransactionType.expense => BillType.expense,
      TransactionType.income => BillType.income,
      TransactionType.transfer => BillType.transfer,
    };
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// 支付/账单截图优先走 ReceiptTextParser（阈值与场景分类器对齐 0.35）
  bool _shouldTryPaymentScreenshot(
    String rawText,
    SceneDetectResult scene,
    BillParserOptions options,
  ) {
    if (options.forceScene != null &&
        options.forceScene != ReceiptScene.paperReceipt) {
      return true;
    }
    if (scene.receiptScene != ReceiptScene.unknown &&
        scene.sceneScore >= 0.35) {
      return true;
    }
    return _hasPaymentScreenshotSignals(rawText);
  }

  /// 支付截图专用解析失败后，不应落入小票分支误取标题数字
  bool _shouldAbortAfterPaymentParseFailure(
    String rawText,
    SceneDetectResult scene,
    BillParserOptions options,
  ) {
    if (options.forceScene != null &&
        options.forceScene != ReceiptScene.paperReceipt) {
      return true;
    }
    if (scene.receiptScene != ReceiptScene.unknown &&
        scene.receiptScene != ReceiptScene.paperReceipt) {
      return true;
    }
    return _hasPaymentScreenshotSignals(rawText);
  }

  bool _hasPaymentScreenshotSignals(String text) {
    const signals = [
      '支付成功',
      '支付时间',
      '账单详情',
      '交易成功',
      '付款成功',
      '当前状态',
      '收单机构',
      '财付通',
      '全部账单',
      '商户全称',
      '付款方式',
      '支付方式',
      '交易单号',
      '商户单号',
      '支出(元)',
      '收入(元)',
      '转账-',
      '借记卡',
      '储蓄卡',
      '余额：',
      '余额:',
    ];
    return signals.any(text.contains);
  }
}
