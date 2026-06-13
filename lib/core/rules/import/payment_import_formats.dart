/// 支付应用对账单：UI 分组与文件名识别（导入走通用列映射）
class PaymentImportGroup {
  const PaymentImportGroup({
    required this.label,
    required this.hint,
    required this.defaultFileType,
    required this.fileTypes,
    this.nameKeywords = const [],
  });

  final String label;
  final String hint;
  final String defaultFileType;
  final List<String> fileTypes;
  final List<String> nameKeywords;
}

class PaymentImportFormats {
  PaymentImportFormats._();

  static const groups = <PaymentImportGroup>[
    PaymentImportGroup(
      label: '支付宝对账单',
      hint: 'App 或网页导出 · .csv',
      defaultFileType: 'alipay_app_csv',
      fileTypes: ['alipay_app_csv', 'alipay_web_csv'],
      nameKeywords: ['支付宝', 'alipay'],
    ),
    PaymentImportGroup(
      label: '微信支付账单',
      hint: '自动识别 · .xlsx / .csv',
      defaultFileType: 'wechat_pay_xlsx',
      fileTypes: ['wechat_pay_xlsx', 'wechat_pay_csv'],
      nameKeywords: ['微信', 'wechat', 'weixin'],
    ),
    PaymentImportGroup(
      label: 'QQ钱包',
      hint: '导出账单 · .csv / Excel',
      defaultFileType: 'qq_pay',
      fileTypes: ['qq_pay'],
      nameKeywords: ['qq钱包', 'qq支付', '腾讯qq', 'qq_pay'],
    ),
    PaymentImportGroup(
      label: '云闪付',
      hint: '银联导出 · .csv / Excel',
      defaultFileType: 'unionpay',
      fileTypes: ['unionpay'],
      nameKeywords: ['云闪付', 'unionpay', '银联'],
    ),
    PaymentImportGroup(
      label: '京东支付',
      hint: '导出账单 · .csv / Excel',
      defaultFileType: 'jdpay',
      fileTypes: ['jdpay'],
      nameKeywords: ['京东', 'jdpay', 'jd_pay'],
    ),
    PaymentImportGroup(
      label: '美团',
      hint: '消费账单 · .csv / Excel',
      defaultFileType: 'meituan',
      fileTypes: ['meituan'],
      nameKeywords: ['美团', 'meituan'],
    ),
    PaymentImportGroup(
      label: '抖音支付',
      hint: '导出账单 · .csv / Excel',
      defaultFileType: 'douyin_pay',
      fileTypes: ['douyin_pay'],
      nameKeywords: ['抖音', 'douyin', '字节'],
    ),
    PaymentImportGroup(
      label: '拼多多',
      hint: '导出账单 · .csv / Excel',
      defaultFileType: 'pdd_pay',
      fileTypes: ['pdd_pay'],
      nameKeywords: ['拼多多', 'pinduoduo', 'pdd'],
    ),
  ];

  static List<String> get allFileTypes => [
        for (final group in groups) ...group.fileTypes,
      ];

  static PaymentImportGroup? groupForFileType(String fileType) {
    for (final group in groups) {
      if (group.fileTypes.contains(fileType)) return group;
    }
    return null;
  }

  /// 根据文件名猜测支付应用类型；微信会区分 xlsx/csv
  static String? suggestFileTypeFromName(String fileName) {
    final lower = fileName.toLowerCase();
    for (final group in groups) {
      if (!_matchesKeywords(lower, group.nameKeywords)) continue;
      if (group.defaultFileType == 'wechat_pay_xlsx' ||
          group.fileTypes.contains('wechat_pay_xlsx')) {
        return lower.endsWith('.xlsx') || lower.endsWith('.xls')
            ? 'wechat_pay_xlsx'
            : 'wechat_pay_csv';
      }
      return group.defaultFileType;
    }
    return null;
  }

  static String? suggestLabelFromName(String fileName) {
    final lower = fileName.toLowerCase();
    for (final group in groups) {
      if (_matchesKeywords(lower, group.nameKeywords)) {
        return group.label;
      }
    }
    return null;
  }

  /// 上传后微调类型（微信 xlsx/csv、支付宝网页归并）
  static String normalizeFileType(String fileType, String fileName) {
    final lower = fileName.toLowerCase();
    final group = groupForFileType(fileType);
    if (group == null) return fileType;

    if (group.fileTypes.contains('wechat_pay_xlsx')) {
      return lower.endsWith('.xlsx') || lower.endsWith('.xls')
          ? 'wechat_pay_xlsx'
          : 'wechat_pay_csv';
    }
    if (fileType == 'alipay_web_csv') return 'alipay_app_csv';
    return fileType;
  }

  static bool _matchesKeywords(String lower, List<String> keywords) {
    for (final keyword in keywords) {
      if (lower.contains(keyword.toLowerCase())) return true;
    }
    return false;
  }

  /// 写入账单元数据 src= 的短平台名（支付宝 / 微信 等）
  static String? platformSourceForFileType(String fileType) {
    final group = groupForFileType(fileType);
    if (group == null) return null;
    if (group.fileTypes.contains('alipay_app_csv') ||
        group.fileTypes.contains('alipay_web_csv')) {
      return '支付宝';
    }
    if (group.fileTypes.contains('wechat_pay_xlsx') ||
        group.fileTypes.contains('wechat_pay_csv')) {
      return '微信';
    }
    if (group.label.contains('QQ')) return 'QQ钱包';
    if (group.label.contains('云闪付')) return '云闪付';
    if (group.label.contains('京东')) return '京东支付';
    if (group.label.contains('美团')) return '美团';
    if (group.label.contains('抖音')) return '抖音支付';
    if (group.label.contains('拼多多')) return '拼多多';
    return null;
  }

  /// 从文件头部说明区识别平台（支付宝/微信账单均有「共N笔记录」汇总，不能据此区分）
  static String? detectPlatformFromText(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return null;

    final wechatSignals = [
      '微信支付账单',
      '微信昵称',
      '微信支付',
      '微信转账',
      '转账备注:微信',
      '转账备注：微信',
    ];
    for (final signal in wechatSignals) {
      if (normalized.contains(signal)) return '微信';
    }
    if (RegExp(r'微信(?!.*支付宝)').hasMatch(normalized) &&
        normalized.contains('零钱')) {
      return '微信';
    }

    final alipaySignals = [
      '支付宝账户',
      '支付宝交易',
      '支付宝（中国）',
      'alipay',
    ];
    for (final signal in alipaySignals) {
      if (normalized.toLowerCase().contains(signal.toLowerCase())) {
        return '支付宝';
      }
    }
    if (normalized.contains('支付宝') && !normalized.contains('微信')) {
      return '支付宝';
    }

    return null;
  }

  static String? detectPlatformFromRows(List<List<String>> rows) {
    final buffer = StringBuffer();
    final limit = rows.length < 24 ? rows.length : 24;
    for (var i = 0; i < limit; i++) {
      buffer.writeln(rows[i].join('\t'));
    }
    return detectPlatformFromText(buffer.toString());
  }
}
