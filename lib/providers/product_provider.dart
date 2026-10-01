import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/filter_options.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _productRepository;

  List<ProductModel> _allProducts = [];
  FilterOptions _filterOptions = const FilterOptions();
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _subscription;

  List<ProductModel> get allProducts =>
      _allProducts.isEmpty ? AppConstants.initialProducts : _allProducts;
  FilterOptions get filterOptions => _filterOptions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalProductsCount => allProducts.where((p) => !p.isDeleted).length;
  int get lowStockCount =>
      allProducts.where((p) => !p.isDeleted && p.stockCount > 0 && p.stockCount <= 5).length;
  int get outOfStockCount =>
      allProducts.where((p) => !p.isDeleted && p.stockCount <= 0).length;
  List<ProductModel> get lowStockProducts =>
      allProducts.where((p) => !p.isDeleted && p.stockCount <= 5).toList();

  List<String> get allCategories {
    final list = _allProducts.isEmpty ? AppConstants.initialProducts : _allProducts;
    final cats = list.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  ProductProvider({ProductRepository? productRepository})
      : _productRepository = productRepository ?? FirestoreProductRepository() {
    _initialize();
  }

  void _initialize() {
    _isLoading = true;
    notifyListeners();

    try {
      _subscription = _productRepository.streamProducts(includeDeleted: false).listen(
        (products) {
          _allProducts = products;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Product stream error: $err');
          _isLoading = false;
          _errorMessage = 'Failed to load products. Please check your connection.';
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Product stream setup error: $e');
      _isLoading = false;
      _errorMessage = 'Failed to connect to store. Please try again.';
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_filterOptions.searchQuery == query) return;
    _filterOptions = _filterOptions.copyWith(searchQuery: query);
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    if (_filterOptions.selectedCategory == category) return;
    _filterOptions = _filterOptions.copyWith(selectedCategory: category);
    notifyListeners();
  }

  void setFilterOptions(FilterOptions options) {
    _filterOptions = options;
    notifyListeners();
  }

  void resetFilters() {
    _filterOptions = _filterOptions.reset();
    notifyListeners();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await _productRepository.getProducts(includeDeleted: false);
      _allProducts = list;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not refresh products. Please try again.';
      notifyListeners();
    }
  }

  List<ProductModel> get filteredProducts {
    final query = _filterOptions.searchQuery.trim().toLowerCase();
    final category = _filterOptions.selectedCategory;
    final priceRange = _filterOptions.priceRange;
    final minRating = _filterOptions.minRating;
    final onlyInStock = _filterOptions.onlyInStock;
    final sortBy = _filterOptions.sortBy;

    var list = _allProducts.where((product) {
      // Exclude soft-deleted products
      if (product.isDeleted) return false;

      // Category filter
      if (category != 'All' && !product.category.toLowerCase().contains(category.toLowerCase())) {
        return false;
      }

      // Search keyword filter
      if (query.isNotEmpty) {
        final inName = product.name.toLowerCase().contains(query);
        final inBrand = product.brand.toLowerCase().contains(query);
        final inDesc = product.description.toLowerCase().contains(query);
        final inCategory = product.category.toLowerCase().contains(query);
        if (!inName && !inBrand && !inDesc && !inCategory) {
          return false;
        }
      }

      // Price range filter
      if (product.price < priceRange.start || product.price > priceRange.end) {
        return false;
      }

      // Rating filter
      if (product.rating < minRating) {
        return false;
      }

      // In-stock filter
      if (onlyInStock && (!product.inStock || product.stockCount <= 0)) {
        return false;
      }

      return true;
    }).toList();

    // Sorting
    switch (sortBy) {
      case SortOption.featured:
        list.sort((a, b) {
          if (a.isFeatured == b.isFeatured) return 0;
          return a.isFeatured ? -1 : 1;
        });
        break;
      case SortOption.priceLowToHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighToLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.ratingHighToLow:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.discountHighToLow:
        list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
    }

    return list;
  }

  ProductModel? findById(String id) {
    try {
      return _allProducts.firstWhere((p) => p.id == id && !p.isDeleted);
    } catch (_) {
      return null;
    }
  }

  List<ProductModel> get featuredProducts =>
      _allProducts.where((p) => p.isFeatured && !p.isDeleted).toList();

  List<ProductModel> get popularProducts =>
      _allProducts.where((p) => p.rating >= 4.7 && !p.isDeleted).toList();

  Future<bool> addProduct(ProductModel product) async {
    try {
      await _productRepository.addProduct(product);
      return true;
    } catch (e) {
      debugPrint('addProduct error: $e');
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _productRepository.updateProduct(product);
      return true;
    } catch (e) {
      debugPrint('updateProduct error: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _productRepository.softDeleteProduct(productId);
      return true;
    } catch (e) {
      debugPrint('deleteProduct error: $e');
      return false;
    }
  }

  Future<bool> updateStock(String productId, int newStock) async {
    try {
      await _productRepository.updateStock(productId, newStock);
      return true;
    } catch (e) {
      debugPrint('updateStock error: $e');
      return false;
    }
  }

  Future<void> reseedSampleProducts() async {
    for (final product in AppConstants.initialProducts) {
      await _productRepository.addProduct(product);
    }
    await refresh();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
