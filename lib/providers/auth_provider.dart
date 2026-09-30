import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  User? _user;
  AuthStatus _status = AuthStatus.loading;
  String? _errorMessage;
  Map<String, dynamic>? _profile;

  User? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get profile => _profile;

  String get userId => _user?.uid ?? '';
  String get displayName =>
      _profile?['name'] as String? ?? _user?.displayName ?? 'Guest Shopper';
  String get email => _user?.email ?? '';
  String get photoUrl => _profile?['photoUrl'] as String? ?? _user?.photoURL ?? '';
  String get phone => _profile?['phone'] as String? ?? '';
  String get role => _profile?['role'] as String? ?? (_isAdminMode ? 'admin' : 'customer');

  bool _isAdminMode = false;
  bool get isAdminMode => _isAdminMode;
  bool get isAdmin => role == 'admin' || _isAdminMode;

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
      _errorMessage = _mapAuthError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Google sign-in failed. Please try again.';
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

  Future<bool> updateProfile({String? name, String? phone}) async {
    if (userId.isEmpty) return false;
    try {
      await FirebaseService.instance.updateUserProfile(userId, name: name, phone: phone);
      final updated = Map<String, dynamic>.from(_profile ?? {});
      if (name != null) updated['name'] = name;
      if (phone != null) updated['phone'] = phone;
      _profile = updated;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
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
      default:
        return 'An error occurred. Please check your credentials and try again.';
    }
  }
}
