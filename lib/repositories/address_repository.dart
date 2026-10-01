import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address_model.dart';

abstract class AddressRepository {
  Stream<List<AddressModel>> streamAddresses(String userId);
  Future<List<AddressModel>> getAddresses(String userId);
  Future<void> addAddress(String userId, AddressModel address);
  Future<void> updateAddress(String userId, AddressModel address);
  Future<void> deleteAddress(String userId, String addressId);
  Future<void> setDefaultAddress(String userId, String addressId);
}

class FirestoreAddressRepository implements AddressRepository {
  final FirebaseFirestore _firestore;

  FirestoreAddressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _addressRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('addresses');

  @override
  Stream<List<AddressModel>> streamAddresses(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _addressRef(userId).snapshots().map(
          (snap) => snap.docs
              .map((d) => AddressModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  @override
  Future<List<AddressModel>> getAddresses(String userId) async {
    if (userId.isEmpty) return [];
    final snap = await _addressRef(userId).get();
    return snap.docs.map((d) => AddressModel.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<void> addAddress(String userId, AddressModel address) async {
    final ref = _addressRef(userId);
    final docRef = ref.doc();

    // If marked default, unset others first
    if (address.isDefault) {
      await _unsetExistingDefaults(userId);
    }

    final data = address.toMap();
    data['id'] = docRef.id;
    data['createdAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }

  @override
  Future<void> updateAddress(String userId, AddressModel address) async {
    if (address.isDefault) {
      await _unsetExistingDefaults(userId, exceptId: address.id);
    }
    final data = address.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _addressRef(userId).doc(address.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteAddress(String userId, String addressId) async {
    await _addressRef(userId).doc(addressId).delete();
  }

  @override
  Future<void> setDefaultAddress(String userId, String addressId) async {
    await _unsetExistingDefaults(userId, exceptId: addressId);
    await _addressRef(userId).doc(addressId).update({
      'isDefault': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _unsetExistingDefaults(String userId, {String? exceptId}) async {
    final snap = await _addressRef(userId).where('isDefault', isEqualTo: true).get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      if (doc.id != exceptId) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }
    await batch.commit();
  }
}
