import 'dart:ui';

import 'package:ezbookkeeping_desktop/core/ai/models/ocr_block.dart';
import 'package:ezbookkeeping_desktop/core/ai/models/ocr_line.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/confidence_rules.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/ocr_params_rules.dart';

/// OCR Block 排序、同行合并
class OcrBlockSorter {
  const OcrBlockSorter();

  /// 将 OCR 块转为阅读顺序行列表（保留坐标）
  List<AiOcrLine> toLines(List<OcrBlock> blocks) {
    if (blocks.isEmpty) return const [];

    final sorted = [...blocks]
      ..sort((a, b) {
        final dy = a.top.compareTo(b.top);
        if (dy != 0) return dy;
        return a.left.compareTo(b.left);
      });

    final merged = <AiOcrLine>[];
    final lineTops = <double>[];
    const tolerance = kReceiptOcrLineMergeTolerance;

    for (final block in sorted) {
      final text = block.text.trim();
      if (text.isEmpty) continue;
      if (block.score < kReceiptSingleCharConfidenceMin &&
          text.runes.length <= 1) {
        continue;
      }

      final top = block.top;
      if (merged.isEmpty) {
        merged.add(AiOcrLine.fromBlock(block, index: 0));
        lineTops.add(top);
        continue;
      }

      final sameLine = (top - lineTops.last).abs() <= tolerance;
      if (sameLine) {
        final prev = merged.last;
        final combined = '${prev.text} $text'.trim();
        final union = prev.boundingBox.expandToInclude(
          Rect.fromLTRB(block.x1, block.y1, block.x2, block.y2),
        );
        merged[merged.length - 1] = AiOcrLine(
          text: combined,
          score: (prev.score + block.score) / 2,
          boundingBox: union,
          index: prev.index,
        );
      } else {
        merged.add(AiOcrLine.fromBlock(block, index: merged.length));
        lineTops.add(top);
      }
    }

    return merged;
  }

  String joinText(List<AiOcrLine> lines) {
    return lines.map((line) => line.text).join('\n');
  }
}
