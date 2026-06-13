import 'package:ezbookkeeping_desktop/core/ai/normalize/ocr_correction_map.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/ocr_correction_rules.dart';

/// OCR 文本清洗：错字修复、特殊字符、数字纠错
class TextNormalizer {
  const TextNormalizer();

  /// 对单行或全文应用全部规范化规则
  String normalize(String raw) {
    var text = raw
        .replaceAll('\r', '')
        .replaceAll('￥', '¥')
        .replaceAll('，', ',')
        .replaceAll('＋', '+')
        .replaceAll('－', '-');

    for (final entry in kOcrCorrectionDictionary.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    for (final rule in kReceiptOcrLiteralReplacements) {
      text = text.replaceAll(rule.from, rule.to);
    }

    for (final rule in kReceiptOcrRegexReplacements) {
      text = text.replaceAllMapped(rule.pattern, (match) {
        var result = rule.replace;
        for (var i = 1; i <= match.groupCount; i++) {
          result = result.replaceAll('\$$i', match.group(i) ?? '');
        }
        return result;
      });
    }

    return text.trim();
  }

  /// 金额行专用：字母 → 数字
  String normalizeAmountLine(String line) {
    var text = normalize(line);
    for (final entry in kOcrDigitCharMap.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    return text;
  }
}
