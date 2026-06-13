import 'package:flutter_test/flutter_test.dart';
import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/ai_match_utils.dart';

void main() {
  final now = DateTime(2026, 6, 11);

  Account account({
    required int id,
    required String name,
    AccountType type = AccountType.bankCard,
  }) {
    return Account(
      id: id,
      uuid: 'uuid-$id',
      bookId: 1,
      name: name,
      type: type,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('按卡号尾号匹配账户', () {
    final accounts = [
      account(id: 1, name: '现金'),
      account(id: 2, name: '银行卡6579'),
      account(id: 3, name: '银行卡1234'),
    ];

    expect(
      matchAccountIdByName(name: '借记卡6579', accounts: accounts),
      2,
    );
  });

  test('借记卡别名可匹配银行卡账户', () {
    final accounts = [
      account(id: 1, name: '现金'),
      account(id: 2, name: '银行卡'),
    ];

    expect(
      matchAccountIdByName(name: '借记卡', accounts: accounts),
      2,
    );
  });
}
