import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/brand_model.dart';
import '../models/cart_item_model.dart';
import '../models/category_model.dart';
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

  Future<User?> signInWithGoogle() async {
    try {
      if (_auth == null) return null;
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth!.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        final userDoc = await _firestore?.collection('users').doc(user.uid).get();
        if (userDoc == null || !userDoc.exists) {
          await _firestore?.collection('users').doc(user.uid).set({
            'name': user.displayName ?? 'Customer',
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'phone': user.phoneNumber ?? '',
            'role': 'customer',
            'createdAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        }
      }
      return user;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
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
        final normalizedEmail = email.trim().toLowerCase();
        final bool isAdminEmail = normalizedEmail.startsWith('admin@') || normalizedEmail.contains('admin');
        await _firestore?.collection('users').doc(cred.user!.uid).set({
          'name': name.trim(),
          'email': email.trim(),
          'photoUrl': '',
          'phone': '',
          'role': isAdminEmail ? 'admin' : 'customer',
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

  Future<void> changePassword(String newPassword, {String? currentPassword}) async {
    try {
      final user = _auth?.currentUser;
      if (user == null) throw Exception('No user signed in');
      if (currentPassword != null && currentPassword.isNotEmpty && user.email != null) {
        final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
        await user.reauthenticateWithCredential(cred);
      }
      await user.updatePassword(newPassword);
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

  Future<void> addProduct(ProductModel product) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final docRef = product.id.isEmpty
          ? firestore.collection('products').doc()
          : firestore.collection('products').doc(product.id);
      final finalProduct = product.copyWith(id: docRef.id);
      await docRef.set(finalProduct.toMap());
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore
          .collection('products')
          .doc(product.id)
          .set(product.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore.collection('products').doc(productId).delete();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  Future<void> updateProductStock(String productId, int newStock) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore.collection('products').doc(productId).update({
        'stockCount': newStock,
        'inStock': newStock > 0,
      });
    } catch (e) {
      debugPrint('Error updating stock: $e');
      rethrow;
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
      final userOrderRef = firestore.collection('users').doc(order.userId).collection('orders').doc(order.id);
      final rootOrderRef = firestore.collection('orders').doc(order.id);

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

        // Save order in both user subcollection and root orders collection
        final orderData = order.toMap();
        transaction.set(userOrderRef, orderData);
        transaction.set(rootOrderRef, orderData);
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

  Stream<List<OrderModel>> streamAllOrders() {
    final firestore = _firestore;
    if (firestore == null) return Stream.value([]);
    return firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> updateOrderStatus(String orderId, String userId, OrderStatus newStatus) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final batch = firestore.batch();
      final rootOrderRef = firestore.collection('orders').doc(orderId);
      batch.update(rootOrderRef, {'status': newStatus.name});

      if (userId.isNotEmpty) {
        final userOrderRef = firestore
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(orderId);
        batch.update(userOrderRef, {'status': newStatus.name});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
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

  Stream<List<PromoCodeModel>> streamPromoCodes() {
    final firestore = _firestore;
    if (firestore == null) return Stream.value([]);
    return firestore.collection('promoCodes').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PromoCodeModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> savePromoCode(PromoCodeModel promo) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore
          .collection('promoCodes')
          .doc(promo.code.trim().toUpperCase())
          .set(promo.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving promo code: $e');
      rethrow;
    }
  }

  Future<void> deletePromoCode(String code) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore
          .collection('promoCodes')
          .doc(code.trim().toUpperCase())
          .delete();
    } catch (e) {
      debugPrint('Error deleting promo code: $e');
      rethrow;
    }
  }

  Future<void> togglePromoCodeStatus(String code, bool isActive) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore
          .collection('promoCodes')
          .doc(code.trim().toUpperCase())
          .update({'isActive': isActive});
    } catch (e) {
      debugPrint('Error toggling promo status: $e');
      rethrow;
    }
  }

  // ===================== USERS & CUSTOMERS =====================

  Stream<List<Map<String, dynamic>>> streamAllUsers() {
    final firestore = _firestore;
    if (firestore == null) return Stream.value([]);
    return firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  Future<void> setUserRole(String userId, String role) async {
    final firestore = _firestore;
    if (firestore == null || userId.isEmpty) return;
    try {
      await firestore.collection('users').doc(userId).set({'role': role}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error setting user role: $e');
      rethrow;
    }
  }

  // ===================== CATEGORIES =====================

  Stream<List<CategoryModel>> streamCategories() {
    final firestore = _firestore;
    if (firestore == null) return Stream.value([]);
    return firestore
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((d) => CategoryModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addCategory(String name, {String? icon, String? imageUrl}) async {
    final firestore = _firestore;
    if (firestore == null || name.trim().isEmpty) return;
    final docRef = firestore.collection('categories').doc();
    final category = CategoryModel(
      id: docRef.id,
      name: name.trim(),
      icon: icon,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
    await docRef.set(category.toMap());
  }

  Future<void> deleteCategory(String categoryId) async {
    final firestore = _firestore;
    if (firestore == null || categoryId.isEmpty) return;
    await firestore.collection('categories').doc(categoryId).delete();
  }

  Future<void> seedDefaultCategories() async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final existing = await firestore.collection('categories').limit(1).get();
      if (existing.docs.isNotEmpty) return;
      final defaultCats = [
        'Electronics',
        'Footwear',
        'Audio',
        'Watches',
        'Fashion',
        'Accessories',
        'Home & Living',
      ];
      final batch = firestore.batch();
      for (final cat in defaultCats) {
        final ref = firestore.collection('categories').doc();
        batch.set(ref, CategoryModel(id: ref.id, name: cat, createdAt: DateTime.now()).toMap());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error seeding categories: $e');
    }
  }

  // ===================== BRANDS =====================

  Stream<List<BrandModel>> streamBrands() {
    final firestore = _firestore;
    if (firestore == null) return Stream.value([]);
    return firestore
        .collection('brands')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((d) => BrandModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addBrand(String name, {String? logoUrl}) async {
    final firestore = _firestore;
    if (firestore == null || name.trim().isEmpty) return;
    final docRef = firestore.collection('brands').doc();
    final brand = BrandModel(
      id: docRef.id,
      name: name.trim(),
      logoUrl: logoUrl,
      createdAt: DateTime.now(),
    );
    await docRef.set(brand.toMap());
  }

  Future<void> deleteBrand(String brandId) async {
    final firestore = _firestore;
    if (firestore == null || brandId.isEmpty) return;
    await firestore.collection('brands').doc(brandId).delete();
  }

  Future<void> seedDefaultBrands() async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final existing = await firestore.collection('brands').limit(1).get();
      if (existing.docs.isNotEmpty) return;
      final defaultBrands = [
        'Apple',
        'Nike',
        'Sony',
        'Adidas',
        'Samsung',
        'Puma',
        'Rolex',
        'Bose',
        'Zara',
        'Casio',
      ];
      final batch = firestore.batch();
      for (final b in defaultBrands) {
        final ref = firestore.collection('brands').doc();
        batch.set(ref, BrandModel(id: ref.id, name: b, createdAt: DateTime.now()).toMap());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error seeding brands: $e');
    }
  }

  // ===================== ATTRIBUTES (COLORS & SIZES) =====================

  Stream<Map<String, dynamic>> streamAttributes() {
    final firestore = _firestore;
    if (firestore == null) return Stream.value({});
    return firestore
        .collection('storeSettings')
        .doc('attributes')
        .snapshots()
        .map((snap) => snap.data() ?? {});
  }

  Future<void> addAttributeItem(String type, String value) async {
    final firestore = _firestore;
    if (firestore == null || value.trim().isEmpty) return;
    await firestore.collection('storeSettings').doc('attributes').set({
      type: FieldValue.arrayUnion([value.trim()]),
    }, SetOptions(merge: true));
  }

  Future<void> removeAttributeItem(String type, String value) async {
    final firestore = _firestore;
    if (firestore == null) return;
    await firestore.collection('storeSettings').doc('attributes').set({
      type: FieldValue.arrayRemove([value]),
    }, SetOptions(merge: true));
  }

  Future<void> seedDefaultAttributes() async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final doc = await firestore.collection('storeSettings').doc('attributes').get();
      if (doc.exists && doc.data() != null && doc.data()!.isNotEmpty) return;
      await firestore.collection('storeSettings').doc('attributes').set({
        'colors': [
          'Black',
          'White',
          'Navy Blue',
          'Crimson Red',
          'Forest Green',
          'Space Grey',
          'Rose Gold',
          'Silver',
          'Beige',
          'Midnight',
        ],
        'sizes': [
          'XS',
          'S',
          'M',
          'L',
          'XL',
          'XXL',
          'US 7',
          'US 8',
          'US 9',
          'US 10',
          'US 11',
          'US 12',
          'One Size',
        ],
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error seeding attributes: $e');
    }
  }
}
