import 'product_model.dart';

class CartItemModel {
  final String id;
  final ProductModel product;
  final int quantity;
  final String? selectedColor;
  final String? selectedSize;
  final DateTime addedAt;

  const CartItemModel({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.selectedColor,
    this.selectedSize,
    required this.addedAt,
  });

  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': product.id,
      'product': product.toMap(),
      'quantity': quantity,
      'selectedColor': selectedColor,
      'selectedSize': selectedSize,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final productData = map['product'] as Map<String, dynamic>?;
    final product = productData != null
        ? ProductModel.fromMap(productData, map['productId'] as String?)
        : ProductModel(
            id: map['productId'] as String? ?? '',
            name: 'Unknown Item',
            brand: '',
            category: '',
            price: 0.0,
            originalPrice: 0.0,
            rating: 0.0,
            reviewCount: 0,
            imageUrl: '',
            description: '',
          );

    return CartItemModel(
      id: docId ?? map['id'] as String? ?? '',
      product: product,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      selectedColor: map['selectedColor'] as String?,
      selectedSize: map['selectedSize'] as String?,
      addedAt: map['addedAt'] != null
          ? DateTime.tryParse(map['addedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  CartItemModel copyWith({
    String? id,
    ProductModel? product,
    int? quantity,
    String? selectedColor,
    String? selectedSize,
    DateTime? addedAt,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
