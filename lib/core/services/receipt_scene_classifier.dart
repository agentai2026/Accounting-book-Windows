import 'package:ezbookkeeping_desktop/core/models/receipt_scene.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/scene_keyword_rules.dart';

/// 根据 OCR 文本判断截图属于哪种支付/账单场景
class ReceiptSceneClassifier {
  const ReceiptSceneClassifier();

  ReceiptSceneMatch classify(String text, List<String> lines) {
    final scores = <ReceiptScene, double>{
      ReceiptScene.bankMonthlyBill: _scoreBankMonthlyBill(text, lines),
      ReceiptScene.wechatPayment: _scoreWechatPayment(text, lines),
      ReceiptScene.wechatTransferIncome: _scoreWechatTransferIncome(text, lines),
      ReceiptScene.wechatTransferExpense: _scoreWechatTransferExpense(text, lines),
      ReceiptScene.alipayPayment: _scoreAlipayPayment(text, lines),
      ReceiptScene.alipayTransfer: _scoreAlipayTransfer(text, lines),
      ReceiptScene.bankCardDetail: _scoreBankCardDetail(text, lines),
    };

    var bestScene = ReceiptScene.unknown;
    var bestScore = 0.0;
    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        bestScene = entry.key;
      }
    }

    if (bestScore < 0.35) {
      return const ReceiptSceneMatch(scene: ReceiptScene.unknown, score: 0);
    }

    return ReceiptSceneMatch(scene: bestScene, score: bestScore);
  }

  double _scoreBankMonthlyBill(String text, List<String> lines) {
    var score = 0.0;
    if (RegExp(r'\d{1,2}\s*月\s*/?\s*\d{4}').hasMatch(text)) score += 0.35;
    if (RegExp(r'\d{1,2}\s*月\s+\d{4}').hasMatch(text)) score += 0.3;
    if (text.contains('支出') && text.contains('收入')) score += 0.2;
    if (lines.any((l) => RegExp(r'^0?\d{1,2}日$').hasMatch(l.trim()))) {
      score += 0.15;
    }
    if (RegExp(r'借记卡|储蓄卡').hasMatch(text)) score += 0.15;
    if (lines.any((l) => RegExp(r'^转账[-—]').hasMatch(l))) score += 0.1;
    if (ReceiptSceneKeywordRules.bankMonthlyPenalties.any(text.contains)) {
      score -= 0.25;
    }
    return score.clamp(0, 1);
  }

  double _scoreWechatPayment(String text, List<String> lines) {
    var score = 0.0;
    if (ReceiptSceneKeywordRules.wechatPaymentStrong.any(text.contains)) {
      score += 0.35;
    }
    if (text.contains('支付成功')) score += 0.05;
    if (text.contains('付款给')) score += 0.05;
    if (ReceiptSceneKeywordRules.wechatPaymentMedium.any(text.contains)) {
      score += 0.15;
    }
    if (text.contains('商品说明')) score += 0.1;
    if (text.contains('支付宝')) score -= 0.3;
    if (_looksLikeBankMonthly(lines)) score -= 0.35;
    return score.clamp(0, 1);
  }

  double _scoreWechatTransferIncome(String text, List<String> lines) {
    var score = 0.0;
    if (RegExp(r'[+\＋]\s*¥?\s*[\d,]').hasMatch(text)) score += 0.2;
    if (ReceiptSceneKeywordRules.wechatTransferIncomeStrong.any(text.contains)) {
      score += 0.35;
    }
    if (text.contains('来自') && text.contains('转账')) score += 0.25;
    if (text.contains('零钱') || text.contains('微信')) score += 0.15;
    if (text.contains('支付成功') || text.contains('付款给')) score -= 0.3;
    if (_looksLikeBankMonthly(lines)) score -= 0.35;
    return score.clamp(0, 1);
  }

  double _scoreWechatTransferExpense(String text, List<String> lines) {
    var score = 0.0;
    if (RegExp(r'[-－]\s*¥?\s*[\d,]').hasMatch(text)) score += 0.15;
    if (ReceiptSceneKeywordRules.wechatTransferExpenseStrong.any(text.contains)) {
      score += 0.35;
    }
    if (text.contains('零钱') || text.contains('微信')) score += 0.15;
    if (text.contains('支付成功')) score -= 0.25;
    if (_looksLikeBankMonthly(lines)) score -= 0.35;
    return score.clamp(0, 1);
  }

  double _scoreAlipayPayment(String text, List<String> lines) {
    var score = 0.0;
    for (final keyword in ReceiptSceneKeywordRules.alipayPaymentStrong) {
      if (text.contains(keyword)) score += 0.15;
    }
    if (text.contains('账单详情')) score += 0.05;
    if (text.contains('交易成功')) score += 0.05;
    if (ReceiptSceneKeywordRules.alipayPaymentMedium.any(text.contains)) {
      score += 0.15;
    }
    if (text.contains('微信')) score -= 0.3;
    if (_looksLikeBankMonthly(lines)) score -= 0.35;
    return score.clamp(0, 1);
  }

  double _scoreAlipayTransfer(String text, List<String> lines) {
    var score = 0.0;
    if (ReceiptSceneKeywordRules.alipayTransferStrong.any(text.contains)) {
      score += 0.35;
    }
    if (text.contains('对方账户') || text.contains('交易对方')) score += 0.2;
    if (text.contains('支付宝')) score += 0.2;
    if (text.contains('账单详情') || text.contains('转账备注')) score -= 0.25;
    if (text.contains('付款成功') && text.contains('收款方')) score -= 0.2;
    if (_looksLikeBankMonthly(lines)) score -= 0.35;
    return score.clamp(0, 1);
  }

  double _scoreBankCardDetail(String text, List<String> lines) {
    var score = 0.0;
    if (RegExp(r'借记卡|储蓄卡|银行卡').hasMatch(text)) score += 0.25;
    if (text.contains('交易时间') || text.contains('交易金额')) score += 0.25;
    if (RegExp(r'\d{4}年\d{1,2}月\d{1,2}日').hasMatch(text)) score += 0.2;
    if (_looksLikeBankMonthly(lines)) score -= 0.4;
    return score.clamp(0, 1);
  }

  bool _looksLikeBankMonthly(List<String> lines) {
    return lines.any((l) => RegExp(r'^\d{1,2}\s*月\s*/?\s*\d{4}$').hasMatch(l.replaceAll(' ', ''))) ||
        lines.any((l) => RegExp(r'^0?\d{1,2}日$').hasMatch(l.trim()));
  }
}
