import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/alipay_csv_summary_parser.dart';
import 'package:ezbookkeeping_desktop/core/services/create_transaction_input.dart';

/// 导入预览行（检查与修改步骤使用）
class ImportPreviewRow {
  ImportPreviewRow({
    required this.index,
    required this.lineNo,
    required this.valid,
    this.selected = true,
    this.input,
    this.validationError,
    this.type,
    this.date,
    this.amountCents = 0,
    this.categoryId,
    this.categoryName,
    this.originalCategoryName,
    this.accountName,
    this.description,
    this.directionText,
    this.statusText,
    this.skipReason,
    this.rawCells = const [],
  });

  final int index;
  final int lineNo;
  final bool valid;
  bool selected;
  final CreateTransactionInput? input;
  final String? validationError;
  final TransactionType? type;
  final DateTime? date;
  final int amountCents;
  final int? categoryId;
  final String? categoryName;
  final String? originalCategoryName;
  final String? accountName;
  final String? description;
  final String? directionText;
  final String? statusText;

  /// 非空表示被记账规则跳过（交易关闭/退款等），不入账
  final String? skipReason;

  final List<String> rawCells;

  bool get isRuleSkipped => skipReason != null;

  ImportPreviewRow copyWith({
    bool? valid,
    bool? selected,
    CreateTransactionInput? input,
    String? validationError,
    TransactionType? type,
    DateTime? date,
    int? amountCents,
    int? categoryId,
    String? categoryName,
    String? originalCategoryName,
    String? accountName,
    String? description,
    String? directionText,
    String? statusText,
    String? skipReason,
    List<String>? rawCells,
  }) {
    return ImportPreviewRow(
      index: index,
      lineNo: lineNo,
      valid: valid ?? this.valid,
      selected: selected ?? this.selected,
      input: input ?? this.input,
      validationError: validationError ?? this.validationError,
      type: type ?? this.type,
      date: date ?? this.date,
      amountCents: amountCents ?? this.amountCents,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      originalCategoryName: originalCategoryName ?? this.originalCategoryName,
      accountName: accountName ?? this.accountName,
      description: description ?? this.description,
      directionText: directionText ?? this.directionText,
      statusText: statusText ?? this.statusText,
      skipReason: skipReason ?? this.skipReason,
      rawCells: rawCells ?? this.rawCells,
    );
  }
}

class ImportParseResult {
  const ImportParseResult({
    required this.rows,
    this.alipayOfficialSummary,
    this.skippedByRule = 0,
    this.skipReasons = const {},
  });

  final List<ImportPreviewRow> rows;
  final AlipayCsvOfficialSummary? alipayOfficialSummary;
  final int skippedByRule;
  final Map<String, int> skipReasons;

  int get validCount => rows.where((row) => row.valid).length;

  int get invalidCount =>
      rows.where((row) => !row.valid && !row.isRuleSkipped).length;

  int get skippedCount => rows.where((row) => row.isRuleSkipped).length;
}
