import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore instance not available: $e');
      return null;
    }
  }

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('FirebaseAuth instance not available: $e');
      return null;
    }
  }

  String? get currentUserId => _auth?.currentUser?.uid;

  Future<User?> ensureAuthenticated() async {
    try {
      if (_auth == null) return null;
      if (_auth!.currentUser != null) {
        return _auth!.currentUser;
      }
      final cred = await _auth!.signInAnonymously();
      return cred.user;
    } catch (e) {
      debugPrint('Anonymous auth error: $e');
      return null;
    }
  }

  // ===================== PRODUCTS =====================

  Stream<List<ProductModel>> streamProducts() {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value([]);
    }

    return firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<List<ProductModel>> fetchProducts() async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore.collection('products').get();
      return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('Error fetching products from Firestore: $e');
      return [];
    }
  }

  // ===================== CART =====================

  Stream<List<CartItemModel>> streamCart(String userId) {
    final firestore = _firestore;
    if (firestore == null || userId.isEmpty) {
      return Stream.value([]);
    }

    return firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CartItemModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addToCart(String userId, CartItemModel item) async {
    final firestore = _firestore;
    if (firestore == null || userId.isEmpty) return;

    try {
      final cartRef = firestore
          .collection('users')
          .doc(userId)
          .collection('cart');

      // Check if product with same selected color & size already exists
      final query = await cartRef
          .where('productId', isEqualTo: item.product.id)
          .where('selectedColor', isEqualTo: item.selectedColor)
          .where('selectedSize', isEqualTo: item.selectedSize)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final existingDoc = query.docs.first;
        final currentQty = (existingDoc.data()['quantity'] as num?)?.toInt() ?? 1;
        await existingDoc.reference.update({
          'quantity': currentQty + item.quantity,
        });
      } else {
        await cartRef.doc(item.id).set(item.toMap());
      }
    } catch (e) {
      debugPrint('Error adding to cart in Firestore: $e');
    }
  }

  Future<void> updateCartQuantity(String userId, String cartItemId, int newQuantity) async {
    final firestore = _firestore;
    if (firestore == null || userId.isEmpty) return;

    try {
      final docRef = firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(cartItemId);

      if (newQuantity <= 0) {
        await docRef.delete();
      } else {
        await docRef.update({'quantity': newQuantity});
      }
    } catch (e) {
      debugPrint('Error updating cart quantity: $e');
    }
  }

  Future<void> removeFromCart(String userId, String cartItemId) async {
    final firestore = _firestore;
    if (firestore == null || userId.isEmpty) return;

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(cartItemId)
          .delete();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
    }
  }

  Future<void> clearCart(String userId) async {
    final firestore = _firestore;
    if (firestore == null || userId.isEmpty) return;

    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    }
  }

  // ===================== WISHLIST =====================

  Stream<List<ProductModel>> streamWishlist(String userId) {
    final firestore = _firestore;
    if (firestore == null || userId.isEmpty) {
      return Stream.value([]);
    }

    return firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addToWishlist(String userId, ProductModel product) async {
    final firestore = _firestore;
    if (firestore == null || userId.isEmpty) return;

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(product.id)
          .set(product.toMap());
    } catch (e) {
      debugPrint('Error adding to wishlist: $e');
    }
  }

  Future<void> removeFromWishlist(String userId, String productId) async {
    final firestore = _firestore;
    if (firestore == null || userId.isEmpty) return;

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(productId)
          .delete();
    } catch (e) {
      debugPrint('Error removing from wishlist: $e');
    }
  }
}
