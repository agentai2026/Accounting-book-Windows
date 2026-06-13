/// 汇率数据常量
class ExchangeRateConstants {
  ExchangeRateConstants._();

  /// 至少支持的货币数量（过滤废止代码后通常约 160+）
  static const int minCurrencyCount = 150;

  static const String cacheFolderName = 'exchange_rates';
  static const String ratesSubFolder = 'rates';
  static const String currenciesCacheFile = 'currencies.json';

  static const String sourceProjectName = 'fawazahmed0/exchange-api';
  static const String sourceProjectUrl =
      'https://github.com/fawazahmed0/exchange-api';
  static const String sourceCdnLatestUrl =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/';
  static const String sourceFallbackLatestUrl =
      'https://latest.currency-api.pages.dev/v1/';

  static const String cdnBase =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api';
  static const String fallbackBase = 'https://latest.currency-api.pages.dev';
  static const String apiVersion = 'v1';

  /// 数据源每日更新一次
  static const Duration updateInterval = Duration(days: 1);
}
