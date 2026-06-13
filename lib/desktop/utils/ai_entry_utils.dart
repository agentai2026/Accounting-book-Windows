import 'package:ezbookkeeping_desktop/core/ai/models/bill.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';

/// 根据用户入账策略与识别置信度级别，判断是否应自动入账。
bool shouldAutoEnterAi({
  required AiEntryStrategy strategy,
  required BillAutoEntryLevel level,
}) {
  return switch (strategy) {
    AiEntryStrategy.manual => false,
    AiEntryStrategy.standard => level == BillAutoEntryLevel.auto,
    AiEntryStrategy.aggressive =>
      level == BillAutoEntryLevel.auto || level == BillAutoEntryLevel.confirm,
  };
}
