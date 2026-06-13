enum TransactionType {
  expense(0),
  income(1),
  transfer(2);

  const TransactionType(this.value);
  final int value;

  static TransactionType fromValue(int value) {
    return TransactionType.values.firstWhere((e) => e.value == value);
  }
}

enum AccountType {
  cash(0),
  alipay(1),
  wechat(2),
  bankCard(3),
  creditCard(4),
  virtual(5),
  none(6);

  const AccountType(this.value);
  final int value;

  static AccountType fromValue(int value) {
    return AccountType.values.firstWhere((e) => e.value == value);
  }
}

enum CategoryType {
  expense(0),
  income(1),
  transfer(2);

  const CategoryType(this.value);
  final int value;

  static CategoryType fromValue(int value) {
    return CategoryType.values.firstWhere((e) => e.value == value);
  }
}

enum LoanType {
  borrow(0),
  lend(1);

  const LoanType(this.value);
  final int value;

  static LoanType fromValue(int value) {
    return LoanType.values.firstWhere((e) => e.value == value);
  }
}

enum BudgetPeriodType {
  monthly(0),
  yearly(1),
  custom(2);

  const BudgetPeriodType(this.value);
  final int value;

  static BudgetPeriodType fromValue(int value) {
    return BudgetPeriodType.values.firstWhere((e) => e.value == value);
  }
}

/// 周期记账频率
enum ScheduledFrequency {
  daily(0),
  weekly(1),
  monthly(2),
  yearly(3);

  const ScheduledFrequency(this.value);
  final int value;

  static ScheduledFrequency fromValue(int value) {
    return ScheduledFrequency.values.firstWhere((e) => e.value == value);
  }
}

enum SyncStatus {
  success(0),
  failed(1);

  const SyncStatus(this.value);
  final int value;

  static SyncStatus fromValue(int value) {
    return SyncStatus.values.firstWhere((e) => e.value == value);
  }
}

enum ReimbursementStatus {
  pending,
  reimbursed,
  all,
}
