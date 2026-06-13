import 'package:ezbookkeeping_desktop/core/models/enums.dart';

class Budget {
  const Budget({
    this.id,
    required this.uuid,
    required this.bookId,
    this.categoryId,
    required this.amount,
    required this.periodType,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final int? id;
  final String uuid;
  final int bookId;
  final int? categoryId;
  final int amount;
  final BudgetPeriodType periodType;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Budget copyWith({
    int? id,
    String? uuid,
    int? bookId,
    int? categoryId,
    int? amount,
    BudgetPeriodType? periodType,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool clearCategoryId = false,
  }) {
    return Budget(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      bookId: bookId ?? this.bookId,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      amount: amount ?? this.amount,
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'uuid': uuid,
        'book_id': bookId,
        'category_id': categoryId,
        'amount': amount,
        'period_type': periodType.value,
        'start_date': startDate?.millisecondsSinceEpoch,
        'end_date': endDate?.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        id: map['id'] as int?,
        uuid: map['uuid'] as String,
        bookId: map['book_id'] as int,
        categoryId: map['category_id'] as int?,
        amount: map['amount'] as int,
        periodType: BudgetPeriodType.fromValue(map['period_type'] as int),
        startDate: map['start_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int)
            : null,
        endDate: map['end_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int)
            : null,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        deletedAt: map['deleted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
            : null,
      );
}
