import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/brand_model.dart';
import '../models/category_model.dart';
import '../models/promo_code_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/brand_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/promo_repository.dart';

class AdminProvider extends ChangeNotifier {
  final CategoryRepository _categoryRepository;
  final BrandRepository _brandRepository;
  final PromoRepository _promoRepository;
  final AuthRepository _authRepository;
  final ProductRepository _productRepository;

  List<PromoCodeModel> _promoCodes = [];
  List<Map<String, dynamic>> _users = [];
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  final List<String> _colors = [
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
  final List<String> _sizes = [
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
  StreamSubscription? _categorySub;
  StreamSubscription? _brandSub;

  static final List<PromoCodeModel> _samplePromoCodes = [
    PromoCodeModel(
      id: 'promo_1',
      code: 'MEGA20',
      discountPercent: 0.20,
      description: 'Grand Launch Sale - 20% off',
      isActive: true,
      minOrderAmount: 1000,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    ),
    PromoCodeModel(
      id: 'promo_2',
      code: 'EID500',
      discountPercent: 0.15,
      description: 'Special Festivity Voucher',
      isActive: true,
      minOrderAmount: 2500,
      expiresAt: DateTime.now().add(const Duration(days: 15)),
    ),
    PromoCodeModel(
      id: 'promo_3',
      code: 'FREESHIP',
      discountPercent: 0.05,
      description: 'Delivery Charge Discount Voucher',
      isActive: true,
      expiresAt: DateTime.now().add(const Duration(days: 60)),
    ),
  ];



  List<PromoCodeModel> get promoCodes =>
      _promoCodes.isEmpty ? _samplePromoCodes : _promoCodes;
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

  AdminProvider({
    CategoryRepository? categoryRepository,
    BrandRepository? brandRepository,
    PromoRepository? promoRepository,
    AuthRepository? authRepository,
    ProductRepository? productRepository,
  })  : _categoryRepository = categoryRepository ?? FirestoreCategoryRepository(),
        _brandRepository = brandRepository ?? FirestoreBrandRepository(),
        _promoRepository = promoRepository ?? FirestorePromoRepository(),
        _authRepository = authRepository ?? FirebaseAuthRepository(),
        _productRepository = productRepository ?? FirestoreProductRepository() {
    initAdminListeners();
  }

  void initAdminListeners() {
    _isLoading = true;
    notifyListeners();

    try {
      _promoSub?.cancel();
      _promoSub = _promoRepository.streamPromoCodes().listen(
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

      _categorySub?.cancel();
      _categorySub = _categoryRepository.streamCategories().listen(
        (cats) {
          _categories = cats;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Admin categories stream error: $err');
        },
      );

      _brandSub?.cancel();
      _brandSub = _brandRepository.streamBrands().listen(
        (b) {
          _brands = b;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Admin brands stream error: $err');
        },
      );

      loadUsers();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers() async {
    try {
      _users = await _authRepository.getAllUsers();
      notifyListeners();
    } catch (e) {
      debugPrint('Load users notice: $e');
    }
  }

  // Categories
  Future<bool> addCategory(String name, [List<String>? subcategories]) async {
    try {
      await _categoryRepository.addCategory(name, subcategories);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _categoryRepository.deleteCategory(id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addSubcategory(String categoryId, String subcategoryName) async {
    try {
      await _categoryRepository.addSubcategory(categoryId, subcategoryName);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSubcategory(String categoryId, String subcategoryName) async {
    try {
      await _categoryRepository.removeSubcategory(categoryId, subcategoryName);
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
      await _brandRepository.addBrand(name);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBrand(String id) async {
    try {
      await _brandRepository.deleteBrand(id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Promo Codes
  Future<bool> savePromoCode(PromoCodeModel promo) async {
    try {
      await _promoRepository.addPromoCode(promo);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePromoCode(String codeId) async {
    try {
      await _promoRepository.deletePromoCode(codeId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> togglePromoStatus(String codeId, bool isActive) async {
    try {
      await _promoRepository.togglePromoStatus(codeId, isActive);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // User management
  Future<bool> updateUserRole(String userId, String role) async {
    try {
      await _authRepository.updateUserRole(uid: userId, role: role);
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Soft delete product
  Future<bool> softDeleteProduct(String productId) async {
    try {
      await _productRepository.softDeleteProduct(productId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Attributes
  Future<void> addColor(String color) async {
    final trimmed = color.trim();
    if (trimmed.isNotEmpty && !_colors.contains(trimmed)) {
      _colors.add(trimmed);
      notifyListeners();
    }
  }

  Future<void> removeColor(String color) async {
    _colors.remove(color);
    notifyListeners();
  }

  Future<void> addSize(String size) async {
    final trimmed = size.trim();
    if (trimmed.isNotEmpty && !_sizes.contains(trimmed)) {
      _sizes.add(trimmed);
      notifyListeners();
    }
  }

  Future<void> removeSize(String size) async {
    _sizes.remove(size);
    notifyListeners();
  }

  Future<bool> deleteUser(String uid) async {
    try {
      await _authRepository.deleteUserDoc(uid);
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<int> clearAllUsersExceptAdmin() async {
    int count = 0;
    try {
      for (final u in _users) {
        if (u['role'] != 'admin' && u['uid'] != null) {
          await _authRepository.deleteUserDoc(u['uid']);
          count++;
        }
      }
      await loadUsers();
    } catch (e) {
      debugPrint('clear users error: $e');
    }
    return count;
  }

  Future<void> deleteAllUsers() async {
    try {
      await _authRepository.deleteAllUsers();
      await loadUsers();
    } catch (e) {
      debugPrint('deleteAllUsers error: $e');
    }
  }

  Future<bool> makeUserAdminByEmail(String email) async {
    try {
      await _authRepository.makeUserAdminByEmail(email);
      await loadUsers();
      return true;
    } catch (e) {
      debugPrint('makeUserAdminByEmail error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _promoSub?.cancel();
    _categorySub?.cancel();
    _brandSub?.cancel();
    super.dispose();
  }
}
