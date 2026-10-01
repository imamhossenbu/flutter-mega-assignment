import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mega_assignment/core/constants/app_constants.dart';
import 'package:flutter_mega_assignment/models/order_model.dart';
import 'package:flutter_mega_assignment/models/product_model.dart';
import 'package:flutter_mega_assignment/models/promo_code_model.dart';
import 'package:flutter_mega_assignment/repositories/order_repository.dart';

class SimulatedOrderRepository implements OrderRepository {
  final Map<String, ProductModel> catalog = {};
  final Map<String, PromoCodeModel> promoCodes = {};
  final Map<String, OrderModel> orders = {};

  @override
  Stream<List<OrderModel>> streamUserOrders(String userId, {int limit = 20}) =>
      Stream.value(orders.values.where((o) => o.userId == userId).toList());

  @override
  Stream<List<OrderModel>> streamAllOrders({int limit = 20, OrderStatus? status}) =>
      Stream.value(orders.values.toList());

  @override
  Future<List<OrderModel>> getUserOrders(String userId, {int limit = 20, DocumentSnapshot? startAfter}) async =>
      orders.values.where((o) => o.userId == userId).toList();

  @override
  Future<List<OrderModel>> getAllOrders({int limit = 20, DocumentSnapshot? startAfter, OrderStatus? status}) async =>
      orders.values.toList();

  @override
  Future<OrderModel?> getOrderById(String orderId) async => orders[orderId];

  @override
  Future<String> placeOrderInTransaction({
    required String userId,
    required String customerName,
    required String customerPhone,
    required String shippingAddress,
    required List<OrderItemModel> items,
    String? promoCode,
    required double deliveryCharge,
  }) async {
    if (items.isEmpty) {
      throw Exception('Cannot place an order with an empty cart.');
    }

    // 1. Verify products exist, are not deleted, stock >= qty, price equals current price
    double subtotal = 0.0;
    for (final item in items) {
      final product = catalog[item.productId];
      if (product == null) {
        throw Exception('Product "${item.name}" was not found in catalog.');
      }
      if (product.isDeleted) {
        throw Exception('Product "${product.name}" is no longer available.');
      }
      if (product.stockCount < item.quantity) {
        throw Exception(
          'Insufficient stock for "${product.name}". Available: ${product.stockCount}, Requested: ${item.quantity}.',
        );
      }
      if ((product.price - item.price).abs() > 0.01) {
        throw Exception(
          'The price for "${product.name}" has changed from ৳${item.price.toInt()} to ৳${product.price.toInt()}. Please update your cart.',
        );
      }
      subtotal += product.price * item.quantity;
    }

    // 2. Validate promo code
    double discount = 0.0;
    if (promoCode != null && promoCode.trim().isNotEmpty) {
      final code = promoCode.trim().toUpperCase();
      final promo = promoCodes[code];
      if (promo == null || !promo.isValid) {
        throw Exception('Promo voucher "$code" is expired or inactive.');
      }
      if (promo.minOrderAmount != null && subtotal < promo.minOrderAmount!) {
        throw Exception(
          'Order subtotal must be at least ৳${promo.minOrderAmount!.toInt()} to use voucher "$code".',
        );
      }
      discount = subtotal * promo.discountFraction;
    }

    final discountedSubtotal = (subtotal - discount).clamp(0.0, double.infinity);
    final tax = discountedSubtotal * AppConstants.taxRate;
    final total = discountedSubtotal + tax + deliveryCharge;

    // 3. Decrement stock
    for (final item in items) {
      final product = catalog[item.productId]!;
      catalog[item.productId] = product.copyWith(
        stockCount: product.stockCount - item.quantity,
        inStock: (product.stockCount - item.quantity) > 0,
      );
    }

    // 4. Save order
    final orderId = 'ord_${DateTime.now().millisecondsSinceEpoch}';
    final order = OrderModel(
      id: orderId,
      userId: userId,
      customerName: customerName,
      customerPhone: customerPhone,
      shippingAddress: shippingAddress,
      paymentMethod: 'Cash on Delivery',
      items: items,
      subtotal: subtotal,
      discount: discount,
      deliveryCharge: deliveryCharge,
      tax: tax,
      totalAmount: total,
      promoCode: promoCode,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
    );
    orders[orderId] = order;
    return orderId;
  }

  @override
  Future<void> cancelOrderCustomer({
    required String orderId,
    required String userId,
  }) async {
    final order = orders[orderId];
    if (order == null) throw Exception('Order not found.');
    if (order.userId != userId) throw Exception('Unauthorized');
    if (order.status != OrderStatus.pending) {
      throw Exception('Orders can only be cancelled while in Pending status.');
    }

    // Restore stock
    for (final item in order.items) {
      final product = catalog[item.productId];
      if (product != null) {
        catalog[item.productId] = product.copyWith(
          stockCount: product.stockCount + item.quantity,
          inStock: true,
        );
      }
    }

    orders[orderId] = order.copyWith(status: OrderStatus.cancelled);
  }

  @override
  Future<void> updateOrderStatusAdmin({
    required String orderId,
    required OrderStatus newStatus,
  }) async {
    final order = orders[orderId];
    if (order == null) throw Exception('Order not found.');
    if (!order.status.canTransitionTo(newStatus)) {
      throw Exception('Invalid status transition');
    }

    if (newStatus == OrderStatus.cancelled) {
      for (final item in order.items) {
        final product = catalog[item.productId];
        if (product != null) {
          catalog[item.productId] = product.copyWith(
            stockCount: product.stockCount + item.quantity,
            inStock: true,
          );
        }
      }
    }

    orders[orderId] = order.copyWith(status: newStatus);
  }
}

void main() {
  late SimulatedOrderRepository repo;

  setUp(() {
    repo = SimulatedOrderRepository();
    repo.catalog['p1'] = const ProductModel(
      id: 'p1',
      name: 'Smart Watch',
      brand: 'Brand',
      category: 'Electronics',
      price: 2000.0,
      originalPrice: 2500.0,
      rating: 4.5,
      reviewCount: 12,
      imageUrl: 'https://example.com/watch.jpg',
      description: 'Awesome smartwatch',
      stockCount: 5,
      inStock: true,
    );
    repo.catalog['p2'] = const ProductModel(
      id: 'p2',
      name: 'Running Shoes',
      brand: 'Brand',
      category: 'Footwear',
      price: 1500.0,
      originalPrice: 1800.0,
      rating: 4.8,
      reviewCount: 30,
      imageUrl: 'https://example.com/shoes.jpg',
      description: 'Comfortable shoes',
      stockCount: 2,
      inStock: true,
    );
    repo.promoCodes['SAVE10'] = const PromoCodeModel(
      code: 'SAVE10',
      discountPercent: 0.10,
      isActive: true,
    );
    repo.promoCodes['EXPIRED'] = PromoCodeModel(
      code: 'EXPIRED',
      discountPercent: 0.20,
      isActive: true,
      expiresAt: DateTime.now().subtract(const Duration(days: 2)),
    );
  });

  group('Order Placement Transaction Logic Tests', () {
    test('Successfully places order and decrements stock atomically', () async {
      final items = [
        const OrderItemModel(
          productId: 'p1',
          name: 'Smart Watch',
          price: 2000.0,
          imageUrl: 'https://example.com/watch.jpg',
          quantity: 2,
        ),
      ];

      final orderId = await repo.placeOrderInTransaction(
        userId: 'usr_1',
        customerName: 'Rahim Khan',
        customerPhone: '01712345678',
        shippingAddress: 'House 1, Road 2, Dhanmondi, Dhaka',
        items: items,
        promoCode: 'SAVE10',
        deliveryCharge: 60.0,
      );

      expect(orderId.isNotEmpty, isTrue);
      // Stock decremented from 5 to 3
      expect(repo.catalog['p1']!.stockCount, 3);

      final order = await repo.getOrderById(orderId);
      expect(order, isNotNull);
      expect(order!.paymentMethod, 'Cash on Delivery');
      expect(order.subtotal, 4000.0);
      expect(order.discount, 400.0); // 10%
      expect(order.tax, 180.0); // 5% of 3600
      expect(order.totalAmount, 3600 + 180 + 60); // 3840.0
      expect(order.status, OrderStatus.pending);
    });

    test('Fails order placement when requested quantity exceeds stock', () async {
      final items = [
        const OrderItemModel(
          productId: 'p2',
          name: 'Running Shoes',
          price: 1500.0,
          imageUrl: 'https://example.com/shoes.jpg',
          quantity: 5, // Only 2 in stock
        ),
      ];

      expect(
        () => repo.placeOrderInTransaction(
          userId: 'usr_1',
          customerName: 'Rahim Khan',
          customerPhone: '01712345678',
          shippingAddress: 'Gulshan, Dhaka',
          items: items,
          deliveryCharge: 60.0,
        ),
        throwsA(predicate((e) => e.toString().contains('Insufficient stock'))),
      );

      // Stock remains unaffected
      expect(repo.catalog['p2']!.stockCount, 2);
    });

    test('Fails order placement when product price in cart is stale', () async {
      final items = [
        const OrderItemModel(
          productId: 'p1',
          name: 'Smart Watch',
          price: 1800.0, // Stale price; current is 2000.0
          imageUrl: 'https://example.com/watch.jpg',
          quantity: 1,
        ),
      ];

      expect(
        () => repo.placeOrderInTransaction(
          userId: 'usr_1',
          customerName: 'Rahim Khan',
          customerPhone: '01712345678',
          shippingAddress: 'Mirpur, Dhaka',
          items: items,
          deliveryCharge: 60.0,
        ),
        throwsA(predicate((e) => e.toString().contains('price') && e.toString().contains('changed'))),
      );
    });

    test('Fails order placement when promo code is expired or inactive', () async {
      final items = [
        const OrderItemModel(
          productId: 'p1',
          name: 'Smart Watch',
          price: 2000.0,
          imageUrl: 'https://example.com/watch.jpg',
          quantity: 1,
        ),
      ];

      expect(
        () => repo.placeOrderInTransaction(
          userId: 'usr_1',
          customerName: 'Rahim Khan',
          customerPhone: '01712345678',
          shippingAddress: 'Uttara, Dhaka',
          items: items,
          promoCode: 'EXPIRED',
          deliveryCharge: 60.0,
        ),
        throwsA(predicate((e) => e.toString().contains('expired or inactive'))),
      );
    });

    test('Customer cancels Pending order and restores stock', () async {
      final items = [
        const OrderItemModel(
          productId: 'p1',
          name: 'Smart Watch',
          price: 2000.0,
          imageUrl: 'https://example.com/watch.jpg',
          quantity: 2,
        ),
      ];

      final orderId = await repo.placeOrderInTransaction(
        userId: 'usr_1',
        customerName: 'Rahim',
        customerPhone: '01712345678',
        shippingAddress: 'Banani, Dhaka',
        items: items,
        deliveryCharge: 60.0,
      );

      expect(repo.catalog['p1']!.stockCount, 3);

      await repo.cancelOrderCustomer(orderId: orderId, userId: 'usr_1');

      final order = await repo.getOrderById(orderId);
      expect(order!.status, OrderStatus.cancelled);
      // Stock restored to 5
      expect(repo.catalog['p1']!.stockCount, 5);
    });
  });
}
