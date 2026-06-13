/// OCR 识别块（与 PaddleOCR 输出对齐，保留坐标）
class OcrBlock {
  const OcrBlock({
    required this.text,
    required this.score,
    required this.box,
  });

  /// 识别文本
  final String text;

  /// 置信度 0~1
  final double score;

  /// 外接矩形 [x1, y1, x2, y2]
  final List<double> box;

  double get x1 => box.isNotEmpty ? box[0] : 0;
  double get y1 => box.length > 1 ? box[1] : 0;
  double get x2 => box.length > 2 ? box[2] : 0;
  double get y2 => box.length > 3 ? box[3] : 0;

  double get width => (x2 - x1).abs();
  double get height => (y2 - y1).abs();
  double get top => y1;
  double get bottom => y2;
  double get left => x1;
}
