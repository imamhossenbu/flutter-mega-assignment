class OrderItemModel {
  final String productId;
  final String productName;
  final String productImage;
  final String productBrand;
  final double unitPrice;
  final int quantity;
  final String? selectedColor;
  final String? selectedSize;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productBrand,
    required this.unitPrice,
    required this.quantity,
    this.selectedColor,
    this.selectedSize,
  });

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'productImage': productImage,
        'productBrand': productBrand,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'selectedColor': selectedColor,
        'selectedSize': selectedSize,
      };

  factory OrderItemModel.fromMap(Map<String, dynamic> map) => OrderItemModel(
        productId: map['productId'] as String? ?? '',
        productName: map['productName'] as String? ?? '',
        productImage: map['productImage'] as String? ?? '',
        productBrand: map['productBrand'] as String? ?? '',
        unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        selectedColor: map['selectedColor'] as String?,
        selectedSize: map['selectedSize'] as String?,
      );
}

enum OrderStatus { pending, confirmed, shipped, delivered, cancelled }

extension OrderStatusExt on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get emoji {
    switch (this) {
      case OrderStatus.pending:
        return '⏳';
      case OrderStatus.confirmed:
        return '✅';
      case OrderStatus.shipped:
        return '🚚';
      case OrderStatus.delivered:
        return '📦';
      case OrderStatus.cancelled:
        return '❌';
    }
  }
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItemModel> items;
  final double subtotal;
  final double discount;
  final double shipping;
  final double tax;
  final double grandTotal;
  final String? promoCode;
  final String shippingAddress;
  final OrderStatus status;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.tax,
    required this.grandTotal,
    this.promoCode,
    required this.shippingAddress,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'items': items.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'shipping': shipping,
        'tax': tax,
        'grandTotal': grandTotal,
        'promoCode': promoCode,
        'shippingAddress': shippingAddress,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory OrderModel.fromMap(Map<String, dynamic> map, [String? docId]) => OrderModel(
        id: docId ?? map['id'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        items: (map['items'] as List<dynamic>?)
                ?.map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
        discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
        shipping: (map['shipping'] as num?)?.toDouble() ?? 0.0,
        tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
        grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
        promoCode: map['promoCode'] as String?,
        shippingAddress: map['shippingAddress'] as String? ?? '',
        status: OrderStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => OrderStatus.pending,
        ),
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
