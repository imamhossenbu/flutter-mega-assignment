import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/filter_options.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';
import '../services/seed_data_service.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _allProducts = [];
  FilterOptions _filterOptions = const FilterOptions();
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _subscription;

  List<ProductModel> get allProducts => _allProducts;
  FilterOptions get filterOptions => _filterOptions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProductProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    // 1. Initial fallback so UI is immediately responsive
    _allProducts = AppConstants.initialProducts;

    // 2. Check if Firestore needs seeding
    try {
      await SeedDataService.seedInitialProductsIfNeeded();
    } catch (e) {
      debugPrint('Firestore seed check failed: $e');
    }

    // 3. Listen to real-time updates from Firestore
    try {
      _subscription = FirebaseService.instance.streamProducts().listen(
        (products) {
          if (products.isNotEmpty) {
            _allProducts = products;
          } else {
            _allProducts = AppConstants.initialProducts;
          }
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Firestore stream products error: $err');
          // Maintain fallback data if stream fails
          if (_allProducts.isEmpty) {
            _allProducts = AppConstants.initialProducts;
          }
          _isLoading = false;
          _errorMessage = err.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Firestore listen setup error: $e');
      _isLoading = false;
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

  Future<void> reseedSampleProducts() async {
    _isLoading = true;
    notifyListeners();
    await SeedDataService.reseedAllProducts();
    _allProducts = AppConstants.initialProducts;
    _isLoading = false;
    notifyListeners();
  }

  List<ProductModel> get filteredProducts {
    final query = _filterOptions.searchQuery.trim().toLowerCase();
    final category = _filterOptions.selectedCategory;
    final priceRange = _filterOptions.priceRange;
    final minRating = _filterOptions.minRating;
    final onlyInStock = _filterOptions.onlyInStock;
    final sortBy = _filterOptions.sortBy;

    var list = _allProducts.where((product) {
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
          if (a.isFeatured == b.isFeatured) {
            return b.rating.compareTo(a.rating);
          }
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
      return _allProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
