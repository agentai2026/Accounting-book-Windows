import 'dart:typed_data';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';

/// 预填「添加交易」表单的数据
class TransactionFormDraft {
  const TransactionFormDraft({
    this.type,
    this.amountText,
    this.categoryId,
    this.categoryName,
    this.fromAccountId,
    this.toAccountId,
    this.accountName,
    this.date,
    this.description,
    this.payer,
    this.tagNames = const [],
    this.imageBytes,
    this.imageFileName,
    this.expenseIncomeOnly = false,
    this.fromAi = false,
  });

  final TransactionType? type;
  final String? amountText;
  final int? categoryId;
  final String? categoryName;
  final int? fromAccountId;
  final int? toAccountId;
  final String? accountName;
  final DateTime? date;
  final String? description;
  final String? payer;
  final List<String> tagNames;
  final Uint8List? imageBytes;
  final String? imageFileName;

  /// AI 识图预填：仅允许支出 / 收入，隐藏转账
  final bool expenseIncomeOnly;

  /// 来自 AI 识图预填（保存时写入 via=ai 元数据）
  final bool fromAi;
}
