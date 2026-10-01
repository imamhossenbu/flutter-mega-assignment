import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mega_assignment/core/constants/app_constants.dart';
import 'package:flutter_mega_assignment/models/order_model.dart';
import 'package:flutter_mega_assignment/models/product_model.dart';
import 'package:flutter_mega_assignment/models/promo_code_model.dart';
import 'package:flutter_mega_assignment/providers/cart_provider.dart';
import 'package:flutter_mega_assignment/repositories/promo_repository.dart';

class FakePromoRepository implements PromoRepository {
  final Map<String, PromoCodeModel> _promos = {};

  void addPromo(PromoCodeModel promo) {
    _promos[promo.code.toUpperCase()] = promo;
  }

  @override
  Stream<List<PromoCodeModel>> streamPromoCodes() {
    return Stream.value(_promos.values.toList());
  }

  @override
  Future<List<PromoCodeModel>> getPromoCodes() async {
    return _promos.values.toList();
  }

  @override
  Future<PromoCodeModel?> validatePromoCode(String code, double currentSubtotal) async {
    final promo = _promos[code.toUpperCase()];
    if (promo == null || !promo.isValid) return null;
    if (promo.minOrderAmount != null && currentSubtotal < promo.minOrderAmount!) {
      return null;
    }
    return promo;
  }

  @override
  Future<void> addPromoCode(PromoCodeModel promo) async {
    _promos[promo.code.toUpperCase()] = promo;
  }

  @override
  Future<void> updatePromoCode(PromoCodeModel promo) async {
    _promos[promo.code.toUpperCase()] = promo;
  }

  @override
  Future<void> togglePromoStatus(String codeId, bool isActive) async {
    final promo = _promos[codeId.toUpperCase()];
    if (promo != null) {
      _promos[codeId.toUpperCase()] = promo.copyWith(isActive: isActive);
    }
  }

  @override
  Future<void> deletePromoCode(String codeId) async {
    _promos.remove(codeId.toUpperCase());
  }
}

void main() {
  group('Bangladesh Phone Validation Tests', () {
    test('Validates 11-digit Bangladesh phone numbers', () {
      expect(AppConstants.isValidPhone('01712345678'), isTrue);
      expect(AppConstants.isValidPhone('01812345678'), isTrue);
      expect(AppConstants.isValidPhone('01912345678'), isTrue);
      expect(AppConstants.isValidPhone('01312345678'), isTrue);
      expect(AppConstants.isValidPhone('01412345678'), isTrue);
      expect(AppConstants.isValidPhone('01512345678'), isTrue);
      expect(AppConstants.isValidPhone('01612345678'), isTrue);
    });

    test('Validates Bangladesh phone numbers with +880 or 880 prefix', () {
      expect(AppConstants.isValidPhone('+8801712345678'), isTrue);
      expect(AppConstants.isValidPhone('8801812345678'), isTrue);
      expect(AppConstants.isValidPhone('+880 1712-345678'), isTrue);
    });

    test('Rejects invalid phone numbers', () {
      expect(AppConstants.isValidPhone(''), isFalse);
      expect(AppConstants.isValidPhone('12345'), isFalse);
      expect(AppConstants.isValidPhone('02712345678'), isFalse);
      expect(AppConstants.isValidPhone('0171234567'), isFalse);
      expect(AppConstants.isValidPhone('017123456789'), isFalse);
      expect(AppConstants.isValidPhone('abcdefghijk'), isFalse);
    });
  });

  group('Currency Formatter Tests', () {
    test('Formats currency with BDT symbol ৳', () {
      expect(AppConstants.formatCurrency(0), '৳0');
      expect(AppConstants.formatCurrency(150), '৳150');
      expect(AppConstants.formatCurrency(1250), '৳1250');
      expect(AppConstants.formatCurrency(100000), '৳100000');
    });
  });

  group('Order Status Transition Machine Tests', () {
    test('Pending can transition to Processing or Cancelled', () {
      expect(OrderStatus.pending.allowedNextStatuses, contains(OrderStatus.processing));
      expect(OrderStatus.pending.allowedNextStatuses, contains(OrderStatus.cancelled));
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.processing), isTrue);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.cancelled), isTrue);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.shipped), isFalse);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.delivered), isFalse);
    });

    test('Processing can transition to Shipped or Cancelled', () {
      expect(OrderStatus.processing.canTransitionTo(OrderStatus.shipped), isTrue);
      expect(OrderStatus.processing.canTransitionTo(OrderStatus.cancelled), isTrue);
      expect(OrderStatus.processing.canTransitionTo(OrderStatus.pending), isFalse);
      expect(OrderStatus.processing.canTransitionTo(OrderStatus.delivered), isFalse);
    });

    test('Shipped can only transition to Delivered', () {
      expect(OrderStatus.shipped.canTransitionTo(OrderStatus.delivered), isTrue);
      expect(OrderStatus.shipped.canTransitionTo(OrderStatus.cancelled), isFalse);
      expect(OrderStatus.shipped.canTransitionTo(OrderStatus.processing), isFalse);
      expect(OrderStatus.shipped.canTransitionTo(OrderStatus.pending), isFalse);
    });

    test('Delivered and Cancelled have no allowed next statuses', () {
      expect(OrderStatus.delivered.allowedNextStatuses, isEmpty);
      expect(OrderStatus.delivered.canTransitionTo(OrderStatus.pending), isFalse);
      expect(OrderStatus.delivered.canTransitionTo(OrderStatus.cancelled), isFalse);

      expect(OrderStatus.cancelled.allowedNextStatuses, isEmpty);
      expect(OrderStatus.cancelled.canTransitionTo(OrderStatus.pending), isFalse);
      expect(OrderStatus.cancelled.canTransitionTo(OrderStatus.processing), isFalse);
    });
  });

  group('Cart Math Calculations Tests', () {
    const productA = ProductModel(
      id: 'p1',
      name: 'Item 1',
      brand: 'Brand',
      category: 'Electronics',
      price: 1000.0,
      originalPrice: 1200.0,
      rating: 4.5,
      reviewCount: 10,
      imageUrl: 'https://example.com/p1.jpg',
      description: 'Item 1 description',
      stockCount: 10,
    );

    const productB = ProductModel(
      id: 'p2',
      name: 'Item 2',
      brand: 'Brand',
      category: 'Electronics',
      price: 500.0,
      originalPrice: 600.0,
      rating: 4.0,
      reviewCount: 5,
      imageUrl: 'https://example.com/p2.jpg',
      description: 'Item 2 description',
      stockCount: 5,
    );

    test('Computes subtotal, tax (5%), delivery fees, and grand total correctly without promo', () async {
      final fakePromoRepo = FakePromoRepository();
      final cart = CartProvider(promoRepository: fakePromoRepo);

      // Empty cart
      expect(cart.subtotal, 0.0);
      expect(cart.taxAmount, 0.0);
      expect(cart.deliveryFee, 0.0);
      expect(cart.grandTotal, 0.0);

      // Add Product A (qty 2) = 2000
      await cart.addToCart(productA, quantity: 2);
      // Add Product B (qty 1) = 500
      await cart.addToCart(productB, quantity: 1);

      // Subtotal = 2500
      expect(cart.subtotal, 2500.0);
      expect(cart.discountAmount, 0.0);

      // Dhaka delivery fee = 60
      expect(cart.isDhaka, isTrue);
      expect(cart.deliveryFee, 60.0);

      // 5% Tax on 2500 = 125.0
      expect(cart.taxAmount, 125.0);

      // Grand total = 2500 + 125 + 60 = 2685.0
      expect(cart.grandTotal, 2685.0);

      // Switch to Outside Dhaka = 120
      cart.setDeliveryZone(isDhaka: false);
      expect(cart.isDhaka, isFalse);
      expect(cart.deliveryFee, 120.0);
      // Grand total = 2500 + 125 + 120 = 2745.0
      expect(cart.grandTotal, 2745.0);
    });

    test('Computes promo discount and recalculated tax properly', () async {
      final fakePromoRepo = FakePromoRepository();
      fakePromoRepo.addPromo(const PromoCodeModel(
        code: 'SAVE10',
        discountPercent: 0.10, // 10%
        isActive: true,
      ));

      final cart = CartProvider(promoRepository: fakePromoRepo);
      await cart.addToCart(productA, quantity: 2); // 2000 subtotal

      expect(cart.subtotal, 2000.0);

      final applied = await cart.applyPromoCode('SAVE10');
      expect(applied, isTrue);

      // 10% discount on 2000 = 200.0
      expect(cart.discountAmount, 200.0);

      // Discounted subtotal = 1800.0
      // 5% Tax on 1800 = 90.0
      expect(cart.taxAmount, 90.0);

      // Dhaka delivery = 60.0
      expect(cart.deliveryFee, 60.0);

      // Grand total = 1800 + 90 + 60 = 1950.0
      expect(cart.grandTotal, 1950.0);

      // Remove promo
      cart.removePromoCode();
      expect(cart.discountAmount, 0.0);
      expect(cart.taxAmount, 100.0); // 5% on 2000
      expect(cart.grandTotal, 2160.0); // 2000 + 100 + 60
    });
  });
}
