import 'package:ezbookkeeping_desktop/core/models/transaction.dart';

import 'package:ezbookkeeping_desktop/core/utils/import_source_metadata.dart';



/// 账单展示文案（导入账单优先显示原始支付方式与来源平台）

class TransactionDisplayUtils {

  TransactionDisplayUtils._();



  static bool isImported(Transaction transaction) {

    final via = metadata(transaction)?.recordVia;

    if (via == TransactionRecordVia.import) return true;

    if (via == TransactionRecordVia.manual || via == TransactionRecordVia.ai) {

      return false;

    }



    final meta = metadata(transaction);

    if (meta == null) return false;

    return meta.categoryName != null ||

        meta.direction != null ||

        meta.importSource != null;

  }



  static bool isAiRecorded(Transaction transaction) {

    return metadata(transaction)?.recordVia == TransactionRecordVia.ai;

  }



  static ImportSourceMetadata? metadata(Transaction transaction) {

    return ImportSourceMetadata.parse(transaction.comment);

  }



  /// 收支账户：优先元数据 pay=，再从备注/付款人提取，最后映射账户名

  static String resolveAccountLabel({

    required Transaction transaction,

    required String mappedAccountName,

  }) {

    final pay = metadata(transaction)?.paymentMethod?.trim();

    if (pay != null && pay.isNotEmpty) {

      return pay;

    }



    final textBlob = [

      transaction.description,

      transaction.payer,

      ImportSourceMetadata.stripMetadata(transaction.comment),

    ].whereType<String>().join(' ');



    final extracted = extractPaymentMethodFromText(textBlob);

    if (extracted != null && extracted.isNotEmpty) {

      return extracted;

    }



    if (_isGenericAccountLabel(mappedAccountName)) {

      final lastFour = extractLastFourDigits(textBlob);

      if (lastFour != null) {

        return enrichGenericAccountLabel(mappedAccountName, lastFour);

      }

    }

    final platform = resolveImportSourceLabel(transaction);
    if (platform == '微信' && _isGenericAccountLabel(mappedAccountName)) {
      return '微信零钱';
    }
    if (platform == '支付宝' && _isGenericAccountLabel(mappedAccountName)) {
      return '支付宝';
    }

    return mappedAccountName;
  }

  /// 从文本中提取完整支付方式，如「农业银行储蓄卡(6579)」「微信零钱」

  static String? extractPaymentMethodFromText(String text) {

    final normalized = text.trim();

    if (normalized.isEmpty) return null;



    final fullCard = RegExp(

      r'([\u4e00-\u9fa5A-Za-z0-9]+(?:储蓄卡|信用卡|借记卡|银行卡))\s*[（(](\d{4})[）)]',

    ).firstMatch(normalized);

    if (fullCard != null) {

      return '${fullCard.group(1)}(${fullCard.group(2)})';

    }



    final bankWithDigits = RegExp(

      r'([\u4e00-\u9fa5]+银行[\u4e00-\u9fa5]*(?:卡|账户)?)\s*[（(](\d{4})[）)]',

    ).firstMatch(normalized);

    if (bankWithDigits != null) {

      return '${bankWithDigits.group(1)}(${bankWithDigits.group(2)})';

    }



    final wallet = RegExp(r'(微信零钱|支付宝余额|支付宝|花呗|余额宝|零钱通|余利宝)')

        .firstMatch(normalized);

    if (wallet != null) return wallet.group(1);



    return null;

  }



  /// 从掩码账号等文本提取后四位，如 (6579)、132******17

  static String? extractLastFourDigits(String text) {

    final normalized = text.trim();

    if (normalized.isEmpty) return null;



    final parenFour = RegExp(r'[（(](\d{4})[）)]').firstMatch(normalized);

    if (parenFour != null) return parenFour.group(1);



    final maskedTail = RegExp(r'[*＊]{2,}(\d{4})').firstMatch(normalized);

    if (maskedTail != null) return maskedTail.group(1);



    final afterMask = RegExp(r'[*＊]+(\d{2,4})').firstMatch(normalized);
    if (afterMask != null) {
      final tail = afterMask.group(1)!;
      return tail.length == 4 ? tail : tail.padLeft(4, '0');
    }

    return null;

  }



  static bool _isGenericAccountLabel(String label) {

    final trimmed = label.trim();

    if (trimmed.isEmpty) return false;

    if (RegExp(r'[（(]\d{4}[）)]').hasMatch(trimmed)) return false;



    const generics = {'银行卡', '信用卡', '储蓄卡', '借记卡', '现金', '其他'};

    if (generics.contains(trimmed)) return true;



    return trimmed.contains('银行') &&

        !RegExp(r'[（(]\d{4}[）)]').hasMatch(trimmed);

  }



  static String enrichGenericAccountLabel(String label, String lastFour) {

    if (RegExp(r'[（(]\d{4}[）)]').hasMatch(label)) return label;

    return '$label($lastFour)';

  }



  /// 导入平台：支付宝 / 微信（备注优先，修正误标为支付宝的微信账单）
  static String? resolveImportSourceLabel(Transaction transaction) {
    final textBlob = _importSourceInferenceText(transaction);
    final fromText = inferImportSourceFromText(textBlob);
    final stored = metadata(transaction)?.importSource?.trim();

    if (fromText != null) {
      if (stored == null || stored.isEmpty || fromText != stored) {
        return fromText;
      }
      return stored;
    }

    if (stored != null && stored.isNotEmpty) return stored;
    if (!isImported(transaction)) return null;
    return null;
  }

  static String resolveImportSourceDisplay(Transaction transaction) {
    return resolveImportSourceLabel(transaction) ?? '—';
  }

  static String _importSourceInferenceText(Transaction transaction) {
    return [
      transaction.description,
      transaction.payer,
      metadata(transaction)?.paymentMethod,
      ImportSourceMetadata.stripMetadata(transaction.comment),
    ].whereType<String>().join(' ');
  }

  static String? inferImportSourceFromText(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return null;

    if (normalized.contains('微信转账') ||
        normalized.contains('微信支付') ||
        normalized.contains('转账备注:微信') ||
        normalized.contains('转账备注：微信')) {
      return '微信';
    }
    if (_containsAny(normalized, ['微信', '零钱', '零钱通', 'WeChat'])) {
      return '微信';
    }
    if (_containsAny(
      normalized,
      ['支付宝', '花呗', '余额宝', '余利宝', 'Alipay'],
    )) {
      return '支付宝';
    }
    return null;
  }



  static bool _containsAny(String text, List<String> keywords) {

    for (final kw in keywords) {

      if (text.contains(kw)) return true;

    }

    return false;

  }



  /// 用户可见备注：description 优先，避免展示 @src: 元数据

  static String resolveRemark(Transaction transaction) {

    final desc = transaction.description?.trim();

    if (desc != null && desc.isNotEmpty) return desc;



    final fromComment = ImportSourceMetadata.stripMetadata(transaction.comment);

    if (fromComment != null && fromComment.isNotEmpty) return fromComment;



    final payer = transaction.payer?.trim();

    if (payer != null && payer.isNotEmpty) return payer;



    return '—';

  }



  static String resolveRecordMethod(Transaction transaction) {

    final detail = resolveRecordMethodDetail(transaction);

    if (detail.endsWith('账单导入')) return '导入记账';

    if (detail == 'AI记账') return 'AI记账';

    return '手动记账';

  }



  /// 记录方式详情：手动记账 / AI记账 / 支付宝账单导入 / 微信账单导入

  static String resolveRecordMethodDetail(Transaction transaction) {

    final meta = metadata(transaction);

    final via = meta?.recordVia;



    if (via == TransactionRecordVia.ai) return 'AI记账';

    if (via == TransactionRecordVia.manual) return '手动记账';



    if (via == TransactionRecordVia.import || isImported(transaction)) {

      final platform = resolveImportSourceLabel(transaction);

      if (platform == '支付宝') return '支付宝账单导入';

      if (platform == '微信') return '微信账单导入';

      return '账单导入';

    }



    return '手动记账';

  }

}


