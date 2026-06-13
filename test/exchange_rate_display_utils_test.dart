import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/core/models/exchange_rate_snapshot.dart';
import 'package:ezbookkeeping_desktop/core/utils/exchange_rate_display_utils.dart';

void main() {
  final snapshot = ExchangeRateSnapshot(
    baseCurrency: 'CNY',
    date: DateTime(2026, 6, 11),
    rates: const {
      'USD': 0.14760419,
      'JPY': 23.69206677,
      'XOF': 83.8470556,
    },
    fetchedAt: DateTime(2026, 6, 11, 12),
    sourceName: 'test',
    nextUpdateAt: DateTime(2026, 6, 12),
  );

  test('direct mode matches converter style', () {
    final usd = buildExchangeRateRowDisplay(
      snapshot: snapshot,
      currencyCode: 'USD',
      mode: ExchangeRateDisplayMode.direct,
    );
    expect(usd.quoteLabel, '1 CNY =');
    expect(usd.quoteSuffix, 'USD');
    expect(usd.quoteValue, closeTo(0.1476, 0.0001));

    final xof = buildExchangeRateRowDisplay(
      snapshot: snapshot,
      currencyCode: 'XOF',
      mode: ExchangeRateDisplayMode.direct,
    );
    expect(xof.quoteValue, closeTo(83.8471, 0.001));
  });

  test('inverse mode shows bank-style CNY quote', () {
    final display = buildExchangeRateRowDisplay(
      snapshot: snapshot,
      currencyCode: 'USD',
      mode: ExchangeRateDisplayMode.inverse,
    );

    expect(display.quoteLabel, '1 USD =');
    expect(display.quoteSuffix, 'CNY');
    expect(display.quoteValue, closeTo(6.7748, 0.001));
  });

  test('inverse mode shows per-100 JPY quote', () {
    final display = buildExchangeRateRowDisplay(
      snapshot: snapshot,
      currencyCode: 'JPY',
      mode: ExchangeRateDisplayMode.inverse,
    );

    expect(display.quoteLabel, '100 JPY =');
    expect(display.quoteSuffix, 'CNY');
    expect(display.quoteValue, closeTo(4.2208, 0.001));
  });
}
