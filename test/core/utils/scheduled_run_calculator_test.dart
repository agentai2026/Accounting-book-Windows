import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/scheduled_run_calculator.dart';

void main() {
  test('daily advance adds interval days', () {
    final next = ScheduledRunCalculator.advanceAfterRun(
      lastRunAt: DateTime(2026, 3, 1),
      frequency: ScheduledFrequency.daily,
      intervalCount: 2,
    );
    expect(next, DateTime(2026, 3, 3));
  });

  test('monthly resolve picks future day from start', () {
    final next = ScheduledRunCalculator.resolveInitialNextRun(
      frequency: ScheduledFrequency.monthly,
      intervalCount: 1,
      startDate: DateTime(2026, 1, 15),
      dayOfMonth: 15,
      reference: DateTime(2026, 6, 10),
    );
    expect(next.year, 2026);
    expect(next.month, 6);
    expect(next.day, 15);
  });
}
