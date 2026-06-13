import 'package:ezbookkeeping_desktop/core/ai/models/ocr_line.dart';

/// 日期时间提取结果
class DateParseResult {
  const DateParseResult({
    required this.date,
    this.time,
    this.hasFullDate = false,
    this.fromExif = false,
  });

  /// YYYY-MM-DD
  final String date;
  final String? time;
  final bool hasFullDate;
  final bool fromExif;
}

/// 从 OCR 行提取交易日期
class DateParser {
  const DateParser();

  /// [exifDateTime] 可选 EXIF 原始时间字符串
  DateParseResult? extractDate(
    List<AiOcrLine> lines, {
    String? exifDateTime,
  }) {
    const dateLabels = [
      '日期',
      '时间',
      '开票日期',
      '交易日期',
      '创建时间',
      '付款时间',
    ];

    for (final line in lines) {
      final hasLabel = dateLabels.any(line.text.contains);
      final parsed = _parseLine(line.text);
      if (parsed != null && (hasLabel || parsed.hasFullDate)) {
        return parsed;
      }
    }

    for (final line in lines) {
      final parsed = _parseLine(line.text);
      if (parsed != null) return parsed;
    }

    final fullText = lines.map((line) => line.text).join('\n');
    final fromFull = _parseLine(fullText);
    if (fromFull != null) return fromFull;

    if (exifDateTime != null) {
      return _parseExif(exifDateTime);
    }

    return null;
  }

  DateParseResult? _parseLine(String text) {
    final fullDatePattern = RegExp(
      r'(\d{4})[-/.年](\d{1,2})[-/.月](\d{1,2})(?:日)?(?:\s+(\d{1,2}:\d{2}(?::\d{2})?))?',
    );
    final fullMatch = fullDatePattern.firstMatch(text);
    if (fullMatch != null) {
      try {
        return DateParseResult(
          date: _formatDate(
            int.parse(fullMatch.group(1)!),
            int.parse(fullMatch.group(2)!),
            int.parse(fullMatch.group(3)!),
          ),
          time: fullMatch.group(4),
          hasFullDate: true,
        );
      } catch (_) {
        return null;
      }
    }

    final monthDayPattern = RegExp(
      r'(\d{1,2})[-/.月](\d{1,2})(?:日)?(?:\s+(\d{1,2}:\d{2}))?',
    );
    final mdMatch = monthDayPattern.firstMatch(text);
    if (mdMatch != null) {
      try {
        final m = int.parse(mdMatch.group(1)!);
        final d = int.parse(mdMatch.group(2)!);
        final now = DateTime.now();
        var y = now.year;
        if (DateTime(y, m, d).isAfter(now)) y -= 1;
        return DateParseResult(
          date: _formatDate(y, m, d),
          time: mdMatch.group(3),
          hasFullDate: false,
        );
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  DateParseResult? _parseExif(String exif) {
    final match = RegExp(
      r'(\d{4}):(\d{2}):(\d{2})\s+(\d{2}:\d{2}:\d{2})',
    ).firstMatch(exif);
    if (match == null) return null;
    return DateParseResult(
      date: _formatDate(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      ),
      time: match.group(4),
      hasFullDate: true,
      fromExif: true,
    );
  }

  String _formatDate(int y, int m, int d) {
    return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }
}
