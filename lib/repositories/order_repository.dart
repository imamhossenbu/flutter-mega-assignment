import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/order_model.dart';

abstract class OrderRepository {
  Stream<List<OrderModel>> streamUserOrders(String userId, {int limit = 20});
  Stream<List<OrderModel>> streamAllOrders({int limit = 20, OrderStatus? status});
  Future<List<OrderModel>> getUserOrders(String userId, {int limit = 20, DocumentSnapshot? startAfter});
  Future<List<OrderModel>> getAllOrders({int limit = 20, DocumentSnapshot? startAfter, OrderStatus? status});
  Future<OrderModel?> getOrderById(String orderId);

  Future<String> placeOrderInTransaction({
    required String userId,
    required String customerName,
    required String customerPhone,
    required String shippingAddress,
    required List<OrderItemModel> items,
    String? promoCode,
    required double deliveryCharge,
  });

  Future<void> cancelOrderCustomer({
    required String orderId,
    required String userId,
  });

  Future<void> updateOrderStatusAdmin({
    required String orderId,
    required OrderStatus newStatus,
  });
}

class FirestoreOrderRepository implements OrderRepository {
  final FirebaseFirestore _firestore;

  FirestoreOrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  @override
  Stream<List<OrderModel>> streamUserOrders(String userId, {int limit = 20}) {
    if (userId.isEmpty) return Stream.value([]);
    return _ordersRef
        .where('userId', isEqualTo: userId)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Stream<List<OrderModel>> streamAllOrders({int limit = 20, OrderStatus? status}) {
    Query<Map<String, dynamic>> q = _ordersRef;
    if (status != null) {
      q = q.where('status', isEqualTo: status.label);
    }
    return q.limit(limit).snapshots().map((snap) {
      final list = snap.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<List<OrderModel>> getUserOrders(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    if (userId.isEmpty) return [];
    Query<Map<String, dynamic>> q = _ordersRef
        .where('userId', isEqualTo: userId)
        .limit(limit);

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.get();
    final list = snap.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<OrderModel>> getAllOrders({
    int limit = 20,
    DocumentSnapshot? startAfter,
    OrderStatus? status,
  }) async {
    Query<Map<String, dynamic>> q = _ordersRef;
    if (status != null) {
      q = q.where('status', isEqualTo: status.label);
    }
    q = q.limit(limit);

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.get();
    final list = snap.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _ordersRef.doc(orderId).get();
    if (!doc.exists || doc.data() == null) return null;
    return OrderModel.fromMap(doc.data()!, doc.id);
  }

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

    return await _firestore.runTransaction<String>((transaction) async {
      // 1. Read all product docs in the order
      final productSnapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final item in items) {
        final docRef = _firestore.collection('products').doc(item.productId);
        final snap = await transaction.get(docRef);
        if (!snap.exists || snap.data() == null) {
          throw Exception('Product "${item.name}" was not found in catalog.');
        }
        productSnapshots[item.productId] = snap;
      }

      // 2. Read promo code doc if provided
      DocumentSnapshot<Map<String, dynamic>>? promoSnap;
      if (promoCode != null && promoCode.trim().isNotEmpty) {
        final promoDocRef = _firestore
            .collection('promo_codes')
            .doc(promoCode.trim().toUpperCase());
        promoSnap = await transaction.get(promoDocRef);
      }

      // 3. Validate product states, stock, and prices
      double recomputedSubtotal = 0.0;
      for (final item in items) {
        final data = productSnapshots[item.productId]!.data()!;
        final isDeleted = data['isDeleted'] as bool? ?? false;
        if (isDeleted) {
          throw Exception('Product "${data['name']}" is no longer available.');
        }

        final currentStock = (data['stockCount'] as num?)?.toInt() ?? 0;
        if (currentStock < item.quantity) {
          throw Exception(
            'Insufficient stock for "${data['name']}". Available: $currentStock, Requested: ${item.quantity}.',
          );
        }

        final currentPrice = (data['price'] as num?)?.toDouble() ?? 0.0;
        if ((currentPrice - item.price).abs() > 0.01) {
          throw Exception(
            'The price for "${data['name']}" has changed from ৳${item.price.toInt()} to ৳${currentPrice.toInt()}. Please update your cart.',
          );
        }

        recomputedSubtotal += currentPrice * item.quantity;
      }

      // 4. Validate and calculate discount from Firestore data
      double recomputedDiscount = 0.0;
      if (promoSnap != null && promoSnap.exists && promoSnap.data() != null) {
        final pData = promoSnap.data()!;
        final isActive = pData['isActive'] as bool? ?? false;
        final expiresAtStr = pData['expiresAt'] as String? ?? pData['expiryDate'] as String?;
        final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;
        final minOrderAmt = (pData['minOrderAmount'] as num?)?.toDouble();

        if (!isActive || (expiresAt != null && DateTime.now().isAfter(expiresAt))) {
          throw Exception('Promo voucher "${promoCode!.toUpperCase()}" is expired or inactive.');
        }

        if (minOrderAmt != null && recomputedSubtotal < minOrderAmt) {
          throw Exception(
            'Order subtotal must be at least ৳${minOrderAmt.toInt()} to use voucher "${promoCode!.toUpperCase()}".',
          );
        }

        final discountPercent = (pData['discountPercent'] as num?)?.toDouble() ?? 0.0;
        final fraction = discountPercent > 1.0 ? discountPercent / 100.0 : discountPercent;
        recomputedDiscount = recomputedSubtotal * fraction;
      }

      final discountedSubtotal = (recomputedSubtotal - recomputedDiscount).clamp(0.0, double.infinity);
      final recomputedTax = discountedSubtotal * AppConstants.taxRate;
      final recomputedTotal = discountedSubtotal + recomputedTax + deliveryCharge;

      // 5. Decrement stock for all items
      for (final item in items) {
        final snap = productSnapshots[item.productId]!;
        final data = snap.data()!;
        final currentStock = (data['stockCount'] as num?)?.toInt() ?? 0;
        final newStock = currentStock - item.quantity;
        final docRef = _firestore.collection('products').doc(item.productId);

        transaction.update(docRef, {
          'stockCount': newStock,
          'inStock': newStock > 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 6. Create order document atomically
      final newOrderRef = _ordersRef.doc();
      final orderData = {
        'id': newOrderRef.id,
        'userId': userId,
        'customerName': customerName.trim(),
        'customerPhone': customerPhone.trim(),
        'shippingAddress': shippingAddress.trim(),
        'paymentMethod': 'Cash on Delivery',
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': recomputedSubtotal,
        'discount': recomputedDiscount,
        'deliveryCharge': deliveryCharge,
        'shipping': deliveryCharge,
        'tax': recomputedTax,
        'totalAmount': recomputedTotal,
        'grandTotal': recomputedTotal,
        if (promoCode != null && promoCode.trim().isNotEmpty)
          'promoCode': promoCode.trim().toUpperCase(),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      transaction.set(newOrderRef, orderData);
      return newOrderRef.id;
    });
  }

  @override
  Future<void> cancelOrderCustomer({
    required String orderId,
    required String userId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      // 1. ALL READS FIRST: Read order document
      final orderRef = _ordersRef.doc(orderId);
      final orderSnap = await transaction.get(orderRef);
      if (!orderSnap.exists || orderSnap.data() == null) {
        throw Exception('Order not found.');
      }

      final orderData = orderSnap.data()!;
      if (orderData['userId'] != userId) {
        throw Exception('You are not authorized to cancel this order.');
      }

      final currentStatus = (orderData['status'] as String? ?? '').toLowerCase();
      if (currentStatus != 'pending') {
        throw Exception(
          'Orders can only be cancelled while in Pending status. Current status: "${orderData['status']}".',
        );
      }

      // Read all product documents FIRST before writing anything
      final rawItems = orderData['items'] as List<dynamic>? ?? [];
      final productSnapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      final itemQuantities = <String, int>{};

      for (final raw in rawItems) {
        final itemMap = raw as Map<String, dynamic>;
        final pId = itemMap['productId'] as String?;
        final qty = (itemMap['quantity'] as num?)?.toInt() ?? 0;
        if (pId != null && qty > 0) {
          itemQuantities[pId] = (itemQuantities[pId] ?? 0) + qty;
          if (!productSnapshots.containsKey(pId)) {
            final pRef = _firestore.collection('products').doc(pId);
            final pSnap = await transaction.get(pRef);
            productSnapshots[pId] = pSnap;
          }
        }
      }

      // 2. ALL WRITES AFTER READS: Restore stock for all products
      itemQuantities.forEach((pId, qty) {
        final pSnap = productSnapshots[pId];
        if (pSnap != null && pSnap.exists && pSnap.data() != null) {
          final pData = pSnap.data()!;
          final currentStock = (pData['stockCount'] as num?)?.toInt() ?? 0;
          final pRef = _firestore.collection('products').doc(pId);
          transaction.update(pRef, {
            'stockCount': currentStock + qty,
            'inStock': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Update order status
      transaction.update(orderRef, {
        'status': 'Cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> updateOrderStatusAdmin({
    required String orderId,
    required OrderStatus newStatus,
  }) async {
    await _firestore.runTransaction((transaction) async {
      // 1. ALL READS FIRST: Read order document
      final orderRef = _ordersRef.doc(orderId);
      final orderSnap = await transaction.get(orderRef);
      if (!orderSnap.exists || orderSnap.data() == null) {
        throw Exception('Order not found.');
      }

      final order = OrderModel.fromMap(orderSnap.data()!, orderSnap.id);
      if (!order.status.canTransitionTo(newStatus)) {
        throw Exception(
          'Cannot transition order status from "${order.status.label}" to "${newStatus.label}".',
        );
      }

      // If transition is to Cancelled, read product documents FIRST before any writes
      final productSnapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      final itemQuantities = <String, int>{};

      if (newStatus == OrderStatus.cancelled) {
        final rawItems = orderSnap.data()!['items'] as List<dynamic>? ?? [];
        for (final raw in rawItems) {
          final itemMap = raw as Map<String, dynamic>;
          final pId = itemMap['productId'] as String?;
          final qty = (itemMap['quantity'] as num?)?.toInt() ?? 0;
          if (pId != null && qty > 0) {
            itemQuantities[pId] = (itemQuantities[pId] ?? 0) + qty;
            if (!productSnapshots.containsKey(pId)) {
              final pRef = _firestore.collection('products').doc(pId);
              final pSnap = await transaction.get(pRef);
              productSnapshots[pId] = pSnap;
            }
          }
        }
      }

      // 2. ALL WRITES AFTER READS:
      if (newStatus == OrderStatus.cancelled) {
        itemQuantities.forEach((pId, qty) {
          final pSnap = productSnapshots[pId];
          if (pSnap != null && pSnap.exists && pSnap.data() != null) {
            final pData = pSnap.data()!;
            final currentStock = (pData['stockCount'] as num?)?.toInt() ?? 0;
            final pRef = _firestore.collection('products').doc(pId);
            transaction.update(pRef, {
              'stockCount': currentStock + qty,
              'inStock': true,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        });
      }

      transaction.update(orderRef, {
        'status': newStatus.label,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
