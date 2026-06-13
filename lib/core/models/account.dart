import 'package:ezbookkeeping_desktop/core/models/enums.dart';

class Account {
  const Account({
    this.id,
    required this.uuid,
    required this.bookId,
    required this.name,
    required this.type,
    this.balance = 0,
    this.currency = 'CNY',
    this.icon,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final int? id;
  final String uuid;
  final int bookId;
  final String name;
  final AccountType type;
  final int balance;
  final String currency;
  final String? icon;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Account copyWith({
    int? id,
    String? uuid,
    int? bookId,
    String? name,
    AccountType? type,
    int? balance,
    String? currency,
    String? icon,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Account(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      bookId: bookId ?? this.bookId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'uuid': uuid,
        'book_id': bookId,
        'name': name,
        'type': type.value,
        'balance': balance,
        'currency': currency,
        'icon': icon,
        'sort_order': sortOrder,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory Account.fromMap(Map<String, dynamic> map) => Account(
        id: map['id'] as int?,
        uuid: map['uuid'] as String,
        bookId: map['book_id'] as int,
        name: map['name'] as String,
        type: AccountType.fromValue(map['type'] as int),
        balance: map['balance'] as int? ?? 0,
        currency: map['currency'] as String? ?? 'CNY',
        icon: map['icon'] as String?,
        sortOrder: map['sort_order'] as int? ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        deletedAt: map['deleted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
            : null,
      );
}
