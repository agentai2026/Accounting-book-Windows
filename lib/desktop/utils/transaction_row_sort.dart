import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';

List<TransactionRowData> sortTransactionRows(
  List<TransactionRowData> rows, {
  required bool timeDescending,
}) {
  final sorted = List<TransactionRowData>.from(rows);
  sorted.sort((a, b) {
    final cmp = a.transaction.date.compareTo(b.transaction.date);
    return timeDescending ? -cmp : cmp;
  });
  return sorted;
}
