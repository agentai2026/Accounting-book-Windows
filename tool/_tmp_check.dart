import 'package:ezbookkeeping_desktop/core/services/receipt_text_parser.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';

void main() {
  const parser = ReceiptTextParser();

  const alipay = '''
03:07
<账单详情 全部账单
海艳好合通讯--齐海(*海)>
-1,688.00
交易成功
创建时间 2026-06-0911:35:14
付款方式 余额宝)
转账备注 xt红订金
支付奖励 立即领取1积分
再转一笔
''';

  const bank = '''
11月 / 2025
0.00 支出(元)    5,417.00 收入(元)
03日
转账-宋宁
借记卡6579 17:25
+ ¥ 5,417.00
余额: ¥ 5,417.01
''';

  for (final (name, text) in [('支付宝账单', alipay), ('银行月账单', bank)]) {
    final r = parser.parse(text);
    print('=== $name ===');
    if (r == null) { print('识别失败'); continue; }
    print('类型: ${r.type}');
    print('金额(分): ${r.amountCents} => ${(r.amountCents / 100).toStringAsFixed(2)}');
    print('时间: ${r.date}');
    print('对方: ${r.payer}');
    print('备注: ${r.description}');
    print('账户: ${r.accountName}');
    print('分类: ${r.categoryName}');
    print('标签: ${r.tagNames}');
    print('场景: ${r.scene}');
    print('');
  }
}
