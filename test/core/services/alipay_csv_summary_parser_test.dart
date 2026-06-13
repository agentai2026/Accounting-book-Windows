import 'package:flutter_test/flutter_test.dart';
import 'package:ezbookkeeping_desktop/core/services/alipay_csv_summary_parser.dart';

void main() {
  test('解析支付宝 CSV 头部汇总', () {
    const content = '''
共509笔记录
收入：4笔 213.03元
支出：168笔 12964.76元
不计收支：337笔 691204.48元
''';

    final summary = AlipayCsvSummaryParser.parseFromContent(content);
    expect(summary, isNotNull);
    expect(summary!.totalRecords, 509);
    expect(summary.incomeCount, 4);
    expect(summary.incomeAmount, 213.03);
    expect(summary.expenseCount, 168);
    expect(summary.expenseAmount, 12964.76);
    expect(summary.neutralCount, 337);
    expect(summary.neutralAmount, 691204.48);
  });

  test('解析微信账单头部汇总', () {
    const content = '''
共186笔记录
收入：37笔 9177.45元
支出：141笔 29124.50元
中性交易：8笔 7125.41元
''';

    final summary = AlipayCsvSummaryParser.parseFromContent(content);
    expect(summary, isNotNull);
    expect(summary!.totalRecords, 186);
    expect(summary.incomeCount, 37);
    expect(summary.expenseCount, 141);
    expect(summary.neutralCount, 8);
    expect(summary.neutralAmount, 7125.41);
  });

  test('从 Excel 原始行解析汇总', () {
    final rows = [
      ['共186笔记录', '', ''],
      ['收入：37笔 9177.45元', '', ''],
      ['支出：141笔 29124.50元', '', ''],
      ['中性交易：8笔 7125.41元', '', ''],
    ];

    final summary = AlipayCsvSummaryParser.parseFromRows(rows);
    expect(summary?.totalRecords, 186);
    expect(summary?.neutralCount, 8);
  });
}
