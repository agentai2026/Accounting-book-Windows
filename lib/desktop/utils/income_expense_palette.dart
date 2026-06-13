import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

/// 根据设置解析收支展示色
class IncomeExpensePalette {
  IncomeExpensePalette._();

  static Color income({
    required bool customEnabled,
    required IncomeExpenseColorScheme scheme,
  }) {
    if (!customEnabled) return AppColors.income;
    return switch (scheme) {
      IncomeExpenseColorScheme.greenRed => const Color(0xFF3BA99C),
      IncomeExpenseColorScheme.redGreen => const Color(0xFFE05D5D),
      IncomeExpenseColorScheme.colorWeak => const Color(0xFF1976D2),
    };
  }

  static Color expense({
    required bool customEnabled,
    required IncomeExpenseColorScheme scheme,
  }) {
    if (!customEnabled) return AppColors.expense;
    return switch (scheme) {
      IncomeExpenseColorScheme.greenRed => const Color(0xFFE05D5D),
      IncomeExpenseColorScheme.redGreen => const Color(0xFF3BA99C),
      IncomeExpenseColorScheme.colorWeak => const Color(0xFFE65100),
    };
  }
}
