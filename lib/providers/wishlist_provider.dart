import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';

class WishlistProvider extends ChangeNotifier {
  final ProductRepository _productRepository;

  String _userId = '';
  final Map<String, ProductModel> _wishlistMap = {};
  bool _isLoading = false;
  StreamSubscription? _subscription;

  List<ProductModel> get wishlistItems => _wishlistMap.values.toList();
  int get count => _wishlistMap.length;
  bool get isLoading => _isLoading;

  bool isInWishlist(String productId) => _wishlistMap.containsKey(productId);

  WishlistProvider({ProductRepository? productRepository})
      : _productRepository = productRepository ?? FirestoreProductRepository() {
    _initSampleWishlist();
  }

  void _initSampleWishlist() {
    if (AppConstants.initialProducts.length >= 4) {
      final p1 = AppConstants.initialProducts[2];
      final p2 = AppConstants.initialProducts[3];
      _wishlistMap[p1.id] = p1;
      _wishlistMap[p2.id] = p2;
    }
  }

  void updateUserId(String newUserId) {
    if (_userId == newUserId) return;
    _userId = newUserId;
    _listenToWishlistStream();
  }

  void _listenToWishlistStream() {
    _subscription?.cancel();
    if (_userId.isEmpty) {
      _wishlistMap.clear();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _subscription = _productRepository.streamWishlist(_userId).listen(
        (items) {
          _wishlistMap.clear();
          for (final item in items) {
            _wishlistMap[item.id] = item;
          }
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Wishlist stream error: $e');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error starting wishlist stream: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleWishlist(ProductModel product) async {
    final exists = _wishlistMap.containsKey(product.id);

    // Optimistic local state update
    if (exists) {
      _wishlistMap.remove(product.id);
    } else {
      _wishlistMap[product.id] = product;
    }
    notifyListeners();

    if (_userId.isNotEmpty) {
      try {
        await _productRepository.toggleWishlist(_userId, product);
      } catch (e) {
        debugPrint('Toggle wishlist error: $e');
        // Revert on error
        if (exists) {
          _wishlistMap[product.id] = product;
        } else {
          _wishlistMap.remove(product.id);
        }
        notifyListeners();
      }
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    final item = _wishlistMap[productId];
    if (item != null) {
      await toggleWishlist(item);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
