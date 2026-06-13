import 'package:ezbookkeeping_desktop/core/models/enums.dart';

/// 统计分析通用查询条件
class StatisticsQueryParams {
  const StatisticsQueryParams({
    this.bookId,
    required this.start,
    required this.end,
    this.type,
    this.keyword,
    this.accountId,
  });

  /// 为 null 时表示全部账本
  final int? bookId;
  final DateTime start;
  final DateTime end;
  final TransactionType? type;
  final String? keyword;
  final int? accountId;
}
