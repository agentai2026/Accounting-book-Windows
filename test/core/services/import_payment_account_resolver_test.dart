import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/import_payment_account_resolver.dart';

void main() {
  final now = DateTime(2026, 6, 11);
  final accounts = [
    Account(
      id: 1,
      uuid: 'a1',
      bookId: 1,
      name: '现金',
      type: AccountType.cash,
      createdAt: now,
      updatedAt: now,
    ),
    Account(
      id: 2,
      uuid: 'a2',
      bookId: 1,
      name: '支付宝',
      type: AccountType.alipay,
      createdAt: now,
      updatedAt: now,
    ),
    Account(
      id: 3,
      uuid: 'a3',
      bookId: 1,
      name: '花呗',
      type: AccountType.creditCard,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  test('maps wechat and huabei payment methods', () {
    expect(
      ImportPaymentAccountResolver.resolveAccountName(
        paymentMethod: '微信零钱',
        importSource: '微信',
      ),
      '微信',
    );
    expect(
      ImportPaymentAccountResolver.resolveAccountName(
        paymentMethod: '花呗',
        importSource: '支付宝',
      ),
      '花呗',
    );
    expect(
      ImportPaymentAccountResolver.resolveAccountName(
        paymentMethod: '农业银行储蓄卡(6579)',
        importSource: '支付宝',
      ),
      '银行卡',
    );
  });

  test('does not default to cash when payment method empty', () {
    expect(
      ImportPaymentAccountResolver.resolveAccountName(
        paymentMethod: '',
        importSource: '支付宝',
      ),
      '支付宝',
    );
    expect(
      ImportPaymentAccountResolver.resolveAccountName(
        paymentMethod: null,
        importSource: null,
      ),
      isNull,
    );
  });

  test('findAccountIdByName matches preset account', () {
    expect(
      ImportPaymentAccountResolver.findAccountIdByName(
        accounts: accounts,
        accountName: '花呗',
      ),
      3,
    );
  });

  test('resolveAccountId maps bank card payment to account id', () {
    expect(
      ImportPaymentAccountResolver.resolveAccountId(
        accounts: [
          ...accounts,
          Account(
            id: 4,
            uuid: 'a4',
            bookId: 1,
            name: '银行卡',
            type: AccountType.bankCard,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        paymentMethod: '农业银行储蓄卡(6579)',
        importSource: '支付宝',
      ),
      4,
    );
  });
}
