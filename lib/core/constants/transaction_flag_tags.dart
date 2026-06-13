/// 账单标记类标签（与退款/优惠同类，通过 transaction_tags 持久化）
abstract final class TransactionFlagTags {
  static const excludeFromIo = '不计入收支';
  static const excludeFromBudget = '不计入预算';
  static const refund = '退款';
  static const discount = '优惠';
  static const reimbursed = '已报销';
}
