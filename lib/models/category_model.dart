class CategoryModel {
  final String id;
  final String name;
  final String? parentId;
  final String? parentName;
  final List<String> subcategories;
  final String? icon;
  final String? imageUrl;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    this.parentName,
    this.subcategories = const [],
    this.icon,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'parentId': parentId,
        'parentName': parentName,
        'subcategories': subcategories,
        'icon': icon,
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map, [String? docId]) => CategoryModel(
        id: docId ?? map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        parentId: map['parentId'] as String?,
        parentName: map['parentName'] as String?,
        subcategories: (map['subcategories'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        icon: map['icon'] as String?,
        imageUrl: map['imageUrl'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  CategoryModel copyWith({
    String? id,
    String? name,
    String? parentId,
    String? parentName,
    List<String>? subcategories,
    String? icon,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      subcategories: subcategories ?? this.subcategories,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

