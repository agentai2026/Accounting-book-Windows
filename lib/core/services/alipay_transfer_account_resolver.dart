/// 从支付宝「不计收支」流水推断转出/转入账户名称。
class AlipayTransferAccountResolver {
  AlipayTransferAccountResolver._();

  static const _accountKeywords = <String, String>{
    '余额宝': '余额宝',
    '花呗': '花呗',
    '信用卡': '信用卡',
    '银行卡': '银行卡',
    '借记卡': '银行卡',
    '储蓄卡': '银行卡',
    '支付宝余额': '支付宝',
    '支付宝': '支付宝',
    '微信': '微信',
    '云闪付': '云闪付',
    '余额': '支付宝',
  };

  static ({String? from, String? to}) resolve({
    required String? paymentMethod,
    String? categoryName,
    String? remark,
  }) {
    final text = '${categoryName ?? ''} ${remark ?? ''}'.trim();
    final mentioned = <String>[];
    for (final entry in _accountKeywords.entries) {
      if (text.contains(entry.key) && !mentioned.contains(entry.value)) {
        mentioned.add(entry.value);
      }
    }

    final isOutflow =
        text.contains('转出') || text.contains('还款') || text.contains('提出');
    final isInflow = text.contains('转入') || text.contains('存入');

    if (isOutflow) {
      if (text.contains('还款')) {
        return (
          from: paymentMethod ?? (mentioned.isNotEmpty ? mentioned.first : null),
          to: _repaymentTarget(text),
        );
      }
      return (
        from: mentioned.isNotEmpty ? mentioned.first : paymentMethod,
        to: mentioned.length > 1 ? mentioned[1] : _counterpartyForOutflow(text),
      );
    }
    if (isInflow) {
      return (
        from: mentioned.length > 1 ? mentioned[1] : _counterpartyForInflow(text),
        to: mentioned.isNotEmpty ? mentioned.first : paymentMethod,
      );
    }

    if (text.contains('收益') && mentioned.isNotEmpty) {
      return (from: paymentMethod, to: mentioned.first);
    }

    if (mentioned.length >= 2) {
      return (from: mentioned[0], to: mentioned[1]);
    }
    if (mentioned.length == 1) {
      final account = mentioned.first;
      if (isOutflow || text.contains('转出')) {
        return (from: account, to: paymentMethod ?? _counterpartyForOutflow(text));
      }
      if (isInflow || text.contains('转入')) {
        return (from: paymentMethod ?? _counterpartyForInflow(text), to: account);
      }
      return (from: paymentMethod ?? account, to: account);
    }
    return (from: paymentMethod, to: null);
  }

  static String? _repaymentTarget(String text) {
    if (text.contains('花呗')) return '花呗';
    if (text.contains('信用卡')) return '信用卡';
    return null;
  }

  static String? _counterpartyForOutflow(String text) {
    if (text.contains('花呗')) return '花呗';
    if (text.contains('信用卡')) return '信用卡';
    if (text.contains('银行卡') || text.contains('借记卡') || text.contains('储蓄卡')) {
      return '银行卡';
    }
    if (text.contains('余额宝')) return '余额宝';
    return null;
  }

  static String? _counterpartyForInflow(String text) {
    if (text.contains('余额宝')) return '银行卡';
    if (text.contains('银行卡') || text.contains('借记卡') || text.contains('储蓄卡')) {
      return '银行卡';
    }
    return null;
  }
}
