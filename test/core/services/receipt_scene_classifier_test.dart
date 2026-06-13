import 'package:flutter_test/flutter_test.dart';
import 'package:ezbookkeeping_desktop/core/models/receipt_scene.dart';
import 'package:ezbookkeeping_desktop/core/services/receipt_scene_classifier.dart';

void main() {
  const classifier = ReceiptSceneClassifier();

  List<String> lines(String text) =>
      text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  test('识别银行月账单', () {
    const text = '''
11月 / 2025
03日
转账-宋宁
借记卡6579 17:25
+ ¥ 5,417.00
余额: ¥ 5,417.01
''';

    final match = classifier.classify(text, lines(text));
    expect(match.scene, ReceiptScene.bankMonthlyBill);
    expect(match.isConfident, isTrue);
  });

  test('识别微信支付', () {
    const text = '''
支付成功
付款给 美团外卖
- ¥ 35.00
2026年1月15日 12:30:45
零钱
''';

    final match = classifier.classify(text, lines(text));
    expect(match.scene, ReceiptScene.wechatPayment);
  });

  test('识别支付宝付款', () {
    const text = '''
付款成功
收款方：麦当劳
- ¥ 28.50
2026年3月2日 18:20:10
支付宝
''';

    final match = classifier.classify(text, lines(text));
    expect(match.scene, ReceiptScene.alipayPayment);
  });
}
