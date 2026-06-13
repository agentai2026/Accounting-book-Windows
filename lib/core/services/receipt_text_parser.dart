import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/date_label_rules.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/income_category_rules.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/merchant_category_rules.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/ocr_correction_rules.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/type_detection_rules.dart';
import 'package:ezbookkeeping_desktop/core/models/ai_recognition_result.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/receipt_scene.dart';
import 'package:ezbookkeeping_desktop/core/services/receipt_ocr_text_corrector.dart';
import 'package:ezbookkeeping_desktop/core/services/receipt_scene_classifier.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';

/// 从 OCR 文本解析微信/支付宝/银行账单截图（纯本地，无需 API）
class ReceiptTextParser {
  const ReceiptTextParser({
    ReceiptSceneClassifier? sceneClassifier,
    ReceiptOcrTextCorrector? ocrCorrector,
  })  : _sceneClassifier = sceneClassifier ?? const ReceiptSceneClassifier(),
        _ocrCorrector = ocrCorrector ?? const ReceiptOcrTextCorrector();

  final ReceiptSceneClassifier _sceneClassifier;
  final ReceiptOcrTextCorrector _ocrCorrector;

  AiRecognitionResult? parse(
    String rawText, {
    ReceiptScene? forceScene,
    TransactionType? forceType,
    bool expenseIncomeOnly = false,
  }) {
    return _parseInternal(
      rawText,
      forceScene: forceScene,
      forceType: forceType,
      expenseIncomeOnly: expenseIncomeOnly,
      confidenceCap: 1,
    );
  }

  /// AI 识图专用：只输出支出 / 收入，不输出转账
  AiRecognitionResult? parseForRecognition(
    String rawText, {
    ReceiptScene? forceScene,
    TransactionType? forceType,
  }) {
    return parse(
      rawText,
      forceScene: forceScene,
      forceType: forceType,
      expenseIncomeOnly: true,
    );
  }

  /// 宽松解析：尽量从 OCR 文本中提取可用字段
  AiRecognitionResult? parseLenient(
    String rawText, {
    ReceiptScene? forceScene,
    TransactionType? forceType,
    bool expenseIncomeOnly = false,
  }) {
    return _parseInternal(
      rawText,
      forceScene: forceScene,
      forceType: forceType,
      expenseIncomeOnly: expenseIncomeOnly,
      confidenceCap: 0.62,
    );
  }

  AiRecognitionResult? parseLenientForRecognition(
    String rawText, {
    ReceiptScene? forceScene,
    TransactionType? forceType,
  }) {
    return parseLenient(
      rawText,
      forceScene: forceScene,
      forceType: forceType,
      expenseIncomeOnly: true,
    );
  }

  AiRecognitionResult? _parseInternal(
    String rawText, {
    ReceiptScene? forceScene,
    TransactionType? forceType,
    bool expenseIncomeOnly = false,
    required double confidenceCap,
  }) {
    final text = _normalizeOcrText(rawText);
    if (text.isEmpty) return null;

    final lines = _splitLines(text);
    final sceneMatch = _resolveSceneMatch(text, lines, forceScene: forceScene);
    final scene = sceneMatch.scene;
    final normalizedForceType = expenseIncomeOnly
        ? _normalizeForceTypeForRecognition(forceType)
        : forceType;
    final type = normalizedForceType ??
        _resolveTransactionType(
          scene,
          text,
          lines,
          expenseIncomeOnly: expenseIncomeOnly,
        );

    var amountCents = _detectAmountForBankScene(text, lines, type, scene);
    amountCents ??= _detectAmountCents(text, lines, type);
    amountCents ??= _detectAmountForType(text, lines, type);
    if (amountCents == null || amountCents <= 0) return null;

    return _buildResult(
      text: text,
      lines: lines,
      type: type,
      amountCents: amountCents,
      sceneMatch: sceneMatch,
      confidenceCap: confidenceCap,
    );
  }

  AiRecognitionResult _buildResult({
    required String text,
    required List<String> lines,
    required TransactionType type,
    required int amountCents,
    required ReceiptSceneMatch sceneMatch,
    double confidenceCap = 1,
  }) {
    final scene = sceneMatch.scene;
    final resolvedType = type;
    final payer = _detectPayerForScene(scene, lines) ?? _detectPayer(lines);
    var date = _detectDateForScene(scene, text, lines);
    if (date == null &&
        scene != ReceiptScene.bankMonthlyBill &&
        scene != ReceiptScene.bankCardDetail) {
      date = _detectDate(text, lines);
    }
    final accountName =
        _detectAccountForScene(scene, lines) ?? _detectAccountName(lines);
    final balanceCents = _detectBalanceCents(lines);
    var description = _detectDescriptionForScene(scene, lines, payer: payer) ??
        _detectDescription(lines, payer: payer);

    if (description == null && balanceCents != null) {
      description = '余额 ${MoneyUtils.format(balanceCents)}';
    }

    var confidence = _estimateConfidence(text, amountCents, resolvedType);
    if (sceneMatch.isConfident) confidence += 0.08;
    if (payer != null) confidence += 0.04;
    if (date != null) confidence += 0.04;
    if (accountName != null) confidence += 0.03;
    confidence = confidence.clamp(0.0, confidenceCap).toDouble();

    final tags = _detectTags(text, lines, resolvedType, scene: scene);

    return AiRecognitionResult(
      type: resolvedType,
      amountCents: amountCents,
      categoryName: _guessCategoryName(text, lines, resolvedType, scene: scene),
      description: description,
      payer: payer,
      date: date,
      accountName: accountName,
      balanceCents: balanceCents,
      scene: scene,
      sceneScore: sceneMatch.score,
      tagNames: tags,
      confidence: confidence,
    );
  }

  bool _isRefundOrCreditReceipt(String text, List<String> lines) {
    if (RegExp(r'退款成功|实退|已退款|退款到账').hasMatch(text)) {
      return true;
    }
    if (RegExp(r'实收').hasMatch(text) && _lineHasIncomeSignInAnyLine(lines)) {
      return true;
    }
    return false;
  }

  bool _lineHasExpenseSignInAnyLine(List<String> lines) {
    for (final line in lines) {
      if (_lineHasExpenseSign(line)) return true;
    }
    return false;
  }

  /// 严格判定：支出 / 收入 / 转账 三选一（AI 识图时仅支出/收入）
  TransactionType _resolveTransactionType(
    ReceiptScene scene,
    String text,
    List<String> lines, {
    bool expenseIncomeOnly = false,
  }) {
    if (expenseIncomeOnly) {
      final signType = _detectTypeFromAmountSigns(lines);
      if (signType != null) return signType;

      if (_isRefundOrCreditReceipt(text, lines)) {
        return TransactionType.income;
      }

      final sceneType =
          _detectTypeForScene(scene, text, lines, expenseIncomeOnly: true);
      if (sceneType != null) return sceneType;

      if (_isIncomeContext(text, lines)) return TransactionType.income;
      if (_isExpenseContext(text, lines)) return TransactionType.expense;

      return TransactionType.expense;
    }

    if (_hasTransferLine(lines)) {
      return TransactionType.transfer;
    }

    final sceneType = _detectTypeForScene(scene, text, lines);
    if (sceneType != null) return sceneType;

    final signType = _detectTypeFromAmountSigns(lines);
    if (signType != null) return signType;

    if (_hasExplicitTransferAction(text, lines)) {
      return TransactionType.transfer;
    }

    return _detectTypeStrict(text, lines);
  }

  TransactionType? _normalizeForceTypeForRecognition(TransactionType? forceType) {
    if (forceType == null || forceType == TransactionType.transfer) {
      return null;
    }
    return forceType;
  }

  /// 仅认「转账-某某 / 转账给 / 向对方转账」等明确动作，不认「转账备注」「再转一笔」
  bool _hasExplicitTransferAction(String text, List<String> lines) {
    for (final keyword in kReceiptExplicitTransferKeywords) {
      if (text.contains(keyword)) return true;
    }
    return lines.any((line) {
      final trimmed = line.trim();
      return RegExp(r'^转账给\s*.+').hasMatch(trimmed) ||
          RegExp(r'^向对方转账').hasMatch(trimmed);
    });
  }

  bool _isTransferLabelOnly(String text) {
    return kReceiptTransferLabelOnlyKeywords.any(text.contains);
  }

  TransactionType? _detectTypeFromAmountSigns(List<String> lines) {
    var hasExpense = false;
    var hasIncome = false;
    for (final line in lines) {
      if (_isBalanceLine(line) || _isIgnoredAmountLine(line)) continue;
      if (_lineHasExpenseSign(line)) hasExpense = true;
      if (_lineHasIncomeSign(line)) hasIncome = true;
    }
    if (hasExpense && !hasIncome) return TransactionType.expense;
    if (hasIncome && !hasExpense) return TransactionType.income;
    if (hasExpense && hasIncome) return TransactionType.expense;
    return null;
  }

  bool _hasTransferLine(List<String> lines) {
    return lines.any((line) => RegExp(r'转账[-—]').hasMatch(line.trim()));
  }

  /// 银行月账单：优先转账行旁带符号金额，再月汇总行，避免把年份当金额
  int? _detectAmountForBankScene(
    String text,
    List<String> lines,
    TransactionType type,
    ReceiptScene scene,
  ) {
    if (scene != ReceiptScene.bankMonthlyBill &&
        scene != ReceiptScene.bankCardDetail) {
      return null;
    }

    return _detectSignedAmount(lines, type) ??
        _extractAmountNearTransfer(lines, type) ??
        _extractFromSplitSummaryLines(lines, type) ??
        _extractFromSummaryText(text, type);
  }

  TransactionType? _detectTypeForScene(
    ReceiptScene scene,
    String text,
    List<String> lines, {
    bool expenseIncomeOnly = false,
  }) {
    return switch (scene) {
      ReceiptScene.bankMonthlyBill =>
        _detectBankMonthlyType(text, lines, expenseIncomeOnly: expenseIncomeOnly),
      ReceiptScene.wechatPayment => TransactionType.expense,
      ReceiptScene.wechatTransferIncome => TransactionType.income,
      ReceiptScene.wechatTransferExpense => expenseIncomeOnly
          ? TransactionType.expense
          : TransactionType.transfer,
      ReceiptScene.alipayPayment => TransactionType.expense,
      ReceiptScene.alipayTransfer => _detectAlipayTransferType(
          text,
          lines,
          expenseIncomeOnly: expenseIncomeOnly,
        ),
      ReceiptScene.bankCardDetail => _detectBankCardDetailType(
          text,
          lines,
          expenseIncomeOnly: expenseIncomeOnly,
        ),
      ReceiptScene.paperReceipt => null,
      ReceiptScene.unknown => null,
    };
  }

  TransactionType _detectAlipayTransferType(
    String text,
    List<String> lines, {
    bool expenseIncomeOnly = false,
  }) {
    if (_lineHasIncomeSignInAnyLine(lines) ||
        RegExp(r'向你转账|转账给你|收款').hasMatch(text)) {
      return TransactionType.income;
    }
    if (!expenseIncomeOnly &&
        (_hasTransferLine(lines) || _hasExplicitTransferAction(text, lines))) {
      return TransactionType.transfer;
    }
    return TransactionType.expense;
  }

  TransactionType _detectBankCardDetailType(
    String text,
    List<String> lines, {
    bool expenseIncomeOnly = false,
  }) {
    if (!expenseIncomeOnly && _hasTransferLine(lines)) {
      return TransactionType.transfer;
    }
    for (final line in lines) {
      if (_isBalanceLine(line)) continue;
      if (_lineHasIncomeSign(line)) return TransactionType.income;
      if (_lineHasExpenseSign(line)) return TransactionType.expense;
    }
    if (expenseIncomeOnly) {
      if (_isIncomeContext(text, lines)) return TransactionType.income;
      if (_isExpenseContext(text, lines)) return TransactionType.expense;
      return TransactionType.expense;
    }
    return _detectTypeStrict(text, lines);
  }

  TransactionType _detectBankMonthlyType(
    String text,
    List<String> lines, {
    bool expenseIncomeOnly = false,
  }) {
    if (!expenseIncomeOnly && _hasTransferLine(lines)) {
      return TransactionType.transfer;
    }

    for (final line in lines) {
      if (_isBalanceLine(line)) continue;
      if (_lineHasIncomeSign(line)) return TransactionType.income;
      if (_lineHasExpenseSign(line)) return TransactionType.expense;
    }

    final inferred = _inferTypeFromSplitSummary(lines);
    if (inferred != null) return inferred;

    if (_isIncomeContext(text, lines)) return TransactionType.income;
    if (_isExpenseContext(text, lines)) return TransactionType.expense;

    return TransactionType.expense;
  }

  /// 月账单「5417.00 0.00」+ 下一行「支出 收入」：判断哪列有值
  TransactionType? _inferTypeFromSplitSummary(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.contains('支出') && !line.contains('收入')) continue;

      final amountLine = i > 0 ? lines[i - 1] : null;
      if (amountLine == null ||
          _isBalanceLine(amountLine) ||
          _isHeaderOrYearLine(amountLine)) {
        continue;
      }

      final amounts = _extractPositiveAmountsFromLine(amountLine);
      if (amounts.isEmpty) continue;

      amounts.sort();
      if (line.contains('支出') && line.contains('收入')) {
        if (amounts.length >= 2) {
          final expense = amounts.first;
          final income = amounts.last;
          if (expense > 0 && income <= 0) return TransactionType.expense;
          if (income > 0 && expense <= 0) return TransactionType.income;
          if (expense > income) return TransactionType.expense;
          if (income > expense) return TransactionType.income;
        }
      }
      if (line.contains('收入') && !line.contains('支出')) {
        return TransactionType.income;
      }
      if (line.contains('支出') && !line.contains('收入')) {
        return TransactionType.expense;
      }
    }
    return null;
  }

  bool _lineHasIncomeSignInAnyLine(List<String> lines) {
    for (final line in lines) {
      if (_lineHasIncomeSign(line)) return true;
    }
    return false;
  }

  bool _isIncomeContext(String text, List<String> lines) {
    // 商家「152xxx已收款」是用户支出，不是用户收入
    if (RegExp(r'已收款').hasMatch(text) &&
        !RegExp(r'向你转账|转账给你|二维码收款|收款成功').hasMatch(text)) {
      for (final line in lines) {
        if (_lineHasIncomeSign(line)) return true;
      }
      return false;
    }

    if (kReceiptIncomeContextKeywords.any(text.contains)) {
      return true;
    }
    for (final line in lines) {
      if (_lineHasIncomeSign(line)) return true;
    }
    if (_containsStandaloneKeyword(text, '收入')) return true;
    return false;
  }

  bool _isExpenseContext(String text, List<String> lines) {
    if (kReceiptExpenseContextKeywords.any(text.contains)) {
      return true;
    }
    for (final line in lines) {
      if (_lineHasExpenseSign(line)) return true;
    }
    if (_containsStandaloneKeyword(text, '支出')) return true;
    return false;
  }

  /// 避免月账单页眉同时含「支出」「收入」列标题时误判
  bool _containsStandaloneKeyword(String text, String keyword) {
    if (!text.contains(keyword)) return false;
    if (keyword == '收入' && text.contains('支出')) {
      return RegExp(r'[+\＋]').hasMatch(text);
    }
    if (keyword == '支出' && text.contains('收入')) {
      return RegExp(r'[-－]').hasMatch(text);
    }
    return true;
  }

  TransactionType _detectTypeStrict(String text, List<String> lines) {
    if (_hasTransferLine(lines)) return TransactionType.transfer;

    for (final line in lines) {
      if (_isBalanceLine(line)) continue;
      if (_lineHasIncomeSign(line)) return TransactionType.income;
      if (_lineHasExpenseSign(line)) return TransactionType.expense;
    }

    if (_hasExplicitTransferAction(text, lines) && !_isTransferLabelOnly(text)) {
      return TransactionType.transfer;
    }

    if (_isIncomeContext(text, lines)) return TransactionType.income;
    if (_isExpenseContext(text, lines)) return TransactionType.expense;

    return TransactionType.expense;
  }

  int? _detectAmountForType(
    String text,
    List<String> lines,
    TransactionType type,
  ) {
    return switch (type) {
      TransactionType.income =>
        _detectSignedAmount(lines, TransactionType.income) ??
            _extractFromSummaryText(text, TransactionType.income) ??
            _extractFromSplitSummaryLines(lines, TransactionType.income),
      TransactionType.expense =>
        _detectSignedAmount(lines, TransactionType.expense) ??
            _extractFromSummaryText(text, TransactionType.expense) ??
            _extractFromSplitSummaryLines(lines, TransactionType.expense),
      TransactionType.transfer =>
        _extractAmountNearTransfer(lines, null) ??
            _extractFromSplitSummaryLines(lines, TransactionType.transfer) ??
            _extractLargestPlainAmount(lines),
    };
  }

  String? _detectPayerForScene(ReceiptScene scene, List<String> lines) {
    if (scene == ReceiptScene.bankMonthlyBill) {
      for (final line in lines) {
        final transfer = RegExp(r'转账[-—](.+)$').firstMatch(line.trim());
        if (transfer != null) {
          return _cleanCounterpartyName(transfer.group(1)!);
        }
      }
    }
    return null;
  }

  DateTime? _detectDateForScene(
    ReceiptScene scene,
    String text,
    List<String> lines,
  ) {
    final header = _resolveBillHeader(text.replaceAll('：', ':'), lines);

    if (scene == ReceiptScene.bankMonthlyBill ||
        scene == ReceiptScene.bankCardDetail) {
      final bankCandidates = _collectBankBillDateTime(lines, header);
      if (bankCandidates.isNotEmpty) {
        bankCandidates.sort((a, b) => b.score.compareTo(a.score));
        return bankCandidates.first.dateTime;
      }
    }

    if (scene == ReceiptScene.wechatPayment ||
        scene == ReceiptScene.alipayPayment ||
        scene == ReceiptScene.wechatTransferIncome ||
        scene == ReceiptScene.wechatTransferExpense ||
        scene == ReceiptScene.alipayTransfer) {
      final labeled = _collectLabeledDateTimes(lines, header);
      final picked = _pickBestDateCandidate([
        ...labeled,
        ..._collectExplicitDateTimes(text.replaceAll('：', ':')),
      ]);
      if (picked != null) return picked;
    }

    return _pickBestDateCandidate([
      ..._collectLabeledDateTimes(lines, header),
      ..._collectMonthDayTimeLines(lines, header),
      if (scene != ReceiptScene.bankMonthlyBill &&
          scene != ReceiptScene.bankCardDetail)
        ..._collectExplicitDateTimes(text.replaceAll('：', ':')),
    ]);
  }

  String? _detectAccountForScene(ReceiptScene scene, List<String> lines) {
    return switch (scene) {
      ReceiptScene.wechatPayment ||
      ReceiptScene.wechatTransferIncome ||
      ReceiptScene.wechatTransferExpense =>
        _detectAccountName(lines) ?? _findAccountByKeyword(lines, '零钱'),
      ReceiptScene.alipayPayment || ReceiptScene.alipayTransfer =>
        _detectAccountName(lines) ??
            _findAccountByKeyword(lines, '支付宝') ??
            _findAccountByKeyword(lines, '花呗') ??
            _findAccountByKeyword(lines, '余额宝'),
      ReceiptScene.bankMonthlyBill || ReceiptScene.bankCardDetail =>
        _detectAccountName(lines),
      ReceiptScene.paperReceipt => null,
      ReceiptScene.unknown => null,
    };
  }

  String? _findAccountByKeyword(List<String> lines, String keyword) {
    for (final line in lines) {
      if (line.contains(keyword)) return keyword;
    }
    return null;
  }

  String? _detectDescriptionForScene(
    ReceiptScene scene,
    List<String> lines, {
    String? payer,
  }) {
    if (scene == ReceiptScene.bankMonthlyBill) {
      for (final line in lines) {
        if (RegExp(r'^转账[-—]').hasMatch(line)) {
          return payer != null ? '转账' : line;
        }
      }
    }
    return null;
  }

  int? _detectBalanceCents(List<String> lines) {
    final pattern = RegExp(
      r'余额\s*[:：]?\s*¥?\s*([\d,\s]+(?:\.\d{1,2})?)',
    );
    for (final line in lines) {
      if (!_isBalanceLine(line)) continue;
      final match = pattern.firstMatch(line);
      if (match != null) return _parseMoney(match.group(1));
    }
    return null;
  }

  TransactionType _detectType(String text, List<String> lines) {
    return _detectTypeStrict(text, lines);
  }

  ReceiptSceneMatch _resolveSceneMatch(
    String text,
    List<String> lines, {
    ReceiptScene? forceScene,
  }) {
    if (forceScene != null && forceScene != ReceiptScene.unknown) {
      return ReceiptSceneMatch(scene: forceScene, score: 1);
    }
    return _sceneClassifier.classify(text, lines);
  }

  String _normalizeOcrText(String rawText) {
    final basic = rawText
        .replaceAll('\r', '')
        .replaceAll('￥', '¥')
        .replaceAll('，', ',')
        .replaceAll('＋', '+')
        .replaceAll('－', '-')
        .replaceAllMapped(
          RegExp(r'(\d),\s+(\d)'),
          (match) => '${match[1]},${match[2]}',
        )
        .trim();
    return _ocrCorrector.apply(basic);
  }

  List<String> _splitLines(String text) {
    return _mergeBrokenAmountLines(
      text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(),
    );
  }

  List<String> _mergeBrokenAmountLines(List<String> lines) {
    final merged = <String>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final next = i + 1 < lines.length ? lines[i + 1] : null;
      if ((line == '+' || line == '-') && next != null) {
        merged.add('$line $next');
        i++;
        continue;
      }
      merged.add(line);
    }
    return merged;
  }

  static const _maxPlausibleAmountCents = 100000000; // 100 万元

  int? _detectAmountCents(
    String text,
    List<String> lines,
    TransactionType type,
  ) {
    final primarySigned = _extractPrimarySignedAmountLine(lines);
    if (primarySigned != null) return primarySigned;

    for (final line in lines) {
      if (_isIgnoredAmountLine(line)) continue;
      final refundMatch = RegExp(r'实退\s*([\d,\s]+(?:\.\d{1,2})?)').firstMatch(line);
      if (refundMatch != null) {
        return _parseMoney(refundMatch.group(1));
      }
    }

    if (type == TransactionType.transfer && _hasTransferLine(lines)) {
      return _extractAmountNearTransfer(lines, TransactionType.transfer) ??
          _extractFromSplitSummaryLines(lines, TransactionType.transfer) ??
          _detectSignedAmount(lines, TransactionType.income) ??
          _extractCurrencyMarkedAmount(lines) ??
          _extractLargestPlainAmount(lines);
    }

    final currencyAmount = _extractCurrencyMarkedAmount(lines);
    if (currencyAmount != null) return currencyAmount;

    final plainDecimalAmount = _extractPlainDecimalAmount(lines);
    if (plainDecimalAmount != null) return plainDecimalAmount;

    final signedAmount = _detectSignedAmount(lines, type);
    if (signedAmount != null) return signedAmount;

    final summaryAmount = _extractFromSummaryText(text, type);
    if (summaryAmount != null) return summaryAmount;

    final splitSummaryAmount = _extractFromSplitSummaryLines(lines, type);
    if (splitSummaryAmount != null) return splitSummaryAmount;

    final transferAmount = _extractAmountNearTransfer(lines, type);
    if (transferAmount != null) return transferAmount;

    for (final line in lines) {
      if (_isIgnoredAmountLine(line)) continue;
      final detailAmount = RegExp(
        r'(?:收入|支出|金额|实付|实收|付款|收款)\s*[:：]?\s*¥?\s*([\d,]+(?:\.\d{1,2})?)',
      ).firstMatch(line);
      if (detailAmount != null) {
        return _parseMoney(detailAmount.group(1));
      }
    }

    return _detectAnyTransactionAmount(text, lines);
  }

  /// 整行带符号金额：-1,688.00 / +200.00（支付宝账单详情常见）
  int? _extractPrimarySignedAmountLine(List<String> lines) {
    final linePattern = RegExp(
      r'^[-－+＋]\s*¥?\s*([\d,\s]+(?:\.\d{1,2})?)$',
    );
    int? best;

    for (final line in lines) {
      if (_isIgnoredAmountLine(line) || _isBalanceLine(line)) continue;
      final trimmed = line.trim();
      final wholeLine = linePattern.firstMatch(trimmed);
      if (wholeLine == null) continue;

      final cents = _parseMoney(wholeLine.group(1));
      if (cents != null && (best == null || cents > best)) best = cents;
    }

    return best;
  }

  int? _detectSignedAmount(List<String> lines, TransactionType type) {
    final signedPattern = RegExp(
      r'[+\-＋－]\s*¥?\s*([\d,\s]+(?:\.\d{1,2})?)',
    );
    final loosePattern = RegExp(
      r'[+\-＋－]\s*([\d,\s]+(?:\.\d{1,2})?)',
    );

    for (final line in lines) {
      if (_isIgnoredAmountLine(line)) continue;

      final match = signedPattern.firstMatch(line) ??
          loosePattern.firstMatch(line);
      if (match == null) continue;

      final sign = match.group(0)!;
      final isIncomeSign = sign.contains('+') || sign.contains('＋');
      final isExpenseSign = sign.contains('-') || sign.contains('－');
      if (type == TransactionType.transfer && (isIncomeSign || isExpenseSign)) {
        return _parseMoney(match.group(1));
      }
      if (type == TransactionType.income && isIncomeSign) {
        return _parseMoney(match.group(1));
      }
      if (type == TransactionType.expense && isExpenseSign) {
        return _parseMoney(match.group(1));
      }
    }

    for (final line in lines) {
      if (_isIgnoredAmountLine(line)) continue;
      if (!_lineHasIncomeSign(line)) continue;
      final match = RegExp(r'([\d,]+(?:\.\d{1,2})?)').allMatches(line).lastOrNull;
      if (match != null) return _parseMoney(match.group(1));
    }

    return null;
  }

  int? _detectAnyTransactionAmount(String text, List<String> lines) {
    final signedPattern = RegExp(
      r'[+\-＋－]\s*¥?\s*([\d,\s]+(?:\.\d{1,2})?)',
    );
    for (final line in lines) {
      if (_isIgnoredAmountLine(line)) continue;
      final match = signedPattern.firstMatch(line);
      if (match != null) return _parseMoney(match.group(1));
    }

    for (final match in signedPattern.allMatches(text)) {
      final cents = _parseMoney(match.group(1));
      if (cents != null && cents > 0) return cents;
    }

    final summaryAmount = _extractFromSummaryText(text, null);
    if (summaryAmount != null) return summaryAmount;

    final splitSummaryAmount = _extractFromSplitSummaryLines(lines, null);
    if (splitSummaryAmount != null) return splitSummaryAmount;

    final transferAmount = _extractAmountNearTransfer(lines, null);
    if (transferAmount != null) return transferAmount;

    final amounts = <int>[];
    for (final line in lines) {
      if (_isIgnoredAmountLine(line)) continue;
      for (final match
          in RegExp(r'¥\s*([\d,\s]+(?:\.\d{1,2})?)').allMatches(line)) {
        final cents = _parseMoney(match.group(1));
        if (cents != null && cents > 0) amounts.add(cents);
      }
    }
    if (amounts.isEmpty) {
      final fromMulti = _extractLargestFromMultiAmountLines(lines);
      if (fromMulti != null) return fromMulti;
      return _extractLargestPlainAmount(lines);
    }

    amounts.sort();
    if (amounts.length == 1) return amounts.first;

    // 多金额时优先取较小的那个，避免误选余额
    return amounts[amounts.length - 2];
  }

  int? _extractLargestPlainAmount(List<String> lines) {
    final amounts = <int>[];
    final plainAmount = RegExp(r'^[\d,]+(?:\.\d{1,2})?$');
    for (final line in lines) {
      if (_isIgnoredAmountLine(line) ||
          _isBalanceLine(line) ||
          _isHeaderOrYearLine(line)) {
        continue;
      }
      final trimmed = line.trim();
      if (!plainAmount.hasMatch(trimmed)) continue;
      if (!trimmed.contains('.') &&
          !trimmed.contains(',') &&
          trimmed.length <= 1) {
        continue;
      }
      final cents = _parseMoney(trimmed);
      if (cents != null && cents > 0) amounts.add(cents);
    }
    if (amounts.isEmpty) return null;
    amounts.sort();
    return amounts.last;
  }

  /// OCR 把「5,417.00 0.00」和「支出(元) 收入(元)」拆成两行时的金额提取
  int? _extractFromSplitSummaryLines(
    List<String> lines,
    TransactionType? preferredType,
  ) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final hasIncome = line.contains('收入');
      final hasExpense = line.contains('支出');
      if (!hasIncome && !hasExpense) continue;

      final amountLine = i > 0 ? lines[i - 1] : null;
      if (amountLine == null ||
          _isBalanceLine(amountLine) ||
          amountLine.contains('转账-') ||
          _isHeaderOrYearLine(amountLine)) {
        continue;
      }

      final amounts = _extractPositiveAmountsFromLine(amountLine);
      if (amounts.isEmpty) continue;

      amounts.sort();
      if (preferredType == TransactionType.transfer) {
        if (hasIncome && hasExpense) {
          return amounts.last >= amounts.first ? amounts.last : amounts.first;
        }
        return amounts.last;
      }
      if (hasIncome && hasExpense) {
        if (preferredType == TransactionType.expense) {
          return amounts.first;
        }
        if (preferredType == TransactionType.income) {
          return amounts.last;
        }
        return amounts.last;
      }
      if (hasIncome) return amounts.last;
      if (hasExpense) return amounts.first;
    }
    return null;
  }

  int? _extractAmountNearTransfer(
    List<String> lines,
    TransactionType? preferredType,
  ) {
    for (var i = 0; i < lines.length; i++) {
      final transferLine = lines[i].trim();
      if (!RegExp(r'转账[-—]').hasMatch(transferLine)) continue;

      final inlineAmounts = _extractPositiveAmountsFromLine(transferLine);
      if (inlineAmounts.isNotEmpty) {
        inlineAmounts.sort();
        return inlineAmounts.last;
      }

      for (final j in [
        ...List.generate(6, (k) => i - 1 - k),
        ...List.generate(4, (k) => i + 1 + k),
      ]) {
        if (j < 0 || j >= lines.length || j == i) continue;
        final line = lines[j];
        if (_isBalanceLine(line) || _isAccountLine(line)) continue;
        if (RegExp(r'^\d{1,2}日$').hasMatch(line.trim())) continue;
        if ((line.contains('收入') || line.contains('支出')) &&
            !RegExp(r'[\d,]+\.\d{2}').hasMatch(line)) {
          continue;
        }
        final amounts = _extractPositiveAmountsFromLine(line);
        if (amounts.isEmpty) continue;
        amounts.sort();
        if (preferredType == TransactionType.expense) {
          return amounts.first;
        }
        return amounts.last;
      }
    }
    return null;
  }

  int? _extractLargestFromMultiAmountLines(List<String> lines) {
    if (!lines.any((line) => line.contains('收入') || line.contains('转账'))) {
      return null;
    }

    final amounts = <int>[];
    for (final line in lines) {
      if (_isBalanceLine(line)) continue;
      amounts.addAll(_extractPositiveAmountsFromLine(line));
    }
    if (amounts.isEmpty) return null;
    amounts.sort();
    return amounts.last;
  }

  bool _isHeaderOrYearLine(String line) {
    final trimmed = line.trim().replaceAll(' ', '');
    if (trimmed.isEmpty) return false;
    if (RegExp(r'^(19|20)\d{2}$').hasMatch(trimmed.replaceAll(',', ''))) {
      return true;
    }
    if (RegExp(r'^\d{1,2}月([/／]?\d{4})?$').hasMatch(trimmed)) return true;
    if (RegExp(r'^月\d').hasMatch(trimmed)) return true;
    if (line.contains('分析') && !RegExp(r'[\d,]+\.\d{2}').hasMatch(line)) {
      return true;
    }
    return false;
  }

  List<int> _extractPositiveAmountsFromLine(String line) {
    if (RegExp(r'^\d{1,2}日$').hasMatch(line.trim())) return [];
    if (_isHeaderOrYearLine(line)) return [];
    if (_isAccountLine(line) && !RegExp(r'[+\-＋－¥￥]').hasMatch(line)) {
      return [];
    }

    final amounts = <int>[];
    for (final match
        in RegExp(r'([\d,\s]+(?:\.\d{1,2})?)').allMatches(line)) {
      final raw = match.group(1)!;
      final compact = raw.replaceAll(' ', '');
      if (!compact.contains('.') &&
          !compact.contains(',') &&
          compact.length <= 2) {
        continue;
      }
      if (!compact.contains('.') &&
          !compact.contains(',') &&
          compact.length == 4 &&
          _isAccountLine(line)) {
        continue;
      }
      final cents = _parseMoney(raw);
      if (cents != null && cents > 0) {
        amounts.add(cents);
      }
    }
    return amounts;
  }

  int? _extractFromSummaryText(String text, TransactionType? preferredType) {
    final incomePattern = RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*收入');
    final expensePattern = RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*支出');

    int? incomeCents;
    int? expenseCents;
    for (final match in incomePattern.allMatches(text)) {
      final cents = _parseMoney(match.group(1));
      if (cents != null && cents > 0) {
        incomeCents = cents;
        break;
      }
    }
    for (final match in expensePattern.allMatches(text)) {
      final cents = _parseMoney(match.group(1));
      if (cents != null && cents > 0) {
        expenseCents = cents;
        break;
      }
    }

    if (preferredType == TransactionType.income && incomeCents != null) {
      return incomeCents;
    }
    if (preferredType == TransactionType.expense && expenseCents != null) {
      return expenseCents;
    }
    if (preferredType == TransactionType.transfer) return null;
    if (incomeCents != null && expenseCents == null) return incomeCents;
    if (expenseCents != null && incomeCents == null) return expenseCents;
    if (incomeCents != null && expenseCents != null) {
      return preferredType == TransactionType.expense
          ? expenseCents
          : incomeCents;
    }
    return null;
  }

  bool _lineHasIncomeSign(String line) {
    final trimmed = line.trim();
    if (RegExp(r'^[+＋]\s*¥?\s*[\d,\s]+(?:\.\d{1,2})?').hasMatch(trimmed)) {
      return true;
    }
    return RegExp(r'^[+＋]\s*[\d,\s]+(?:\.\d{1,2})?').hasMatch(trimmed);
  }

  bool _lineHasExpenseSign(String line) {
    final trimmed = line.trim();
    if (RegExp(r'^[-－]\s*¥?\s*[\d,\s]+(?:\.\d{1,2})?').hasMatch(trimmed)) {
      return true;
    }
    return RegExp(r'^[-－]\s*[\d,\s]+(?:\.\d{1,2})?').hasMatch(trimmed);
  }

  bool _isBalanceLine(String line) {
    return RegExp(r'余额|结余|可用余额|账户余额|账面余额').hasMatch(line);
  }

  bool _isIgnoredAmountLine(String line) {
    if (_isBalanceLine(line)) return true;
    if (RegExp(r'\d{11}已收款').hasMatch(line.replaceAll(' ', ''))) return true;
    for (final keyword in kReceiptIgnoredAmountKeywords) {
      if (line.contains(keyword)) return true;
    }
    if (line.contains('支出') &&
        line.contains('收入') &&
        !_lineHasIncomeSign(line) &&
        !_lineHasExpenseSign(line)) {
      return true;
    }
    return false;
  }

  int? _parseMoney(String? raw) {
    if (raw == null) return null;
    if (_isLikelyNonAmountNumber(raw)) return null;
    try {
      final normalized = raw.replaceAll(',', '').replaceAll(' ', '');
      final cents = MoneyUtils.parseToCents(normalized);
      if (!_isPlausibleAmountCents(cents)) return null;
      return cents;
    } catch (_) {
      return null;
    }
  }

  bool _isPlausibleAmountCents(int? cents) {
    if (cents == null || cents <= 0) return false;
    return cents <= _maxPlausibleAmountCents;
  }

  bool _isLikelyNonAmountNumber(String raw) {
    final normalized = raw.replaceAll(',', '').replaceAll(' ', '');
    if (normalized.contains('.')) return false;
    if (RegExp(r'^(19|20)\d{2}$').hasMatch(normalized)) return true;
    if (RegExp(r'^1\d{10}$').hasMatch(normalized)) return true;
    if (normalized.length >= 9 && RegExp(r'^\d+$').hasMatch(normalized)) {
      return true;
    }
    return false;
  }

  int? _extractCurrencyMarkedAmount(List<String> lines) {
    final amounts = <int>[];
    for (final line in lines) {
      if (_isIgnoredAmountLine(line)) continue;
      for (final match
          in RegExp(r'¥\s*([\d,\s]+(?:\.\d{1,2})?)').allMatches(line)) {
        final cents = _parseMoney(match.group(1));
        if (cents != null) amounts.add(cents);
      }
    }
    if (amounts.isEmpty) return null;
    amounts.sort();
    return amounts.first;
  }

  int? _extractPlainDecimalAmount(List<String> lines) {
    final amounts = <int>[];
    final pattern = RegExp(r'^[\d,]+\.\d{2}$');
    for (final line in lines) {
      if (_isIgnoredAmountLine(line) || _isBalanceLine(line)) continue;
      final trimmed = line.trim();
      if (!pattern.hasMatch(trimmed)) continue;
      final cents = _parseMoney(trimmed);
      if (cents != null) amounts.add(cents);
    }
    if (amounts.isEmpty) return null;
    amounts.sort();
    return amounts.first;
  }

  String? _detectDescription(List<String> lines, {String? payer}) {
    const labeledFields = [
      '转账备注',
      '备注',
      '附言',
      '交易摘要',
      '商品说明',
      '摘要',
      '用途',
    ];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final label in labeledFields) {
        if (!line.contains(label)) continue;
        final inline = _extractLabeledValue(line, label);
        if (inline != null) return inline;
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          const nextLabels = [
            '对方账户',
            '付款方式',
            '支付方式',
            '支付奖励',
            '交易单号',
            '商户单号',
          ];
          if (!nextLabels.contains(nextLine)) {
            final next = _cleanDescriptionText(lines[i + 1]);
            if (next != null) return next;
          }
        }
      }
    }

    for (final line in lines) {
      final transfer = RegExp(r'转账[-—](.+)').firstMatch(line);
      if (transfer != null) {
        final suffix = transfer.group(1)!.trim();
        if (payer != null && suffix == payer) {
          return '转账';
        }
        return line;
      }
    }

    for (final line in lines) {
      if (RegExp(r'^(美团|饿了么|滴滴|淘宝|京东|拼多多|星巴克|麦当劳)').hasMatch(line)) {
        return line;
      }
    }

    return null;
  }

  String? _cleanDescriptionText(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return null;
    if (_isBalanceLine(text) || _isAmountLikeLine(text)) return null;
    if (_isAccountLine(text)) return null;
    if (RegExp(r'^\d{1,2}月').hasMatch(text)) return null;
    if (RegExp(r'^\d{1,2}日$').hasMatch(text)) return null;
    if (text.length > 80) {
      text = text.substring(0, 80).trim();
    }
    return text;
  }

  String? _detectPayer(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (RegExp(r'^向你转账$|^转账给你$').hasMatch(trimmed) && i > 0) {
        final name = _cleanCounterpartyName(lines[i - 1]);
        if (name != null && _looksLikeCounterpartyName(lines[i - 1])) {
          return name;
        }
      }
    }

    final inlinePatterns = <RegExp>[
      RegExp(r'(.+?)\s*1\d{10}已收款'),
      RegExp(r'(.+?)已收款'),
      RegExp(r'付款给\s*[:：]?\s*(.+)'),
      RegExp(r'收款方(?!式)\s*[:：]?\s*(.+)'),
      RegExp(r'交易对方\s*[:：]?\s*(.+)'),
      RegExp(r'对方账户\s*[:：]?\s*(.+)'),
      RegExp(r'付款方(?!式)\s*[:：]?\s*(.+)'),
      RegExp(r'商户名称?\s*[:：]?\s*(.+)'),
      RegExp(r'商家名称?\s*[:：]?\s*(.+)'),
      RegExp(r'向对方\s*(.+?)\s*转账'),
      RegExp(r'向(?!你\b)(.+?)\s*转账'),
      RegExp(r'转账给\s*(.+)'),
      RegExp(r'扫二维码付款[-—给\s]*(.+)'),
      RegExp(r'二维码收款[-—]*\s*(.+)'),
      RegExp(r'来自\s*(.+?)(?:的转账)?$'),
      RegExp(r'(.+?)\s*向你转账'),
      RegExp(r'(.+?)\s*转账给你'),
      RegExp(r'(.+?)的转账$'),
    ];

    for (final line in lines) {
      for (final pattern in inlinePatterns) {
        final match = pattern.firstMatch(line);
        if (match == null) continue;
        final name = _cleanCounterpartyName(match.group(1)!);
        if (name != null && name.length >= 2) return name;
      }
    }

    for (var i = 0; i < lines.length; i++) {
      if (!_lineHasIncomeSign(lines[i]) && !_lineHasExpenseSign(lines[i])) {
        continue;
      }
      if (i == 0) continue;

      final prev = lines[i - 1];
      if (RegExp(r'^转账[-—]').hasMatch(prev)) continue;

      final name = _cleanCounterpartyName(prev);
      if (name != null && _looksLikeCounterpartyName(prev)) {
        return name;
      }
    }

    const labelOnly = ['付款给', '收款方', '交易对方', '对方账户', '付款方', '商户名称', '商家名称'];
    const skipNextLines = {
      '再转一笔',
      '账单管理',
      '更多',
      '支付奖励',
      '全部账单',
      '账单详情',
    };
    for (var i = 0; i < lines.length - 1; i++) {
      final line = lines[i].replaceAll('：', '').replaceAll(':', '').trim();
      if (!labelOnly.contains(line)) continue;
      final next = lines[i + 1].trim();
      if (skipNextLines.contains(next)) continue;
      final name = _cleanCounterpartyName(lines[i + 1]);
      if (name != null) return name;
    }

    for (var i = 0; i < lines.length; i++) {
      final transfer = RegExp(r'转账[-—](.+)').firstMatch(lines[i]);
      if (transfer == null) continue;

      if (i > 0) {
        final prevName = _cleanCounterpartyName(lines[i - 1]);
        if (prevName != null && _looksLikeCounterpartyName(lines[i - 1])) {
          return prevName;
        }
      }

      final suffix = transfer.group(1)!.split('-').first.trim();
      final name = _cleanCounterpartyName(suffix);
      if (name != null) return name;
    }

    return null;
  }

  String? _extractLabeledValue(String line, String label) {
    final trimmed = line.trim();
    final escaped = RegExp.escape(label);

    final trailing = RegExp('(.+?)\\s*$escaped\\s*\$').firstMatch(trimmed);
    if (trailing != null) {
      return _cleanCounterpartyName(trailing.group(1)!);
    }

    final leading = RegExp('^$escaped(?!\\u4e00-\\u9fff)\\s*[:：]?\\s*(.+)\$')
        .firstMatch(trimmed);
    if (leading != null) {
      return _cleanCounterpartyName(leading.group(1)!);
    }

    return null;
  }

  String? _extractPaymentMethod(String line) {
    final trimmed = line.trim();
    const labels = ['付款方式', '支付方式'];

    for (final label in labels) {
      final trailing = RegExp('(.+?)\\s*${RegExp.escape(label)}\\s*\$')
          .firstMatch(trimmed);
      if (trailing != null) {
        final value = trailing.group(1)!.replaceAll(RegExp(r'[>〉\s]+$'), '').trim();
        if (value.isNotEmpty) return value;
      }

      final leading = _extractLabeledValue(trimmed, label);
      if (leading != null) return leading;
    }

    return null;
  }

  String? _cleanCounterpartyName(String raw) {
    var name = raw.trim();
    if (name.isEmpty) return null;

    name = name.replaceAll(RegExp(r'[>〉]+$'), '');
    name = name.replaceAll(RegExp(r'\s*[\(（][^)）]*[\)）]'), '');
    name = name.replaceAll(RegExp(r'[¥￥]\s*[\d,.]+.*$'), '');
    if (RegExp(r'^转账[-—]').hasMatch(name)) {
      name = name.replaceFirst(RegExp(r'^转账[-—]'), '').trim();
    } else if (name.contains('--')) {
      // 商户名中的双连字符（如 海艳好合通讯--齐海）保留
    } else {
      name = name.replaceAll(RegExp(r'\s*[-—].*$'), '');
    }
    name = name.trim();

    if (name.isEmpty || name.length < 2) return null;
    if (name.length > 40) {
      name = name.substring(0, 40).trim();
    }

    const skipExact = {
      '支付成功',
      '交易成功',
      '已完成',
      '当前状态',
      '退款成功',
      '零钱',
      '余额宝',
      '花呗',
      '信用卡',
      '储蓄卡',
      '借记卡',
      '银行卡',
      '微信',
      '支付宝',
      '云闪付',
      '账单',
      '收入',
      '支出',
      '转账',
      '再转一笔',
      '全部账单',
      '账单详情',
      '账单管理',
      '更多',
      '支付奖励',
      '买手',
      '找我',
    };
    if (skipExact.contains(name)) return null;

    if (RegExp(r'^\d+$').hasMatch(name)) return null;
    if (RegExp(r'^\d{1,2}月').hasMatch(name)) return null;
    if (RegExp(r'^\d{1,2}日$').hasMatch(name)) return null;
    if (_isBalanceLine(name)) return null;
    if (_isAccountLine(name)) return null;
    if (RegExp(r'^[\d:：./\-]+$').hasMatch(name)) return null;

    return name;
  }

  bool _looksLikeCounterpartyName(String line) {
    final trimmed = line.trim();
    if (trimmed.length < 2 || trimmed.length > 24) return false;
    if (RegExp(r'^[\d:：./\-]+$').hasMatch(trimmed)) return false;
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return false;
    if (_isAccountLine(trimmed) || _isBalanceLine(trimmed)) return false;

    if (RegExp(r'^\d{1,2}日$').hasMatch(trimmed)) return false;
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(trimmed)) return false;

    const skipContains = [
      '支付成功',
      '交易成功',
      '当前状态',
      '付款给',
      '收款方',
      '交易对方',
      '对方账户',
      '商品说明',
      '账单',
      '微信',
      '支付宝',
      '支出',
      '收入',
      '转账-',
      '转账—',
      '再转一笔',
      '付款方式',
      '支付方式',
    ];
    for (final keyword in skipContains) {
      if (trimmed.contains(keyword)) return false;
    }

    return RegExp(r'[\u4e00-\u9fffA-Za-z]').hasMatch(trimmed);
  }

  DateTime? _detectDate(String text, List<String> lines) {
    final normalizedText = text.replaceAll('：', ':');
    final header = _resolveBillHeader(normalizedText, lines);

    return _pickBestDateCandidate([
      ..._collectExplicitDateTimes(normalizedText),
      ..._collectLabeledDateTimes(lines, header),
      ..._collectMonthDayTimeLines(lines, header),
      ..._collectBankBillDateTime(lines, header),
    ]);
  }

  DateTime? _pickBestDateCandidate(List<_DateCandidate> candidates) {
    if (candidates.isEmpty) return null;

    final filtered = candidates
        .where((candidate) => !_isImplausibleRecognitionDate(candidate.dateTime))
        .toList();
    if (filtered.isEmpty) return null;

    filtered.sort((a, b) => b.score.compareTo(a.score));

    final withTime = filtered
        .where(
          (candidate) =>
              candidate.dateTime.hour != 0 || candidate.dateTime.minute != 0,
        )
        .toList();
    if (withTime.isNotEmpty) {
      withTime.sort((a, b) => b.score.compareTo(a.score));
      return withTime.first.dateTime;
    }

    return filtered.first.dateTime;
  }

  bool _isImplausibleRecognitionDate(DateTime date) {
    final now = DateTime.now();
    if (date.year < 2000 || date.year > now.year + 1) return true;
    if (date.isAfter(now.add(const Duration(days: 2)))) return true;
    return false;
  }

  List<_DateCandidate> _collectExplicitDateTimes(String text) {
    final results = <_DateCandidate>[];
    final header = (year: null, month: null);

    for (final line in text.split('\n')) {
      final parsed = _parseFlexibleDateTime(line.trim(), header);
      if (parsed != null) {
        results.add(_DateCandidate(dateTime: parsed, score: 100));
      }
    }

    final cnFull = RegExp(
      r'(\d{4})年(\d{1,2})月(\d{1,2})日\s*(\d{1,2})[.:：](\d{2})(?:[.:：](\d{2}))?',
    );
    for (final match in cnFull.allMatches(text)) {
      results.add(
        _DateCandidate(
          dateTime: _buildDate(
            year: int.parse(match.group(1)!),
            month: int.parse(match.group(2)!),
            day: int.parse(match.group(3)!),
            hour: int.parse(match.group(4)!),
            minute: int.parse(match.group(5)!),
            second: int.tryParse(match.group(6) ?? '0') ?? 0,
          ),
          score: 100,
        ),
      );
    }

    final isoFull = RegExp(
      r'(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})\s+(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?',
    );
    for (final match in isoFull.allMatches(text)) {
      results.add(
        _DateCandidate(
          dateTime: _buildDate(
            year: int.parse(match.group(1)!),
            month: int.parse(match.group(2)!),
            day: int.parse(match.group(3)!),
            hour: int.parse(match.group(4)!),
            minute: int.parse(match.group(5)!),
            second: int.tryParse(match.group(6) ?? '0') ?? 0,
          ),
          score: 100,
        ),
      );
    }

    return results;
  }

  List<_DateCandidate> _collectLabeledDateTimes(
    List<String> lines,
    ({int? year, int? month}) header,
  ) {
    const labels = kReceiptDateLabelRules;
    final results = <_DateCandidate>[];

    for (var i = 0; i < lines.length; i++) {
      final rawLine = lines[i].replaceAll('：', ':');
      for (final (label, score) in labels) {
        if (!rawLine.contains(label)) continue;

        final remainder = rawLine.replaceFirst(label, '').trim();
        final inline = _parseFlexibleDateTime(remainder, header);
        if (inline != null) {
          results.add(_DateCandidate(dateTime: inline, score: score));
        }

        final combinedParts = <String>[
          if (remainder.isNotEmpty) remainder,
          for (var j = 1; j <= 2 && i + j < lines.length; j++) lines[i + j],
        ];
        final combined = combinedParts.join(' ').trim();
        if (combined.isNotEmpty && combined != remainder) {
          final combinedParsed = _parseFlexibleDateTime(combined, header);
          if (combinedParsed != null) {
            results.add(_DateCandidate(dateTime: combinedParsed, score: score));
          }
        }

        if (i + 1 < lines.length) {
          final nextInline = _parseFlexibleDateTime(lines[i + 1], header);
          if (nextInline != null) {
            results.add(_DateCandidate(dateTime: nextInline, score: score - 1));
          }

          final dateParts = _parseDateParts(lines[i + 1], header);
          if (dateParts != null && i + 2 < lines.length) {
            final time = _parseStandaloneTime(lines[i + 2]) ??
                _lastValidTimeInLine(lines[i + 2]);
            if (time != null) {
              results.add(
                _DateCandidate(
                  dateTime: _buildDate(
                    year: dateParts.$1,
                    month: dateParts.$2,
                    day: dateParts.$3,
                    hour: time.$1,
                    minute: time.$2,
                    second: time.$3,
                  ),
                  score: score - 2,
                ),
              );
            }
          }
        }
      }
    }

    return results;
  }

  List<_DateCandidate> _collectMonthDayTimeLines(
    List<String> lines,
    ({int? year, int? month}) header,
  ) {
    if (header.year == null) return [];

    final results = <_DateCandidate>[];
    final pattern = RegExp(
      r'(\d{1,2})月(\d{1,2})日\s*(\d{1,2})[.:：](\d{2})(?:[.:：](\d{2}))?',
    );

    for (final line in lines) {
      if (_isAmountLikeLine(line) || _isBalanceLine(line)) continue;
      final match = pattern.firstMatch(line.replaceAll('：', ':'));
      if (match == null) continue;

      results.add(
        _DateCandidate(
          dateTime: _buildDate(
            year: header.year!,
            month: int.parse(match.group(1)!),
            day: int.parse(match.group(2)!),
            hour: int.parse(match.group(3)!),
            minute: int.parse(match.group(4)!),
            second: int.tryParse(match.group(5) ?? '0') ?? 0,
          ),
          score: 82,
        ),
      );
    }

    return results;
  }

  List<_DateCandidate> _collectBankBillDateTime(
    List<String> lines,
    ({int? year, int? month}) header,
  ) {
    if (header.year == null || header.month == null) return [];

    final day = _findBillDay(lines);
    if (day == null) return [];

    final time = _findTransactionTime(lines);
    final dateTime = _buildDate(
      year: header.year!,
      month: header.month!,
      day: day,
      hour: time?.$1 ?? 0,
      minute: time?.$2 ?? 0,
      second: time?.$3 ?? 0,
    );

    return [
      _DateCandidate(
        dateTime: dateTime,
        score: time != null ? 90 : 75,
      ),
    ];
  }

  DateTime? _parseInlineDateTime(
    String line,
    ({int? year, int? month}) header,
  ) {
    return _parseFlexibleDateTime(line, header);
  }

  /// 兼容 OCR 粘连、点号时间、仅日期行等多种格式
  DateTime? _parseFlexibleDateTime(
    String line,
    ({int? year, int? month}) header,
  ) {
    final source = line.replaceAll('：', ':').trim();
    if (source.isEmpty || _isAmountLikeLine(source)) return null;
    if (_isStatusBarClockLine(source)) return null;

    final iso = _parseIsoDateTime(source);
    if (iso != null) return iso;

    final gluedIso = RegExp(
      r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?$',
    ).firstMatch(source);
    if (gluedIso != null) {
      return _buildDate(
        year: int.parse(gluedIso.group(1)!),
        month: int.parse(gluedIso.group(2)!),
        day: int.parse(gluedIso.group(3)!),
        hour: int.parse(gluedIso.group(4)!),
        minute: int.parse(gluedIso.group(5)!),
        second: int.tryParse(gluedIso.group(6) ?? '0') ?? 0,
      );
    }

    final cnFull = RegExp(
      r'(\d{4})年(\d{1,2})月(\d{1,2})日\s*(\d{1,2})[.:：](\d{2})(?:[.:：](\d{2}))?',
    ).firstMatch(source);
    if (cnFull != null) {
      return _buildDate(
        year: int.parse(cnFull.group(1)!),
        month: int.parse(cnFull.group(2)!),
        day: int.parse(cnFull.group(3)!),
        hour: int.parse(cnFull.group(4)!),
        minute: int.parse(cnFull.group(5)!),
        second: int.tryParse(cnFull.group(6) ?? '0') ?? 0,
      );
    }

    final cnGlued = RegExp(
      r'^(\d{4})年(\d{1,2})月(\d{1,2})日(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?$',
    ).firstMatch(source);
    if (cnGlued != null) {
      return _buildDate(
        year: int.parse(cnGlued.group(1)!),
        month: int.parse(cnGlued.group(2)!),
        day: int.parse(cnGlued.group(3)!),
        hour: int.parse(cnGlued.group(4)!),
        minute: int.parse(cnGlued.group(5)!),
        second: int.tryParse(cnGlued.group(6) ?? '0') ?? 0,
      );
    }

    final cnDate = RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日').firstMatch(source);
    if (cnDate != null) {
      return DateTime(
        int.parse(cnDate.group(1)!),
        int.parse(cnDate.group(2)!),
        int.parse(cnDate.group(3)!),
      );
    }

    final monthDayTime = RegExp(
      r'(\d{1,2})月(\d{1,2})日\s*(\d{1,2})[.:：](\d{2})(?:[.:：](\d{2}))?',
    ).firstMatch(source);
    if (monthDayTime != null && header.year != null) {
      return _buildDate(
        year: header.year!,
        month: int.parse(monthDayTime.group(1)!),
        day: int.parse(monthDayTime.group(2)!),
        hour: int.parse(monthDayTime.group(3)!),
        minute: int.parse(monthDayTime.group(4)!),
        second: int.tryParse(monthDayTime.group(5) ?? '0') ?? 0,
      );
    }

    final isoDateOnly = RegExp(
      r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})$',
    ).firstMatch(source);
    if (isoDateOnly != null) {
      return DateTime(
        int.parse(isoDateOnly.group(1)!),
        int.parse(isoDateOnly.group(2)!),
        int.parse(isoDateOnly.group(3)!),
      );
    }

    return null;
  }

  bool _isStatusBarClockLine(String line) {
    return RegExp(r'^\d{1,2}:\d{2}$').hasMatch(line.trim());
  }

  DateTime? _parseIsoDateTime(String source) {
    final isoFull = RegExp(
      r'(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})\s+(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?',
    ).firstMatch(source);
    if (isoFull == null) return null;

    return _buildDate(
      year: int.parse(isoFull.group(1)!),
      month: int.parse(isoFull.group(2)!),
      day: int.parse(isoFull.group(3)!),
      hour: int.parse(isoFull.group(4)!),
      minute: int.parse(isoFull.group(5)!),
      second: int.tryParse(isoFull.group(6) ?? '0') ?? 0,
    );
  }

  (int year, int month, int day)? _parseDateParts(
    String line,
    ({int? year, int? month}) header,
  ) {
    final source = line.replaceAll('：', ':').trim();
    if (source.isEmpty || _isAmountLikeLine(source)) return null;

    final cnDate = RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日').firstMatch(source);
    if (cnDate != null) {
      return (
        int.parse(cnDate.group(1)!),
        int.parse(cnDate.group(2)!),
        int.parse(cnDate.group(3)!),
      );
    }

    final monthDay = RegExp(r'(\d{1,2})月(\d{1,2})日').firstMatch(source);
    if (monthDay != null && header.year != null) {
      return (
        header.year!,
        int.parse(monthDay.group(1)!),
        int.parse(monthDay.group(2)!),
      );
    }

    final isoDate = RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})$').firstMatch(source);
    if (isoDate != null) {
      return (
        int.parse(isoDate.group(1)!),
        int.parse(isoDate.group(2)!),
        int.parse(isoDate.group(3)!),
      );
    }

    return null;
  }

  int? _findBillDay(List<String> lines) {
    for (final line in lines) {
      final match = RegExp(r'^0?(\d{1,2})日$').firstMatch(line.trim());
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    }
    return null;
  }

  (int, int, int)? _findTransactionTime(List<String> lines) {
    for (final line in lines) {
      if (!_isAccountLine(line)) continue;
      final inline = _lastValidTimeInLine(line);
      if (inline != null) return inline;
    }

    for (var i = 0; i < lines.length; i++) {
      if (_findBillDay([lines[i]]) == null) continue;

      for (var offset = 1; offset <= 3 && i + offset < lines.length; offset++) {
        final standalone = _parseStandaloneTime(lines[i + offset]);
        if (standalone != null) return standalone;

        if (_isAccountLine(lines[i + offset])) {
          final inline = _lastValidTimeInLine(lines[i + offset]);
          if (inline != null) return inline;
        }
      }
    }

    for (var i = 0; i < lines.length; i++) {
      if (!_lineHasIncomeSign(lines[i]) && !_lineHasExpenseSign(lines[i])) {
        continue;
      }
      for (var j = i - 1; j >= 0 && j >= i - 4; j--) {
        final line = lines[j];
        if (_isBalanceLine(line) || _isAmountLikeLine(line)) continue;
        final time = _lastValidTimeInLine(line) ?? _parseStandaloneTime(line);
        if (time != null) return time;
      }
    }

    for (final line in lines) {
      if (_isBalanceLine(line) || _isAmountLikeLine(line)) continue;
      final standalone = _parseStandaloneTime(line);
      if (standalone != null) return standalone;
    }

    return null;
  }

  (int, int, int)? _parseStandaloneTime(String line) {
    final source = line.replaceAll('：', ':').trim();
    if (source.isEmpty || _isAmountLikeLine(source)) return null;

    final match = RegExp(
      r'^(\d{1,2})[.:：](\d{2})(?:[.:：](\d{2}))?$',
    ).firstMatch(source);
    if (match == null) return null;

    return _parseTimeMatch(match);
  }

  (int, int, int)? _lastValidTimeInLine(String line) {
    final source = line.replaceAll('：', ':');
    final colonPattern = RegExp(r'(\d{1,2}):(\d{2})(?::(\d{2}))?');
    final dotPattern = RegExp(r'(\d{1,2})\.(\d{2})(?:\.(\d{2}))?');
    RegExpMatch? lastValid;

    void consider(RegExpMatch match) {
      if (!_isLikelyClockTime(source, match)) return;
      final hour = int.tryParse(match.group(1)!);
      final minute = int.tryParse(match.group(2)!);
      if (hour == null || minute == null) return;
      if (hour > 23 || minute > 59) return;
      lastValid = match;
    }

    for (final match in colonPattern.allMatches(source)) {
      consider(match);
    }
    if (lastValid == null) {
      for (final match in dotPattern.allMatches(source)) {
        consider(match);
      }
    }

    if (lastValid == null) return null;
    return _parseTimeMatch(lastValid!);
  }

  bool _isLikelyClockTime(String source, RegExpMatch match) {
    final start = match.start;
    if (start > 0) {
      final prev = source[start - 1];
      if (RegExp(r'[\d,¥￥]').hasMatch(prev)) return false;
    }
    final end = match.end;
    if (end < source.length) {
      final next = source[end];
      if (RegExp(r'\d').hasMatch(next)) return false;
    }
    return true;
  }

  (int, int, int) _parseTimeMatch(RegExpMatch match) {
    return (
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.tryParse(match.group(3) ?? '0') ?? 0,
    );
  }

  bool _isAmountLikeLine(String line) {
    if (line.contains('¥') || line.contains('￥')) return true;
    if (_lineHasIncomeSign(line) || _lineHasExpenseSign(line)) return true;
    return false;
  }

  bool _isAccountLine(String line) {
    return RegExp(r'(借记卡|储蓄卡|信用卡|微信|支付宝|银行卡|花呗|零钱)').hasMatch(line);
  }

  ({int? year, int? month}) _resolveBillHeader(
    String text,
    List<String> lines,
  ) {
    final headerLineLimit = lines.length < 5 ? lines.length : 5;
    for (var i = 0; i < headerLineLimit; i++) {
      final parsed = _parseHeaderMonthYear(lines[i]);
      if (parsed != null) return parsed;
    }

    for (var i = 0; i < headerLineLimit - 1; i++) {
      final monthOnly = RegExp(r'^(\d{1,2})\s*月$').firstMatch(lines[i].trim());
      if (monthOnly == null) continue;

      final next = lines[i + 1].trim();
      final yearOnly = RegExp(r'^/?\s*(\d{4})$').firstMatch(next);
      if (yearOnly != null) {
        return (
          year: int.parse(yearOnly.group(1)!),
          month: int.parse(monthOnly.group(1)!),
        );
      }
    }

    final textCompact = text.replaceAll(' ', '');
    final compact = RegExp(r'(\d{1,2})月/(\d{4})').firstMatch(textCompact);
    if (compact != null) {
      return (
        year: int.parse(compact.group(2)!),
        month: int.parse(compact.group(1)!),
      );
    }

    final spaced = RegExp(r'(\d{1,2})\s*月\s*/\s*(\d{4})').firstMatch(text);
    if (spaced != null) {
      return (
        year: int.parse(spaced.group(2)!),
        month: int.parse(spaced.group(1)!),
      );
    }

    final monthSpaceYear = RegExp(r'(\d{1,2})\s*月\s+(\d{4})').firstMatch(text);
    if (monthSpaceYear != null) {
      return (
        year: int.parse(monthSpaceYear.group(2)!),
        month: int.parse(monthSpaceYear.group(1)!),
      );
    }

    for (var i = 0; i < headerLineLimit; i++) {
      final parsed = _parseGarbledHeaderMonthYear(lines[i]);
      if (parsed != null) return parsed;
    }

    return (year: null, month: null);
  }

  ({int? year, int? month})? _parseGarbledHeaderMonthYear(String line) {
    final compact = line.replaceAll(' ', '');

    // 月12025 → 11月2025（OCR 漏掉两位月份的首位 1）
    final missingLeading = RegExp(r'^月(\d)(\d{4})$').firstMatch(compact);
    if (missingLeading != null) {
      final trailing = missingLeading.group(1)!;
      final year = int.parse(missingLeading.group(2)!);
      if (year >= 2000 && year <= 2100) {
        final twoDigit = int.tryParse('1$trailing');
        if (twoDigit != null && twoDigit >= 10 && twoDigit <= 12) {
          return (year: year, month: twoDigit);
        }
      }
    }

    final twoDigitMonth = RegExp(r'^月(\d{2})(\d{4})').firstMatch(compact);
    if (twoDigitMonth != null) {
      final month = int.parse(twoDigitMonth.group(1)!);
      final year = int.parse(twoDigitMonth.group(2)!);
      if (month >= 1 && month <= 12 && year >= 2000 && year <= 2100) {
        return (year: year, month: month);
      }
    }

    final oneDigitMonth = RegExp(r'^月(\d{1})(\d{4})').firstMatch(compact);
    if (oneDigitMonth != null) {
      final month = int.parse(oneDigitMonth.group(1)!);
      final year = int.parse(oneDigitMonth.group(2)!);
      if (month >= 1 && month <= 12 && year >= 2000 && year <= 2100) {
        return (year: year, month: month);
      }
    }

    return null;
  }

  ({int? year, int? month})? _parseHeaderMonthYear(String line) {
    final compact = line.replaceAll(' ', '');
    final compactMonthYear = RegExp(r'^(\d{1,2})月/(\d{4})$').firstMatch(compact);
    if (compactMonthYear != null) {
      return (
        year: int.parse(compactMonthYear.group(2)!),
        month: int.parse(compactMonthYear.group(1)!),
      );
    }

    final spacedMonthYear =
        RegExp(r'^(\d{1,2})\s*月\s*/\s*(\d{4})$').firstMatch(line.trim());
    if (spacedMonthYear != null) {
      return (
        year: int.parse(spacedMonthYear.group(2)!),
        month: int.parse(spacedMonthYear.group(1)!),
      );
    }

    final monthSpaceYear =
        RegExp(r'^(\d{1,2})\s*月\s+(\d{4})$').firstMatch(line.trim());
    if (monthSpaceYear != null) {
      return (
        year: int.parse(monthSpaceYear.group(2)!),
        month: int.parse(monthSpaceYear.group(1)!),
      );
    }

    return _parseGarbledHeaderMonthYear(line);
  }

  DateTime _buildDate({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    required int second,
  }) {
    return DateTime(year, month, day, hour, minute, second);
  }

  String? _detectAccountName(List<String> lines) {
    final withTail = RegExp(
      r'(借记卡|储蓄卡|信用卡|银行卡|微信|支付宝|花呗|零钱|余额宝)\s*[*＊]?\s*(\d{4})',
    );
    final accountOnly = RegExp(
      r'(借记卡|储蓄卡|信用卡|银行卡|微信|支付宝|花呗|零钱|余额宝)',
    );

    for (final line in lines) {
      if (line.contains('转账-')) continue;

      final paymentMethod = _extractPaymentMethod(line);
      if (paymentMethod != null) {
        final accountMatch = accountOnly.firstMatch(paymentMethod);
        if (accountMatch != null) return accountMatch.group(1);
        return paymentMethod;
      }

      final tailMatch = withTail.firstMatch(line);
      if (tailMatch != null) {
        return '${tailMatch.group(1)}${tailMatch.group(2)}';
      }
    }

    for (final line in lines) {
      if (line.contains('转账-')) continue;

      final accountMatch = accountOnly.firstMatch(line);
      if (accountMatch != null) {
        return accountMatch.group(1);
      }
    }

    return null;
  }

  String? _guessCategoryName(
    String text,
    List<String> lines,
    TransactionType type, {
    ReceiptScene scene = ReceiptScene.unknown,
  }) {
    if (scene == ReceiptScene.bankMonthlyBill ||
        scene == ReceiptScene.bankCardDetail) {
      return switch (type) {
        TransactionType.income => '其他收入',
        TransactionType.expense => '其他支出',
        TransactionType.transfer => '银行转账',
      };
    }
    if (scene == ReceiptScene.wechatTransferIncome) {
      return '其他收入';
    }
    if (scene == ReceiptScene.wechatTransferExpense ||
        type == TransactionType.transfer) {
      return scene == ReceiptScene.bankMonthlyBill ||
              scene == ReceiptScene.bankCardDetail
          ? '银行转账'
          : '其他转账';
    }
    if (scene == ReceiptScene.alipayTransfer) {
      return switch (type) {
        TransactionType.income => '其他收入',
        TransactionType.expense => '其他支出',
        TransactionType.transfer => '其他转账',
      };
    }
    final source = '$text\n${lines.join('\n')}';

    for (final rule in kReceiptMerchantCategoryRules) {
      if (type != TransactionType.expense) break;
      if (rule.keywords.any(source.contains)) return rule.category;
    }

    for (final rule in kReceiptIncomeCategoryRules) {
      if (type != TransactionType.income) break;
      if (rule.keywords.any(source.contains)) return rule.category;
    }

    final isTransfer = _hasTransferLine(lines) ||
        _hasExplicitTransferAction(text, lines);
    if (isTransfer) {
      return switch (type) {
        TransactionType.income => '其他收入',
        TransactionType.expense => '其他支出',
        TransactionType.transfer => '银行转账',
      };
    }

    if (RegExp(r'借记卡|储蓄卡|银行卡').hasMatch(source)) {
      return switch (type) {
        TransactionType.income => '其他收入',
        TransactionType.expense => '其他支出',
        TransactionType.transfer => '银行转账',
      };
    }

    if (source.contains('微信') || source.contains('支付宝')) {
      return switch (type) {
        TransactionType.income => '其他收入',
        TransactionType.expense => '食品',
        TransactionType.transfer => '其他转账',
      };
    }

    return switch (type) {
      TransactionType.income => '其他收入',
      TransactionType.expense => '其他支出',
      TransactionType.transfer => '其他转账',
    };
  }

  List<String> _detectTags(
    String text,
    List<String> lines,
    TransactionType type, {
    ReceiptScene scene = ReceiptScene.unknown,
  }) {
    final source = '$text\n${lines.join('\n')}';
    final tags = <String>[];

    void add(String tag) {
      if (!tags.contains(tag)) tags.add(tag);
    }

    if (scene != ReceiptScene.unknown) {
      add(scene.label);
    }

    // 类型标签互斥：只打当前类型
    switch (type) {
      case TransactionType.expense:
        add('支出');
      case TransactionType.income:
        add('收入');
      case TransactionType.transfer:
        add('转账');
    }

    if (source.contains('微信')) add('微信');
    if (source.contains('支付宝')) add('支付宝');
    if (RegExp(r'借记卡|储蓄卡|银行卡|云闪付').hasMatch(source)) {
      add('银行');
    }
    if (source.contains('话费') || source.contains('充值')) add('话费');
    if (source.contains('美团') || source.contains('饿了么')) add('外卖');
    if (source.contains('报销')) add('报销');
    if (source.contains('红包')) add('红包');

    return tags;
  }

  double _estimateConfidence(
    String text,
    int amountCents,
    TransactionType type,
  ) {
    var score = 0.55;
    if (text.contains('¥')) score += 0.1;
    if (text.contains('收入') || text.contains('支出')) score += 0.1;
    if (RegExp(r'\d{1,2}:\d{2}').hasMatch(text)) score += 0.05;
    if (text.contains('转账') || text.contains('微信') || text.contains('支付宝')) {
      score += 0.1;
    }
    if (amountCents > 0) score += 0.1;
    if (type == TransactionType.income && text.contains('+')) score += 0.05;
    return score.clamp(0, 1);
  }
}

class _DateCandidate {
  const _DateCandidate({
    required this.dateTime,
    required this.score,
  });

  final DateTime dateTime;
  final int score;
}

extension<T> on Iterable<T> {
  T? get lastOrNull {
    if (isEmpty) return null;
    return last;
  }
}
