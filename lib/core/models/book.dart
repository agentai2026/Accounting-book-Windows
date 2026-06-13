class Book {
  const Book({
    this.id,
    required this.uuid,
    required this.name,
    this.color = '#2196F3',
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final int? id;
  final String uuid;
  final String name;
  final String color;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Book copyWith({
    int? id,
    String? uuid,
    String? name,
    String? color,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Book(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'name': name,
        'color': color,
        'sort_order': sortOrder,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as int?,
        uuid: json['uuid'] as String,
        name: json['name'] as String,
        color: json['color'] as String? ?? '#2196F3',
        sortOrder: json['sort_order'] as int? ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
        deletedAt: json['deleted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['deleted_at'] as int)
            : null,
      );

  factory Book.fromMap(Map<String, dynamic> map) => Book(
        id: map['id'] as int?,
        uuid: map['uuid'] as String,
        name: map['name'] as String,
        color: map['color'] as String? ?? '#2196F3',
        sortOrder: map['sort_order'] as int? ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        deletedAt: map['deleted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
            : null,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'uuid': uuid,
        'name': name,
        'color': color,
        'sort_order': sortOrder,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };
}
