/// 三、PaddleOCR PP-OCRv5 调用参数（mobile_ocr 插件）

/// 方向分类：插件内置 cls.onnx，enhanceRecognitionCrops 会启用裁剪增强
const kReceiptOcrUseAngleCls = true;

/// 检测阈值（原生侧默认值；若插件后续暴露 API 则对齐此值）
const kReceiptOcrDetDbThresh = 0.2;

const kReceiptOcrDetDbBoxThresh = 0.5;
const kReceiptOcrDetDbUnclipRatio = 1.5;
const kReceiptOcrRecBatchNum = 6;

/// 传给 mobile_ocr 的 Dart 侧参数
const kReceiptOcrEnhanceRecognitionCrops = true;
const kReceiptOcrIncludeAllConfidenceScores = true;
const kReceiptOcrRecognitionContrastBoost = 0.12;
const kReceiptOcrRecognitionBrightnessBoost = 0.03;

/// 同行合并 Y 容差（像素）
const kReceiptOcrLineMergeTolerance = 12.0;
