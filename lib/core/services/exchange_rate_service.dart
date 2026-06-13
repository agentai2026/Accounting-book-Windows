import 'package:dio/dio.dart';

import 'package:ezbookkeeping_desktop/core/constants/exchange_rate_constants.dart';
import 'package:ezbookkeeping_desktop/core/constants/iso_fiat_currencies.dart';
import 'package:ezbookkeeping_desktop/core/models/exchange_rate_snapshot.dart';
import 'package:ezbookkeeping_desktop/core/models/exchange_rate_trend.dart';
import 'package:ezbookkeeping_desktop/core/services/exchange_rate_local_cache.dart';
import 'package:ezbookkeeping_desktop/core/utils/exchange_rate_schedule_utils.dart';

class ExchangeRateException implements Exception {
  ExchangeRateException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// [fawazahmed0/currency-api](https://github.com/fawazahmed0/exchange-api)
/// 在线拉取 + 本地缓存，免 API Key，支持 200+ 货币，离线可读缓存。
class ExchangeRateService {
  ExchangeRateService({
    Dio? dio,
    ExchangeRateLocalCache? cache,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                headers: {'Accept': 'application/json'},
              ),
            ),
        _cache = cache ?? ExchangeRateLocalCache();

  final Dio _dio;
  final ExchangeRateLocalCache _cache;

  Future<ExchangeRateSnapshot> fetchLatest(String baseCurrency) async {
    final baseCode = baseCurrency.trim().toUpperCase();
    if (baseCode.isEmpty) {
      throw ExchangeRateException('请选择基准货币');
    }

    Object? onlineError;
    try {
      final fetched = await _fetchRatesJsonOnline(baseCode.toLowerCase());
      await _cache.saveRates(baseCode.toLowerCase(), fetched.data);
      await _refreshCurrencyCatalogOnline();
      return _buildSnapshot(
        data: fetched.data,
        baseCode: baseCode,
        fromLocalCache: false,
        fetchedAt: DateTime.now(),
        sourceApiUrl: fetched.url,
      );
    } catch (e) {
      onlineError = e;
    }

    final baseLower = baseCode.toLowerCase();
    final cached = await _cache.loadRates(baseLower);
    if (cached != null) {
      try {
        final savedAt = await _cache.ratesSavedAt(baseLower);
        return _buildSnapshot(
          data: cached,
          baseCode: baseCode,
          fromLocalCache: true,
          fetchedAt: savedAt ?? DateTime.now(),
          sourceApiUrl: null,
        );
      } catch (_) {}
    }

    throw ExchangeRateException(
      '在线更新失败且本地无缓存：$onlineError',
    );
  }

  /// 货币代码 → 英文名称（优先本地缓存）
  Future<Map<String, String>> loadCurrencyNames() async {
    final cached = await _cache.loadCurrencies();
    if (cached != null && cached.isNotEmpty) {
      return _parseCurrencyNames(cached);
    }

    try {
      final data = await _fetchCurrenciesJsonOnline();
      await _cache.saveCurrencies(data);
      return _parseCurrencyNames(data);
    } catch (_) {
      return {};
    }
  }

  /// 可作为基准的货币列表（来自 currencies.json）
  Future<List<String>> listBaseCurrencies() async {
    final names = await loadCurrencyNames();
    if (names.isEmpty) {
      return const ['CNY', 'USD', 'EUR', 'GBP', 'JPY'];
    }
    final codes = names.keys.where(isIsoFiatCurrency).toList()..sort();
    if (codes.length >= ExchangeRateConstants.minCurrencyCount) {
      return codes;
    }
    return kIsoFiatCurrencyNamesZh.keys.toList()..sort();
  }

  Future<String?> getLocalCachePath() => _cache.getCacheRootPath();

  /// 近 7 日走势（用于涨跌幅与迷你折线图，基于每日收盘参考价）
  Future<ExchangeRateTrendMap> loadWeeklyTrends(String baseCurrency) async {
    final baseLower = baseCurrency.trim().toLowerCase();
    final today = DateTime.now();
    final dailyRates = <DateTime, Map<String, double>>{};

    for (var offset = 6; offset >= 0; offset--) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: offset));
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      try {
        final fetched = await _fetchRatesJsonForDate(baseLower, dateStr);
        final rates = _parseRatesMap(fetched.data, baseLower);
        if (rates.isNotEmpty) {
          dailyRates[day] = rates;
        }
      } catch (_) {}
    }

    if (dailyRates.length < 2) return const {};

    final sortedDays = dailyRates.keys.toList()..sort();
    final latestRates = dailyRates[sortedDays.last]!;
    final previousRates = dailyRates[sortedDays[sortedDays.length - 2]]!;
    final trends = <String, ExchangeRateTrend>{};

    for (final code in latestRates.keys) {
      final history = <double>[];
      for (final day in sortedDays) {
        final value = dailyRates[day]?[code];
        if (value != null) history.add(value);
      }
      if (history.length < 2) continue;

      final previous = previousRates[code];
      final latest = latestRates[code];
      double? changePercent;
      if (previous != null && previous > 0 && latest != null) {
        changePercent = (latest - previous) / previous * 100;
      }

      trends[code] = ExchangeRateTrend(
        changePercent24h: changePercent,
        sparklineRates: history,
      );
    }

    return trends;
  }

  Future<void> _refreshCurrencyCatalogOnline() async {
    try {
      final data = await _fetchCurrenciesJsonOnline();
      await _cache.saveCurrencies(data);
    } catch (_) {}
  }

  Future<({Map<String, dynamic> data, String url})> _fetchRatesJsonOnline(
    String baseLower,
  ) {
    return _fetchRatesJsonForDate(baseLower, 'latest');
  }

  Future<({Map<String, dynamic> data, String url})> _fetchRatesJsonForDate(
    String baseLower,
    String date,
  ) async {
    final urls = [
      '${ExchangeRateConstants.cdnBase}@$date/${ExchangeRateConstants.apiVersion}/currencies/$baseLower.json',
      '${ExchangeRateConstants.fallbackBase}/${ExchangeRateConstants.apiVersion}/currencies/$baseLower.json',
    ];

    Object? lastError;
    for (final url in urls) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(url);
        final data = response.data;
        if (data != null && data.containsKey(baseLower)) {
          return (data: data, url: url);
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw ExchangeRateException(
      '无法从 currency-api 获取 $baseLower 汇率${lastError != null ? '：$lastError' : ''}',
    );
  }

  Future<Map<String, dynamic>> _fetchCurrenciesJsonOnline() async {
    const date = 'latest';
    final urls = [
      '${ExchangeRateConstants.cdnBase}@$date/${ExchangeRateConstants.apiVersion}/currencies.json',
      '${ExchangeRateConstants.fallbackBase}/${ExchangeRateConstants.apiVersion}/currencies.json',
    ];

    for (final url in urls) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(url);
        final data = response.data;
        if (data != null && data.isNotEmpty) {
          return data;
        }
      } catch (_) {}
    }

    throw ExchangeRateException('无法获取货币列表');
  }

  Map<String, double> _parseRatesMap(
    Map<String, dynamic> data,
    String baseLower,
  ) {
    final ratesRaw = data[baseLower] as Map<String, dynamic>? ?? {};
    final rates = <String, double>{};
    for (final entry in ratesRaw.entries) {
      final code = entry.key.toUpperCase();
      if (!isQueryableExchangeCurrency(code)) continue;
      final value = entry.value;
      if (value is num) {
        rates[code] = value.toDouble();
      }
    }
    return rates;
  }

  ExchangeRateSnapshot _buildSnapshot({
    required Map<String, dynamic> data,
    required String baseCode,
    required bool fromLocalCache,
    required DateTime fetchedAt,
    required String? sourceApiUrl,
  }) {
    final baseLower = baseCode.toLowerCase();
    final dateStr = data['date'] as String?;
    final rates = _parseRatesMap(data, baseLower);

    if (rates.length < ExchangeRateConstants.minCurrencyCount) {
      throw ExchangeRateException(
        '货币数量不足（${rates.length}），需要至少 ${ExchangeRateConstants.minCurrencyCount} 种',
      );
    }

    final dataDate = dateStr != null
        ? (DateTime.tryParse(dateStr) ?? DateTime.now())
        : DateTime.now();

    return ExchangeRateSnapshot(
      baseCurrency: baseCode,
      date: dataDate,
      rates: rates,
      fetchedAt: fetchedAt,
      sourceName: fromLocalCache ? '本地缓存' : '在线获取',
      fromLocalCache: fromLocalCache,
      currencyCount: rates.length + 1,
      sourceApiUrl: sourceApiUrl,
      nextUpdateAt: computeExchangeRateNextUpdate(dataDate),
    );
  }

  Map<String, String> _parseCurrencyNames(Map<String, dynamic> data) {
    final names = <String, String>{};
    for (final entry in data.entries) {
      final code = entry.key.toUpperCase();
      if (!isIsoFiatCurrency(code)) continue;
      final item = entry.value;
      if (item is Map<String, dynamic>) {
        final name = item['name'] as String? ?? item['code'] as String?;
        if (name != null && name.isNotEmpty) {
          names[code] = name;
        }
      }
    }
    return names;
  }

}
