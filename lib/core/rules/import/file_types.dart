/// 导入文件类型（3 个分类：支付 / 自定义表格 / 银行）
class ImportFileTypeOption {
  const ImportFileTypeOption({
    required this.category,
    required this.type,
    required this.label,
    required this.extensions,
    this.supportsEncoding = true,
    this.helpAnchor,
    this.comingSoon = false,
  });

  final String category;
  final String type;
  final String label;
  final List<String> extensions;
  final bool supportsEncoding;
  final String? helpAnchor;
  final bool comingSoon;
}

class ImportFileCategories {
  ImportFileCategories._();

  /// 支付宝、微信等第三方支付
  static const paymentApp = '支付应用对账单';

  /// CSV / Excel 万能兜底 + 定义列
  static const customTable = '自定义表格';

  /// 银行网银导出 + 国际通用对账单格式
  static const bankStatement = '银行对账单';

  static const ordered = [
    paymentApp,
    customTable,
    bankStatement,
  ];
}

class ImportFileTypes {
  ImportFileTypes._();

  static const autoEncoding = 'auto';
  static const utf8Encoding = 'utf-8';
  static const gbkEncoding = 'gbk';

  static const encodingOptions = [
    (value: autoEncoding, label: '自动检测'),
    (value: utf8Encoding, label: 'UTF-8'),
    (value: gbkEncoding, label: 'GBK / GB18030'),
  ];

  static const all = <ImportFileTypeOption>[
    // 支付应用对账单
    ImportFileTypeOption(
      category: ImportFileCategories.paymentApp,
      type: 'alipay_app_csv',
      label: '支付宝 App 对账单',
      extensions: ['csv'],
      helpAnchor: '如何获取支付宝app交易流水文件',
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.paymentApp,
      type: 'alipay_web_csv',
      label: '支付宝网页版对账单',
      extensions: ['csv'],
      helpAnchor: '如何获取支付宝网页版交易流水文件',
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.paymentApp,
      type: 'wechat_pay_xlsx',
      label: '微信支付账单（Excel）',
      extensions: ['xlsx'],
      supportsEncoding: false,
      helpAnchor: '如何获取微信支付账单文件',
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.paymentApp,
      type: 'wechat_pay_csv',
      label: '微信支付账单（CSV）',
      extensions: ['csv'],
      helpAnchor: '如何获取微信支付账单文件',
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.paymentApp,
      type: 'qq_pay',
      label: 'QQ钱包对账单',
      extensions: ['csv', 'xlsx', 'xls'],
      helpAnchor: 'how-to-import-delimiter-separated-values-dsv-file-or-data',
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.paymentApp,
      type: 'unionpay',
      label: '云闪付对账单',
      extensions: ['csv', 'xlsx', 'xls'],
      helpAnchor: 'how-to-import-delimiter-separated-values-dsv-file-or-data',
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.paymentApp,
      type: 'jdpay',
      label: '京东支付对账单',
      extensions: ['csv', 'xlsx', 'xls'],
      helpAnchor: 'how-to-import-delimiter-separated-values-dsv-file-or-data',
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.paymentApp,
      type: 'meituan',
      label: '美团账单',
      extensions: ['csv', 'xlsx', 'xls'],
      helpAnchor: 'how-to-import-delimiter-separated-values-dsv-file-or-data',
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.paymentApp,
      type: 'douyin_pay',
      label: '抖音支付账单',
      extensions: ['csv', 'xlsx', 'xls'],
      helpAnchor: 'how-to-import-delimiter-separated-values-dsv-file-or-data',
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.paymentApp,
      type: 'pdd_pay',
      label: '拼多多账单',
      extensions: ['csv', 'xlsx', 'xls'],
      helpAnchor: 'how-to-import-delimiter-separated-values-dsv-file-or-data',
    ),

    // 自定义表格
    ImportFileTypeOption(
      category: ImportFileCategories.customTable,
      type: 'custom_csv',
      label: 'CSV（逗号分隔）',
      extensions: ['csv'],
      helpAnchor: 'how-to-import-delimiter-separated-values-dsv-file-or-data',
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.customTable,
      type: 'custom_tsv',
      label: 'TSV（制表符分隔）',
      extensions: ['tsv', 'txt'],
      helpAnchor: 'how-to-import-delimiter-separated-values-dsv-file-or-data',
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.customTable,
      type: 'custom_xlsx',
      label: 'Excel 工作簿（.xlsx）',
      extensions: ['xlsx'],
      supportsEncoding: false,
      helpAnchor: 'how-to-import-delimiter-separated-values-dsv-file-or-data',
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.customTable,
      type: 'custom_xls',
      label: 'Excel 97-2003（.xls）',
      extensions: ['xls'],
      supportsEncoding: false,
      helpAnchor: 'how-to-import-delimiter-separated-values-dsv-file-or-data',
    ),

    // 银行对账单（国内网银 + 国际标准）
    ImportFileTypeOption(
      category: ImportFileCategories.bankStatement,
      type: 'bank_csv',
      label: '银行网银导出（CSV）',
      extensions: ['csv'],
      helpAnchor: 'how-to-import-delimiter-separated-values-dsv-file-or-data',
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.bankStatement,
      type: 'bank_xlsx',
      label: '银行网银导出（Excel）',
      extensions: ['xlsx', 'xls'],
      supportsEncoding: false,
      helpAnchor: 'how-to-import-delimiter-separated-values-dsv-file-or-data',
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.bankStatement,
      type: 'camt052',
      label: 'Camt.052（国际标准）',
      extensions: ['xml'],
      comingSoon: true,
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.bankStatement,
      type: 'camt053',
      label: 'Camt.053（国际标准）',
      extensions: ['xml'],
      comingSoon: true,
    ),
    ImportFileTypeOption(
      category: ImportFileCategories.bankStatement,
      type: 'mt940',
      label: 'MT940（国际标准）',
      extensions: ['txt'],
      comingSoon: true,
    ),
  ];

  static List<String> get categories => ImportFileCategories.ordered;

  static List<ImportFileTypeOption> byCategory(String category) {
    return all.where((item) => item.category == category).toList();
  }

  static ImportFileTypeOption? findByType(String type) {
    for (final item in all) {
      if (item.type == type) return item;
    }
    return null;
  }

  static String extensionsForType(String type) {
    final option = findByType(type);
    if (option == null) return 'csv,xlsx,xls';
    return option.extensions.join(',');
  }

  static ImportFileTypeOption get defaultOption => all.first;
}
