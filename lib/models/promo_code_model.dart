class PromoCodeModel {
  final String code;
  final double discountPercent;
  final bool isActive;
  final DateTime? expiresAt;
  final String description;

  const PromoCodeModel({
    required this.code,
    required this.discountPercent,
    required this.isActive,
    this.expiresAt,
    required this.description,
  });

  bool get isValid {
    if (!isActive) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'discountPercent': discountPercent,
        'isActive': isActive,
        'expiresAt': expiresAt?.toIso8601String(),
        'description': description,
      };

  factory PromoCodeModel.fromMap(Map<String, dynamic> map, [String? docId]) => PromoCodeModel(
        code: docId ?? map['code'] as String? ?? '',
        discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0.0,
        isActive: map['isActive'] as bool? ?? false,
        expiresAt: map['expiresAt'] != null
            ? DateTime.tryParse(map['expiresAt'] as String)
            : null,
        description: map['description'] as String? ?? '',
      );

  PromoCodeModel copyWith({
    String? code,
    double? discountPercent,
    bool? isActive,
    DateTime? expiresAt,
    String? description,
  }) {
    return PromoCodeModel(
      code: code ?? this.code,
      discountPercent: discountPercent ?? this.discountPercent,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      description: description ?? this.description,
    );
  }
}
