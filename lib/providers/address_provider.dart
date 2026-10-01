import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/address_model.dart';
import '../repositories/address_repository.dart';

class AddressProvider extends ChangeNotifier {
  final AddressRepository _addressRepository;

  AddressProvider({AddressRepository? addressRepository})
      : _addressRepository = addressRepository ?? FirestoreAddressRepository();

  List<AddressModel> _addresses = [];
  List<AddressModel> get addresses => _addresses;

  AddressModel? _selectedAddress;
  AddressModel? get selectedAddress => _selectedAddress;

  AddressModel? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  bool get hasAddresses => _addresses.isNotEmpty;

  bool get isDhakaSelected {
    final addr = _selectedAddress ?? defaultAddress;
    if (addr == null) return true; // Default to Dhaka
    return addr.isDhaka;
  }

  double get currentDeliveryCharge =>
      isDhakaSelected ? AppConstants.deliveryFeeDhaka : AppConstants.deliveryFeeOutsideDhaka;

  StreamSubscription<List<AddressModel>>? _sub;
  String _currentUserId = '';

  void initAddresses(String userId) {
    if (_currentUserId == userId && _sub != null) return;
    _currentUserId = userId;
    _sub?.cancel();

    if (userId.isEmpty) {
      _addresses = [];
      _selectedAddress = null;
      notifyListeners();
      return;
    }

    _sub = _addressRepository.streamAddresses(userId).listen((list) {
      _addresses = list;
      if (_selectedAddress != null) {
        final found = list.where((a) => a.id == _selectedAddress!.id);
        _selectedAddress = found.isNotEmpty ? found.first : defaultAddress;
      } else {
        _selectedAddress = defaultAddress;
      }
      notifyListeners();
    });
  }

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<void> addAddress(AddressModel address) async {
    if (_currentUserId.isEmpty) return;
    await _addressRepository.addAddress(_currentUserId, address);
  }

  Future<void> updateAddress(AddressModel address) async {
    if (_currentUserId.isEmpty) return;
    await _addressRepository.updateAddress(_currentUserId, address);
  }

  Future<void> deleteAddress(String addressId) async {
    if (_currentUserId.isEmpty) return;
    await _addressRepository.deleteAddress(_currentUserId, addressId);
    if (_selectedAddress?.id == addressId) {
      _selectedAddress = defaultAddress;
      notifyListeners();
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    if (_currentUserId.isEmpty) return;
    await _addressRepository.setDefaultAddress(_currentUserId, addressId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
