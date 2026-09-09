import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mega_assignment/models/product_model.dart';
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
}
