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

    try {
      // 1. Direct document by ID in Firebase
      final doc = await _promoRef.doc(cleanCode).get();
      if (doc.exists && doc.data() != null) {
        final promo = PromoCodeModel.fromMap(doc.data()!, doc.id);
        if (promo.isValidForAmount(currentSubtotal)) {
          return promo;
        }
        return null;
      }

      // 2. Query by 'code' field matching cleanCode
      final query = await _promoRef.where('code', isEqualTo: cleanCode).limit(1).get();
      if (query.docs.isNotEmpty) {
        final promo = PromoCodeModel.fromMap(query.docs.first.data(), query.docs.first.id);
        if (promo.isValidForAmount(currentSubtotal)) {
          return promo;
        }
        return null;
      }

      // 3. Scan all docs in promo_codes collection for case-insensitive match
      final allDocs = await _promoRef.get();
      for (final d in allDocs.docs) {
        final data = d.data();
        final docCode = (data['code'] as String? ?? d.id).trim().toUpperCase();
        if (docCode == cleanCode) {
          final promo = PromoCodeModel.fromMap(data, d.id);
          if (promo.isValidForAmount(currentSubtotal)) {
            return promo;
          }
          return null;
        }
      }
    } catch (_) {
      // Firestore read error
    }

    return null;
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
