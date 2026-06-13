import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/account_currency_catalog.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/category_icon_catalog.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

export 'package:ezbookkeeping_desktop/desktop/constants/account_currency_catalog.dart';
export 'package:ezbookkeeping_desktop/desktop/constants/account_icon_catalog.dart';
export 'package:ezbookkeeping_desktop/desktop/constants/category_icon_catalog.dart';

IconData accountTypeIcon(AccountType type) {
  return switch (type) {
    AccountType.none => Icons.block_outlined,
    AccountType.cash => Icons.payments_outlined,
    AccountType.alipay => Icons.account_balance_wallet_outlined,
    AccountType.wechat => Icons.chat_outlined,
    AccountType.bankCard => Icons.credit_card_outlined,
    AccountType.creditCard => Icons.credit_score_outlined,
    AccountType.virtual => Icons.cloud_outlined,
  };
}

const kAccountColorOptions = [
  Color(0xFF2D2A26),
  Color(0xFFC07C4D),
  Color(0xFF3BA99C),
  Color(0xFFE05D5D),
  Color(0xFF6B8CAE),
  Color(0xFF5C6BC0),
  Color(0xFF8D6E63),
  Color(0xFF7BC67E),
];

/// 分类/账户表单共用的颜色选项（与参考版一致）
const kCategoryColorOptions = kAccountColorOptions;

String colorToStorage(Color color) {
  final value = color.toARGB32();
  return '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

Color? colorFromStorage(String? stored) {
  if (stored == null || stored.trim().isEmpty) return null;
  var hex = stored.trim();
  if (hex.startsWith('#')) {
    hex = hex.substring(1);
  }
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length != 8) return null;
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  return Color(value);
}

Color categoryIconColor(String? storedColor, {Color fallback = AppColors.primary}) {
  return colorFromStorage(storedColor) ?? fallback;
}
