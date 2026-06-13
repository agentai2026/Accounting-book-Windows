import 'package:ezbookkeeping_desktop/core/models/exchange_rate_snapshot.dart';

/// 汇率展示方向
enum ExchangeRateDisplayMode {
  /// 换算器口径：1 基准 = X 外币（与 Xe 一致）
  direct,

  /// 银行牌价口径：1 外币 = X 人民币（仅 CNY 基准时有意义）
  inverse,
}

/// 汇率行展示
class ExchangeRateRowDisplay {
  const ExchangeRateRowDisplay({
    required this.quoteLabel,
    required this.quoteValue,
    required this.quoteSuffix,
  });

  /// 例如 `1 CNY =`、`100 JPY =`
  final String quoteLabel;

  final double quoteValue;

  final String quoteSuffix;
}

const kExchangeRatePer100QuoteCurrencies = {'JPY', 'KRW', 'IDR', 'VND'};

ExchangeRateRowDisplay buildExchangeRateRowDisplay({
  required ExchangeRateSnapshot snapshot,
  required String currencyCode,
  ExchangeRateDisplayMode mode = ExchangeRateDisplayMode.direct,
}) {
  final code = currencyCode.toUpperCase();
  final base = snapshot.baseCurrency;
  final internalRate = snapshot.rateFor(code) ?? 1;

  if (code == base) {
    return ExchangeRateRowDisplay(
      quoteLabel: '1 $base =',
      quoteValue: 1,
      quoteSuffix: base,
    );
  }

  if (mode == ExchangeRateDisplayMode.direct) {
    return ExchangeRateRowDisplay(
      quoteLabel: '1 $base =',
      quoteValue: internalRate,
      quoteSuffix: code,
    );
  }

  if (base == 'CNY') {
    final per100 = kExchangeRatePer100QuoteCurrencies.contains(code);
    final units = per100 ? 100.0 : 1.0;
    return ExchangeRateRowDisplay(
      quoteLabel: '${units.toInt()} $code =',
      quoteValue: units / internalRate,
      quoteSuffix: 'CNY',
    );
  }

  if (code == 'CNY') {
    return ExchangeRateRowDisplay(
      quoteLabel: '1 $base =',
      quoteValue: internalRate,
      quoteSuffix: 'CNY',
    );
  }

  return ExchangeRateRowDisplay(
    quoteLabel: '1 $code =',
    quoteValue: 1 / internalRate,
    quoteSuffix: base,
  );
}

String formatExchangeRateQuoteValue(double value) {
  if (value >= 1000) return value.toStringAsFixed(2);
  if (value >= 100) return value.toStringAsFixed(3);
  if (value >= 1) return value.toStringAsFixed(4);
  if (value >= 0.01) return value.toStringAsFixed(4);
  return value.toStringAsFixed(6);
}
