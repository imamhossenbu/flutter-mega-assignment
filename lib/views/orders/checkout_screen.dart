import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
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
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  String _selectedPayment = 'Credit Card';

  @override
  void initState() {
    super.initState();
    // Pre-fill name from auth
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.displayName.isNotEmpty && auth.displayName != 'Guest Shopper') {
        _nameController.text = auth.displayName;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final cart = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final auth = context.read<AuthProvider>();

    if (auth.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to place an order'),
          action: SnackBarAction(
            label: 'Sign In',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final shippingAddress =
        '${_nameController.text.trim()}, ${_addressController.text.trim()}, ${_cityController.text.trim()} ${_zipController.text.trim()}';

    final order = await orderProvider.placeOrder(
      cartItems: cart.items.toList(),
      subtotal: cart.subtotal,
      discount: cart.discountAmount,
      shipping: cart.shippingFee,
      tax: cart.taxAmount,
      grandTotal: cart.grandTotal,
      shippingAddress: shippingAddress,
      promoCode: cart.appliedPromo,
    );

    if (!mounted) return;

    if (order != null) {
      cart.removePromoCode();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to place order. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Guest warning
              if (auth.isGuest) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Sign in to save your order history.',
                          style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _buildSectionHeader('Shipping Information', Icons.local_shipping_outlined),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _zipController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'ZIP'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Payment Method', Icons.payment_outlined),
              const SizedBox(height: 12),
              ...[
                ('Credit Card', Icons.credit_card_rounded),
                ('Cash on Delivery', Icons.money_rounded),
                ('Mobile Banking', Icons.phone_android_rounded),
              ].map((method) => _buildPaymentOption(method.$1, method.$2)),
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
                                  ? Image.network(item.product.imageUrl,
                                      width: 44, height: 44, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 44, height: 44,
                                        color: Colors.grey.shade100,
                                        child: const Icon(Icons.image_not_supported_outlined, size: 18, color: Colors.grey),
                                      ))
                                  : Image.network(item.product.imageUrl,
                                      width: 44, height: 44, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.product.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'x${item.quantity}',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '\$${item.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    _summaryRow('Subtotal', '\$${cart.subtotal.toStringAsFixed(2)}'),
                    if (cart.discountAmount > 0)
                      _summaryRow(
                          'Discount (${cart.appliedPromoCode})',
                          '-\$${cart.discountAmount.toStringAsFixed(2)}',
                          color: AppTheme.success),
                    _summaryRow('Shipping',
                        cart.shippingFee == 0 ? 'FREE' : '\$${cart.shippingFee.toStringAsFixed(2)}',
                        color: cart.shippingFee == 0 ? AppTheme.success : null),
                    _summaryRow('Tax (5%)', '\$${cart.taxAmount.toStringAsFixed(2)}'),
                    const Divider(height: 20),
                    _summaryRow(
                      'Grand Total',
                      '\$${cart.grandTotal.toStringAsFixed(2)}',
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
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4)),
          ],
          border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: orderProvider.isPlacingOrder ? null : _placeOrder,
              child: orderProvider.isPlacingOrder
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                        SizedBox(width: 12),
                        Text('Placing Order...'),
                      ],
                    )
                  : Text('Place Order • \$${cart.grandTotal.toStringAsFixed(2)}'),
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String label, IconData icon) {
    final isSelected = _selectedPayment == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
              )),
          Text(value,
              style: TextStyle(
                fontSize: isBold ? 16 : 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: color ?? AppTheme.textPrimary,
              )),
        ],
      ),
    );
  }
}
