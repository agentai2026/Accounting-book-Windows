import 'dart:ui';

import 'package:mobile_ocr/models/text_block.dart' as ocr;

import 'package:ezbookkeeping_desktop/core/models/ocr_text_line.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/confidence_rules.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/ocr_params_rules.dart';

/// OCR 文本块 → 有序行列表（Y 自上而下，X 从左到右）
class OcrLineUtils {
  const OcrLineUtils();

  List<OcrTextLine> fromBlocks(List<ocr.TextBlock> blocks) {
    if (blocks.isEmpty) return const [];

    final sorted = [...blocks]
      ..sort((a, b) {
        final dy = a.boundingBox.top.compareTo(b.boundingBox.top);
        if (dy != 0) return dy;
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      });

    final merged = <OcrTextLine>[];
    final lineTops = <double>[];
    const tolerance = kReceiptOcrLineMergeTolerance;

    for (final block in sorted) {
      final text = block.text.trim();
      if (text.isEmpty) continue;
      if (block.confidence < kReceiptSingleCharConfidenceMin &&
          text.runes.length <= 1) {
        continue;
      }

      final top = block.boundingBox.top;
      if (merged.isEmpty) {
        merged.add(_toLine(block, 0));
        lineTops.add(top);
        continue;
      }

      final sameLine = (top - lineTops.last).abs() <= tolerance;
      if (sameLine) {
        final prev = merged.last;
        final combinedText = '${prev.text} $text'.trim();
        final union = prev.boundingBox.expandToInclude(block.boundingBox);
        merged[merged.length - 1] = OcrTextLine(
          text: combinedText,
          confidence: (prev.confidence + block.confidence) / 2,
          boundingBox: union,
          index: prev.index,
        );
      } else {
        merged.add(_toLine(block, merged.length));
        lineTops.add(top);
      }
    }

    return merged;
  }

  String joinLines(List<OcrTextLine> lines) {
    return lines.map((line) => line.text).join('\n');
  }

  double maxBottom(List<OcrTextLine> lines) {
    if (lines.isEmpty) return 0;
    return lines
        .map((line) => line.bottom)
        .reduce((a, b) => a > b ? a : b);
  }

  OcrTextLine _toLine(ocr.TextBlock block, int index) {
    return OcrTextLine(
      text: block.text.trim(),
      confidence: block.confidence,
      boundingBox: block.boundingBox,
      index: index,
    );
  }
}
