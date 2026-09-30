class BrandModel {
  final String id;
  final String name;
  final String? logoUrl;
  final DateTime createdAt;

  const BrandModel({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'logoUrl': logoUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BrandModel.fromMap(Map<String, dynamic> map, [String? docId]) => BrandModel(
        id: docId ?? map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        logoUrl: map['logoUrl'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
