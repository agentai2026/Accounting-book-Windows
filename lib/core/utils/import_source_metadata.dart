const _prefix = '@src:';
const _suffix = '@';

/// 记录方式：manual / ai / import
abstract final class TransactionRecordVia {
  static const manual = 'manual';
  static const ai = 'ai';
  static const import = 'import';
}

/// 导入来源元数据（存于 comment 字段，供统计规则与详情展示）
class ImportSourceMetadata {
  const ImportSourceMetadata({
    this.recordVia,
    this.categoryName,
    this.direction,
    this.status,
    this.paymentMethod,
    this.importSource,
  });

  /// 记录方式：manual / ai / import
  final String? recordVia;

  final String? categoryName;
  final String? direction;
  final String? status;

  /// 导入文件中的原始收/付款方式，如「农业银行储蓄卡(6579)」「微信零钱」
  final String? paymentMethod;

  /// 导入平台：支付宝 / 微信 等
  final String? importSource;

  static String encode({
    String? recordVia,
    String? categoryName,
    String? direction,
    String? status,
    String? paymentMethod,
    String? importSource,
  }) {
    final parts = <String>[];
    if (recordVia != null && recordVia.isNotEmpty) {
      parts.add('via=$recordVia');
    }
    if (categoryName != null && categoryName.isNotEmpty) {
      parts.add('cat=$categoryName');
    }
    if (direction != null && direction.isNotEmpty) {
      parts.add('dir=$direction');
    }
    if (status != null && status.isNotEmpty) {
      parts.add('st=$status');
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      parts.add('pay=$paymentMethod');
    }
    if (importSource != null && importSource.isNotEmpty) {
      parts.add('src=$importSource');
    }
    if (parts.isEmpty) return '';
    return '$_prefix${parts.join(';')}$_suffix';
  }

  static ImportSourceMetadata? parse(String? comment) {
    if (comment == null || !comment.contains(_prefix)) return null;
    final start = comment.indexOf(_prefix);
    final end = comment.indexOf(_suffix, start + _prefix.length);
    if (end < 0) return null;
    final payload = comment.substring(start + _prefix.length, end);
    String? via;
    String? cat;
    String? dir;
    String? st;
    String? pay;
    String? src;
    for (final part in payload.split(';')) {
      final eq = part.indexOf('=');
      if (eq <= 0) continue;
      final key = part.substring(0, eq);
      final value = part.substring(eq + 1);
      switch (key) {
        case 'via':
          via = value;
        case 'cat':
          cat = value;
        case 'dir':
          dir = value;
        case 'st':
          st = value;
        case 'pay':
          pay = value;
        case 'src':
          src = value;
      }
    }
    return ImportSourceMetadata(
      recordVia: via,
      categoryName: cat,
      direction: dir,
      status: st,
      paymentMethod: pay,
      importSource: src,
    );
  }

  static String mergeComment({
    required String? existingComment,
    required String metadata,
  }) {
    if (metadata.isEmpty) return existingComment ?? '';
    final base = existingComment?.replaceAll(
          RegExp('$_prefix[^@]*$_suffix'),
          '',
        ).trim() ??
        '';
    if (base.isEmpty) return metadata;
    return '$metadata $base';
  }

  /// 去掉 @src:...@ 后的用户可见备注
  static String? stripMetadata(String? comment) {
    if (comment == null) return null;
    final cleaned = comment.replaceAll(RegExp('$_prefix[^@]*$_suffix'), '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }
}
