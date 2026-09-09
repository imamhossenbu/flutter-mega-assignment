import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  String get userId => _user?.uid ?? 'guest_user';
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    initAuth();
  }

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await FirebaseService.instance.ensureAuthenticated();
    } catch (e) {
      debugPrint('Auth initialization warning: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInAnonymously() async {
    try {
      _isLoading = true;
      notifyListeners();
      _user = await FirebaseService.instance.ensureAuthenticated();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
