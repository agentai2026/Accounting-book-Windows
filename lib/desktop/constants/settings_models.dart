import 'package:ezbookkeeping_desktop/core/models/enums.dart';

enum BackgroundStyle {
  warm,
  cool,
  mint,
  sunset,
  minimal,
  custom,
}

enum GlassStrength {
  light,
  standard,
  strong,
}

enum ForegroundMaterial {
  transparent,
  solid,
  blur,
}

enum SettingsIconSize {
  small,
  medium,
  large,
}

enum ImageCompressionLevel {
  sd,
  hd,
  original,
}

enum IconColumnCount {
  four,
  five,
  six,
}

enum BillInfoDisplayMode {
  time,
  note,
  all,
}

enum CalendarFontWeight {
  light,
  normal,
  bold,
}

enum CalendarFontSize {
  small,
  normal,
  large,
}

enum IncomeExpenseColorScheme {
  greenRed,
  redGreen,
  colorWeak,
}

enum WeekStartDay {
  saturday,
  sunday,
  monday,
}

enum AmountFormatStyle {
  off,
  thousands,
  tenThousands,
}

enum BackupCycle {
  off,
  daily,
  weekly,
}

enum NotificationSoundStyle {
  drum,
  morning,
  cave,
}

extension ImageCompressionLevelX on ImageCompressionLevel {
  String get label => switch (this) {
        ImageCompressionLevel.sd => '标清',
        ImageCompressionLevel.hd => '高清',
        ImageCompressionLevel.original => '原画',
      };
}

extension IconColumnCountX on IconColumnCount {
  String get label => switch (this) {
        IconColumnCount.four => '四列',
        IconColumnCount.five => '五列',
        IconColumnCount.six => '六列',
      };

  int get columns => switch (this) {
        IconColumnCount.four => 4,
        IconColumnCount.five => 5,
        IconColumnCount.six => 6,
      };
}

enum AiEntryStrategy {
  manual,
  standard,
  aggressive,
}

extension AiEntryStrategyX on AiEntryStrategy {
  String get label => switch (this) {
        AiEntryStrategy.manual => '手动确认',
        AiEntryStrategy.standard => '标准',
        AiEntryStrategy.aggressive => '高置信自动',
      };
}

extension TransactionTypeSettingX on TransactionType {
  String get settingLabel => switch (this) {
        TransactionType.expense => '支出',
        TransactionType.income => '收入',
        TransactionType.transfer => '转账',
      };
}

extension ForegroundMaterialX on ForegroundMaterial {
  String get label => switch (this) {
        ForegroundMaterial.transparent => '轻透',
        ForegroundMaterial.solid => '纯色',
        ForegroundMaterial.blur => '毛玻璃',
      };
}

extension BillInfoDisplayModeX on BillInfoDisplayMode {
  String get label => switch (this) {
        BillInfoDisplayMode.time => '时间',
        BillInfoDisplayMode.note => '备注',
        BillInfoDisplayMode.all => '全部',
      };
}

extension CalendarFontWeightX on CalendarFontWeight {
  String get label => switch (this) {
        CalendarFontWeight.light => '细体',
        CalendarFontWeight.normal => '正常',
        CalendarFontWeight.bold => '粗体',
      };
}

extension CalendarFontSizeX on CalendarFontSize {
  String get label => switch (this) {
        CalendarFontSize.small => '偏小',
        CalendarFontSize.normal => '正常',
        CalendarFontSize.large => '偏大',
      };
}

extension IncomeExpenseColorSchemeX on IncomeExpenseColorScheme {
  String get label => switch (this) {
        IncomeExpenseColorScheme.greenRed => '绿红',
        IncomeExpenseColorScheme.redGreen => '红绿',
        IncomeExpenseColorScheme.colorWeak => '色弱',
      };
}

extension WeekStartDayX on WeekStartDay {
  String get label => switch (this) {
        WeekStartDay.saturday => '周六',
        WeekStartDay.sunday => '周日',
        WeekStartDay.monday => '周一',
      };
}

extension AmountFormatStyleX on AmountFormatStyle {
  String get label => switch (this) {
        AmountFormatStyle.off => '关闭',
        AmountFormatStyle.thousands => '千分位',
        AmountFormatStyle.tenThousands => '万分位',
      };
}

extension BackupCycleX on BackupCycle {
  String get label => switch (this) {
        BackupCycle.off => '关闭',
        BackupCycle.daily => '每天',
        BackupCycle.weekly => '每周',
      };
}

extension NotificationSoundStyleX on NotificationSoundStyle {
  String get label => switch (this) {
        NotificationSoundStyle.drum => '手鼓',
        NotificationSoundStyle.morning => '晨露',
        NotificationSoundStyle.cave => '溶洞',
      };
}

extension GlassStrengthX on GlassStrength {
  String get label => switch (this) {
        GlassStrength.light => '轻盈',
        GlassStrength.standard => '标准',
        GlassStrength.strong => '浓郁',
      };
}

extension SettingsIconSizeX on SettingsIconSize {
  String get label => switch (this) {
        SettingsIconSize.small => '小',
        SettingsIconSize.medium => '中',
        SettingsIconSize.large => '大',
      };
}
