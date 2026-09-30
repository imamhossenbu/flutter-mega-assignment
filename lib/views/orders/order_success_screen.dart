import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../main_navigation_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final OrderModel order;
  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success animation
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 70,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Order Placed! 🎉',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your order #${order.id.substring(6, 16)} has been confirmed.',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Order summary card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _infoRow('Items', '${order.items.length} item(s)'),
                      _infoRow('Total', '\$${order.grandTotal.toStringAsFixed(2)}'),
                      _infoRow('Status', '${order.status.emoji} ${order.status.label}'),
                      _infoRow('Deliver to', order.shippingAddress, wrap: true),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home_rounded, size: 20),
                    label: const Text('Back to Home'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                        builder: (_) => MainNavigationScreen(initialIndex: 3),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.receipt_long_outlined, size: 20),
                    label: const Text('View My Orders'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool wrap = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: wrap ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
