import 'package:ezbookkeeping_desktop/core/ai/models/bill.dart';
import 'package:ezbookkeeping_desktop/core/models/ai_recognition_result.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/receipt_scene.dart';
import 'package:ezbookkeeping_desktop/core/ai/models/bill_platform.dart';

/// Bill → 现有识图结果 / 表单模型转换
class BillRecognitionMapper {
  const BillRecognitionMapper();

  AiRecognitionResult toRecognitionResult(Bill bill) {
    return AiRecognitionResult(
      type: _mapType(bill.type),
      amountCents: (bill.amount * 100).round(),
      categoryName: bill.category,
      description: bill.duplicateSuspected ? '疑似重复账单，请核对' : null,
      payer: bill.merchant.isEmpty ? null : bill.merchant,
      date: _parseDateTime(bill.date, bill.time),
      scene: _mapScene(bill.platform),
      sceneScore: bill.confidence / 100,
      tagNames: _buildTags(bill),
      confidence: bill.confidence / 100,
      rawText: bill.rawText,
      primaryCategory: bill.primaryCategory,
      secondaryCategory: bill.secondaryCategory,
      lowConfidence: bill.confidence < 70,
    );
  }

  TransactionType _mapType(BillType type) {
    return switch (type) {
      BillType.expense => TransactionType.expense,
      BillType.income => TransactionType.income,
      BillType.transfer => TransactionType.transfer,
    };
  }

  ReceiptScene _mapScene(BillPlatform? platform) {
    return switch (platform) {
      BillPlatform.wechat => ReceiptScene.wechatPayment,
      BillPlatform.alipay => ReceiptScene.alipayPayment,
      BillPlatform.bank => ReceiptScene.bankCardDetail,
      BillPlatform.receipt => ReceiptScene.paperReceipt,
      BillPlatform.invoice => ReceiptScene.paperReceipt,
      BillPlatform.unionpay => ReceiptScene.bankCardDetail,
      BillPlatform.unknown => ReceiptScene.unknown,
      null => ReceiptScene.unknown,
    };
  }

  DateTime? _parseDateTime(String date, String? time) {
    try {
      final parts = date.split('-');
      if (parts.length != 3) return null;
      var hour = 0;
      var minute = 0;
      if (time != null) {
        final tp = time.split(':');
        if (tp.isNotEmpty) hour = int.parse(tp[0]);
        if (tp.length > 1) minute = int.parse(tp[1]);
      }
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
        hour,
        minute,
      );
    } catch (_) {
      return null;
    }
  }

  List<String> _buildTags(Bill bill) {
    final tags = <String>[];
    if (bill.platform != null) tags.add(bill.platform!.label);
    tags.add(
      bill.type == BillType.income ? '收入' : '支出',
    );
    if (bill.primaryCategory != null &&
        bill.primaryCategory!.isNotEmpty &&
        !tags.contains(bill.primaryCategory)) {
      tags.add(bill.primaryCategory!);
    }
    return tags;
  }
}
