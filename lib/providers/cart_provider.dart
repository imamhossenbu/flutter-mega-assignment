import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/promo_code_model.dart';
import '../repositories/promo_repository.dart';

class CartProvider extends ChangeNotifier {
  final PromoRepository _promoRepository;

  final List<CartItemModel> _items = [];
  final bool _isLoading = false;
  String? _appliedPromoCode;
  double _promoDiscountFraction = 0.0;
  PromoCodeModel? _appliedPromo;
  bool _isValidatingPromo = false;
  bool _isDhaka = true;

  List<CartItemModel> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get appliedPromoCode => _appliedPromoCode;
  double get promoDiscountPercent => _promoDiscountFraction;
  PromoCodeModel? get appliedPromo => _appliedPromo;
  bool get isValidatingPromo => _isValidatingPromo;
  bool get isDhaka => _isDhaka;

  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get discountAmount {
    if (_promoDiscountFraction <= 0) return 0.0;
    return subtotal * _promoDiscountFraction;
  }

  double get deliveryFee =>
      _items.isEmpty ? 0.0 : (_isDhaka ? AppConstants.deliveryFeeDhaka : AppConstants.deliveryFeeOutsideDhaka);

  double get shippingFee => deliveryFee;

  double get taxAmount => (subtotal - discountAmount).clamp(0.0, double.infinity) * AppConstants.taxRate;

  double get grandTotal {
    if (subtotal == 0) return 0.0;
    final discounted = (subtotal - discountAmount).clamp(0.0, double.infinity);
    return discounted + taxAmount + deliveryFee;
  }

  CartProvider({PromoRepository? promoRepository, bool seedSample = false})
      : _promoRepository = promoRepository ?? FirestorePromoRepository() {
    if (seedSample) {
      _initSampleCart();
    }
  }

  void _initSampleCart() {
    if (AppConstants.initialProducts.length >= 2) {
      final p1 = AppConstants.initialProducts[0];
      final p2 = AppConstants.initialProducts[1];
      _items.addAll([
        CartItemModel(
          id: 'cart_item_1',
          product: p1,
          quantity: 1,
          selectedColor: p1.colors.isNotEmpty ? p1.colors.first : 'Black',
          selectedSize: p1.sizes.isNotEmpty ? p1.sizes.first : 'Standard',
          addedAt: DateTime.now(),
        ),
        CartItemModel(
          id: 'cart_item_2',
          product: p2,
          quantity: 2,
          selectedColor: p2.colors.isNotEmpty ? p2.colors.first : 'Teal',
          selectedSize: p2.sizes.isNotEmpty ? p2.sizes.first : 'Standard',
          addedAt: DateTime.now(),
        ),
      ]);
      _appliedPromoCode = 'MEGA20';
      _promoDiscountFraction = 0.20;
    }
  }

  void setDeliveryZone({required bool isDhaka}) {
    if (_isDhaka == isDhaka) return;
    _isDhaka = isDhaka;
    notifyListeners();
  }

  void updateUserId(String newUserId) {
    // Session tracking if needed
  }

  Future<void> addToCart(
    ProductModel product, {
    int quantity = 1,
    String? selectedColor,
    String? selectedSize,
  }) async {
    final effectiveColor = selectedColor ?? (product.colors.isNotEmpty ? product.colors.first : null);
    final effectiveSize = selectedSize ?? (product.sizes.isNotEmpty ? product.sizes.first : null);

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
  }

  Future<void> removeItem(String cartItemId) async {
    _items.removeWhere((item) => item.id == cartItemId);
    notifyListeners();
  }

  String? _promoValidationMessage;
  String? get promoValidationMessage => _promoValidationMessage;

  Future<void> clearCart() async {
    _items.clear();
    _appliedPromoCode = null;
    _promoDiscountFraction = 0.0;
    _appliedPromo = null;
    _promoValidationMessage = null;
    notifyListeners();
  }

  Future<bool> applyPromoCode(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) {
      _promoValidationMessage = 'Please enter a promo code.';
      notifyListeners();
      return false;
    }

    _isValidatingPromo = true;
    _promoValidationMessage = null;
    notifyListeners();
    try {
      final promo = await _promoRepository.validatePromoCode(clean, subtotal);
      if (promo != null) {
        _appliedPromo = promo;
        _appliedPromoCode = promo.code;
        _promoDiscountFraction = promo.discountFraction;
        _isValidatingPromo = false;
        _promoValidationMessage = null;
        notifyListeners();
        return true;
      }

      final allPromos = await _promoRepository.getPromoCodes();
      final matching = allPromos.where((p) => p.code.toUpperCase() == clean).firstOrNull;
      if (matching != null) {
        if (!matching.isActive) {
          _promoValidationMessage = 'Promo code "$clean" is currently inactive.';
        } else if (matching.expiresAt != null && DateTime.now().isAfter(matching.expiresAt!)) {
          _promoValidationMessage = 'Promo code "$clean" has expired.';
        } else if (matching.minOrderAmount != null && subtotal < matching.minOrderAmount!) {
          _promoValidationMessage =
              'Minimum order of ৳${matching.minOrderAmount!.toStringAsFixed(0)} required for "$clean".';
        } else {
          _promoValidationMessage = 'Promo code "$clean" cannot be applied to this order.';
        }
      } else {
        _promoValidationMessage = 'Invalid promo code. Please enter a valid voucher code.';
      }

      _isValidatingPromo = false;
      notifyListeners();
      return false;
    } catch (_) {
      _isValidatingPromo = false;
      _promoValidationMessage = 'Failed to validate promo code. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void removePromoCode() {
    _appliedPromoCode = null;
    _promoDiscountFraction = 0.0;
    _appliedPromo = null;
    _promoValidationMessage = null;
    notifyListeners();
  }

  List<OrderItemModel> toOrderSnapshotItems() {
    return _items.map((item) => OrderItemModel(
      productId: item.product.id,
      name: item.product.name,
      price: item.product.price,
      imageUrl: item.product.imageUrl,
      unit: item.product.unit,
      selectedColor: item.selectedColor,
      selectedSize: item.selectedSize,
      quantity: item.quantity,
    )).toList();
  }
}
