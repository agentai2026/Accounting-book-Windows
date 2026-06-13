import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/core/rules/import/payment_import_formats.dart';

void main() {
  test('platformSourceForFileType maps wechat and alipay', () {
    expect(
      PaymentImportFormats.platformSourceForFileType('wechat_pay_csv'),
      '微信',
    );
    expect(
      PaymentImportFormats.platformSourceForFileType('alipay_app_csv'),
      '支付宝',
    );
  });

  test('detectPlatformFromText distinguishes wechat and alipay headers', () {
    expect(
      PaymentImportFormats.detectPlatformFromText(
        '微信支付账单明细\n微信昵称：test\n共10笔记录',
      ),
      '微信',
    );
    expect(
      PaymentImportFormats.detectPlatformFromText(
        '支付宝账户：test@qq.com\n共10笔记录\n收入：1笔 9.00元',
      ),
      '支付宝',
    );
  });
}
