import 'package:ezbookkeeping_desktop/core/models/enums.dart';

class ScheduledTransaction {
  const ScheduledTransaction({
    this.id,
    required this.uuid,
    required this.bookId,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.fromAccountId,
    this.toAccountId,
    this.description,
    this.comment,
    this.location,
    this.isReimbursable = false,
    required this.frequency,
    this.intervalCount = 1,
    this.dayOfMonth,
    this.weekday,
    required this.startDate,
    this.endDate,
    required this.nextRunAt,
    this.lastRunAt,
    this.isPaused = false,
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
  final String? description;
  final String? comment;
  final String? location;
  final bool isReimbursable;
  final ScheduledFrequency frequency;
  final int intervalCount;
  final int? dayOfMonth;
  final int? weekday;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextRunAt;
  final DateTime? lastRunAt;
  final bool isPaused;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  ScheduledTransaction copyWith({
    int? id,
    String? uuid,
    int? bookId,
    TransactionType? type,
    int? amount,
    int? categoryId,
    int? fromAccountId,
    int? toAccountId,
    String? description,
    String? comment,
    String? location,
    bool? isReimbursable,
    ScheduledFrequency? frequency,
    int? intervalCount,
    int? dayOfMonth,
    int? weekday,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextRunAt,
    DateTime? lastRunAt,
    bool? isPaused,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearEndDate = false,
    bool clearLastRunAt = false,
    bool clearDeletedAt = false,
    bool clearFromAccount = false,
    bool clearToAccount = false,
  }) {
    return ScheduledTransaction(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      bookId: bookId ?? this.bookId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      fromAccountId:
          clearFromAccount ? null : (fromAccountId ?? this.fromAccountId),
      toAccountId: clearToAccount ? null : (toAccountId ?? this.toAccountId),
      description: description ?? this.description,
      comment: comment ?? this.comment,
      location: location ?? this.location,
      isReimbursable: isReimbursable ?? this.isReimbursable,
      frequency: frequency ?? this.frequency,
      intervalCount: intervalCount ?? this.intervalCount,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      weekday: weekday ?? this.weekday,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      nextRunAt: nextRunAt ?? this.nextRunAt,
      lastRunAt: clearLastRunAt ? null : (lastRunAt ?? this.lastRunAt),
      isPaused: isPaused ?? this.isPaused,
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
        'description': description,
        'comment': comment,
        'location': location,
        'is_reimbursable': isReimbursable ? 1 : 0,
        'frequency': frequency.value,
        'interval_count': intervalCount,
        'day_of_month': dayOfMonth,
        'weekday': weekday,
        'start_date': startDate.millisecondsSinceEpoch,
        'end_date': endDate?.millisecondsSinceEpoch,
        'next_run_at': nextRunAt.millisecondsSinceEpoch,
        'last_run_at': lastRunAt?.millisecondsSinceEpoch,
        'is_paused': isPaused ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory ScheduledTransaction.fromMap(Map<String, dynamic> map) =>
      ScheduledTransaction(
        id: map['id'] as int?,
        uuid: map['uuid'] as String,
        bookId: map['book_id'] as int,
        type: TransactionType.fromValue(map['type'] as int),
        amount: map['amount'] as int,
        categoryId: map['category_id'] as int,
        fromAccountId: map['from_account_id'] as int?,
        toAccountId: map['to_account_id'] as int?,
        description: map['description'] as String?,
        comment: map['comment'] as String?,
        location: map['location'] as String?,
        isReimbursable: (map['is_reimbursable'] as int? ?? 0) == 1,
        frequency: ScheduledFrequency.fromValue(map['frequency'] as int),
        intervalCount: map['interval_count'] as int? ?? 1,
        dayOfMonth: map['day_of_month'] as int?,
        weekday: map['weekday'] as int?,
        startDate:
            DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
        endDate: map['end_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int)
            : null,
        nextRunAt:
            DateTime.fromMillisecondsSinceEpoch(map['next_run_at'] as int),
        lastRunAt: map['last_run_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['last_run_at'] as int)
            : null,
        isPaused: (map['is_paused'] as int? ?? 0) == 1,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        deletedAt: map['deleted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
            : null,
      );
}
