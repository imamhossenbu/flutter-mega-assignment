import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/brand_model.dart';

abstract class BrandRepository {
  Stream<List<BrandModel>> streamBrands();
  Future<List<BrandModel>> getBrands();
  Future<void> addBrand(String name, [String? logoUrl]);
  Future<void> deleteBrand(String brandId);
}

class FirestoreBrandRepository implements BrandRepository {
  final FirebaseFirestore _firestore;

  FirestoreBrandRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _brandsRef =>
      _firestore.collection('brands');

  @override
  Stream<List<BrandModel>> streamBrands() {
    return _brandsRef.snapshots().map(
          (snap) =>
              snap.docs.map((d) => BrandModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  @override
  Future<List<BrandModel>> getBrands() async {
    final snap = await _brandsRef.get();
    return snap.docs.map((d) => BrandModel.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<void> addBrand(String name, [String? logoUrl]) async {
    final docRef = _brandsRef.doc();
    final brand = BrandModel(
      id: docRef.id,
      name: name.trim(),
      logoUrl: logoUrl,
      createdAt: DateTime.now(),
    );
    await docRef.set(brand.toMap());
  }

  @override
  Future<void> deleteBrand(String brandId) async {
    await _brandsRef.doc(brandId).delete();
  }
}
