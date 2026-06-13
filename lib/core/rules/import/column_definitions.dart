/// 交易导入/导出 CSV、Excel 列定义（表头需与导出一致）
class TransactionImportColumns {
  TransactionImportColumns._();

  static const headers = [
    '日期',
    '类型',
    '金额',
    '分类',
    '账户',
    '付款人',
    '备注',
  ];

  static const headerLine = '日期,类型,金额,分类,账户,付款人,备注';

  static const templateExample = [
    '2026/06/10 12:30',
    '支出',
    '35.00',
    '食品',
    '微信',
    '美团外卖',
    '午餐',
  ];

  static const legacyHeaders = [
    '日期',
    '类型',
    '金额',
    '分类ID',
    '备注',
  ];

  static const dateAliases = [
    '日期',
    'date',
    '交易时间',
    '付款时间',
    '交易创建时间',
    '时间',
  ];
  static const typeAliases = ['类型', 'type', '收支类型', '收/支', '收支'];
  static const amountAliases = [
    '金额',
    'amount',
    '交易金额',
    '金额(元)',
    '金额（元）',
  ];
  static const categoryIdAliases = ['分类id', 'categoryid', 'category_id'];
  static const categoryNameAliases = [
    '分类',
    '分类名称',
    'category',
    'category_name',
    '交易分类',
  ];
  static const accountAliases = [
    '账户',
    'account',
    '付款账户',
    '收款账户',
    '收/付款方式',
    '支付方式',
  ];
  static const fromAccountAliases = ['转出账户', 'from_account', 'fromaccount'];
  static const toAccountAliases = ['转入账户', 'to_account', 'toaccount'];
  static const payerAliases = [
    '付款人',
    '收款人',
    '对方',
    'payer',
    '交易对方',
  ];
  static const remarkAliases = [
    '备注',
    '说明',
    'comment',
    'description',
    '摘要',
    '商品说明',
    '商品名称',
  ];
  static const statusAliases = [
    '交易状态',
    '当前状态',
    '订单状态',
    '状态',
    'status',
  ];
  static const refundAmountAliases = [
    '成功退款(元)',
    '成功退款（元）',
    '成功退款',
    '退款金额',
  ];
}
