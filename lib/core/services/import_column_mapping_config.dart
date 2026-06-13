/// 导入列字段类型（对应 ezBookkeeping「定义列」映射项）
enum ImportColumnField {
  time,
  type,
  amount,
  category,
  account,
  remark,
  status,
  payer,
  refund,
}

extension ImportColumnFieldX on ImportColumnField {
  String get label => switch (this) {
        ImportColumnField.time => '交易时间',
        ImportColumnField.type => '交易类型',
        ImportColumnField.amount => '金额',
        ImportColumnField.category => '分类',
        ImportColumnField.account => '账户',
        ImportColumnField.remark => '备注',
        ImportColumnField.status => '交易状态',
        ImportColumnField.payer => '交易对方',
        ImportColumnField.refund => '退款金额',
      };
}

/// 列映射配置
class ImportColumnMappingConfig {
  ImportColumnMappingConfig({
    this.headerRowIndex = 0,
    this.includeHeader = true,
    Map<ImportColumnField, int>? fieldToColumn,
    this.timeFormat = '',
  }) : fieldToColumn = {...?fieldToColumn};

  int headerRowIndex;
  bool includeHeader;
  final Map<ImportColumnField, int> fieldToColumn;
  String timeFormat;

  ImportColumnMappingConfig copyWith({
    int? headerRowIndex,
    bool? includeHeader,
    Map<ImportColumnField, int>? fieldToColumn,
    String? timeFormat,
  }) {
    return ImportColumnMappingConfig(
      headerRowIndex: headerRowIndex ?? this.headerRowIndex,
      includeHeader: includeHeader ?? this.includeHeader,
      fieldToColumn: fieldToColumn ?? this.fieldToColumn,
      timeFormat: timeFormat ?? this.timeFormat,
    );
  }

  int? columnFor(ImportColumnField field) => fieldToColumn[field];

  ImportColumnField? fieldAtColumn(int columnIndex) {
    for (final entry in fieldToColumn.entries) {
      if (entry.value == columnIndex) return entry.key;
    }
    return null;
  }

  void setColumnMapping(int columnIndex, ImportColumnField? field) {
    fieldToColumn.removeWhere((_, index) => index == columnIndex);
    if (field != null) {
      fieldToColumn.remove(field);
      fieldToColumn[field] = columnIndex;
    }
  }

  bool get hasRequiredMapping =>
      fieldToColumn.containsKey(ImportColumnField.time) &&
      fieldToColumn.containsKey(ImportColumnField.type) &&
      fieldToColumn.containsKey(ImportColumnField.amount);

  static String normalizeHeader(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll('（', '(')
        .replaceAll('）', ')');
  }

  static final Map<String, ImportColumnField> _knownHeaders = {
    for (final alias in ['time', 'date', 'datetime', 'timestamp'])
      alias: ImportColumnField.time,
    '日期': ImportColumnField.time,
    '时间': ImportColumnField.time,
    '交易日期': ImportColumnField.time,
    '交易时间': ImportColumnField.time,
    '付款时间': ImportColumnField.time,
    'transactiontype': ImportColumnField.type,
    '交易类型': ImportColumnField.type,
    '类型': ImportColumnField.type,
    '收/支': ImportColumnField.type,
    '收支': ImportColumnField.type,
    '收支类型': ImportColumnField.type,
    'amount': ImportColumnField.amount,
    '金额': ImportColumnField.amount,
    '交易金额': ImportColumnField.amount,
    '金额(元)': ImportColumnField.amount,
    '金额（元）': ImportColumnField.amount,
    'category': ImportColumnField.category,
    'categoryname': ImportColumnField.category,
    '分类': ImportColumnField.category,
    '分类名称': ImportColumnField.category,
    '交易分类': ImportColumnField.category,
    '类别': ImportColumnField.category,
    'account': ImportColumnField.account,
    '账户': ImportColumnField.account,
    '付款账户': ImportColumnField.account,
    '收款账户': ImportColumnField.account,
    '收/付款方式': ImportColumnField.account,
    '支付方式': ImportColumnField.account,
    'remark': ImportColumnField.remark,
    'comment': ImportColumnField.remark,
    'description': ImportColumnField.remark,
    '备注': ImportColumnField.remark,
    '说明': ImportColumnField.remark,
    '摘要': ImportColumnField.remark,
    '商品说明': ImportColumnField.remark,
    '商品名称': ImportColumnField.remark,
    '商品': ImportColumnField.remark,
    'status': ImportColumnField.status,
    '状态': ImportColumnField.status,
    '交易状态': ImportColumnField.status,
    '当前状态': ImportColumnField.status,
    '订单状态': ImportColumnField.status,
    'payer': ImportColumnField.payer,
    '付款人': ImportColumnField.payer,
    '收款人': ImportColumnField.payer,
    '对方': ImportColumnField.payer,
    '交易对方': ImportColumnField.payer,
    '成功退款(元)': ImportColumnField.refund,
    '成功退款（元）': ImportColumnField.refund,
    '成功退款': ImportColumnField.refund,
    '退款金额': ImportColumnField.refund,
  };

  static ImportColumnMappingConfig autoDetect({
    required List<List<String>> rows,
    required int headerRowIndex,
  }) {
    final config = ImportColumnMappingConfig(
      headerRowIndex: headerRowIndex,
      includeHeader: true,
    );

    if (headerRowIndex < 0 || headerRowIndex >= rows.length) {
      return config;
    }

    final headerCells = rows[headerRowIndex];
    final normalizedHeaders = <int, String>{
      for (var i = 0; i < headerCells.length; i++)
        i: normalizeHeader(headerCells[i]),
    };

    for (final entry in normalizedHeaders.entries) {
      final field = _resolveFieldFromHeader(entry.value);
      if (field == null || field == ImportColumnField.type) continue;
      if (!config.fieldToColumn.containsKey(field)) {
        config.fieldToColumn[field] = entry.key;
      }
    }

    // 收/支 优先于 交易类型（微信账单「交易类型」是商户消费等，不是收支方向）
    const typePriority = [
      '收/支',
      '收支',
      '收支类型',
      '类型',
      'type',
      'transactiontype',
      '交易类型',
    ];
    for (final key in typePriority) {
      final col = normalizedHeaders.entries
          .where((e) => e.value == key)
          .map((e) => e.key)
          .firstOrNull;
      if (col != null) {
        config.fieldToColumn[ImportColumnField.type] = col;
        break;
      }
    }

    // 微信：收/支 与 交易类型 分列时，将交易类型映射为分类（商户消费/零钱通等）
    if (!config.fieldToColumn.containsKey(ImportColumnField.category)) {
      final txnKindCol = normalizedHeaders.entries
          .where((e) => e.value == '交易类型')
          .map((e) => e.key)
          .firstOrNull;
      if (txnKindCol != null) {
        config.fieldToColumn[ImportColumnField.category] = txnKindCol;
      }
    }

    return config;
  }

  static ImportColumnField? _resolveFieldFromHeader(String normalized) {
    if (normalized.isEmpty) return null;
    final exact = _knownHeaders[normalized];
    if (exact != null) return exact;

    if (normalized.contains('交易时间') ||
        normalized.contains('付款时间') ||
        normalized.contains('交易创建时间') ||
        normalized == '日期') {
      return ImportColumnField.time;
    }
    if (normalized.contains('金额')) return ImportColumnField.amount;
    if (normalized.contains('交易对方') || normalized == '对方') {
      return ImportColumnField.payer;
    }
    if (normalized.contains('支付方式') ||
        normalized.contains('付款方式') ||
        normalized.contains('收/付款方式')) {
      return ImportColumnField.account;
    }
    if (normalized.contains('当前状态') ||
        normalized.contains('交易状态') ||
        normalized == '状态') {
      return ImportColumnField.status;
    }
    if (normalized.contains('交易分类') || normalized == '分类') {
      return ImportColumnField.category;
    }
    if (normalized.contains('退款')) return ImportColumnField.refund;
    if (normalized == '商品' ||
        normalized.contains('商品说明') ||
        normalized == '备注') {
      return ImportColumnField.remark;
    }
    return null;
  }
}
