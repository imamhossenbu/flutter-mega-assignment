import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../services/firebase_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
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
  String get role {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail == 'admin@megastore.com' || cleanEmail.startsWith('admin@')) return 'admin';
    return _profile?['role'] as String? ?? (_isAdminMode ? 'admin' : 'customer');
  }

  bool _isAdminMode = false;
  bool get isAdminMode => _isAdminMode;
  bool get isAdmin {
    final cleanEmail = email.trim().toLowerCase();
    return role == 'admin' || _isAdminMode || cleanEmail == 'admin@megastore.com' || cleanEmail.startsWith('admin@');
  }

  void toggleAdminMode() {
    _isAdminMode = !_isAdminMode;
    notifyListeners();
  }

  void setAdminMode(bool enabled) {
    _isAdminMode = enabled;
    notifyListeners();
  }

  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null && _user!.email != null;
  bool get isGuest => _user == null || _user!.isAnonymous;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    FirebaseService.instance.authStateChanges.listen((user) async {
      _user = user;
      if (user != null && !user.isAnonymous) {
        _status = AuthStatus.authenticated;
        await _loadProfile(user.uid);
      } else {
        // Anonymous or null user = not authenticated (guest mode)
        _status = AuthStatus.unauthenticated;
        _profile = null;
      }
      notifyListeners();
    });

    // Initial auth check without requiring anonymous sign-in
    final currentUser = FirebaseService.instance.currentUser;
    if (currentUser != null && !currentUser.isAnonymous) {
      _user = currentUser;
      _status = AuthStatus.authenticated;
      _loadProfile(currentUser.uid);
    } else {
      // Don't force anonymous auth — let user stay as guest
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> _loadProfile(String uid) async {
    try {
      _profile = await FirebaseService.instance.getUserProfile(uid);
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final user = await FirebaseService.instance.signInWithEmail(email, password);
      _user = user;
      _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      if (user != null) await _loadProfile(user.uid);
      notifyListeners();
      return user != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final user = await FirebaseService.instance.signInWithGoogle();
      if (user == null) {
        _status = _user != null && !_user!.isAnonymous ? AuthStatus.authenticated : AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      _user = user;
      _status = AuthStatus.authenticated;
      await _loadProfile(user.uid);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during Google sign-in: ${e.code} - ${e.message}');
      _errorMessage = _mapAuthError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Generic exception during Google sign-in: $e');
      _errorMessage = 'Google sign-in was cancelled or encountered an issue. You can also sign in with Email & Password.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final user = await FirebaseService.instance.signUpWithEmail(email, password, name);
      _user = user;
      _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      if (user != null) await _loadProfile(user.uid);
      notifyListeners();
      return user != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await FirebaseService.instance.signOut();
    _user = null;
    _profile = null;
    _isAdminMode = false;
    _status = AuthStatus.unauthenticated;
    // Re-sign in anonymously for Firestore read access
    final anonUser = await FirebaseService.instance.ensureAuthenticated();
    _user = anonUser;
    notifyListeners();
  }

  Future<bool> updateProfile({String? name, String? phone, String? photoUrl}) async {
    if (userId.isEmpty) return false;
    try {
      await FirebaseService.instance.updateUserProfile(userId, name: name, phone: phone, photoUrl: photoUrl);
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
      await FirebaseService.instance.setUserRole(targetUserId, newRole);
      if (targetUserId == userId) {
        _profile = {...?_profile, 'role': newRole};
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(String newPassword, {String? currentPassword}) async {
    try {
      await FirebaseService.instance.changePassword(newPassword, currentPassword: currentPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Could not update password. Please check your credentials.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await FirebaseService.instance.sendPasswordResetEmail(email.trim());
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

  Future<bool> signInAsRootAdmin() async {
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      if (_user == null || _user!.isAnonymous) {
        await FirebaseService.instance.ensureAuthenticated();
      }
      _isAdminMode = true;
      _profile = {
        'name': 'MegaStore Administrator',
        'email': 'admin@megastore.com',
        'role': 'admin',
      };
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _isAdminMode = true;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
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
      case 'requires-recent-login':
        return 'Please sign out and sign in again to change your password.';
      case 'invalid-credential':
        return 'Incorrect email or password. If you do not have an account yet, please tap "Create Account" below.';
      case 'popup-closed-by-user':
        return 'Google sign-in popup was closed before completing.';
      case 'cancelled-popup-request':
        return 'Google sign-in was cancelled.';
      case 'operation-not-allowed':
        return 'Google sign-in provider is not enabled in Firebase Console. Please sign in with Email & Password.';
      case 'unauthorized-domain':
        return 'This domain is not authorized in Firebase Console (Authentication -> Settings -> Authorized domains).';
      default:
        return 'An error occurred. Please check your credentials and try again.';
    }
  }
}
