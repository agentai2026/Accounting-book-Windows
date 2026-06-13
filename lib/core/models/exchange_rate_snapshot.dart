import 'package:ezbookkeeping_desktop/core/constants/exchange_rate_constants.dart';

/// 一次汇率查询结果（用于实时汇率展示，非本地持久化）
class ExchangeRateSnapshot {
  const ExchangeRateSnapshot({
    required this.baseCurrency,
    required this.date,
    required this.rates,
    required this.fetchedAt,
    required this.sourceName,
    this.fromLocalCache = false,
    this.currencyCount,
    this.sourceProjectUrl = ExchangeRateConstants.sourceProjectUrl,
    this.sourceApiUrl,
    required this.nextUpdateAt,
  });

  /// 基准货币 ISO 代码
  final String baseCurrency;

  /// API 标注的汇率日期（通常为最近交易日）
  final DateTime date;

  /// 相对基准货币的汇率：1 [baseCurrency] = rates[code] [code]
  final Map<String, double> rates;

  final DateTime fetchedAt;

  final String sourceName;

  final bool fromLocalCache;

  /// 含基准货币在内的可查询货币总数
  final int? currencyCount;

  /// 开源项目主页
  final String sourceProjectUrl;

  /// 本次实际请求的 API 地址（离线时为 null）
  final String? sourceApiUrl;

  /// 预计下次数据源更新时间
  final DateTime nextUpdateAt;

  int get queryableCurrencyCount => currencyCount ?? rates.length + 1;

  double? rateFor(String currencyCode) {
    final code = currencyCode.toUpperCase();
    if (code == baseCurrency) return 1;
    return rates[code];
  }
}
