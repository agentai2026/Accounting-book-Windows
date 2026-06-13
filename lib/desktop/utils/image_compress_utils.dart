import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';

/// 按设置压缩/缩放账单图片（仅缩小尺寸，不改变格式）
class ImageCompressUtils {
  ImageCompressUtils._();

  static Future<Uint8List> compress(
    Uint8List bytes,
    ImageCompressionLevel level,
  ) async {
    if (level == ImageCompressionLevel.original) return bytes;

    final maxSide = switch (level) {
      ImageCompressionLevel.sd => 1280,
      ImageCompressionLevel.hd => 1920,
      ImageCompressionLevel.original => 4096,
    };

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final w = image.width;
    final h = image.height;
    image.dispose();

    if (w <= maxSide && h <= maxSide) return bytes;

    final scale = maxSide / (w > h ? w : h);
    final targetW = (w * scale).round().clamp(1, maxSide);
    final targetH = (h * scale).round().clamp(1, maxSide);

    final resizedCodec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: targetW,
      targetHeight: targetH,
    );
    final resizedFrame = await resizedCodec.getNextFrame();
    final resizedImage = resizedFrame.image;
    final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
    resizedImage.dispose();

    if (byteData == null) return bytes;
    return byteData.buffer.asUint8List();
  }
}
