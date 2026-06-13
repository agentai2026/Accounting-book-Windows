import 'package:lunar/lunar.dart';

/// 农历日期短显示（如：十六、廿六）
String lunarDayShort(DateTime date) {
  try {
    final solar = Solar.fromYmd(date.year, date.month, date.day);
    return solar.getLunar().getDayInChinese();
  } catch (_) {
    return '';
  }
}
