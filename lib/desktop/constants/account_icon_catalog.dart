import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/constants/icon_constants.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/line_awesome_icon_resolver.dart';

class AccountIconOption {
  const AccountIconOption({
    required this.key,
    required this.icon,
    this.label,
  });

  final String key;
  final IconData icon;
  final String? label;
}

/// Same IDs and order as ezBookkeeping `ALL_ACCOUNT_ICONS`.
final kAccountIconCatalog = [
  for (final id in accountIconIdsInOrder)
    AccountIconOption(
      key: id,
      icon: lineAwesomeIconFromCssClass(accountIconCssClass(id)),
    ),
];

/// Maps legacy string keys saved before ezBookkeeping icon IDs were adopted.
const _legacyAccountIconKeyAliases = {
  'wallet': '1',
  'cash': '10',
  'receipt': '701',
  'pos': '701',
  'piggy': '30',
  'savings': '30',
  'credit_card': '100',
  'bank': '100',
  'contactless': '8101',
  'unionpay': '8101',
  'trend_up': '801',
  'chart': '801',
  'building': '911',
  'factory': '912',
  'home': '910',
  'groups': '901',
  'globe': '990',
  'usd': '1000',
  'eur': '1001',
  'gbp': '1002',
  'cny': '1003',
  'jpy': '1003',
  'rub': '1004',
  'inr': '1005',
  'krw': '1006',
  'ngn': '1007',
  'uah': '1008',
  'kzt': '1009',
  'btc': '1500',
  'eth': '1501',
  'visa': '5000',
  'mastercard': '5001',
  'amex': '5002',
  'discover': '5100',
  'jcb': '5200',
  'paypal': '8000',
  'apple_pay': '8100',
  'amazon_pay': '8200',
  'stripe': '8201',
  'alipay': '8300',
  'wechat': '8302',
  'line_pay': '8303',
  'cloud': '8101',
  'store': '911',
  'work': '911',
  'school': '700',
  'health': '560',
  'travel': '990',
  'food': '540',
  'shopping': '530',
};

String resolveAccountIconKey(String? key) {
  if (key == null || key.isEmpty) return defaultAccountIconId;
  return _legacyAccountIconKeyAliases[key] ?? key;
}

AccountIconOption accountIconOptionOf(String? key) {
  final resolved = resolveAccountIconKey(key);
  for (final option in kAccountIconCatalog) {
    if (option.key == resolved) return option;
  }
  return kAccountIconCatalog.first;
}

AccountType accountTypeFromIconKey(String key) {
  final resolved = resolveAccountIconKey(key);
  return switch (resolved) {
    '8300' => AccountType.alipay,
    '8302' || '8303' => AccountType.wechat,
    '100' ||
    '5000' ||
    '5001' ||
    '5002' ||
    '5100' ||
    '5200' ||
    '5300' =>
      AccountType.creditCard,
    '8101' ||
    '8000' ||
    '8201' ||
    '8100' ||
    '8200' ||
    '1500' ||
    '1501' =>
      AccountType.virtual,
    _ => AccountType.cash,
  };
}

Widget buildAccountIconWidget(
  String? iconKey, {
  Color color = Colors.black87,
  double size = 22,
  AccountType? fallbackType,
}) {
  final option = accountIconOptionOf(iconKey);
  return Icon(option.icon, size: size, color: color);
}

IconData accountIconData(String? iconKey, {AccountType? fallbackType}) {
  return accountIconOptionOf(iconKey).icon;
}
