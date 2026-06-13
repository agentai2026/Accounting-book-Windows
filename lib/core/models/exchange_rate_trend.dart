/// 单种货币的近期走势（用于涨跌幅与迷你图）
class ExchangeRateTrend {
  const ExchangeRateTrend({
    required this.changePercent24h,
    required this.sparklineRates,
  });

  /// 相对前一交易日的涨跌百分比
  final double? changePercent24h;

  /// 近若干日「1 基准 = X 外币」汇率序列（由旧到新）
  final List<double> sparklineRates;
}

typedef ExchangeRateTrendMap = Map<String, ExchangeRateTrend>;
