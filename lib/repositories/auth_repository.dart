import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
  });

  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();

  Future<Map<String, dynamic>?> getUserProfile(String uid);
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? photoUrl,
  });

  Future<List<Map<String, dynamic>>> getAllUsers();
  Future<void> updateUserRole({required String uid, required String role});
  Future<void> deleteUserDoc(String uid);
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      await user.updateDisplayName(name.trim());
      // Security rules require role to be 'customer' on creation
      await _firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': 'customer',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    return cred;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    if (uid.isEmpty) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name.trim();
    if (phone != null) updates['phone'] = phone.trim();
    if (photoUrl != null) updates['photoUrl'] = photoUrl.trim();

    await _firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));
    if (name != null && _auth.currentUser?.uid == uid) {
      await _auth.currentUser?.updateDisplayName(name.trim());
    }
    if (photoUrl != null && _auth.currentUser?.uid == uid) {
      await _auth.currentUser?.updatePhotoURL(photoUrl.trim());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snap = await _firestore.collection('users').get();
    return snap.docs.map((d) {
      final data = d.data();
      data['uid'] = d.id;
      return data;
    }).toList();
  }

  @override
  Future<void> updateUserRole({required String uid, required String role}) async {
    await _firestore.collection('users').doc(uid).update({
      'role': role,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteUserDoc(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}
