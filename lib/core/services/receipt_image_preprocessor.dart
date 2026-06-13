import 'package:image/image.dart' as img;

import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/image_preprocess_rules.dart';

/// 小票/发票 OCR 前图像预处理（灰阶 + 对比度 + 降噪）
class ReceiptImagePreprocessor {
  const ReceiptImagePreprocessor();

  img.Image process(img.Image source) {
    if (!kReceiptPreprocessEnabled) return source;

    var image = _resizeIfNeeded(source);
    image = img.grayscale(image);
    image = img.adjustColor(
      image,
      contrast: kReceiptPreprocessContrast,
      brightness: kReceiptPreprocessBrightness,
    );

    if (kReceiptPreprocessMedianRadius > 0) {
      image = img.gaussianBlur(
        image,
        radius: kReceiptPreprocessMedianRadius,
      );
    }

    return image;
  }

  img.Image _resizeIfNeeded(img.Image image) {
    final maxEdge = kReceiptMaxImageEdge;
    final w = image.width;
    final h = image.height;
    final longest = w > h ? w : h;
    if (longest <= maxEdge) return image;

    final scale = maxEdge / longest;
    return img.copyResize(
      image,
      width: (w * scale).round(),
      height: (h * scale).round(),
      interpolation: img.Interpolation.linear,
    );
  }
}
