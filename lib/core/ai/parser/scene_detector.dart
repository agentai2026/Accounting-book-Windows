import 'package:ezbookkeeping_desktop/core/ai/models/bill_platform.dart';
import 'package:ezbookkeeping_desktop/core/ai/models/ocr_line.dart';
import 'package:ezbookkeeping_desktop/core/models/receipt_scene.dart';
import 'package:ezbookkeeping_desktop/core/services/receipt_scene_classifier.dart';

/// 根据 OCR 内容识别图片/平台场景
class SceneDetector {
  const SceneDetector({ReceiptSceneClassifier? classifier})
      : _classifier = classifier ?? const ReceiptSceneClassifier();

  final ReceiptSceneClassifier _classifier;

  /// 返回平台类型及原始场景匹配
  SceneDetectResult detect(String fullText, List<AiOcrLine> lines) {
    final lineTexts = lines.map((line) => line.text).toList(growable: false);
    final match = _classifier.classify(fullText, lineTexts);
    final platform = _mapSceneToPlatform(match.scene, fullText);
    return SceneDetectResult(
      platform: platform,
      receiptScene: match.scene,
      sceneScore: match.score,
    );
  }
}

class SceneDetectResult {
  const SceneDetectResult({
    required this.platform,
    required this.receiptScene,
    required this.sceneScore,
  });

  final BillPlatform platform;
  final ReceiptScene receiptScene;
  final double sceneScore;
}

BillPlatform _mapSceneToPlatform(ReceiptScene scene, String text) {
  return switch (scene) {
    ReceiptScene.wechatPayment ||
    ReceiptScene.wechatTransferIncome ||
    ReceiptScene.wechatTransferExpense =>
      BillPlatform.wechat,
    ReceiptScene.alipayPayment || ReceiptScene.alipayTransfer =>
      BillPlatform.alipay,
    ReceiptScene.bankMonthlyBill || ReceiptScene.bankCardDetail =>
      BillPlatform.bank,
    ReceiptScene.paperReceipt => BillPlatform.receipt,
    ReceiptScene.unknown => _guessUnknownPlatform(text),
  };
}

BillPlatform _guessUnknownPlatform(String text) {
  if (text.contains('云闪付') || text.contains('银联')) {
    return BillPlatform.unionpay;
  }
  if (text.contains('电子发票') || text.contains('发票代码')) {
    return BillPlatform.invoice;
  }
  if (RegExp(r'实付|合计|总计|小票').hasMatch(text)) {
    return BillPlatform.receipt;
  }
  return BillPlatform.unknown;
}
