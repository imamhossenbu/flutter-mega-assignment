import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';

class SeedDataService {
  static Future<bool> seedInitialProductsIfNeeded() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('products').limit(1).get();

      if (snapshot.docs.isEmpty) {
        debugPrint('Products collection is empty. Seeding initial products to Firestore...');
        await reseedAllProducts();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Seeding error (will use local fallback products): $e');
      return false;
    }
  }

  static Future<void> reseedAllProducts() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final product in AppConstants.initialProducts) {
        final docRef = firestore.collection('products').doc(product.id);
        batch.set(docRef, product.toMap());
      }

      await batch.commit();
      debugPrint('Successfully seeded ${AppConstants.initialProducts.length} products to Firestore.');
    } catch (e) {
      debugPrint('Error reseeding products to Firestore: $e');
    }
  }
}
