import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../auth/login_screen.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _districtController = TextEditingController();
  final _streetController = TextEditingController();

  bool _isDhaka = true;
  bool _saveAddress = true;
  bool _useNewAddress = false;
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<AddressProvider>().initAddresses(auth.userId);
        if (mounted) {
          _selectDefaultAddressIfAvailable();
        }
      }
      _prefillUserData();
    });
  }

  void _selectDefaultAddressIfAvailable() {
    final addressProvider = context.read<AddressProvider>();
    if (addressProvider.addresses.isNotEmpty && _selectedAddressId == null && !_useNewAddress) {
      final defaultAddr = addressProvider.addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addressProvider.addresses.first,
      );
      _onAddressSelected(defaultAddr);
    }
  }

  void _prefillUserData() {
    final auth = context.read<AuthProvider>();
    if (auth.displayName.isNotEmpty && auth.displayName != 'Guest Shopper') {
      _nameController.text = auth.displayName;
    }
    if (auth.phone.isNotEmpty) {
      _phoneController.text = auth.phone;
    }
    if (_districtController.text.isEmpty) {
      _districtController.text = 'Dhaka';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  void _onAddressSelected(AddressModel addr) {
    setState(() {
      _selectedAddressId = addr.id;
      _useNewAddress = false;
      _nameController.text = addr.name;
      _phoneController.text = addr.phone;
      _districtController.text = addr.district;
      _streetController.text = addr.detailedAddress;
      _isDhaka = addr.isDhaka;
    });
    context.read<CartProvider>().setDeliveryZone(isDhaka: addr.isDhaka);
  }

  Future<void> _placeOrder() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      AppToast.showWarning(
        context,
        'Please sign in to place an order',
        title: 'Sign In Required',
        actionLabel: 'Sign In',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      AppToast.showWarning(context, 'Your cart is empty. Please add items to checkout.');
      return;
    }

    final addressProvider = context.read<AddressProvider>();
    final hasSaved = addressProvider.addresses.isNotEmpty;

    // If using new address form or no saved address, validate the form fields
    if (!hasSaved || _useNewAddress) {
      if (!_formKey.currentState!.validate()) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
        AppToast.showWarning(
          context,
          'Please complete all required address fields properly.',
          title: 'Address Incomplete',
        );
        return;
      }
    }

    final orderProvider = context.read<OrderProvider>();

    if (auth.isAuthenticated && auth.userId.isNotEmpty) {
      orderProvider.updateUserId(auth.userId);
    }

    String customerName = _nameController.text.trim();
    String customerPhone = AppConstants.normalizePhone(_phoneController.text.trim());
    String shippingAddress =
        '${_streetController.text.trim()}, ${_districtController.text.trim()}';

    // If using a saved address, pull directly from the selected address
    if (hasSaved && !_useNewAddress) {
      final selectedAddr = addressProvider.addresses.firstWhere(
        (a) => a.id == _selectedAddressId,
        orElse: () => addressProvider.addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => addressProvider.addresses.first,
        ),
      );
      customerName = selectedAddr.name;
      customerPhone = AppConstants.normalizePhone(selectedAddr.phone);
      shippingAddress = selectedAddr.fullAddress;
    }

    // Optionally save address to user's address book
    if (_useNewAddress && _saveAddress && auth.isAuthenticated) {
      final newAddr = AddressModel(
        id: '',
        name: customerName,
        phone: customerPhone,
        district: _districtController.text.trim(),
        detailedAddress: _streetController.text.trim(),
        isDhaka: _isDhaka,
        isDefault: !addressProvider.hasAddresses,
      );
      addressProvider.addAddress(newAddr);
    }

    final deliveryCharge = _isDhaka
        ? AppConstants.deliveryFeeDhaka
        : AppConstants.deliveryFeeOutsideDhaka;

    try {
      final order = await orderProvider.placeOrder(
        cartItems: cart.items.toList(),
        customerName: customerName,
        customerPhone: customerPhone,
        shippingAddress: shippingAddress,
        deliveryCharge: deliveryCharge,
        promoCode: cart.appliedPromo,
        subtotal: cart.subtotal,
        discount: cart.discountAmount,
        shipping: deliveryCharge,
        tax: cart.taxAmount,
        grandTotal: cart.grandTotal,
      );

      if (!mounted) return;

      if (order != null) {
        cart.clearCart();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
        );
      } else {
        final err = orderProvider.errorMessage ??
            'Failed to place order. Please review your cart and try again.';
        AppToast.showError(context, err, title: 'Order Placement Error');
      }
    } catch (e) {
      if (!mounted) return;
      final err = orderProvider.errorMessage ??
          e.toString().replaceFirst('Exception: ', '');
      AppToast.showError(context, err, title: 'Order Failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Checkout'), centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline_rounded, size: 40, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sign In Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please sign in or create an account to proceed with checkout and place your order.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Sign In to Continue'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final savedAddresses = addressProvider.addresses;
    final hasSaved = savedAddresses.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


              // Delivery Address Section
              _buildSectionHeader('Delivery Address', Icons.location_on_outlined),
              const SizedBox(height: 12),

              // Saved Addresses Selector
              if (hasSaved) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Saved Addresses',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _useNewAddress = !_useNewAddress;
                                if (_useNewAddress) {
                                  _selectedAddressId = null;
                                }
                              });
                            },
                            icon: Icon(
                              _useNewAddress ? Icons.check_circle_outline : Icons.add,
                              size: 16,
                            ),
                            label: Text(
                              _useNewAddress ? 'Use Saved' : 'Add New',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      if (!_useNewAddress) ...[
                        const SizedBox(height: 8),
                        ...savedAddresses.map((addr) {
                          final isSelected = _selectedAddressId == addr.id ||
                              (_selectedAddressId == null && addr.isDefault);
                          return InkWell(
                            onTap: () => _onAddressSelected(addr),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor.withOpacity(0.06)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade200,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              addr.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              addr.phone,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                            if (addr.isDefault) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Default',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppTheme.primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          addr.fullAddress,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Address Form (if no saved address, or user clicked "Add New")
              if (!hasSaved || _useNewAddress) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recipient Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Recipient Full Name *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Recipient name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number (e.g. 01712345678) *',
                          prefixIcon: Icon(Icons.phone_outlined),
                          helperText: '11 digits Bangladesh phone number',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Phone number is mandatory';
                          }
                          if (!AppConstants.isValidPhone(v)) {
                            return 'Enter a valid 11-digit BD number (01XXXXXXXXX)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Delivery Zone Selection
                      const Text(
                        'Delivery Area / Zone *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isDhaka = true;
                                  if (_districtController.text.trim().toLowerCase() != 'dhaka') {
                                    _districtController.text = 'Dhaka';
                                  }
                                });
                                context.read<CartProvider>().setDeliveryZone(isDhaka: true);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: _isDhaka
                                      ? AppTheme.primaryColor.withOpacity(0.08)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isDhaka
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade300,
                                    width: _isDhaka ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Inside Dhaka',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: _isDhaka
                                            ? AppTheme.primaryColor
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppConstants.formatCurrency(AppConstants.deliveryFeeDhaka),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _isDhaka
                                            ? AppTheme.primaryColor
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isDhaka = false;
                                  if (_districtController.text.trim().toLowerCase() == 'dhaka') {
                                    _districtController.clear();
                                  }
                                });
                                context.read<CartProvider>().setDeliveryZone(isDhaka: false);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: !_isDhaka
                                      ? AppTheme.primaryColor.withOpacity(0.08)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: !_isDhaka
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade300,
                                    width: !_isDhaka ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Outside Dhaka',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: !_isDhaka
                                            ? AppTheme.primaryColor
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppConstants.formatCurrency(AppConstants.deliveryFeeOutsideDhaka),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: !_isDhaka
                                            ? AppTheme.primaryColor
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _districtController,
                        decoration: InputDecoration(
                          labelText: _isDhaka ? 'Area in Dhaka (e.g. Dhanmondi, Gulshan) *' : 'District & Thana *',
                          prefixIcon: const Icon(Icons.location_city_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Area/District is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _streetController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Detailed Street Address (House, Road, Block) *',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Detailed street address is required';
                          }
                          return null;
                        },
                      ),
                      if (auth.isAuthenticated) ...[
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Save this address for future orders',
                            style: TextStyle(fontSize: 13),
                          ),
                          value: _saveAddress,
                          onChanged: (val) => setState(() => _saveAddress = val ?? true),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Payment Method Section - CASH ON DELIVERY ONLY
              _buildSectionHeader('Payment Method', Icons.payments_outlined),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: Color(0xFF059669),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Cash on Delivery (COD)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF059669),
                                size: 18,
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pay with cash to our delivery executive when your package arrives at your doorstep.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Order Summary
              _buildSectionHeader('Order Summary', Icons.receipt_long_outlined),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    ...cart.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.network(
                                      item.product.imageUrl,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 44,
                                        height: 44,
                                        color: Colors.grey.shade100,
                                        child: const Icon(Icons.inventory_2_outlined,
                                            size: 18, color: Colors.grey),
                                      ),
                                    )
                                  : Image.network(
                                      item.product.imageUrl,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.selectedSize != null || item.selectedColor != null)
                                    Text(
                                      [
                                        if (item.selectedColor != null) item.selectedColor,
                                        if (item.selectedSize != null) item.selectedSize,
                                      ].join(' • '),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              'x${item.quantity}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppConstants.formatCurrency(item.totalPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    _summaryRow('Subtotal', AppConstants.formatCurrency(cart.subtotal)),
                    if (cart.discountAmount > 0)
                      _summaryRow(
                        'Discount (${cart.appliedPromoCode})',
                        '-${AppConstants.formatCurrency(cart.discountAmount)}',
                        color: AppTheme.success,
                      ),
                    _summaryRow(
                      'Delivery Charge (${_isDhaka ? "Inside Dhaka" : "Outside Dhaka"})',
                      AppConstants.formatCurrency(cart.deliveryFee),
                    ),
                    _summaryRow(
                      'Tax (5% VAT)',
                      AppConstants.formatCurrency(cart.taxAmount),
                    ),
                    const Divider(height: 20),
                    _summaryRow(
                      'Grand Total',
                      AppConstants.formatCurrency(cart.grandTotal),
                      isBold: true,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: orderProvider.isPlacingOrder ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: orderProvider.isPlacingOrder
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Placing Order...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Confirm Order (COD) • ${AppConstants.formatCurrency(cart.grandTotal)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
