/// 记账本统计规则（通用版，以「收/支」为最高优先级）
class BookkeepingMetricsRules {
  BookkeepingMetricsRules._();

  /// 净转账：转给他人 / 账户存取（推荐）
  static const netTransferCategories = {
    '转账红包',
    '账户存取',
    '收钱码收款',
  };

  /// 转账总流水（可选）
  static const totalFlowCategories = {
    '转账红包',
    '账户存取',
    '投资理财',
    '信用借还',
  };

  static const incomeDirections = {'收入'};
  static const expenseDirections = {'支出'};
  static const neutralDirections = {
    '不计收支',
    '不计入收支',
    '/', // 微信中性交易
    '中性',
    '中性交易',
  };

  /// 支付宝/微信/网银等账单中常见的「成功」状态（与「交易成功」等价）
  static const successStatuses = {
    '交易成功',
    '支付成功',
    '付款成功',
    '提现成功',
    '充值成功',
    '充值完成',
    '提现已到账',
    '成功',
    '已完成',
    '已收款',
    '已支付',
    '确认收货',
    '已存入零钱',
    '已转账',
    '已收钱',
    '对方已收钱',
    '转入成功',
    '资金准备完成',
  };

  static const incomeStatuses = successStatuses;
  static const expenseStatuses = successStatuses;

  static const excludedStatuses = {
    '交易关闭',
    '关闭',
    '退款成功',
    '已退款',
    '退款',
    '交易失败',
    '失败',
    '等待付款',
    '待付款',
    '已全额退款',
    '已部分退款',
  };

  /// 是否应导入账本（交易关闭、退款成功等不入账）
  static bool shouldImportRow({
    required String? direction,
    required String? status,
    required String? categoryName,
  }) {
    final dir = _normalize(direction);
    final st = _normalize(status);
    final cat = categoryName?.trim() ?? '';

    if (isRefundRow(categoryName: cat, status: st)) return false;
    if (isClosedStatus(st)) return false;
    if (excludedStatuses.contains(st)) return false;

    if (neutralDirections.contains(dir)) return true;

    // 自定义 CSV / 本应用导出无「交易状态」列时，按收/支方向入账
    if (st.isEmpty) {
      return incomeDirections.contains(dir) || expenseDirections.contains(dir);
    }

    if (incomeDirections.contains(dir)) return isImportableSuccessStatus(st);
    if (expenseDirections.contains(dir)) return isImportableSuccessStatus(st);
    return false;
  }

  /// 是否为可导入的成功状态（兼容支付成功、已收款等别名）
  static bool isImportableSuccessStatus(String? status) {
    final st = _normalize(status);
    if (st.isEmpty) return true;
    if (excludedStatuses.contains(st) || isClosedStatus(st)) return false;
    if (successStatuses.contains(st)) return true;
    // 部分账单带后缀：支付成功(合并支付)
    return successStatuses.any((ok) => st.startsWith(ok));
  }

  static bool isRefundRow({
    required String categoryName,
    required String? status,
  }) {
    final st = _normalize(status);
    return categoryName.contains('退款') &&
        (st == '退款成功' || st == '已退款' || st == '退款');
  }

  static bool isClosedStatus(String? status) {
    final st = _normalize(status);
    return st == '交易关闭' || st == '关闭';
  }

  /// 是否计入总收入
  static bool countsAsIncome({
    required String? direction,
    required String? status,
  }) {
    return incomeDirections.contains(_normalize(direction)) &&
        incomeStatuses.contains(_normalize(status));
  }

  /// 是否计入总支出
  static bool countsAsExpense({
    required String? direction,
    required String? status,
  }) {
    return expenseDirections.contains(_normalize(direction)) &&
        expenseStatuses.contains(_normalize(status));
  }

  /// 是否计入「总支出」卡片（净转账类单独统计，不计入收支合计）
  static bool countsInExpenseTotal({
    required String? categoryName,
    required String? direction,
    required String? status,
  }) {
    if (!countsAsExpense(direction: direction, status: status)) return false;
    return !countsAsNetTransfer(
      categoryName: categoryName,
      direction: direction,
      status: status,
    );
  }

  /// 是否计入「总收入」卡片（净转账类单独统计，不计入收支合计）
  static bool countsInIncomeTotal({
    required String? categoryName,
    required String? direction,
    required String? status,
  }) {
    if (!countsAsIncome(direction: direction, status: status)) return false;
    return !countsAsNetTransfer(
      categoryName: categoryName,
      direction: direction,
      status: status,
    );
  }

  /// 是否「不计收支」流水（不影响结余）
  static bool isNeutralFlow({required String? direction}) {
    return neutralDirections.contains(_normalize(direction));
  }

  /// 净转账金额（规则 5.1）
  static bool countsAsNetTransfer({
    required String? categoryName,
    required String? direction,
    required String? status,
  }) {
    final cat = categoryName?.trim() ?? '';
    final dir = _normalize(direction);
    final st = _normalize(status);
    if (!expenseStatuses.contains(st) && !incomeStatuses.contains(st)) {
      return false;
    }
    if (!incomeDirections.contains(dir) && !expenseDirections.contains(dir)) {
      return false;
    }
    return netTransferCategories.any(cat.contains);
  }

  /// 转账总流水（规则 5.2）
  static bool countsAsTransferTotalFlow({
    required String? categoryName,
    required String? direction,
    required String? status,
  }) {
    final cat = categoryName?.trim() ?? '';
    final st = _normalize(status);
    if (excludedStatuses.contains(st) || isClosedStatus(st)) return false;
    if (totalFlowCategories.any(cat.contains)) {
      return true;
    }
    return isNeutralFlow(direction: direction) &&
        totalFlowCategories.any(cat.contains);
  }

  static int calcDaySpan(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    return days > 0 ? days : 1;
  }

  static double? calcSavingsRate({
    required int incomeCents,
    required int netCents,
  }) {
    if (incomeCents <= 0) return null;
    return netCents / incomeCents * 100;
  }

  static String _normalize(String? raw) => raw?.trim() ?? '';
}

enum TransferMetricMode {
  /// 净转账支出（推荐）
  netTransfer,
  /// 转账总流水
  totalFlow,
}
