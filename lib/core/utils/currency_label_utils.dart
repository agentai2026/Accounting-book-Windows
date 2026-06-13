import 'package:ezbookkeeping_desktop/core/constants/iso_fiat_currencies.dart';

/// 汇率页货币名称：优先中文法币名，其次 API 英文名，最后代码
String exchangeCurrencyLabel(
  String code, {
  Map<String, String>? apiEnglishNames,
}) {
  final upper = code.toUpperCase();
  final zh = kIsoFiatCurrencyNamesZh[upper];
  if (zh != null) return zh;

  final english = apiEnglishNames?[upper];
  if (english != null && english.isNotEmpty && english.toUpperCase() != upper) {
    return english;
  }

  return upper;
}
