import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/brand_model.dart';
import '../models/category_model.dart';
import '../models/promo_code_model.dart';
import '../services/firebase_service.dart';

class AdminProvider extends ChangeNotifier {
  List<PromoCodeModel> _promoCodes = [];
  List<Map<String, dynamic>> _users = [];
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  List<String> _colors = [
    'Black',
    'White',
    'Navy Blue',
    'Crimson Red',
    'Forest Green',
    'Space Grey',
    'Rose Gold',
    'Silver',
    'Beige',
    'Midnight',
  ];
  List<String> _sizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'US 7',
    'US 8',
    'US 9',
    'US 10',
    'US 11',
    'US 12',
    'One Size',
  ];

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _promoSub;
  StreamSubscription? _usersSub;
  StreamSubscription? _categorySub;
  StreamSubscription? _brandSub;
  StreamSubscription? _attributeSub;

  List<PromoCodeModel> get promoCodes => _promoCodes;
  List<Map<String, dynamic>> get users => _users;
  List<CategoryModel> get categories => _categories;
  List<BrandModel> get brands => _brands;
  List<String> get colors => _colors;
  List<String> get sizes => _sizes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalUsersCount => _users.length;
  int get adminUsersCount => _users.where((u) => u['role'] == 'admin').length;
  int get activePromoCount => _promoCodes.where((p) => p.isValid).length;
  int get totalCategoriesCount => _categories.length;
  int get totalBrandsCount => _brands.length;

  AdminProvider() {
    initAdminListeners();
  }

  void initAdminListeners() {
    _isLoading = true;
    notifyListeners();

    try {
      FirebaseService.instance.seedDefaultCategories();
      FirebaseService.instance.seedDefaultBrands();
      FirebaseService.instance.seedDefaultAttributes();
    } catch (_) {}

    try {
      _promoSub?.cancel();
      _promoSub = FirebaseService.instance.streamPromoCodes().listen(
        (codes) {
          _promoCodes = codes;
          _isLoading = false;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Admin promo stream error: $err');
          _isLoading = false;
          notifyListeners();
        },
      );

      _usersSub?.cancel();
      _usersSub = FirebaseService.instance.streamAllUsers().listen(
        (allUsers) {
          _users = allUsers;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Admin users stream error: $err');
        },
      );

      _categorySub?.cancel();
      _categorySub = FirebaseService.instance.streamCategories().listen(
        (cats) {
          _categories = cats;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Admin categories stream error: $err');
        },
      );

      _brandSub?.cancel();
      _brandSub = FirebaseService.instance.streamBrands().listen(
        (b) {
          _brands = b;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Admin brands stream error: $err');
        },
      );

      _attributeSub?.cancel();
      _attributeSub = FirebaseService.instance.streamAttributes().listen(
        (attrs) {
          if (attrs['colors'] != null) {
            _colors = List<String>.from(attrs['colors'] as List);
          }
          if (attrs['sizes'] != null) {
            _sizes = List<String>.from(attrs['sizes'] as List);
          }
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Admin attributes stream error: $err');
        },
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Categories
  Future<bool> addCategory(String name) async {
    try {
      await FirebaseService.instance.addCategory(name);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await FirebaseService.instance.deleteCategory(id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addSubcategory(String categoryId, String subcategoryName) async {
    try {
      await FirebaseService.instance.addSubcategory(categoryId, subcategoryName);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSubcategory(String categoryId, String subcategoryName) async {
    try {
      await FirebaseService.instance.deleteSubcategory(categoryId, subcategoryName);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Brands
  Future<bool> addBrand(String name) async {
    try {
      await FirebaseService.instance.addBrand(name);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBrand(String id) async {
    try {
      await FirebaseService.instance.deleteBrand(id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Colors & Sizes (Variants)
  Future<bool> addColor(String color) async {
    try {
      await FirebaseService.instance.addAttributeItem('colors', color);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeColor(String color) async {
    try {
      await FirebaseService.instance.removeAttributeItem('colors', color);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addSize(String size) async {
    try {
      await FirebaseService.instance.addAttributeItem('sizes', size);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeSize(String size) async {
    try {
      await FirebaseService.instance.removeAttributeItem('sizes', size);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Promo Codes
  Future<bool> savePromoCode(PromoCodeModel promo) async {
    try {
      await FirebaseService.instance.savePromoCode(promo);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePromoCode(String code) async {
    try {
      await FirebaseService.instance.deletePromoCode(code);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> togglePromoStatus(String code, bool isActive) async {
    try {
      await FirebaseService.instance.togglePromoCodeStatus(code, isActive);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUserRole(String userId, String role) async {
    try {
      await FirebaseService.instance.setUserRole(userId, role);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await FirebaseService.instance.deleteUser(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<int> clearAllUsersExceptAdmin() async {
    final count = await FirebaseService.instance.deleteAllUsersExceptAdmin();
    notifyListeners();
    return count;
  }

  @override
  void dispose() {
    _promoSub?.cancel();
    _usersSub?.cancel();
    _categorySub?.cancel();
    _brandSub?.cancel();
    _attributeSub?.cancel();
    super.dispose();
  }
}
