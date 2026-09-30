class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String? imageUrl;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map, [String? docId]) => CategoryModel(
        id: docId ?? map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        icon: map['icon'] as String?,
        imageUrl: map['imageUrl'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
