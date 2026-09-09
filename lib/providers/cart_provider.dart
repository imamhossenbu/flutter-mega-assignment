import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';

class CartProvider extends ChangeNotifier {
  String _userId = '';
  List<CartItemModel> _items = [];
  bool _isLoading = false;
  String? _appliedPromoCode;
  double _promoDiscountPercent = 0.0;
  StreamSubscription? _subscription;

  List<CartItemModel> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get appliedPromoCode => _appliedPromoCode;
  double get promoDiscountPercent => _promoDiscountPercent;

  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get discountAmount {
    if (_promoDiscountPercent <= 0) return 0.0;
    return (subtotal * _promoDiscountPercent);
  }

  double get shippingFee {
    if (subtotal == 0) return 0.0;
    return subtotal > 150 ? 0.0 : 15.0; // Free shipping over $150
  }

  double get taxAmount => (subtotal - discountAmount) * 0.05; // 5% tax

  double get grandTotal {
    if (subtotal == 0) return 0.0;
    final total = (subtotal - discountAmount) + shippingFee + taxAmount;
    return total > 0 ? total : 0.0;
  }

  void updateUserId(String newUserId) {
    if (_userId == newUserId) return;
    _userId = newUserId;
    _listenToCartStream();
  }

  void _listenToCartStream() {
    _subscription?.cancel();
    if (_userId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      _subscription = FirebaseService.instance.streamCart(_userId).listen(
        (cartList) {
          _items = cartList;
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Firestore cart stream error: $e');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error starting cart stream: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(
    ProductModel product, {
    int quantity = 1,
    String? selectedColor,
    String? selectedSize,
  }) async {
    final effectiveColor = selectedColor ?? (product.colors.isNotEmpty ? product.colors.first : null);
    final effectiveSize = selectedSize ?? (product.sizes.isNotEmpty ? product.sizes.first : null);

    // Optimistic local update
    final existingIndex = _items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.selectedColor == effectiveColor &&
          item.selectedSize == effectiveSize,
    );

    final cartItemId = existingIndex >= 0
        ? _items[existingIndex].id
        : 'cart_${product.id}_${DateTime.now().millisecondsSinceEpoch}';

    if (existingIndex >= 0) {
      final updated = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + quantity,
      );
      _items[existingIndex] = updated;
    } else {
      final newItem = CartItemModel(
        id: cartItemId,
        product: product,
        quantity: quantity,
        selectedColor: effectiveColor,
        selectedSize: effectiveSize,
        addedAt: DateTime.now(),
      );
      _items.insert(0, newItem);
    }
    notifyListeners();

    // Firebase Firestore sync
    if (_userId.isNotEmpty) {
      final itemToSync = CartItemModel(
        id: cartItemId,
        product: product,
        quantity: quantity,
        selectedColor: effectiveColor,
        selectedSize: effectiveSize,
        addedAt: DateTime.now(),
      );
      await FirebaseService.instance.addToCart(_userId, itemToSync);
    }
  }

  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index < 0) return;

    if (newQuantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(quantity: newQuantity);
    }
    notifyListeners();

    // Firebase Firestore sync
    if (_userId.isNotEmpty) {
      await FirebaseService.instance.updateCartQuantity(_userId, cartItemId, newQuantity);
    }
  }

  Future<void> removeItem(String cartItemId) async {
    _items.removeWhere((item) => item.id == cartItemId);
    notifyListeners();

    // Firebase Firestore sync
    if (_userId.isNotEmpty) {
      await FirebaseService.instance.removeFromCart(_userId, cartItemId);
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    _appliedPromoCode = null;
    _promoDiscountPercent = 0.0;
    notifyListeners();

    // Firebase Firestore sync
    if (_userId.isNotEmpty) {
      await FirebaseService.instance.clearCart(_userId);
    }
  }

  bool applyPromoCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized == 'MEGA20' || normalized == 'SAVE20') {
      _appliedPromoCode = normalized;
      _promoDiscountPercent = 0.20;
      notifyListeners();
      return true;
    } else if (normalized == 'WELCOME10') {
      _appliedPromoCode = normalized;
      _promoDiscountPercent = 0.10;
      notifyListeners();
      return true;
    }
    return false;
  }

  void removePromoCode() {
    _appliedPromoCode = null;
    _promoDiscountPercent = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
