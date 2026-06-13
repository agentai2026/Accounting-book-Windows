import 'package:flutter_test/flutter_test.dart';
import 'package:ezbookkeeping_desktop/core/models/ai_recognition_result.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/receipt_scene.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction_form_draft.dart';
import 'package:ezbookkeeping_desktop/core/services/recognition_draft_formatter.dart';

void main() {
  const formatter = RecognitionDraftFormatter();

  test('银行转账备注自动排版', () {
    final recognition = AiRecognitionResult(
      type: TransactionType.income,
      amountCents: 541700,
      description: '转账',
      payer: '宋宁',
      date: DateTime(2025, 11, 3, 17, 25),
      accountName: '借记卡6579',
      balanceCents: 541701,
      categoryName: '其他收入',
      scene: ReceiptScene.bankMonthlyBill,
      sceneScore: 0.9,
      tagNames: ['银行月账单', '转账', '银行'],
    );

    final draft = formatter.formatDraft(
      draft: const TransactionFormDraft(
        type: TransactionType.income,
        amountText: '5417.00',
        payer: '宋宁',
        description: '转账',
      ),
      recognition: recognition,
    );

    expect(draft.payer, '宋宁');
    expect(draft.date, DateTime(2025, 11, 3, 17, 25));
    expect(draft.description, contains('转账'));
    expect(draft.description, contains('—— 识图 ——'));
    expect(draft.description, contains('时间：2025/11/03 17:25'));
    expect(draft.description, contains('收款人：宋宁'));
    expect(draft.description, contains('账户：借记卡6579'));
    expect(draft.description, contains('余额：¥5417.01'));
  });

  test('微信支付清洗付款人并排版备注', () {
    final recognition = AiRecognitionResult(
      type: TransactionType.expense,
      amountCents: 3500,
      description: '午餐套餐',
      payer: ' 美团外卖 ',
      date: DateTime(2026, 1, 15, 12, 30, 45),
      accountName: '零钱',
      categoryName: '食品',
      scene: ReceiptScene.wechatPayment,
      sceneScore: 0.8,
      tagNames: ['微信支付', '外卖'],
    );

    final draft = formatter.formatDraft(
      draft: const TransactionFormDraft(
        type: TransactionType.expense,
        amountText: '35.00',
      ),
      recognition: recognition,
    );

    expect(draft.payer, '美团外卖');
    expect(draft.description, contains('午餐套餐'));
    expect(draft.description, contains('付款人：美团外卖'));
    expect(draft.description, contains('时间：2026/01/15 12:30'));
  });

  test('无备注时自动生成付款人加支付账户', () {
    final recognition = AiRecognitionResult(
      type: TransactionType.income,
      amountCents: 541700,
      payer: '宋宁',
      accountName: '借记卡6579',
      date: DateTime(2025, 11, 3, 17, 25),
      scene: ReceiptScene.bankMonthlyBill,
    );

    final draft = formatter.formatDraft(
      draft: const TransactionFormDraft(
        type: TransactionType.income,
        amountText: '5417.00',
      ),
      recognition: recognition,
    );

    expect(draft.description, contains('宋宁 借记卡6579'));
    expect(draft.description, isNot(contains('收款人：宋宁')));
  });

  test('无备注时微信零钱显示为微信', () {
    final recognition = AiRecognitionResult(
      type: TransactionType.expense,
      amountCents: 3500,
      payer: '美团外卖',
      accountName: '零钱',
      scene: ReceiptScene.wechatPayment,
    );

    final remarks = formatter.buildFormattedRemarks(
      recognition: recognition,
      rawNote: null,
      payer: '美团外卖',
      date: null,
    );

    expect(remarks, contains('美团外卖 微信'));
    expect(remarks, isNot(contains('付款人：')));
  });

  test('有备注时保留原备注不生成 fallback', () {
    final recognition = AiRecognitionResult(
      type: TransactionType.income,
      amountCents: 541700,
      description: '转账',
      payer: '宋宁',
      accountName: '借记卡6579',
      scene: ReceiptScene.bankMonthlyBill,
    );

    final remarks = formatter.buildFormattedRemarks(
      recognition: recognition,
      rawNote: '转账',
      payer: '宋宁',
      date: null,
    );

    expect(remarks, contains('转账'));
    expect(remarks, isNot(contains('宋宁 借记卡6579')));
  });

  test('仅有日期无时分时备注只显示日期', () {
    final recognition = AiRecognitionResult(
      type: TransactionType.income,
      amountCents: 541700,
      payer: '宋宁',
      date: DateTime(2025, 11, 3),
      scene: ReceiptScene.bankMonthlyBill,
    );

    final remarks = formatter.buildFormattedRemarks(
      recognition: recognition,
      rawNote: null,
      payer: '宋宁',
      date: DateTime(2025, 11, 3),
    );

    expect(remarks, contains('时间：2025/11/03'));
    expect(remarks, isNot(contains('00:00')));
  });
}
