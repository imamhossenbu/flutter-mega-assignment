import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/promo_code_model.dart';
import '../services/firebase_service.dart';

class OrderProvider extends ChangeNotifier {
  String _userId = '';
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  bool _isPlacingOrder = false;
  StreamSubscription? _subscription;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  bool get isPlacingOrder => _isPlacingOrder;

  void updateUserId(String newUserId) {
    if (_userId == newUserId) return;
    _userId = newUserId;
    _listenToOrders();
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
    super.dispose();
  }
}
