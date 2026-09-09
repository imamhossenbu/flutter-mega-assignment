class ProductModel {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final double originalPrice;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String description;
  final List<String> colors;
  final List<String> sizes;
  final bool isFeatured;
  final bool inStock;
  final int stockCount;

  const ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.description,
    this.colors = const [],
    this.sizes = const [],
    this.isFeatured = false,
    this.inStock = true,
    this.stockCount = 10,
  });

  double get discountPercent {
    if (originalPrice <= price || originalPrice == 0) return 0;
    return (((originalPrice - price) / originalPrice) * 100).roundToDouble();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'price': price,
      'originalPrice': originalPrice,
      'rating': rating,
      'reviewCount': reviewCount,
      'imageUrl': imageUrl,
      'description': description,
      'colors': colors,
      'sizes': sizes,
      'isFeatured': isFeatured,
      'inStock': inStock,
      'stockCount': stockCount,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ProductModel(
      id: docId ?? (map['id'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] as String? ?? '',
      description: map['description'] as String? ?? '',
      colors: (map['colors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      sizes: (map['sizes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isFeatured: map['isFeatured'] as bool? ?? false,
      inStock: map['inStock'] as bool? ?? true,
      stockCount: (map['stockCount'] as num?)?.toInt() ?? 10,
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
    double? price,
    double? originalPrice,
    double? rating,
    int? reviewCount,
    String? imageUrl,
    String? description,
    List<String>? colors,
    List<String>? sizes,
    bool? isFeatured,
    bool? inStock,
    int? stockCount,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      isFeatured: isFeatured ?? this.isFeatured,
      inStock: inStock ?? this.inStock,
      stockCount: stockCount ?? this.stockCount,
    );
  }
}
