import 'package:ezbookkeeping_desktop/core/models/enums.dart';

class Loan {
  const Loan({
    this.id,
    required this.uuid,
    required this.type,
    required this.person,
    required this.amount,
    required this.date,
    this.dueDate,
    this.isRepaid = false,
    this.description,
    this.bookId,
    this.accountId,
    this.excludeFromIo = true,
    this.excludeFromBudget = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final int? id;
  final String uuid;
  final LoanType type;
  final String person;
  final int amount;
  final DateTime date;
  final DateTime? dueDate;
  final bool isRepaid;
  final String? description;
  final int? bookId;
  final int? accountId;
  final bool excludeFromIo;
  final bool excludeFromBudget;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Loan copyWith({
    int? id,
    String? uuid,
    LoanType? type,
    String? person,
    int? amount,
    DateTime? date,
    DateTime? dueDate,
    bool? isRepaid,
    String? description,
    int? bookId,
    int? accountId,
    bool? excludeFromIo,
    bool? excludeFromBudget,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool clearBookId = false,
    bool clearAccountId = false,
    bool clearDueDate = false,
  }) {
    return Loan(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      type: type ?? this.type,
      person: person ?? this.person,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isRepaid: isRepaid ?? this.isRepaid,
      description: description ?? this.description,
      bookId: clearBookId ? null : (bookId ?? this.bookId),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      excludeFromIo: excludeFromIo ?? this.excludeFromIo,
      excludeFromBudget: excludeFromBudget ?? this.excludeFromBudget,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'uuid': uuid,
        'type': type.value,
        'person': person,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'due_date': dueDate?.millisecondsSinceEpoch,
        'is_repaid': isRepaid ? 1 : 0,
        'description': description,
        'book_id': bookId,
        'account_id': accountId,
        'exclude_from_io': excludeFromIo ? 1 : 0,
        'exclude_from_budget': excludeFromBudget ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory Loan.fromMap(Map<String, dynamic> map) => Loan(
        id: map['id'] as int?,
        uuid: map['uuid'] as String,
        type: LoanType.fromValue(map['type'] as int),
        person: map['person'] as String,
        amount: map['amount'] as int,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        dueDate: map['due_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int)
            : null,
        isRepaid: (map['is_repaid'] as int? ?? 0) == 1,
        description: map['description'] as String?,
        bookId: map['book_id'] as int?,
        accountId: map['account_id'] as int?,
        excludeFromIo: (map['exclude_from_io'] as int? ?? 1) == 1,
        excludeFromBudget: (map['exclude_from_budget'] as int? ?? 1) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        deletedAt: map['deleted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
            : null,
      );
}
