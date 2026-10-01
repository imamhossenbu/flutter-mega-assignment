class PromoCodeModel {
  final String id;
  final String code;
  final double discountPercent; // e.g. 20 for 20% or 0.20
  final bool isActive;
  final DateTime? expiresAt;
  final String description;
  final double? minOrderAmount;

  const PromoCodeModel({
    this.id = '',
    required this.code,
    required this.discountPercent,
    required this.isActive,
    this.expiresAt,
    this.description = '',
    this.minOrderAmount,
  });

  DateTime? get expiryDate => expiresAt;

  // Normalized discount fraction between 0.0 and 1.0 (e.g. 20 -> 0.20, 0.20 -> 0.20)
  double get discountFraction {
    if (discountPercent > 1.0) {
      return discountPercent / 100.0;
    }
    return discountPercent;
  }

  bool get isValid {
    if (!isActive) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  bool isValidForAmount(double amount) {
    if (!isValid) return false;
    if (minOrderAmount != null && amount < minOrderAmount!) return false;
    return true;
  }

  Map<String, dynamic> toMap() => {
        'id': id.isNotEmpty ? id : code.toUpperCase(),
        'code': code.toUpperCase(),
        'discountPercent': discountPercent,
        'isActive': isActive,
        'expiresAt': expiresAt?.toIso8601String(),
        'description': description,
        if (minOrderAmount != null) 'minOrderAmount': minOrderAmount,
      };

  factory PromoCodeModel.fromMap(Map<String, dynamic> map, [String? docId]) =>
      PromoCodeModel(
        id: docId ?? map['id'] as String? ?? (map['code'] as String? ?? ''),
        code: (map['code'] as String? ?? docId ?? '').toUpperCase(),
        discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0.0,
        isActive: map['isActive'] as bool? ?? false,
        expiresAt: map['expiresAt'] != null
            ? DateTime.tryParse(map['expiresAt'] as String)
            : (map['expiryDate'] != null
                ? DateTime.tryParse(map['expiryDate'] as String)
                : null),
        description: map['description'] as String? ?? '',
        minOrderAmount: (map['minOrderAmount'] as num?)?.toDouble(),
      );

  PromoCodeModel copyWith({
    String? id,
    String? code,
    double? discountPercent,
    bool? isActive,
    DateTime? expiresAt,
    String? description,
    double? minOrderAmount,
  }) {
    return PromoCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      discountPercent: discountPercent ?? this.discountPercent,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      description: description ?? this.description,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
    );
  }
}
