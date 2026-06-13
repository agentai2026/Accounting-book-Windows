import 'package:decimal/decimal.dart';

import 'package:ezbookkeeping_desktop/core/constants/money_grouping.dart';

class MoneyUtils {
  MoneyUtils._();

  /// 由设置页同步，全局金额展示分组
  static MoneyGrouping displayGrouping = MoneyGrouping.none;

  static String format(int amountInCents, {String? currencyCode}) {
    final currency = currencyCode ?? 'CNY';
    final symbol = _getSymbol(currency);
    final isNegative = amountInCents < 0;
    final absCents = amountInCents.abs();
    final value = _formatDigits(absCents, displayGrouping);
    return isNegative ? '-$symbol$value' : '$symbol$value';
  }
  static String formatWithSign(
    int amountInCents, {
    String? currencyCode,
    bool isExpense = false,
    bool isIncome = false,
  }) {
    if (isExpense) {
      return '-${format(amountInCents.abs(), currencyCode: currencyCode)}';
    }
    if (isIncome) {
      return '+${format(amountInCents.abs(), currencyCode: currencyCode)}';
    }
    final prefix = amountInCents >= 0 ? '' : '-';
    return '$prefix${format(amountInCents.abs(), currencyCode: currencyCode)}';
  }

  static int parseToCents(String input) {
    final cleaned = input.trim().replaceAll(RegExp(r'[^\d.\-]'), '');
    final decimal = Decimal.parse(cleaned);
    return (decimal * Decimal.fromInt(100)).toBigInt().toInt();
  }

  /// 金额输入框用纯数字文本，不含货币符号
  static String formatInputAmount(int amountInCents) {
    final absCents = amountInCents.abs();
    final yuan = absCents ~/ 100;
    final cents = absCents % 100;
    return '$yuan.${cents.toString().padLeft(2, '0')}';
  }

  static String formatSpaced(int amountInCents, {String? currencyCode}) {
    final currency = currencyCode ?? 'CNY';
    final symbol = _getSymbol(currency);
    final isNegative = amountInCents < 0;
    final absCents = amountInCents.abs();
    final value = _formatDigits(absCents, displayGrouping);
    return isNegative ? '-$symbol $value' : '$symbol $value';
  }

  static String _formatDigits(int absCents, MoneyGrouping grouping) {
    final yuan = absCents ~/ 100;
    final cents = absCents % 100;
    final decimal = cents.toString().padLeft(2, '0');
    final yuanText = yuan.toString();

    final groupedInteger = switch (grouping) {
      MoneyGrouping.none => yuanText,
      MoneyGrouping.thousands => _groupThousands(yuanText),
      MoneyGrouping.tenThousands => _groupTenThousands(yuanText),
    };
    return '$groupedInteger.$decimal';
  }

  static String _groupThousands(String digits) {
    if (digits.length <= 3) return digits;
    final buffer = StringBuffer();
    final mod = digits.length % 3;
    if (mod > 0) {
      buffer.write(digits.substring(0, mod));
      if (digits.length > mod) buffer.write(',');
    }
    for (var i = mod; i < digits.length; i += 3) {
      if (i > mod) buffer.write(',');
      buffer.write(digits.substring(i, i + 3));
    }
    return buffer.toString();
  }

  /// 万分位：整数部分每 4 位一组，如 12,3456
  static String _groupTenThousands(String digits) {
    if (digits.length <= 4) return digits;
    final buffer = StringBuffer();
    final mod = digits.length % 4;
    if (mod > 0) {
      buffer.write(digits.substring(0, mod));
      if (digits.length > mod) buffer.write(',');
    }
    for (var i = mod; i < digits.length; i += 4) {
      if (i > mod) buffer.write(',');
      buffer.write(digits.substring(i, i + 4));
    }
    return buffer.toString();
  }

  static String _getSymbol(String currencyCode) {
    return switch (currencyCode) {
      'CNY' => '¥',
      'USD' => r'$',
      'EUR' => '€',
      'JPY' => '¥',
      _ => currencyCode,
    };
  }
}
