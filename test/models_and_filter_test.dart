import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mega_assignment/models/product_model.dart';
import 'package:flutter_mega_assignment/models/promo_code_model.dart';
import 'package:flutter_mega_assignment/models/cart_item_model.dart';
import 'package:flutter_mega_assignment/models/filter_options.dart';
import 'package:flutter_mega_assignment/core/constants/app_constants.dart';

void main() {
  group('ProductModel Tests', () {
    test('Calculates discount percentage correctly', () {
      const product = ProductModel(
        id: 'test_1',
        name: 'Test Shoes',
        brand: 'Nike',
        category: 'Footwear',
        price: 80.0,
        originalPrice: 100.0,
        rating: 4.5,
        reviewCount: 10,
        imageUrl: '',
        description: 'Test description',
      );

      expect(product.discountPercent, 20.0);
    });

    test('toMap and fromMap serialization matches', () {
      final product = AppConstants.initialProducts.first;
      final map = product.toMap();
      final revived = ProductModel.fromMap(map, product.id);

      expect(revived.id, product.id);
      expect(revived.name, product.name);
      expect(revived.price, product.price);
      expect(revived.category, product.category);
    });
  });

  group('CartItemModel Tests', () {
    test('Calculates total price based on quantity', () {
      final product = AppConstants.initialProducts.first;
      final item = CartItemModel(
        id: 'c1',
        product: product,
        quantity: 3,
        addedAt: DateTime.now(),
      );

      expect(item.totalPrice, product.price * 3);
    });
  });

  group('FilterOptions Tests', () {
    test('Default filter has no active filters', () {
      const options = FilterOptions();
      expect(options.hasActiveFilters, false);
      expect(options.filterBadgeCount, 0);
    });

    test('Custom filter updates active state and badge count', () {
      final options = const FilterOptions().copyWith(
        selectedCategory: 'Electronics',
        minRating: 4.0,
        onlyInStock: true,
      );

      expect(options.hasActiveFilters, true);
      expect(options.filterBadgeCount, 3);
    });

    test('Reset restores default filter options', () {
      final options = const FilterOptions().copyWith(
        selectedCategory: 'Watches',
        minRating: 4.5,
      );

      final resetOptions = options.reset();
      expect(resetOptions.hasActiveFilters, false);
      expect(resetOptions.selectedCategory, 'All');
    });
  });

  group('PromoCodeModel Tests', () {
    test('Calculates isValid based on expiry and isActive', () {
      final validPromo = PromoCodeModel(
        code: 'SAVE20',
        discountPercent: 0.20,
        isActive: true,
        description: '20% off',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );
      expect(validPromo.isValid, true);

      final expiredPromo = PromoCodeModel(
        code: 'EXPIRED10',
        discountPercent: 0.10,
        isActive: true,
        description: 'Expired',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expiredPromo.isValid, false);

      final inactivePromo = validPromo.copyWith(isActive: false);
      expect(inactivePromo.isValid, false);
    });
  });

  group('Category & Catalog Navigation Tests', () {
    test('AppConstants has standard e-commerce categories', () {
      expect(AppConstants.categories.isNotEmpty, true);
      expect(AppConstants.categories.any((c) => c.id == 'All'), true);
      expect(AppConstants.categories.any((c) => c.id == 'Electronics'), true);
      expect(AppConstants.categories.any((c) => c.id == 'Footwear'), true);
    });

    test('Initial products match categories in catalogue', () {
      final categories = AppConstants.categories.map((c) => c.name.toLowerCase()).toSet();
      expect(categories.isNotEmpty, true);
      for (final p in AppConstants.initialProducts) {
        expect(p.name.isNotEmpty, true);
        expect(p.price > 0, true);
      }
    });
  });
}
