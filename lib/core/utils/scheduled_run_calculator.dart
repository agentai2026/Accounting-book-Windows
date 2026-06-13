import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';

/// 计算周期记账的下一次执行时间
class ScheduledRunCalculator {
  ScheduledRunCalculator._();

  static DateTime resolveInitialNextRun({
    required ScheduledFrequency frequency,
    required int intervalCount,
    required DateTime startDate,
    int? dayOfMonth,
    int? weekday,
    DateTime? reference,
  }) {
    final ref = AppDateUtils.startOfDay(reference ?? DateTime.now());
    var candidate = AppDateUtils.startOfDay(startDate);
    candidate = _alignCandidate(
      candidate,
      frequency: frequency,
      dayOfMonth: dayOfMonth,
      weekday: weekday,
    );

    var guard = 0;
    while (candidate.isBefore(ref) && guard < 5000) {
      candidate = advanceAfterRun(
        lastRunAt: candidate,
        frequency: frequency,
        intervalCount: intervalCount,
        dayOfMonth: dayOfMonth,
        weekday: weekday,
      );
      guard++;
    }
    return candidate;
  }

  static DateTime advanceAfterRun({
    required DateTime lastRunAt,
    required ScheduledFrequency frequency,
    required int intervalCount,
    int? dayOfMonth,
    int? weekday,
  }) {
    final safeInterval = intervalCount < 1 ? 1 : intervalCount;
    final base = AppDateUtils.startOfDay(lastRunAt);

    return switch (frequency) {
      ScheduledFrequency.daily => base.add(Duration(days: safeInterval)),
      ScheduledFrequency.weekly => _advanceWeekly(
          base,
          intervalCount: safeInterval,
          weekday: weekday,
        ),
      ScheduledFrequency.monthly => _advanceMonthly(
          base,
          intervalCount: safeInterval,
          dayOfMonth: dayOfMonth ?? base.day,
        ),
      ScheduledFrequency.yearly => _advanceYearly(
          base,
          intervalCount: safeInterval,
          dayOfMonth: dayOfMonth ?? base.day,
        ),
    };
  }

  static DateTime _advanceWeekly(
    DateTime base, {
    required int intervalCount,
    int? weekday,
  }) {
    if (weekday == null) {
      return base.add(Duration(days: 7 * intervalCount));
    }
    var next = base.add(Duration(days: 7 * intervalCount));
    next = _setWeekday(next, weekday);
    if (!next.isAfter(base)) {
      next = next.add(const Duration(days: 7));
    }
    return AppDateUtils.startOfDay(next);
  }

  static DateTime _advanceMonthly(
    DateTime base, {
    required int intervalCount,
    required int dayOfMonth,
  }) {
    final monthOffset = base.month - 1 + intervalCount;
    final year = base.year + monthOffset ~/ 12;
    final month = monthOffset % 12 + 1;
    return AppDateUtils.startOfDay(
      DateTime(year, month, _clampDay(year, month, dayOfMonth)),
    );
  }

  static DateTime _advanceYearly(
    DateTime base, {
    required int intervalCount,
    required int dayOfMonth,
  }) {
    final year = base.year + intervalCount;
    return AppDateUtils.startOfDay(
      DateTime(year, base.month, _clampDay(year, base.month, dayOfMonth)),
    );
  }

  static DateTime _alignCandidate(
    DateTime candidate, {
    required ScheduledFrequency frequency,
    int? dayOfMonth,
    int? weekday,
  }) {
    return switch (frequency) {
      ScheduledFrequency.daily => candidate,
      ScheduledFrequency.weekly when weekday != null =>
        _setWeekday(candidate, weekday),
      ScheduledFrequency.monthly when dayOfMonth != null => AppDateUtils.startOfDay(
          DateTime(
            candidate.year,
            candidate.month,
            _clampDay(candidate.year, candidate.month, dayOfMonth),
          ),
        ),
      ScheduledFrequency.yearly when dayOfMonth != null => AppDateUtils.startOfDay(
          DateTime(
            candidate.year,
            candidate.month,
            _clampDay(candidate.year, candidate.month, dayOfMonth),
          ),
        ),
      _ => candidate,
    };
  }

  static DateTime _setWeekday(DateTime date, int weekday) {
    final current = date.weekday;
    var delta = weekday - current;
    if (delta < 0) delta += 7;
    return AppDateUtils.startOfDay(date.add(Duration(days: delta)));
  }

  static int _clampDay(int year, int month, int day) {
    final last = DateTime(year, month + 1, 0).day;
    if (day < 1) return 1;
    if (day > last) return last;
    return day;
  }
}
