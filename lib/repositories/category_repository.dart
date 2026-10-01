import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

abstract class CategoryRepository {
  Stream<List<CategoryModel>> streamCategories();
  Future<List<CategoryModel>> getCategories();
  Future<void> addCategory(String name, [List<String>? subcategories]);
  Future<void> addSubcategory(String categoryId, String subcategory);
  Future<void> removeSubcategory(String categoryId, String subcategory);
  Future<void> deleteCategory(String categoryId);
}

class FirestoreCategoryRepository implements CategoryRepository {
  final FirebaseFirestore _firestore;

  FirestoreCategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _firestore.collection('categories');

  @override
  Stream<List<CategoryModel>> streamCategories() {
    return _categoriesRef.snapshots().map(
          (snap) => snap.docs
              .map((d) => CategoryModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final snap = await _categoriesRef.get();
    return snap.docs.map((d) => CategoryModel.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<void> addCategory(String name, [List<String>? subcategories]) async {
    final docRef = _categoriesRef.doc();
    final cat = CategoryModel(
      id: docRef.id,
      name: name.trim(),
      subcategories: subcategories ?? const [],
      createdAt: DateTime.now(),
    );
    await docRef.set(cat.toMap());
  }

  @override
  Future<void> addSubcategory(String categoryId, String subcategory) async {
    await _categoriesRef.doc(categoryId).update({
      'subcategories': FieldValue.arrayUnion([subcategory.trim()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeSubcategory(String categoryId, String subcategory) async {
    await _categoriesRef.doc(categoryId).update({
      'subcategories': FieldValue.arrayRemove([subcategory.trim()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _categoriesRef.doc(categoryId).delete();
  }
}
