import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';

class TransactionImportAmountResolver {
  TransactionImportAmountResolver._();

  static ({TransactionType type, int amountCents})? resolve({
    required TransactionType type,
    required String? amountText,
    String? refundText,
  }) {
    var amountCents = _parseAmountCentsOrZero(amountText);

    if (refundText != null &&
        refundText.isNotEmpty &&
        type == TransactionType.expense) {
      amountCents -= _parseAmountCentsOrZero(refundText).abs();
    }

    if (amountCents < 0) {
      if (type == TransactionType.expense) {
        type = TransactionType.income;
      }
      amountCents = amountCents.abs();
    }

    if (amountCents < 0) return null;
    return (type: type, amountCents: amountCents);
  }

  static int _parseAmountCentsOrZero(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return 0;
    return MoneyUtils.parseToCents(text);
  }
}
