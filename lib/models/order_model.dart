class OrderItemModel {
  final String productId;
  final String name;
  final double price; // Price at purchase snapshot
  final String imageUrl;
  final String unit; // 'pcs', 'ml', 'L', 'g', 'kg', etc.
  final String? selectedColor;
  final String? selectedSize;
  final int quantity;

  const OrderItemModel({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.unit = 'pcs',
    this.selectedColor,
    this.selectedSize,
    required this.quantity,
  });

  // Backward compatibility getters
  String get productName => name;
  double get unitPrice => price;
  String get productImage => imageUrl;
  String get productBrand => '';

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'unit': unit,
        'selectedColor': selectedColor,
        'selectedSize': selectedSize,
        'quantity': quantity,
      };

  factory OrderItemModel.fromMap(Map<String, dynamic> map) => OrderItemModel(
        productId: map['productId'] as String? ?? '',
        name: map['name'] as String? ?? map['productName'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble() ??
            (map['unitPrice'] as num?)?.toDouble() ??
            0.0,
        imageUrl: map['imageUrl'] as String? ??
            map['productImage'] as String? ??
            '',
        unit: map['unit'] as String? ?? 'pcs',
        selectedColor: map['selectedColor'] as String?,
        selectedSize: map['selectedSize'] as String?,
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      );
}

enum OrderStatus { pending, processing, shipped, delivered, cancelled }

extension OrderStatusExt on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
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
      case OrderStatus.processing:
        return '⚙️';
      case OrderStatus.shipped:
        return '🚚';
      case OrderStatus.delivered:
        return '📦';
      case OrderStatus.cancelled:
        return '❌';
    }
  }

  /// Strict state machine transitions:
  /// Pending -> Processing, Cancelled
  /// Processing -> Shipped, Cancelled
  /// Shipped -> Delivered
  /// Delivered and Cancelled are final.
  List<OrderStatus> get allowedNextStatuses {
    switch (this) {
      case OrderStatus.pending:
        return [OrderStatus.processing, OrderStatus.cancelled];
      case OrderStatus.processing:
        return [OrderStatus.shipped, OrderStatus.cancelled];
      case OrderStatus.shipped:
        return [OrderStatus.delivered];
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return [];
    }
  }

  bool canTransitionTo(OrderStatus next) => allowedNextStatuses.contains(next);
}

class OrderModel {
  final String id;
  final String userId;
  final String customerName;
  final String customerPhone;
  final String shippingAddress;
  final String paymentMethod; // Always "Cash on Delivery"
  final List<OrderItemModel> items;
  final double subtotal;
  final double discount;
  final double deliveryCharge;
  final double tax;
  final double totalAmount;
  final String? promoCode;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const OrderModel({
    required this.id,
    required this.userId,
    this.customerName = '',
    this.customerPhone = '',
    required this.shippingAddress,
    this.paymentMethod = 'Cash on Delivery',
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.deliveryCharge,
    required this.tax,
    required this.totalAmount,
    this.promoCode,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  // Backward compatibility getters
  double get shipping => deliveryCharge;
  double get grandTotal => totalAmount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'shippingAddress': shippingAddress,
        'paymentMethod': 'Cash on Delivery',
        'items': items.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'deliveryCharge': deliveryCharge,
        'shipping': deliveryCharge,
        'tax': tax,
        'totalAmount': totalAmount,
        'grandTotal': totalAmount,
        'promoCode': promoCode,
        'status': status.label,
        'createdAt': createdAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  factory OrderModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final statusStr = (map['status'] as String? ?? '').toLowerCase();
    OrderStatus status = OrderStatus.pending;
    if (statusStr == 'processing') {
      status = OrderStatus.processing;
    } else if (statusStr == 'shipped') {
      status = OrderStatus.shipped;
    } else if (statusStr == 'delivered') {
      status = OrderStatus.delivered;
    } else if (statusStr == 'cancelled') {
      status = OrderStatus.cancelled;
    } else {
      status = OrderStatus.pending;
    }

    final delivery = (map['deliveryCharge'] as num?)?.toDouble() ??
        (map['shipping'] as num?)?.toDouble() ??
        60.0;
    final total = (map['totalAmount'] as num?)?.toDouble() ??
        (map['grandTotal'] as num?)?.toDouble() ??
        0.0;

    return OrderModel(
      id: docId ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      shippingAddress: map['shippingAddress'] as String? ?? '',
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash on Delivery',
      items: (map['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: delivery,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      totalAmount: total,
      promoCode: map['promoCode'] as String?,
      status: status,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String)
          : null,
    );
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? customerName,
    String? customerPhone,
    String? shippingAddress,
    String? paymentMethod,
    List<OrderItemModel>? items,
    double? subtotal,
    double? discount,
    double? deliveryCharge,
    double? tax,
    double? totalAmount,
    String? promoCode,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      tax: tax ?? this.tax,
      totalAmount: totalAmount ?? this.totalAmount,
      promoCode: promoCode ?? this.promoCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
