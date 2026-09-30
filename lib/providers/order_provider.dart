import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/promo_code_model.dart';
import '../services/firebase_service.dart';

class OrderProvider extends ChangeNotifier {
  String _userId = '';
  List<OrderModel> _orders = [];
  List<OrderModel> _allOrders = [];
  bool _isLoading = false;
  bool _isPlacingOrder = false;
  StreamSubscription? _subscription;
  StreamSubscription? _allOrdersSub;

  List<OrderModel> get orders => _orders;
  List<OrderModel> get allOrders => _allOrders;
  bool get isLoading => _isLoading;
  bool get isPlacingOrder => _isPlacingOrder;

  // Customer metrics
  double get totalSpent => _orders.fold(0.0, (sum, o) => sum + o.grandTotal);
  int get ordersCount => _orders.length;
  int get activeOrdersCount => _orders
      .where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
      .length;
  OrderModel? get latestActiveOrder {
    try {
      return _orders.firstWhere(
        (o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled,
      );
    } catch (_) {
      return _orders.isNotEmpty ? _orders.first : null;
    }
  }

  // Admin metrics
  double get totalRevenue => _allOrders.fold(
      0.0, (sum, o) => sum + (o.status != OrderStatus.cancelled ? o.grandTotal : 0.0));
  int get totalOrdersCount => _allOrders.length;
  int get pendingOrdersCount =>
      _allOrders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.confirmed).length;
  int get shippedOrdersCount => _allOrders.where((o) => o.status == OrderStatus.shipped).length;
  int get deliveredOrdersCount => _allOrders.where((o) => o.status == OrderStatus.delivered).length;

  void updateUserId(String newUserId) {
    if (_userId == newUserId) return;
    _userId = newUserId;
    _listenToOrders();
  }

  void initAdminOrdersStream() {
    _allOrdersSub?.cancel();
    try {
      _allOrdersSub = FirebaseService.instance.streamAllOrders().listen(
        (orders) {
          _allOrders = orders;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Admin orders stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Admin orders stream listen error: $e');
    }
  }

  void _listenToOrders() {
    _subscription?.cancel();
    if (_userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      _subscription = FirebaseService.instance.streamOrders(_userId).listen(
        (orders) {
          _orders = orders;
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Orders stream error: $e');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(String orderId, String userId, OrderStatus newStatus) async {
    try {
      await FirebaseService.instance.updateOrderStatus(orderId, userId, newStatus);
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  Future<OrderModel?> placeOrder({
    required List<CartItemModel> cartItems,
    required double subtotal,
    required double discount,
    required double shipping,
    required double tax,
    required double grandTotal,
    required String shippingAddress,
    PromoCodeModel? promoCode,
  }) async {
    if (_userId.isEmpty || cartItems.isEmpty) return null;

    _isPlacingOrder = true;
    notifyListeners();

    try {
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      final orderItems = cartItems
          .map((item) => OrderItemModel(
                productId: item.product.id,
                productName: item.product.name,
                productImage: item.product.imageUrl,
                productBrand: item.product.brand,
                unitPrice: item.product.price,
                quantity: item.quantity,
                selectedColor: item.selectedColor,
                selectedSize: item.selectedSize,
              ))
          .toList();

      final order = OrderModel(
        id: orderId,
        userId: _userId,
        items: orderItems,
        subtotal: subtotal,
        discount: discount,
        shipping: shipping,
        tax: tax,
        grandTotal: grandTotal,
        promoCode: promoCode?.code,
        shippingAddress: shippingAddress,
        status: OrderStatus.confirmed,
        createdAt: DateTime.now(),
      );

      final result = await FirebaseService.instance.placeOrder(order);
      _isPlacingOrder = false;
      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('Error placing order: $e');
      _isPlacingOrder = false;
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _allOrdersSub?.cancel();
    super.dispose();
  }
}
