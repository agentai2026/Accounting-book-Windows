import 'package:ezbookkeeping_desktop/core/ai/models/bill_platform.dart';

/// AI 规则引擎输出的标准账单
class Bill {
  const Bill({
    required this.id,
    required this.type,
    required this.amount,
    required this.merchant,
    required this.category,
    required this.date,
    this.time,
    this.platform,
    required this.confidence,
    required this.hash,
    this.rawText,
    this.primaryCategory,
    this.secondaryCategory,
    this.duplicateSuspected = false,
    this.autoEntryLevel = BillAutoEntryLevel.manual,
  });

  final String id;
  final BillType type;
  final double amount;
  final String merchant;
  final String category;
  final String date;
  final String? time;
  final BillPlatform? platform;
  final double confidence;
  final String hash;
  final String? rawText;
  final String? primaryCategory;
  final String? secondaryCategory;
  final bool duplicateSuspected;
  final BillAutoEntryLevel autoEntryLevel;
}

enum BillType {
  expense,
  income,
  transfer,
}

/// 置信度对应的入账策略
enum BillAutoEntryLevel {
  /// >= 85 分
  auto,

  /// 70~84 分
  confirm,

  /// < 70 分
  manual,
}
