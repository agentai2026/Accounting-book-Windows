import 'package:ezbookkeeping_desktop/core/models/enums.dart';

/// 可选的默认账户预设（与 ezBookkeeping 参考版一致）
class DefaultAccountPreset {
  const DefaultAccountPreset({
    required this.name,
    required this.type,
    required this.icon,
    this.currency = 'CNY',
  });

  final String name;
  final AccountType type;
  final String icon;
  final String currency;
}

const kDefaultAccountPresets = <DefaultAccountPreset>[
  DefaultAccountPreset(
    name: '现金',
    type: AccountType.cash,
    icon: '1',
  ),
  DefaultAccountPreset(
    name: '支付宝',
    type: AccountType.alipay,
    icon: '8300',
  ),
  DefaultAccountPreset(
    name: '微信',
    type: AccountType.wechat,
    icon: '8302',
  ),
  DefaultAccountPreset(
    name: '银行卡',
    type: AccountType.bankCard,
    icon: '100',
  ),
  DefaultAccountPreset(
    name: '余额宝',
    type: AccountType.alipay,
    icon: '8300',
  ),
  DefaultAccountPreset(
    name: '花呗',
    type: AccountType.creditCard,
    icon: '200',
  ),
  DefaultAccountPreset(
    name: '云闪付',
    type: AccountType.bankCard,
    icon: '8101',
  ),
];
