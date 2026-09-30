import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import 'admin_attributes_screen.dart';
import 'admin_brands_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_promo_codes_screen.dart';

class AdminCatalogMenuScreen extends StatelessWidget {
  const AdminCatalogMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Catalog & Variants'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildItem(
            context: context,
            icon: Icons.category_rounded,
            iconColor: AppTheme.primaryColor,
            title: 'Categories',
            subtitle: 'Add, edit and organize product categories',
            badge: '${adminProvider.totalCategoriesCount} items',
            destination: const AdminCategoriesScreen(),
          ),
          const SizedBox(height: 12),
          _buildItem(
            context: context,
            icon: Icons.business_rounded,
            iconColor: Colors.blue.shade700,
            title: 'Brands',
            subtitle: 'Manage manufacturers and brand partners',
            badge: '${adminProvider.totalBrandsCount} brands',
            destination: const AdminBrandsScreen(),
          ),
          const SizedBox(height: 12),
          _buildItem(
            context: context,
            icon: Icons.palette_rounded,
            iconColor: Colors.purple.shade700,
            title: 'Colors & Sizes',
            subtitle: 'Configure available product variant attributes',
            badge: '${adminProvider.colors.length} colors, ${adminProvider.sizes.length} sizes',
            destination: const AdminAttributesScreen(),
          ),
          const SizedBox(height: 12),
          _buildItem(
            context: context,
            icon: Icons.local_offer_rounded,
            iconColor: Colors.teal.shade700,
            title: 'Promo Codes & Vouchers',
            subtitle: 'Create discount coupons and flash deals',
            badge: '${adminProvider.promoCodes.length} vouchers',
            destination: const AdminPromoCodesScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required Widget destination,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destination),
        ),
      ),
    );
  }
}
