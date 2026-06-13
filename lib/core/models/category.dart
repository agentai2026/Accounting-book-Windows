import 'package:ezbookkeeping_desktop/core/models/enums.dart';

class Category {
  const Category({
    this.id,
    required this.uuid,
    this.parentId,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final int? id;
  final String uuid;
  final int? parentId;
  final String name;
  final CategoryType type;
  final String? icon;
  final String? color;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Category copyWith({
    int? id,
    String? uuid,
    int? parentId,
    String? name,
    CategoryType? type,
    String? icon,
    String? color,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool clearParentId = false,
  }) {
    return Category(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'uuid': uuid,
        'parent_id': parentId,
        'name': name,
        'type': type.value,
        'icon': icon,
        'color': color,
        'sort_order': sortOrder,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as int?,
        uuid: map['uuid'] as String,
        parentId: map['parent_id'] as int?,
        name: map['name'] as String,
        type: CategoryType.fromValue(map['type'] as int),
        icon: map['icon'] as String?,
        color: map['color'] as String?,
        sortOrder: map['sort_order'] as int? ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        deletedAt: map['deleted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
            : null,
      );
}
