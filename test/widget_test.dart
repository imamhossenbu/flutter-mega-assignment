import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mega_assignment/core/constants/app_constants.dart';

void main() {
  test('Initial products catalog is populated and valid', () {
    final products = AppConstants.initialProducts;
    expect(products.isNotEmpty, true);
    expect(products.length >= 5, true);

    for (final product in products) {
      expect(product.id.isNotEmpty, true);
      expect(product.name.isNotEmpty, true);
      expect(product.price > 0, true);
      expect(product.imageUrl.isNotEmpty, true);
    }
  });
}
