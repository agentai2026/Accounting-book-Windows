import 'dart:ui';

import 'package:ezbookkeeping_desktop/core/ai/models/ocr_block.dart';

/// 排序合并后的 OCR 行（规则引擎内部使用）
class AiOcrLine {
  const AiOcrLine({
    required this.text,
    required this.score,
    required this.boundingBox,
    required this.index,
  });

  final String text;
  final double score;
  final Rect boundingBox;
  final int index;

  double get top => boundingBox.top;
  double get bottom => boundingBox.bottom;
  double get height => boundingBox.height;

  /// 从 [OcrBlock] 构造
  factory AiOcrLine.fromBlock(OcrBlock block, {required int index}) {
    return AiOcrLine(
      text: block.text.trim(),
      score: block.score,
      boundingBox: Rect.fromLTRB(block.x1, block.y1, block.x2, block.y2),
      index: index,
    );
  }
}
