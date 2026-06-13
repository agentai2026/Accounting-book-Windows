import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

/// 搜索页配色（与全局暖色主题一致）
class SearchPageColors {
  SearchPageColors._();

  /// 交互强调色（按钮、选中、图标）
  static const accent = AppColors.primary;

  @Deprecated('Use SearchPageColors.accent')
  static const searchGreen = AppColors.primary;

  static const expenseOrange = Color(0xFFE2955D);
  static const expenseRed = AppColors.expense;
  static const expenseBar = AppColors.expense;
  static const incomeBlue = AppColors.transfer;
  static const incomeGreen = AppColors.income;
  static const incomeBar = AppColors.income;
  static const balanceGreen = AppColors.income;
  static const chipSelectedBg = AppColors.selectedBackground;
  static const detailHeaderTeal = AppColors.primary;
}
