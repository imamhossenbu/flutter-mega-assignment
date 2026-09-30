import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/promo_code_model.dart';
import '../models/review_model.dart';

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
  User? get currentUser => _auth?.currentUser;

  // ===================== AUTH =====================

  Future<User?> ensureAuthenticated() async {
    try {
      if (_auth == null) return null;
      if (_auth!.currentUser != null) return _auth!.currentUser;
      final cred = await _auth!.signInAnonymously();
      return cred.user;
    } catch (e) {
      debugPrint('Anonymous auth error: $e');
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  Future<User?> signUpWithEmail(String email, String password, String name) async {
    try {
      final cred = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(name.trim());
      // Save user profile to Firestore
      if (cred.user != null) {
        await _firestore?.collection('users').doc(cred.user!.uid).set({
          'name': name.trim(),
          'email': email.trim(),
          'photoUrl': '',
          'phone': '',
          'createdAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
      return cred.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign up error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  Future<void> updateUserProfile(String userId, {String? name, String? phone}) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (updates.isEmpty) return;
    try {
      await firestore.collection('users').doc(userId).set(updates, SetOptions(merge: true));
      if (name != null) await _auth?.currentUser?.updateDisplayName(name);
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      await _auth?.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      debugPrint('Change password error: ${e.code}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final firestore = _firestore;
    if (firestore == null) return null;
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  // ===================== PRODUCTS =====================

  Stream<List<ProductModel>> streamProducts() {
    final firestore = _firestore;
    if (firestore == null) return Stream.value([]);
    return firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<List<ProductModel>> fetchProducts() async {
    final firestore = _firestore;
    if (firestore == null) return [];
    try {
      final snapshot = await firestore.collection('products').get();
      return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  // ===================== CART =====================

  Stream<List<CartItemModel>> streamCart(String userId) {
    final firestore = _firestore;
    if (firestore == null || userId.isEmpty) return Stream.value([]);
    return firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CartItemModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addToCart(String userId, CartItemModel item) async {
    final firestore = _firestore;
    if (firestore == null || userId.isEmpty) return;
    try {
      final cartRef = firestore.collection('users').doc(userId).collection('cart');
      final query = await cartRef
          .where('productId', isEqualTo: item.product.id)
          .where('selectedColor', isEqualTo: item.selectedColor)
          .where('selectedSize', isEqualTo: item.selectedSize)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        final existingDoc = query.docs.first;
        final currentQty = (existingDoc.data()['quantity'] as num?)?.toInt() ?? 1;
        await existingDoc.reference.update({'quantity': currentQty + item.quantity});
      } else {
        await cartRef.doc(item.id).set(item.toMap());
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
    }
  }

  Future<void> updateCartQuantity(String userId, String cartItemId, int newQuantity) async {
    final firestore = _firestore;
    if (firestore == null || userId.isEmpty) return;
    try {
      final docRef = firestore.collection('users').doc(userId).collection('cart').doc(cartItemId);
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
      await firestore.collection('users').doc(userId).collection('cart').doc(cartItemId).delete();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
    }
  }

  Future<void> clearCart(String userId) async {
    final firestore = _firestore;
    if (firestore == null || userId.isEmpty) return;
    try {
      final snapshot = await firestore.collection('users').doc(userId).collection('cart').get();
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
    if (firestore == null || userId.isEmpty) return Stream.value([]);
    return firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList());
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

  // ===================== ORDERS =====================

  Future<OrderModel?> placeOrder(OrderModel order) async {
    final firestore = _firestore;
    if (firestore == null) return null;
    try {
      // Use a transaction to:
      // 1. Create the order document
      // 2. Deduct stock from each product (live stock deduction)
      // 3. Clear the user's cart
      final orderRef = firestore.collection('users').doc(order.userId).collection('orders').doc(order.id);

      await firestore.runTransaction((transaction) async {
        // Fetch all product docs for stock check
        final productRefs = order.items
            .map((item) => firestore.collection('products').doc(item.productId))
            .toList();

        final productDocs = await Future.wait(productRefs.map((ref) => transaction.get(ref)));

        for (int i = 0; i < order.items.length; i++) {
          final item = order.items[i];
          final productDoc = productDocs[i];
          if (productDoc.exists) {
            final currentStock = (productDoc.data()?['stockCount'] as num?)?.toInt() ?? 0;
            final newStock = (currentStock - item.quantity).clamp(0, 99999);
            transaction.update(productRefs[i], {
              'stockCount': newStock,
              'inStock': newStock > 0,
            });
          }
        }

        // Save order
        transaction.set(orderRef, order.toMap());
      });

      // Clear cart after order
      await clearCart(order.userId);

      return order;
    } catch (e) {
      debugPrint('Error placing order: $e');
      return null;
    }
  }

  Stream<List<OrderModel>> streamOrders(String userId) {
    final firestore = _firestore;
    if (firestore == null || userId.isEmpty) return Stream.value([]);
    return firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromMap(doc.data(), doc.id)).toList());
  }

  // ===================== REVIEWS =====================

  Stream<List<ReviewModel>> streamReviews(String productId) {
    final firestore = _firestore;
    if (firestore == null) return Stream.value([]);
    return firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addReview(String productId, ReviewModel review) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final reviewRef = firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(review.id);

      await firestore.runTransaction((transaction) async {
        // Add the review
        transaction.set(reviewRef, review.toMap());

        // Update product's aggregate rating
        final productRef = firestore.collection('products').doc(productId);
        final productDoc = await transaction.get(productRef);
        if (productDoc.exists) {
          final currentReviewCount = (productDoc.data()?['reviewCount'] as num?)?.toInt() ?? 0;
          final currentRating = (productDoc.data()?['rating'] as num?)?.toDouble() ?? 0.0;
          final newCount = currentReviewCount + 1;
          final newRating = ((currentRating * currentReviewCount) + review.rating) / newCount;
          transaction.update(productRef, {
            'reviewCount': newCount,
            'rating': double.parse(newRating.toStringAsFixed(1)),
          });
        }
      });
    } catch (e) {
      debugPrint('Error adding review: $e');
    }
  }

  Future<bool> hasUserReviewed(String productId, String userId) async {
    final firestore = _firestore;
    if (firestore == null) return false;
    try {
      final query = await firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ===================== PROMO CODES =====================

  Future<PromoCodeModel?> validatePromoCode(String code) async {
    final firestore = _firestore;
    if (firestore == null) return null;
    try {
      final doc = await firestore.collection('promoCodes').doc(code.trim().toUpperCase()).get();
      if (!doc.exists || doc.data() == null) return null;
      final promo = PromoCodeModel.fromMap(doc.data()!, doc.id);
      return promo.isValid ? promo : null;
    } catch (e) {
      debugPrint('Error validating promo code: $e');
      return null;
    }
  }

  Future<void> seedPromoCodes() async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final existing = await firestore.collection('promoCodes').limit(1).get();
      if (existing.docs.isNotEmpty) return;

      final codes = [
        {
          'code': 'MEGA20',
          'discountPercent': 0.20,
          'isActive': true,
          'description': '20% off on all orders',
          'expiresAt': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        },
        {
          'code': 'WELCOME10',
          'discountPercent': 0.10,
          'isActive': true,
          'description': '10% off for new users',
          'expiresAt': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        },
        {
          'code': 'SAVE20',
          'discountPercent': 0.20,
          'isActive': true,
          'description': 'Save 20% on your order',
          'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        },
        {
          'code': 'FLASH50',
          'discountPercent': 0.50,
          'isActive': true,
          'description': 'Flash sale! 50% off',
          'expiresAt': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        },
      ];

      final batch = firestore.batch();
      for (final c in codes) {
        batch.set(firestore.collection('promoCodes').doc(c['code'] as String), c);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error seeding promo codes: $e');
    }
  }
}
