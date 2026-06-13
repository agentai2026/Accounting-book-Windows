import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction_form_draft.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/services/receipt_recognition_service.dart';

import 'real_image_benchmark_cases.dart';

class _ImageResult {
  _ImageResult({
    required this.id,
    required this.label,
    required this.passed,
    this.errors = const [],
    this.actualType,
    this.actualAmountCents,
    this.actualPayer,
    this.actualDate,
    this.ocrBlockCount,
    this.failureReason,
  });

  final String id;
  final String label;
  final bool passed;
  final List<String> errors;
  final TransactionType? actualType;
  final int? actualAmountCents;
  final String? actualPayer;
  final DateTime? actualDate;
  final int? ocrBlockCount;
  final String? failureReason;
}

String? _findImagePath(RealImageBenchmarkCase c) {
  final dir = Directory(kRealImageAssetsDir);
  if (!dir.existsSync()) return null;
  final needle = '${c.fileSuffix}-';
  for (final f in dir.listSync()) {
    if (f is File && f.path.contains(needle)) {
      return f.path;
    }
  }
  return null;
}

int? _parseAmountCents(String? amountText) {
  if (amountText == null || amountText.trim().isEmpty) return null;
  try {
    return MoneyUtils.parseToCents(amountText);
  } catch (_) {
    return null;
  }
}

List<String> _validate(
  RealImageBenchmarkCase c,
  TransactionFormDraft draft,
) {
  final errors = <String>[];

  if (c.expectedType != null) {
    if (draft.type == null) {
      errors.add('类型: 期望 ${c.expectedType!.name}，实际 null');
    } else if (draft.type != c.expectedType) {
      errors.add(
        '类型: 期望 ${c.expectedType!.name}，实际 ${draft.type!.name}',
      );
    }
  }
  if (draft.type == TransactionType.transfer) {
    errors.add('类型不应为 transfer');
  }

  if (c.amountCents != null) {
    final actual = _parseAmountCents(draft.amountText);
    if (actual == null) {
      errors.add('金额: 无法解析「${draft.amountText}」');
    } else if (actual != c.amountCents) {
      errors.add(
        '金额: 期望 ¥${(c.amountCents! / 100).toStringAsFixed(2)}，'
        '实际 ¥${(actual / 100).toStringAsFixed(2)}',
      );
    }
  }

  if (c.payerContains != null) {
    final payer = draft.payer ?? draft.description ?? '';
    if (!payer.contains(c.payerContains!)) {
      errors.add(
        '对方/商户: 期望包含「${c.payerContains}」，实际「$payer」',
      );
    }
  }

  if (c.year != null && draft.date != null) {
    if (draft.date!.year != c.year) {
      errors.add('年: 期望 ${c.year}，实际 ${draft.date!.year}');
    }
    if (c.month != null && draft.date!.month != c.month) {
      errors.add('月: 期望 ${c.month}，实际 ${draft.date!.month}');
    }
    if (c.day != null && !c.multiTransaction && draft.date!.day != c.day) {
      errors.add('日: 期望 ${c.day}，实际 ${draft.date!.day}');
    }
  } else if (c.year != null && draft.date == null) {
    errors.add('日期: 期望有日期，实际 null');
  }

  return errors;
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportDir;
  late Directory docsDir;
  late Directory tempDir;

  setUpAll(() {
    supportDir = Directory.systemTemp.createTempSync('ezb_support_');
    docsDir = Directory.systemTemp.createTempSync('ezb_docs_');
    tempDir = Directory.systemTemp.createTempSync('ezb_temp_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async {
        switch (call.method) {
          case 'getApplicationSupportDirectory':
            return supportDir.path;
          case 'getApplicationDocumentsDirectory':
            return docsDir.path;
          case 'getTemporaryDirectory':
            return tempDir.path;
          default:
            return null;
        }
      },
    );
  });

  test(
    '真实截图 OCR 全链路基准测试',
    () async {
    final cases = buildRealImageBenchmarkCases();
    expect(cases.length, 19);

    if (!Directory(kRealImageAssetsDir).existsSync()) {
      // ignore: avoid_print
      print('⚠️ 截图目录不存在: $kRealImageAssetsDir');
      return;
    }

    final service = ReceiptRecognitionService();
    const categories = <Category>[];
    const accounts = <Account>[];

    final results = <_ImageResult>[];

    for (final c in cases) {
      final path = _findImagePath(c);
      if (path == null) {
        results.add(_ImageResult(
          id: c.id,
          label: c.label,
          passed: false,
          errors: ['找不到图片: ${c.fileSuffix}'],
        ));
        continue;
      }

      final bytes = await File(path).readAsBytes();
      final result = await service.recognize(
        imageBytes: bytes,
        fileName: '${c.id}.png',
        categories: categories,
        accounts: accounts,
      );

      ReceiptRecognitionOutcome? outcome;
      String? failMsg;
      result.when(
        success: (data) => outcome = data,
        failure: (err) => failMsg = err.message,
      );

      if (outcome == null) {
        results.add(_ImageResult(
          id: c.id,
          label: c.label,
          passed: !c.shouldParse,
          errors: c.shouldParse ? [failMsg ?? '识别失败'] : [],
          failureReason: failMsg,
        ));
        continue;
      }

      final draft = outcome!.draft;
      final errors = c.shouldParse ? _validate(c, draft) : ['不应解析成功'];
      results.add(_ImageResult(
        id: c.id,
        label: c.label,
        passed: errors.isEmpty,
        errors: errors,
        actualType: draft.type,
        actualAmountCents: _parseAmountCents(draft.amountText),
        actualPayer: draft.payer ?? draft.description,
        actualDate: draft.date,
      ));
    }

    final passed = results.where((r) => r.passed).length;
    final total = results.length;
    final failed = results.where((r) => !r.passed).toList();

    // ignore: avoid_print
    print('\n${'=' * 60}');
    // ignore: avoid_print
    print('📸 真实截图 OCR 全链路测试');
    // ignore: avoid_print
    print('${'=' * 60}');
    // ignore: avoid_print
    print('总计: $total 张 | ✅ 成功: $passed | ❌ 失败: ${total - passed} '
        '| 通过率: ${(passed / total * 100).toStringAsFixed(1)}%');

    // ignore: avoid_print
    print('\n逐条结果:');
    for (final r in results) {
      final icon = r.passed ? '✅' : '❌';
      final typeStr = r.actualType?.name ?? '-';
      final amt = r.actualAmountCents != null
          ? '¥${(r.actualAmountCents! / 100).toStringAsFixed(2)}'
          : '-';
      // ignore: avoid_print
      print(
        '  $icon [${r.id}] ${r.label}\n'
        '      → 类型=$typeStr 金额=$amt 对方=${r.actualPayer ?? '-'} '
        '日期=${r.actualDate?.toString().substring(0, 10) ?? '-'}',
      );
      if (r.errors.isNotEmpty) {
        for (final e in r.errors) {
          // ignore: avoid_print
          print('      ⚠ $e');
        }
      }
      if (r.failureReason != null) {
        // ignore: avoid_print
        print('      ⚠ OCR/识别失败: ${r.failureReason}');
      }
    }

    if (failed.isNotEmpty) {
      // ignore: avoid_print
      print('\n失败摘要 (${failed.length} 张):');
      for (final f in failed) {
        // ignore: avoid_print
        print('  ❌ [${f.id}] ${f.label}: ${f.errors.join('; ')}');
      }
    }

    // 报告用例，不因失败而中断 CI（真实 OCR 依赖本机环境）
    expect(total, 19);
  },
    skip: Platform.environment['RUN_OCR_BENCHMARK'] != '1'
        ? 'Set RUN_OCR_BENCHMARK=1 to run real OCR benchmark'
        : false,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
