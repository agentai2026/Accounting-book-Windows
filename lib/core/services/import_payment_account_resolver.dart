import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/utils/ai_match_utils.dart';

/// 将导入文件中的「收/付款方式」映射到账本内账户名称
class ImportPaymentAccountResolver {
  ImportPaymentAccountResolver._();

  static const _rules = <_Rule>[
    _Rule(['花呗', '借呗'], '花呗'),
    _Rule(['余额宝', '余利宝'], '余额宝'),
    _Rule(['微信零钱', '零钱通', '零钱', '微信'], '微信'),
    _Rule(['支付宝余额', '支付宝'], '支付宝'),
    _Rule(['云闪付', '银联'], '云闪付'),
    _Rule(['储蓄卡', '借记卡', '信用卡', '银行卡', '银行'], '银行卡'),
    _Rule(['现金'], '现金'),
  ];

  static String? resolveAccountName({
    required String? paymentMethod,
    String? importSource,
    String? categoryName,
    String? remark,
  }) {
    final pay = paymentMethod?.replaceAll(RegExp(r'\s+'), '') ?? '';
    if (pay.isNotEmpty) {
      final fromPay = _matchRules(pay);
      if (fromPay != null) return fromPay;
    }

    final blob = [
      categoryName,
      remark,
    ].whereType<String>().join(' ').replaceAll(RegExp(r'\s+'), '');
    if (blob.isNotEmpty) {
      final fromText = _matchRules(blob);
      if (fromText != null) return fromText;
    }

    return _fromImportSource(importSource);
  }

  static String? _matchRules(String normalized) {
    for (final rule in _rules) {
      for (final keyword in rule.keywords) {
        if (normalized.contains(keyword)) {
          return rule.accountName;
        }
      }
    }
    return null;
  }

  static String? _fromImportSource(String? importSource) {
    return switch (importSource) {
      '微信' => '微信',
      '支付宝' => '支付宝',
      _ => null,
    };
  }

  /// 将收/付款方式解析为账本内账户 ID（导入与历史修复共用）
  static int? resolveAccountId({
    required List<Account> accounts,
    required String? paymentMethod,
    String? importSource,
    String? categoryName,
    String? remark,
  }) {
    final direct = matchAccountIdByName(
      name: paymentMethod,
      accounts: accounts,
      fallbackToFirst: false,
    );
    if (direct != null) return direct;

    final resolvedName = resolveAccountName(
      paymentMethod: paymentMethod,
      importSource: importSource,
      categoryName: categoryName,
      remark: remark,
    );
    if (resolvedName == null) return null;

    return findAccountIdByName(
      accounts: accounts,
      accountName: resolvedName,
    );
  }

  static int? findAccountIdByName({
    required List<Account> accounts,
    required String accountName,
  }) {
    final target = accountName.trim().toLowerCase();
    for (final account in accounts) {
      if (account.name.trim().toLowerCase() == target) {
        return account.id;
      }
    }
    for (final account in accounts) {
      final name = account.name.toLowerCase();
      if (name.contains(target) || target.contains(name)) {
        return account.id;
      }
    }
    return null;
  }
}

class _Rule {
  const _Rule(this.keywords, this.accountName);

  final List<String> keywords;
  final String accountName;
}
