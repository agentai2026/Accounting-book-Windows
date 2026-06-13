import 'dart:ui';

/// OCR 单行文本（含坐标与置信度，供小票/发票规则提取）
class OcrTextLine {
  const OcrTextLine({
    required this.text,
    required this.confidence,
    required this.boundingBox,
    this.index = 0,
  });

  final String text;
  final double confidence;
  final Rect boundingBox;
  final int index;

  double get top => boundingBox.top;
  double get bottom => boundingBox.bottom;
  double get left => boundingBox.left;
  double get height => boundingBox.height;
  double get width => boundingBox.width;
  double get centerY => boundingBox.center.dy;
}
