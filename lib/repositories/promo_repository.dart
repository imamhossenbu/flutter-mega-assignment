import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promo_code_model.dart';

abstract class PromoRepository {
  Stream<List<PromoCodeModel>> streamPromoCodes();
  Future<List<PromoCodeModel>> getPromoCodes();
  Future<PromoCodeModel?> validatePromoCode(String code, double currentSubtotal);
  Future<void> addPromoCode(PromoCodeModel promo);
  Future<void> updatePromoCode(PromoCodeModel promo);
  Future<void> togglePromoStatus(String codeId, bool isActive);
  Future<void> deletePromoCode(String codeId);
}

class FirestorePromoRepository implements PromoRepository {
  final FirebaseFirestore _firestore;

  FirestorePromoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _promoRef =>
      _firestore.collection('promo_codes');

  @override
  Stream<List<PromoCodeModel>> streamPromoCodes() {
    return _promoRef.snapshots().map(
          (snap) => snap.docs
              .map((d) => PromoCodeModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  @override
  Future<List<PromoCodeModel>> getPromoCodes() async {
    final snap = await _promoRef.get();
    return snap.docs.map((d) => PromoCodeModel.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<PromoCodeModel?> validatePromoCode(String code, double currentSubtotal) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return null;

    final doc = await _promoRef.doc(cleanCode).get();
    if (!doc.exists || doc.data() == null) {
      // Also try query by code field in case docId differs
      final query = await _promoRef.where('code', isEqualTo: cleanCode).limit(1).get();
      if (query.docs.isEmpty) return null;
      final promo = PromoCodeModel.fromMap(query.docs.first.data(), query.docs.first.id);
      return promo.isValidForAmount(currentSubtotal) ? promo : null;
    }

    final promo = PromoCodeModel.fromMap(doc.data()!, doc.id);
    if (!promo.isValidForAmount(currentSubtotal)) {
      return null;
    }
    return promo;
  }

  @override
  Future<void> addPromoCode(PromoCodeModel promo) async {
    final cleanCode = promo.code.trim().toUpperCase();
    final data = promo.copyWith(code: cleanCode).toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _promoRef.doc(cleanCode).set(data);
  }

  @override
  Future<void> updatePromoCode(PromoCodeModel promo) async {
    final cleanCode = promo.code.trim().toUpperCase();
    final data = promo.copyWith(code: cleanCode).toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _promoRef.doc(promo.id.isNotEmpty ? promo.id : cleanCode).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> togglePromoStatus(String codeId, bool isActive) async {
    await _promoRef.doc(codeId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deletePromoCode(String codeId) async {
    await _promoRef.doc(codeId).delete();
  }
}
