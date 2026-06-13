import 'dart:convert';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';

class Transaction {
  const Transaction({
    this.id,
    required this.uuid,
    required this.bookId,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.fromAccountId,
    this.toAccountId,
    required this.date,
    this.timezoneUtcOffset,
    this.comment,
    this.payer,
    this.description,
    this.images,
    this.location,
    this.isReimbursable = false,
    this.isScheduled = false,
    this.scheduledTransactionId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final int? id;
  final String uuid;
  final int bookId;
  final TransactionType type;
  final int amount;
  final int categoryId;
  final int? fromAccountId;
  final int? toAccountId;
  final DateTime date;
  final int? timezoneUtcOffset;
  final String? comment;
  final String? payer;
  final String? description;
  final List<String>? images;
  final String? location;
  final bool isReimbursable;
  final bool isScheduled;
  final int? scheduledTransactionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Transaction copyWith({
    int? id,
    String? uuid,
    int? bookId,
    TransactionType? type,
    int? amount,
    int? categoryId,
    int? fromAccountId,
    int? toAccountId,
    DateTime? date,
    int? timezoneUtcOffset,
    String? comment,
    String? payer,
    String? description,
    List<String>? images,
    String? location,
    bool? isReimbursable,
    bool? isScheduled,
    int? scheduledTransactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Transaction(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      bookId: bookId ?? this.bookId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      date: date ?? this.date,
      timezoneUtcOffset: timezoneUtcOffset ?? this.timezoneUtcOffset,
      comment: comment ?? this.comment,
      payer: payer ?? this.payer,
      description: description ?? this.description,
      images: images ?? this.images,
      location: location ?? this.location,
      isReimbursable: isReimbursable ?? this.isReimbursable,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledTransactionId:
          scheduledTransactionId ?? this.scheduledTransactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'uuid': uuid,
        'book_id': bookId,
        'type': type.value,
        'amount': amount,
        'category_id': categoryId,
        'from_account_id': fromAccountId,
        'to_account_id': toAccountId,
        'date': date.millisecondsSinceEpoch,
        'timezone_utc_offset': timezoneUtcOffset,
        'comment': comment,
        'payer': payer,
        'description': description,
        'images': images != null ? jsonEncode(images) : null,
        'location': location,
        'is_reimbursable': isReimbursable ? 1 : 0,
        'is_scheduled': isScheduled ? 1 : 0,
        'scheduled_transaction_id': scheduledTransactionId,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) {
    List<String>? images;
    final imagesRaw = map['images'] as String?;
    if (imagesRaw != null && imagesRaw.isNotEmpty) {
      images = List<String>.from(jsonDecode(imagesRaw) as List);
    }

    return Transaction(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      bookId: map['book_id'] as int,
      type: TransactionType.fromValue(map['type'] as int),
      amount: map['amount'] as int,
      categoryId: map['category_id'] as int,
      fromAccountId: map['from_account_id'] as int?,
      toAccountId: map['to_account_id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      timezoneUtcOffset: map['timezone_utc_offset'] as int?,
      comment: map['comment'] as String?,
      payer: map['payer'] as String?,
      description: map['description'] as String?,
      images: images,
      location: map['location'] as String?,
      isReimbursable: (map['is_reimbursable'] as int? ?? 0) == 1,
      isScheduled: (map['is_scheduled'] as int? ?? 0) == 1,
      scheduledTransactionId: map['scheduled_transaction_id'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      deletedAt: map['deleted_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
          : null,
    );
  }
}
