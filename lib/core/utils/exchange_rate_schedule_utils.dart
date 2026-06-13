import 'package:ezbookkeeping_desktop/core/constants/exchange_rate_constants.dart';

/// 根据汇率数据日期推算下次更新时间（按每日更新）
DateTime computeExchangeRateNextUpdate(DateTime dataDate) {
  final now = DateTime.now();
  var next = DateTime(
    dataDate.year,
    dataDate.month,
    dataDate.day,
  ).add(ExchangeRateConstants.updateInterval);

  while (!next.isAfter(now)) {
    next = next.add(ExchangeRateConstants.updateInterval);
  }
  return next;
}

String formatExchangeRateCountdown(DateTime nextUpdateAt) {
  final diff = nextUpdateAt.difference(DateTime.now());
  if (diff.isNegative || diff.inSeconds <= 0) {
    return '即将更新';
  }
  if (diff.inHours >= 1) {
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (minutes > 0) return '$hours 小时 $minutes 分后';
    return '$hours 小时 后';
  }
  if (diff.inMinutes >= 1) {
    return '${diff.inMinutes} 分 ${diff.inSeconds % 60} 秒后';
  }
  return '${diff.inSeconds} 秒后';
}
