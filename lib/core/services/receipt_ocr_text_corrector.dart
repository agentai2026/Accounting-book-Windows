import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/ocr_correction_rules.dart';

/// 对 OCR 原始文本应用纠错规则
class ReceiptOcrTextCorrector {
  const ReceiptOcrTextCorrector();

  String apply(String rawText) {
    var text = rawText;
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
    return text;
  }
}
