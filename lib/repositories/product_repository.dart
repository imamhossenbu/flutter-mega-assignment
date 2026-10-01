import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getProducts({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? category,
    bool includeDeleted = false,
  });

  Stream<List<ProductModel>> streamProducts({bool includeDeleted = false});
  Future<ProductModel?> getProductById(String id);
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> softDeleteProduct(String productId);
  Future<void> quickRestock(String productId, int addAmount);
  Future<void> updateStock(String productId, int newStock);

  // Wishlist subcollection: users/{userId}/wishlist/{productId}
  Stream<List<ProductModel>> streamWishlist(String userId);
  Future<void> toggleWishlist(String userId, ProductModel product);

  // Reviews subcollection: products/{productId}/reviews/{reviewId}
  Stream<List<ReviewModel>> streamReviews(String productId);
  Future<bool> hasUserReviewed(String productId, String userId);
  Future<void> addReview(String productId, ReviewModel review);
}

class FirestoreProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;

  FirestoreProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  @override
  Future<List<ProductModel>> getProducts({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? category,
    bool includeDeleted = false,
  }) async {
    Query<Map<String, dynamic>> query = _productsRef;

    if (!includeDeleted) {
      query = query.where('isDeleted', isEqualTo: false);
    }

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    query = query.limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.get();
    return snap.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList();
  }

  @override
  Stream<List<ProductModel>> streamProducts({bool includeDeleted = false}) {
    Query<Map<String, dynamic>> query = _productsRef;
    if (!includeDeleted) {
      query = query.where('isDeleted', isEqualTo: false);
    }
    return query.snapshots().map(
          (snap) =>
              snap.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    final doc = await _productsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ProductModel.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    final docRef = _productsRef.doc();
    final data = product.toMap();
    data['id'] = docRef.id;
    data['createdAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final data = product.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _productsRef.doc(product.id).update(data);
  }

  @override
  Future<void> softDeleteProduct(String productId) async {
    await _productsRef.doc(productId).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> quickRestock(String productId, int addAmount) async {
    await _productsRef.doc(productId).update({
      'stockCount': FieldValue.increment(addAmount),
      'inStock': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateStock(String productId, int newStock) async {
    await _productsRef.doc(productId).update({
      'stockCount': newStock,
      'inStock': newStock > 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<ProductModel>> streamWishlist(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList());
  }

  @override
  Future<void> toggleWishlist(String userId, ProductModel product) async {
    if (userId.isEmpty) return;
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(product.id);
    final snap = await docRef.get();
    if (snap.exists) {
      await docRef.delete();
    } else {
      await docRef.set(product.toMap());
    }
  }

  @override
  Stream<List<ReviewModel>> streamReviews(String productId) {
    return _productsRef
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ReviewModel.fromMap(d.data(), d.id)).toList());
  }

  @override
  Future<bool> hasUserReviewed(String productId, String userId) async {
    final snap = await _productsRef
        .doc(productId)
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  @override
  Future<void> addReview(String productId, ReviewModel review) async {
    final ref = _productsRef.doc(productId).collection('reviews').doc(review.id);
    await ref.set(review.toMap());

    // Update product rating
    final allReviewsSnap = await _productsRef.doc(productId).collection('reviews').get();
    if (allReviewsSnap.docs.isNotEmpty) {
      final total = allReviewsSnap.docs.fold<double>(
        0.0,
        (acc, doc) => acc + ((doc.data()['rating'] as num?)?.toDouble() ?? 5.0),
      );
      final avg = total / allReviewsSnap.docs.length;
      await _productsRef.doc(productId).update({
        'rating': double.parse(avg.toStringAsFixed(1)),
        'reviewCount': allReviewsSnap.docs.length,
      });
    }
  }
}
