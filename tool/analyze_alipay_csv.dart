import 'dart:io';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/alipay_type_resolver.dart';
import 'package:ezbookkeeping_desktop/core/services/transaction_import_amount_resolver.dart';
import 'package:ezbookkeeping_desktop/core/services/transaction_import_column_map.dart';
import 'package:ezbookkeeping_desktop/core/utils/text_file_encoding.dart';

Future<void> main(List<String> args) async {
  final path = args.first;
  final content = await readTextFileAutoEncoding(path);
  final lines = content
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  var headerIndex = -1;
  for (var i = 0; i < lines.length; i++) {
    final cells = _parseCsvLine(lines[i]);
    if (TransactionImportColumnMap.looksLikeHeaderRow(cells)) {
      headerIndex = i;
      break;
    }
  }
  if (headerIndex < 0) {
    print('未找到表头');
    return;
  }

  final columnMap =
      TransactionImportColumnMap.fromHeaders(_parseCsvLine(lines[headerIndex]));

  var incomeCount = 0;
  var expenseCount = 0;
  var neutralCount = 0;
  var closedCount = 0;
  var skippedOther = 0;
  var incomeSum = 0.0;
  var expenseSum = 0.0;
  var neutralSum = 0.0;
  var importableCount = 0;
  var importableExpenseCount = 0;
  var importableIncomeCount = 0;
  var importableExpenseSum = 0.0;
  var importableIncomeSum = 0.0;
  var importableTransferSum = 0.0;
  var importableTransferCount = 0;

  for (var i = headerIndex + 1; i < lines.length; i++) {
    final row = _parseCsvLine(lines[i]);
    final status = columnMap.cell(row, columnMap.status) ?? '';
    final typeText = columnMap.cell(row, columnMap.type);
    final amountText = columnMap.cell(row, columnMap.amount) ?? '0';
    final category = columnMap.cell(row, columnMap.categoryName);
    final amount = double.tryParse(amountText.replaceAll(',', '')) ?? 0;

    final direction = typeText?.trim() ?? '';
    if (direction == '收入') {
      incomeCount++;
      incomeSum += amount;
    } else if (direction == '支出') {
      expenseCount++;
      expenseSum += amount;
    } else if (direction == '不计收支') {
      neutralCount++;
      neutralSum += amount;
    }

    if (status == '交易关闭') {
      closedCount++;
      continue;
    }

    final type = AlipayTypeResolver.resolve(typeText: typeText, categoryName: category);
    if (type == null) {
      skippedOther++;
      print('SKIP type null line ${i + 1}: $typeText | $category | $amountText');
      continue;
    }

    final resolved = TransactionImportAmountResolver.resolve(
      type: type,
      amountText: amountText,
    );
    if (resolved == null) {
      skippedOther++;
      print('SKIP amount null line ${i + 1}: $typeText | $amountText');
      continue;
    }

    importableCount++;
    final cents = resolved.amountCents / 100;
    switch (resolved.type) {
      case TransactionType.expense:
        importableExpenseCount++;
        importableExpenseSum += cents;
      case TransactionType.income:
        importableIncomeCount++;
        importableIncomeSum += cents;
      case TransactionType.transfer:
        importableTransferSum += cents;
        importableTransferCount++;
    }
  }

  print('=== 支付宝文件头汇总 ===');
  print('收入: $incomeCount 笔, $incomeSum 元');
  print('支出: $expenseCount 笔, $expenseSum 元');
  print('不计收支: $neutralCount 笔, $neutralSum 元');
  print('合计: ${incomeCount + expenseCount + neutralCount} 笔');
  print('');
  var closedExpenseSum = 0.0;
  var closedExpenseCount = 0;
  var closedNeutralSum = 0.0;
  var closedNeutralCount = 0;
  var closedIncomeSum = 0.0;
  var successExpenseSum = 0.0;
  var successExpenseCount = 0;

  for (var i = headerIndex + 1; i < lines.length; i++) {
    final row = _parseCsvLine(lines[i]);
    final status = columnMap.cell(row, columnMap.status) ?? '';
    final typeText = columnMap.cell(row, columnMap.type) ?? '';
    final amountText = columnMap.cell(row, columnMap.amount) ?? '0';
    final amount = double.tryParse(amountText.replaceAll(',', '')) ?? 0;
    if (status != '交易关闭') {
      if (typeText == '支出') {
        successExpenseCount++;
        successExpenseSum += amount;
      }
      continue;
    }
    if (typeText == '支出') {
      closedExpenseCount++;
      closedExpenseSum += amount;
    } else if (typeText == '不计收支') {
      closedNeutralCount++;
      closedNeutralSum += amount;
    } else if (typeText == '收入') {
      closedIncomeSum += amount;
    }
  }

  print('=== 交易关闭拆分 ===');
  print('关闭-支出: $closedExpenseCount 笔, $closedExpenseSum 元');
  print('关闭-不计收支: $closedNeutralCount 笔, $closedNeutralSum 元');
  print('关闭-收入: $closedIncomeSum 元');
  print('成功-支出直接累加: $successExpenseCount 笔, $successExpenseSum 元');
  print('与支付宝头支出差: ${successExpenseSum - 12964.76}');
  print('关闭支出+头差验证: ${closedExpenseSum + (successExpenseSum - 12964.76)}');

  final suspectExpenses = <String>[];
  for (var i = headerIndex + 1; i < lines.length; i++) {
    final row = _parseCsvLine(lines[i]);
    final status = columnMap.cell(row, columnMap.status) ?? '';
    final typeText = columnMap.cell(row, columnMap.type) ?? '';
    if (status == '交易关闭' || typeText != '支出') continue;
    final category = columnMap.cell(row, columnMap.categoryName) ?? '';
    final remark = columnMap.cell(row, columnMap.remark) ?? '';
    final amount = columnMap.cell(row, columnMap.amount) ?? '';
    suspectExpenses.add('$category | $remark | $amount | $status');
  }
  print('成功支出中可能的特殊分类:');
  final categories = <String, double>{};
  for (var i = headerIndex + 1; i < lines.length; i++) {
    final row = _parseCsvLine(lines[i]);
    if ((columnMap.cell(row, columnMap.status) ?? '') == '交易关闭') continue;
    if ((columnMap.cell(row, columnMap.type) ?? '') != '支出') continue;
    final category = columnMap.cell(row, columnMap.categoryName) ?? '未知';
    final amount = double.tryParse(
          (columnMap.cell(row, columnMap.amount) ?? '0').replaceAll(',', ''),
        ) ??
        0;
    categories[category] = (categories[category] ?? 0) + amount;
  }
  for (final entry in categories.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value))) {
    print('  ${entry.key}: ${entry.value}');
  }

  const suspectKeywords = ['退款', '充值', '提现', '信用', '花呗', '借呗', '还款'];
  var suspectSum = 0.0;
  for (var i = headerIndex + 1; i < lines.length; i++) {
    final row = _parseCsvLine(lines[i]);
    if ((columnMap.cell(row, columnMap.status) ?? '') == '交易关闭') continue;
    if ((columnMap.cell(row, columnMap.type) ?? '') != '支出') continue;
    final remark = columnMap.cell(row, columnMap.remark) ?? '';
    final category = columnMap.cell(row, columnMap.categoryName) ?? '';
    final text = '$category $remark';
    if (!suspectKeywords.any(text.contains)) continue;
    final amount = double.tryParse(
          (columnMap.cell(row, columnMap.amount) ?? '0').replaceAll(',', ''),
        ) ??
        0;
    suspectSum += amount;
    print('  可疑支出: $category | $remark | $amount');
  }
  print('可疑支出合计: $suspectSum');
  print('');

  print('=== 导入逻辑可入账(跳过交易关闭) ===');
  print('可导入: $importableCount 笔 (交易关闭 $closedCount)');
  print('支出: $importableExpenseCount 笔, $importableExpenseSum 元');
  print('收入: $importableIncomeCount 笔, $importableIncomeSum 元');
  print('转账: $importableTransferCount 笔, $importableTransferSum 元');
  print('其它跳过: $skippedOther');
}

List<String> _parseCsvLine(String line) {
  final result = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        buffer.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == ',' && !inQuotes) {
      result.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  result.add(buffer.toString());
  return result;
}
