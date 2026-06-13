import 'package:ezbookkeeping_desktop/core/models/enums.dart';

/// Picker order: none first, then concrete types.
const kAccountTypePickerOptions = [
  AccountType.none,
  AccountType.cash,
  AccountType.alipay,
  AccountType.wechat,
  AccountType.bankCard,
  AccountType.creditCard,
  AccountType.virtual,
];

String accountTypeLabel(AccountType type) {
  return switch (type) {
    AccountType.none => '\u65e0',
    AccountType.cash => '\u73b0\u91d1',
    AccountType.alipay => '\u652f\u4ed8\u5b9d',
    AccountType.wechat => '\u5fae\u4fe1',
    AccountType.bankCard => '\u94f6\u884c\u5361',
    AccountType.creditCard => '\u4fe1\u7528\u5361',
    AccountType.virtual => '\u865a\u62df',
  };
}

String accountNameWithTypeLabel(AccountType type, String name) {
  if (type == AccountType.none) return name;
  return '${accountTypeLabel(type)} \u00b7 $name';
}
String categoryTypeLabel(CategoryType type) {
  return switch (type) {
    CategoryType.expense => '支出',
    CategoryType.income => '收入',
    CategoryType.transfer => '转账',
  };
}

String loanTypeLabel(LoanType type) {
  return switch (type) {
    LoanType.borrow => '借入',
    LoanType.lend => '借出',
  };
}

String budgetPeriodLabel(BudgetPeriodType type) {
  return switch (type) {
    BudgetPeriodType.monthly => '每月',
    BudgetPeriodType.yearly => '每年',
    BudgetPeriodType.custom => '自定义',
  };
}

String scheduledFrequencyLabel(ScheduledFrequency frequency) {
  return switch (frequency) {
    ScheduledFrequency.daily => '每天',
    ScheduledFrequency.weekly => '每周',
    ScheduledFrequency.monthly => '每月',
    ScheduledFrequency.yearly => '每年',
  };
}

/// 周期间隔描述，如「每2周」「每月」
String scheduledIntervalLabel({
  required ScheduledFrequency frequency,
  required int intervalCount,
}) {
  if (intervalCount <= 1) return scheduledFrequencyLabel(frequency);
  return switch (frequency) {
    ScheduledFrequency.daily => '每${intervalCount}天',
    ScheduledFrequency.weekly => '每${intervalCount}周',
    ScheduledFrequency.monthly => '每${intervalCount}个月',
    ScheduledFrequency.yearly => '每${intervalCount}年',
  };
}

String weekdayLabel(int weekday) {
  return switch (weekday) {
    DateTime.monday => '周一',
    DateTime.tuesday => '周二',
    DateTime.wednesday => '周三',
    DateTime.thursday => '周四',
    DateTime.friday => '周五',
    DateTime.saturday => '周六',
    DateTime.sunday => '周日',
    _ => '周$weekday',
  };
}

String transactionTypeLabel(TransactionType type) {
  return switch (type) {
    TransactionType.expense => '支出',
    TransactionType.income => '收入',
    TransactionType.transfer => '转账',
  };
}
