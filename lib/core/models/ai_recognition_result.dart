import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/receipt_scene.dart';

class AiRecognitionResult {
  const AiRecognitionResult({
    required this.type,
    required this.amountCents,
    this.categoryName,
    this.description,
    this.payer,
    this.date,
    this.accountName,
    this.balanceCents,
    this.scene = ReceiptScene.unknown,
    this.sceneScore = 0,
    this.tagNames = const [],
    this.confidence = 1,
    this.rawText,
    this.currency = 'CNY',
    this.primaryCategory,
    this.secondaryCategory,
    this.lowConfidence = false,
  });

  final TransactionType type;
  final int amountCents;
  final String? categoryName;
  final String? description;
  final String? payer;
  final DateTime? date;
  final String? accountName;

  /// 截图中的账户余额（仅作核对，不写入交易金额）
  final int? balanceCents;

  /// 识别出的截图场景（银行月账单 / 微信支付 等）
  final ReceiptScene scene;
  final double sceneScore;
  final List<String> tagNames;
  final double confidence;

  /// OCR 全部原文（备查）
  final String? rawText;

  /// 货币代码，默认 CNY
  final String currency;

  /// 一级分类（如 餐饮）
  final String? primaryCategory;

  /// 二级分类（如 早餐）
  final String? secondaryCategory;

  /// 低置信度，建议用户核对
  final bool lowConfidence;
}
