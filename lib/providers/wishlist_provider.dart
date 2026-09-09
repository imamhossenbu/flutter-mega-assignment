import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';

class WishlistProvider extends ChangeNotifier {
  String _userId = '';
  final Map<String, ProductModel> _wishlistMap = {};
  bool _isLoading = false;
  StreamSubscription? _subscription;

  List<ProductModel> get wishlistItems => _wishlistMap.values.toList();
  int get count => _wishlistMap.length;
  bool get isLoading => _isLoading;

  bool isInWishlist(String productId) => _wishlistMap.containsKey(productId);

  void updateUserId(String newUserId) {
    if (_userId == newUserId) return;
    _userId = newUserId;
    _listenToWishlistStream();
  }

  void _listenToWishlistStream() {
    _subscription?.cancel();
    if (_userId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      _subscription = FirebaseService.instance.streamWishlist(_userId).listen(
        (items) {
          _wishlistMap.clear();
          for (final item in items) {
            _wishlistMap[item.id] = item;
          }
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Firestore wishlist stream error: $e');
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

    // Firestore sync
    if (_userId.isNotEmpty) {
      if (exists) {
        await FirebaseService.instance.removeFromWishlist(_userId, product.id);
      } else {
        await FirebaseService.instance.addToWishlist(_userId, product);
      }
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    if (!_wishlistMap.containsKey(productId)) return;

    _wishlistMap.remove(productId);
    notifyListeners();

    if (_userId.isNotEmpty) {
      await FirebaseService.instance.removeFromWishlist(_userId, productId);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
