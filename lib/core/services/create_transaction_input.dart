import 'package:ezbookkeeping_desktop/core/models/enums.dart';

class CreateTransactionInput {
  const CreateTransactionInput({
    required this.bookId,
    required this.type,
    required this.amountInCents,
    required this.categoryId,
    this.fromAccountId,
    this.toAccountId,
    required this.date,
    this.timezoneUtcOffset,
    this.comment,
    this.payer,
    this.description,
    this.tagIds = const [],
    this.images = const [],
    this.isReimbursable = false,
    this.isScheduled = false,
    this.scheduledTransactionId,
  });

  final int bookId;
  final TransactionType type;
  final int amountInCents;
  final int categoryId;
  final int? fromAccountId;
  final int? toAccountId;
  final DateTime date;
  final int? timezoneUtcOffset;
  final String? comment;
  final String? payer;
  final String? description;
  final List<int> tagIds;
  final List<String> images;
  final bool isReimbursable;
  final bool isScheduled;
  final int? scheduledTransactionId;
}

class UpdateTransactionInput {
  const UpdateTransactionInput({
    required this.transactionId,
    required this.type,
    required this.amountInCents,
    required this.categoryId,
    this.fromAccountId,
    this.toAccountId,
    required this.date,
    this.timezoneUtcOffset,
    this.comment,
    this.payer,
    this.description,
    this.tagIds = const [],
    this.isReimbursable,
  });

  final int transactionId;
  final TransactionType type;
  final int amountInCents;
  final int categoryId;
  final int? fromAccountId;
  final int? toAccountId;
  final DateTime date;
  final int? timezoneUtcOffset;
  final String? comment;
  final String? payer;
  final String? description;
  final List<int> tagIds;
  final bool? isReimbursable;
}
