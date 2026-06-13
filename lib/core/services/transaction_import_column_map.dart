import 'package:ezbookkeeping_desktop/core/constants/transaction_import_columns.dart';
import 'package:ezbookkeeping_desktop/core/services/import_column_mapping_config.dart';
import 'package:ezbookkeeping_desktop/core/services/import_header_detector.dart';

class TransactionImportColumnMap {
  const TransactionImportColumnMap({
    required this.date,
    required this.type,
    required this.amount,
    this.categoryId,
    this.categoryName,
    this.account,
    this.fromAccount,
    this.toAccount,
    this.payer,
    this.remark,
    this.status,
    this.refundAmount,
  });

  final int date;
  final int type;
  final int amount;
  final int? categoryId;
  final int? categoryName;
  final int? account;
  final int? fromAccount;
  final int? toAccount;
  final int? payer;
  final int? remark;
  final int? status;
  final int? refundAmount;

  factory TransactionImportColumnMap.fromHeaders(List<String> headers) {
    final normalized = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      normalized[_normalizeHeader(headers[i])] = i;
    }

    int? findIndex(List<String> aliases) {
      for (final alias in aliases) {
        final index = normalized[alias];
        if (index != null) return index;
      }
      return null;
    }

    int requireIndex(List<String> aliases, String label) {
      final index = findIndex(aliases);
      if (index == null) {
        throw FormatException('缺少必填列：$label');
      }
      return index;
    }

    if (findIndex(TransactionImportColumns.dateAliases) != null) {
      final typeIndex = findIndex(const [
        '收/支',
        '收支',
        '收支类型',
        '类型',
        'type',
      ]);
      return TransactionImportColumnMap(
        date: requireIndex(TransactionImportColumns.dateAliases, '日期'),
        type: typeIndex ?? requireIndex(TransactionImportColumns.typeAliases, '类型'),
        amount: requireIndex(TransactionImportColumns.amountAliases, '金额'),
        categoryId: findIndex(TransactionImportColumns.categoryIdAliases),
        categoryName: findIndex(TransactionImportColumns.categoryNameAliases),
        account: findIndex(TransactionImportColumns.accountAliases),
        fromAccount: findIndex(TransactionImportColumns.fromAccountAliases),
        toAccount: findIndex(TransactionImportColumns.toAccountAliases),
        payer: findIndex(TransactionImportColumns.payerAliases),
        remark: findIndex(TransactionImportColumns.remarkAliases),
        status: findIndex(TransactionImportColumns.statusAliases),
        refundAmount: findIndex(TransactionImportColumns.refundAmountAliases),
      );
    }

    return const TransactionImportColumnMap(
      date: 0,
      type: 1,
      amount: 2,
      categoryId: 3,
      remark: 4,
    );
  }

  /// 由「定义列」步骤的手动映射生成
  factory TransactionImportColumnMap.fromImportMapping(
    ImportColumnMappingConfig config,
  ) {
    int? col(ImportColumnField field) => config.columnFor(field);

    final date = col(ImportColumnField.time);
    final type = col(ImportColumnField.type);
    final amount = col(ImportColumnField.amount);
    if (date == null || type == null || amount == null) {
      throw FormatException('缺少必填列映射：时间、类型或金额');
    }

    return TransactionImportColumnMap(
      date: date,
      type: type,
      amount: amount,
      categoryName: col(ImportColumnField.category),
      account: col(ImportColumnField.account),
      remark: col(ImportColumnField.remark),
      status: col(ImportColumnField.status),
      payer: col(ImportColumnField.payer),
      refundAmount: col(ImportColumnField.refund),
    );
  }

  static String _normalizeHeader(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('（', '(')
        .replaceAll('）', ')');
  }

  static bool looksLikeHeaderRow(List<String> cells) {
    if (cells.length < 3) return false;
    try {
      TransactionImportColumnMap.fromHeaders(cells);
      return true;
    } catch (_) {
      return ImportHeaderDetector.looksLikePaymentBillHeader(cells);
    }
  }

  String? cell(List<String> row, int? index) {
    if (index == null || index >= row.length) return null;
    final value = row[index].trim();
    return value.isEmpty ? null : value;
  }
}
