import 'package:ezbookkeeping_desktop/core/services/import_column_mapping_config.dart';

/// 识别支付宝/微信等对账单中的真实表头行（跳过标题与元数据行）
class ImportHeaderDetector {
  ImportHeaderDetector._();

  static int? findHeaderRowIndex(List<List<String>> rows) {
    for (var i = 0; i < rows.length; i++) {
      if (looksLikePaymentBillHeader(rows[i])) return i;
    }
    return null;
  }

  /// 是否为支付账单数据表头（交易时间 + 金额 + 收/支 等）
  static bool looksLikePaymentBillHeader(List<String> cells) {
    final norms = cells
        .map(ImportColumnMappingConfig.normalizeHeader)
        .where((s) => s.isNotEmpty)
        .toList();
    if (norms.length < 4) return false;

    var score = 0;
    if (norms.any(_isTimeHeader)) score++;
    if (norms.any(_isAmountHeader)) score++;
    if (norms.any(_isDirectionHeader)) score++;
    if (norms.any(_isPayerHeader)) score++;
    if (norms.any(_isAccountHeader)) score++;
    if (norms.any(_isStatusHeader)) score++;
    if (norms.any((h) => h.contains('交易类型'))) score++;

    return score >= 3;
  }

  /// 是否为「微信支付账单明细」等标题行（非列名）
  static bool isTitlePreambleRow(List<String> cells) {
    final parts = cells.where((c) => c.trim().isNotEmpty).toList();
    if (parts.isEmpty) return false;

    final joined = parts.join();
    if (joined.contains('交易时间') || joined.contains('收/支')) {
      return false;
    }

    final titlePattern = RegExp(r'账单明细|对账单|交易流水|微信支付|支付宝');
    if (parts.length >= 4) {
      final unique = parts.map((p) => p.trim()).toSet();
      if (unique.length == 1 && titlePattern.hasMatch(unique.first)) {
        return true;
      }
      return false;
    }
    return titlePattern.hasMatch(joined);
  }

  /// 导出说明行（微信昵称、起止时间等），不是表头
  static bool isMetadataPreambleRow(List<String> cells) {
    final joined = cells.where((c) => c.trim().isNotEmpty).join();
    if (joined.isEmpty) return true;
    if (joined.contains('交易时间') && joined.contains('金额')) return false;
    return RegExp(
      r'微信昵称|起始时间|终止时间|导出类型|导出时间|支付宝账户|姓名[:：]|账号[:：]',
    ).hasMatch(joined);
  }

  static bool _isTimeHeader(String h) =>
      h.contains('交易时间') ||
      h.contains('付款时间') ||
      h.contains('交易创建时间') ||
      h == '日期' ||
      h == 'time' ||
      h == 'date';

  static bool _isAmountHeader(String h) =>
      h.contains('金额') || h == 'amount';

  static bool _isDirectionHeader(String h) =>
      h == '收/支' || h == '收支' || h.contains('收支类型');

  static bool _isPayerHeader(String h) =>
      h.contains('交易对方') || h == '对方' || h.contains('收款方');

  static bool _isAccountHeader(String h) =>
      h.contains('支付方式') ||
      h.contains('付款方式') ||
      h.contains('收/付款方式') ||
      h == '账户';

  static bool _isStatusHeader(String h) =>
      h.contains('当前状态') ||
      h.contains('交易状态') ||
      h == '状态' ||
      h == 'status';
}
