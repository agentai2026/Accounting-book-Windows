import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/exchange_rate_snapshot.dart';
import 'package:ezbookkeeping_desktop/core/models/exchange_rate_trend.dart';
import 'package:ezbookkeeping_desktop/core/services/exchange_rate_service.dart';

final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  return ExchangeRateService();
});

/// 递增以触发重新拉取汇率
final exchangeRateRefreshTickProvider = StateProvider<int>((ref) => 0);

final exchangeRatesProvider =
    FutureProvider.autoDispose.family<ExchangeRateSnapshot, String>(
  (ref, baseCurrency) async {
    ref.watch(exchangeRateRefreshTickProvider);
    final service = ref.watch(exchangeRateServiceProvider);
    return service.fetchLatest(baseCurrency);
  },
);

final exchangeCurrencyNamesProvider =
    FutureProvider<Map<String, String>>((ref) async {
  ref.watch(exchangeRateRefreshTickProvider);
  final service = ref.watch(exchangeRateServiceProvider);
  return service.loadCurrencyNames();
});

final exchangeBaseCurrenciesProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(exchangeRateRefreshTickProvider);
  final service = ref.watch(exchangeRateServiceProvider);
  return service.listBaseCurrencies();
});

final exchangeRateTrendsProvider =
    FutureProvider.autoDispose.family<ExchangeRateTrendMap, String>(
  (ref, baseCurrency) async {
    ref.watch(exchangeRateRefreshTickProvider);
    final service = ref.watch(exchangeRateServiceProvider);
    return service.loadWeeklyTrends(baseCurrency);
  },
);
