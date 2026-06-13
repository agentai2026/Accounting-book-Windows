import 'dart:async';

import 'package:flutter/foundation.dart';

typedef ScheduledTransactionRunner = Future<int> Function();

/// 应用运行期间定期检查并执行到期的周期记账。
class ScheduledTransactionRunnerService {
  ScheduledTransactionRunnerService._();

  static final ScheduledTransactionRunnerService instance =
      ScheduledTransactionRunnerService._();

  Timer? _timer;
  ScheduledTransactionRunner? _runner;

  void start({required ScheduledTransactionRunner runner}) {
    _runner = runner;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(_maybeRun());
    });
    unawaited(_maybeRun());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _runner = null;
  }

  @visibleForTesting
  Future<void> tick() => _maybeRun();

  Future<void> _maybeRun() async {
    final runner = _runner;
    if (runner == null) return;
    try {
      await runner();
    } catch (_) {}
  }
}
