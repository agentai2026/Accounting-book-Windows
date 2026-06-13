import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/ocr_text_line.dart';
import 'package:ezbookkeeping_desktop/core/services/receipt_bill_extractor.dart';

OcrTextLine _line(
  String text, {
  double top = 0,
  double height = 20,
  required int index,
}) {
  return OcrTextLine(
    text: text,
    confidence: 0.92,
    boundingBox: Rect.fromLTWH(10, top, 200, height),
    index: index,
  );
}

void main() {
  const extractor = ReceiptBillExtractor();

  test('小票实付金额提取', () {
    final lines = [
      _line('星巴克咖啡', top: 10, height: 28, index: 0),
      _line('2026-03-15 14:30', top: 40, index: 1),
      _line('合计 38.00', top: 200, index: 2),
      _line('实付 38.00', top: 230, height: 24, index: 3),
    ];

    final result = extractor.extract(lines);
    expect(result, isNotNull);
    expect(result!.amountCents, 3800);
    expect(result.type, TransactionType.expense);
    expect(result.merchant, '星巴克咖啡');
    expect(result.appCategoryName, '食品');
    expect(result.primaryCategory, '餐饮');
  });

  test('退款识别为收入', () {
    final lines = [
      _line('京东自营', top: 10, index: 0),
      _line('退款成功', top: 50, index: 1),
      _line('实退 128.50', top: 100, index: 2),
    ];

    final result = extractor.extract(lines);
    expect(result, isNotNull);
    expect(result!.type, TransactionType.income);
    expect(result.amountCents, 12850);
  });

  test('无关键词时取底部较大金额', () {
    final lines = [
      _line('某某超市', top: 10, index: 0),
      _line('商品A  12.00', top: 80, index: 1),
      _line('88.00', top: 300, height: 30, index: 2),
    ];

    final result = extractor.extract(lines);
    expect(result, isNotNull);
    expect(result!.amountCents, 8800);
  });

  test('商户名称标签提取', () {
    final lines = [
      _line('欢迎光临', index: 0),
      _line('商户名称：海底捞火锅', index: 1),
      _line('实付 268.00', top: 200, index: 2),
    ];

    final result = extractor.extract(lines);
    expect(result, isNotNull);
    expect(result!.merchant, '海底捞火锅');
    expect(result.primaryCategory, '餐饮');
  });
}
