import 'package:ezbookkeeping_desktop/core/constants/money_grouping.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';

/// 将设置项同步到全局运行时（金额格式等）
class SettingsBindings {
  SettingsBindings._();

  static void applyAmountFormat(AmountFormatStyle format) {
    MoneyUtils.displayGrouping = switch (format) {
      AmountFormatStyle.off => MoneyGrouping.none,
      AmountFormatStyle.thousands => MoneyGrouping.thousands,
      AmountFormatStyle.tenThousands => MoneyGrouping.tenThousands,
    };
  }

  static int weekStartsOn(WeekStartDay day) => switch (day) {
        WeekStartDay.monday => DateTime.monday,
        WeekStartDay.sunday => DateTime.sunday,
        WeekStartDay.saturday => DateTime.saturday,
      };
}
