import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String formatDateChinese(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  static String formatDateChineseWithWeekday(DateTime date) {
    return DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(date);
  }

  static String formatDateTimeRange(DateTime start, DateTime end) {
    final startText =
        '${formatDateChinese(start)} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}:${start.second.toString().padLeft(2, '0')}';
    final endText =
        '${formatDateChinese(end)} ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}:${end.second.toString().padLeft(2, '0')}';
    return '$startText - $endText';
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  static DateTime startOfWeek(
    DateTime date, {
    int weekStartsOn = DateTime.monday,
  }) {
    final weekday = date.weekday;
    var delta = weekday - weekStartsOn;
    if (delta < 0) delta += 7;
    return startOfDay(date.subtract(Duration(days: delta)));
  }

  static DateTime endOfWeek(
    DateTime date, {
    int weekStartsOn = DateTime.monday,
  }) {
    return endOfDay(
      startOfWeek(date, weekStartsOn: weekStartsOn).add(const Duration(days: 6)),
    );
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfMonth(DateTime date) {
    return endOfDay(DateTime(date.year, date.month + 1, 0));
  }

  /// 自定义账期月起始日（1–28），1 表示自然月
  static DateTime startOfBillingMonth(
    DateTime date, {
    int monthStartDay = 1,
  }) {
    if (monthStartDay <= 1) return startOfMonth(date);
    final clamped = monthStartDay.clamp(1, 28);
    if (date.day >= clamped) {
      return DateTime(date.year, date.month, clamped);
    }
    final prev = DateTime(date.year, date.month, 1).subtract(const Duration(days: 1));
    return DateTime(prev.year, prev.month, clamped);
  }

  static DateTime endOfBillingMonth(
    DateTime date, {
    int monthStartDay = 1,
  }) {
    if (monthStartDay <= 1) return endOfMonth(date);
    final start = startOfBillingMonth(date, monthStartDay: monthStartDay);
    final nextStart = start.month == 12
        ? DateTime(start.year + 1, 1, monthStartDay.clamp(1, 28))
        : DateTime(start.year, start.month + 1, monthStartDay.clamp(1, 28));
    return endOfDay(nextStart.subtract(const Duration(days: 1)));
  }

  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  static DateTime endOfYear(DateTime date) {
    return endOfDay(DateTime(date.year, 12, 31));
  }

  static int toMillis(DateTime date) => date.millisecondsSinceEpoch;

  static DateTime fromMillis(int millis) =>
      DateTime.fromMillisecondsSinceEpoch(millis);

  static String formatMonth(DateTime date) {
    return DateFormat('yyyy/MM').format(date);
  }

  static int calendarGridStartOffset(
    DateTime month, {
    int weekStartsOn = DateTime.monday,
  }) {
    final first = startOfMonth(month);
    var delta = first.weekday - weekStartsOn;
    if (delta < 0) delta += 7;
    return delta;
  }

  static List<String> weekdayLabels({int weekStartsOn = DateTime.monday}) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    const order = [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    ];
    final startIndex = order.indexOf(weekStartsOn);
    if (startIndex < 0) return labels;
    return [for (var i = 0; i < 7; i++) labels[(startIndex + i) % 7]];
  }
}
