import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/core/ai/index.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/receipt_text_parser.dart';

import 'ai_recognition_benchmark_cases.dart';

class _CaseResult {
  _CaseResult({
    required this.id,
    required this.category,
    required this.passed,
    this.errors = const [],
  });

  final String id;
  final String category;
  final bool passed;
  final List<String> errors;
}

/// 走 TextParser（与 AI 识图对话框一致）
const _textParserCategories = {
  '银行月账单-收入',
  '银行月账单-支出',
  '微信支付',
  '微信转账-收入',
  '微信转账-支出',
  '支付宝账单',
  'OCR边界',
  '负样本',
};

/// 走 BillParser 小票路径
const _billOnlyCategories = {'纸质小票'};

List<OcrBlock> _textToBlocks(String text) {
  final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
  return [
    for (var i = 0; i < lines.length; i++)
      OcrBlock(
        text: lines[i],
        score: 0.92,
        box: [10.0, i * 24.0, 300.0, i * 24.0 + 20.0],
      ),
  ];
}

List<String> _validateCase(
  AiRecognitionBenchmarkCase c,
  dynamic result, {
  required bool isBill,
}) {
  final errors = <String>[];

  if (!c.shouldParse) {
    if (result != null) {
      errors.add('期望解析失败，实际返回了结果');
    }
    return errors;
  }

  if (result == null) {
    errors.add('期望解析成功，实际返回 null');
    return errors;
  }

  TransactionType? type;
  int? amountCents;
  String? payer;
  String? description;
  String? accountName;
  DateTime? date;

  if (isBill) {
    final bill = result as Bill;
    type = switch (bill.type) {
      BillType.expense => TransactionType.expense,
      BillType.income => TransactionType.income,
      BillType.transfer => TransactionType.transfer,
    };
    amountCents = (bill.amount * 100).round();
    payer = bill.merchant;
  } else {
    final r = result;
    type = r.type;
    amountCents = r.amountCents;
    payer = r.payer;
    description = r.description;
    accountName = r.accountName;
    date = r.date;
  }

  if (c.type != null && type != c.type) {
    errors.add('类型: 期望 ${c.type!.name}，实际 ${type?.name ?? 'null'}');
  }
  if (c.amountCents != null && amountCents != c.amountCents) {
    errors.add('金额: 期望 ${c.amountCents} 分，实际 $amountCents 分');
  }
  if (c.payerExact != null && payer != c.payerExact) {
    errors.add('付款人: 期望「${c.payerExact}」，实际「$payer」');
  }
  if (c.payerContains != null &&
      (payer == null || !payer.contains(c.payerContains!))) {
    errors.add('付款人: 期望包含「${c.payerContains}」，实际「$payer」');
  }
  if (!isBill && c.descriptionContains != null) {
    if (description == null || !description.contains(c.descriptionContains!)) {
      errors.add('备注: 期望包含「${c.descriptionContains}」，实际「$description」');
    }
  }
  if (!isBill && c.accountName != null && accountName != c.accountName) {
    errors.add('账户: 期望「${c.accountName}」，实际「$accountName」');
  }

  if (c.year != null) {
    if (date == null) {
      errors.add('日期: 期望有日期，实际 null');
    } else {
      if (c.year != null && date.year != c.year) {
        errors.add('年: 期望 ${c.year}，实际 ${date.year}');
      }
      if (c.month != null && date.month != c.month) {
        errors.add('月: 期望 ${c.month}，实际 ${date.month}');
      }
      if (c.day != null && date.day != c.day) {
        errors.add('日: 期望 ${c.day}，实际 ${date.day}');
      }
      if (c.hour != null && date.hour != c.hour) {
        errors.add('时: 期望 ${c.hour}，实际 ${date.hour}');
      }
      if (c.minute != null && date.minute != c.minute) {
        errors.add('分: 期望 ${c.minute}，实际 ${date.minute}');
      }
    }
  }

  return errors;
}

void main() {
  final cases = buildAiRecognitionBenchmarkCases();
  final textParser = ReceiptTextParser();
  final billParser = BillParser();

  test('AI识图基准测试 ${cases.length} 条', () {
    expect(cases.length, greaterThanOrEqualTo(200));

    final textResults = <_CaseResult>[];
    final billResults = <_CaseResult>[];
    final aiPathResults = <_CaseResult>[];

    for (final c in cases) {
      final useText = _textParserCategories.contains(c.category);
      final useBill = _billOnlyCategories.contains(c.category) || useText;

      if (useText) {
        final textResult = textParser.parseForRecognition(c.ocrText);
        final textErrors = _validateCase(c, textResult, isBill: false);
        textResults.add(_CaseResult(
          id: c.id,
          category: c.category,
          passed: textErrors.isEmpty,
          errors: textErrors,
        ));
        aiPathResults.add(_CaseResult(
          id: c.id,
          category: c.category,
          passed: textErrors.isEmpty,
          errors: textErrors,
        ));
      }

      if (useBill) {
        final bill = billParser.parseBillFromOCR(
          _textToBlocks(c.ocrText),
          options: const BillParserOptions(expenseIncomeOnly: true),
        );
        final billErrors = _validateCase(c, bill, isBill: true);
        billResults.add(_CaseResult(
          id: c.id,
          category: c.category,
          passed: billErrors.isEmpty,
          errors: billErrors,
        ));
        if (_billOnlyCategories.contains(c.category)) {
          aiPathResults.add(_CaseResult(
            id: c.id,
            category: c.category,
            passed: billErrors.isEmpty,
            errors: billErrors,
          ));
        }
      }
    }

    _printReport('AI识图主路径（支付截图 TextParser + 小票 BillParser）', aiPathResults);
    _printReport('ReceiptTextParser 明细', textResults);
    _printReport('BillParser 明细', billResults);

    final aiPassed = aiPathResults.where((r) => r.passed).length;
    final aiTotal = aiPathResults.length;
    final aiFailed = aiPathResults.where((r) => !r.passed).toList();

    // ignore: avoid_print
    print('\n🎯 AI识图综合通过率: $aiPassed/$aiTotal '
        '(${(aiPassed / aiTotal * 100).toStringAsFixed(1)}%)');

    if (aiFailed.isNotEmpty) {
      final detail = aiFailed
          .map((r) => '  [${r.id}] ${r.errors.join('; ')}')
          .join('\n');
      // ignore: avoid_print
      print('\n⚠️ 未通过用例明细:\n$detail');
    }

    expect(aiPassed, greaterThanOrEqualTo(200),
        reason: 'AI识图基准至少 200 条应通过，实际 $aiPassed/$aiTotal');
    expect(aiPassed / aiTotal, equals(1.0),
        reason: 'AI识图通过率应为 100%，实际 ${(aiPassed / aiTotal * 100).toStringAsFixed(1)}%');
  });
}

void _printReport(String title, List<_CaseResult> results) {
  if (results.isEmpty) return;

  final total = results.length;
  final passed = results.where((r) => r.passed).length;
  final failed = total - passed;
  final rate = (passed / total * 100).toStringAsFixed(1);

  // ignore: avoid_print
  print('\n${'=' * 60}');
  // ignore: avoid_print
  print('📊 $title');
  // ignore: avoid_print
  print('${'=' * 60}');
  // ignore: avoid_print
  print('总计: $total 条 | ✅ 成功: $passed | ❌ 失败: $failed | 通过率: $rate%');

  final byCategory = <String, List<_CaseResult>>{};
  for (final r in results) {
    byCategory.putIfAbsent(r.category, () => []).add(r);
  }

  // ignore: avoid_print
  print('\n分类统计:');
  for (final entry in byCategory.entries) {
    final catPassed = entry.value.where((r) => r.passed).length;
    final catTotal = entry.value.length;
    final catRate = (catPassed / catTotal * 100).toStringAsFixed(0);
    final icon = catPassed == catTotal ? '✅' : '⚠️';
    // ignore: avoid_print
    print('  $icon ${entry.key}: $catPassed/$catTotal ($catRate%)');
  }

  final failures = results.where((r) => !r.passed).toList();
  if (failures.isNotEmpty) {
    // ignore: avoid_print
    print('\n失败用例 (${failures.length} 条):');
    for (final f in failures) {
      // ignore: avoid_print
      print('  ❌ [${f.id}] (${f.category})');
      for (final e in f.errors) {
        // ignore: avoid_print
        print('     → $e');
      }
    }
  }
}
