import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../repositories/auth_repository.dart';
import '../services/cloudinary_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authSub;

  User? _user;
  AuthStatus _status = AuthStatus.loading;
  String? _errorMessage;
  Map<String, dynamic>? _profile;
  bool _isUploadingPhoto = false;

  User? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get profile => _profile;
  bool get isUploadingPhoto => _isUploadingPhoto;

  String get userId => _user?.uid ?? '';
  String get displayName =>
      _profile?['name'] as String? ?? _user?.displayName ?? 'Guest Shopper';
  String get email => _user?.email ?? '';
  String get photoUrl => _profile?['photoUrl'] as String? ?? _user?.photoURL ?? '';
  String get phone => _profile?['phone'] as String? ?? '';

  String get role => _profile?['role'] as String? ?? 'customer';
  bool get isAdmin => role == 'admin';

  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null && _user!.email != null;
  bool get isGuest => _user == null || _user!.isAnonymous;

  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? FirebaseAuthRepository() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSub = _authRepository.authStateChanges.listen((user) async {
      _user = user;
      if (user != null && !user.isAnonymous) {
        _status = AuthStatus.authenticated;
        await _loadProfile(user.uid);
      } else {
        _status = AuthStatus.unauthenticated;
        _profile = null;
      }
      notifyListeners();
    });

    final currentUser = _authRepository.currentUser;
    if (currentUser != null && !currentUser.isAnonymous) {
      _user = currentUser;
      _status = AuthStatus.authenticated;
      _loadProfile(currentUser.uid);
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> _loadProfile(String uid) async {
    try {
      _profile = await _authRepository.getUserProfile(uid);
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final cred = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = cred.user;
      _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      if (_user != null) await _loadProfile(_user!.uid);
      notifyListeners();
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Sign in failed. Please check your credentials.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name, [String phone = '']) async {
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final cred = await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      _user = cred.user;
      _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      if (_user != null) await _loadProfile(_user!.uid);
      notifyListeners();
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed. Please try again.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    _user = null;
    _profile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> updateProfile({String? name, String? phone, String? photoUrl}) async {
    if (userId.isEmpty) return false;
    try {
      await _authRepository.updateUserProfile(
        uid: userId,
        name: name,
        phone: phone,
        photoUrl: photoUrl,
      );
      final updated = Map<String, dynamic>.from(_profile ?? {});
      if (name != null) updated['name'] = name;
      if (phone != null) updated['phone'] = phone;
      if (photoUrl != null) updated['photoUrl'] = photoUrl;
      _profile = updated;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadProfileImage({ImageSource source = ImageSource.gallery}) async {
    if (userId.isEmpty) return null;
    _isUploadingPhoto = true;
    notifyListeners();

    try {
      final picked = await CloudinaryService.instance.pickImage(source: source);
      if (picked == null) {
        _isUploadingPhoto = false;
        notifyListeners();
        return null;
      }

      final bytes = await picked.readAsBytes();
      final filename = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final photoUrl = await CloudinaryService.instance.uploadImageBytes(bytes, filename: filename);

      if (photoUrl != null && photoUrl.isNotEmpty) {
        await updateProfile(photoUrl: photoUrl);
        _isUploadingPhoto = false;
        notifyListeners();
        return photoUrl;
      }
    } catch (e) {
      debugPrint('Profile photo upload error: $e');
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> setRole(String targetUserId, String newRole) async {
    try {
      await _authRepository.updateUserRole(uid: targetUserId, role: newRole);
      if (targetUserId == userId) {
        _profile = {...?_profile, 'role': newRole};
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(String newPassword, {required String currentPassword}) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final user = _authRepository.currentUser;
      if (user == null || user.email == null) {
        _errorMessage = 'User not logged in';
        notifyListeners();
        return false;
      }
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Could not update password. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepository.sendPasswordResetEmail(email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Could not send password reset email. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please tap "Create Account" below to register.';
      case 'wrong-password':
        return 'Incorrect password. Please verify and try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please verify your credentials.';
      default:
        return 'Authentication error: $code. Please try again.';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
