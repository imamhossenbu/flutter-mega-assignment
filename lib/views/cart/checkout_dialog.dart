import 'package:flutter/material.dart';
import '../orders/checkout_screen.dart';

class CheckoutDialog extends StatelessWidget {
  const CheckoutDialog({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const CheckoutScreen();
  }
}
