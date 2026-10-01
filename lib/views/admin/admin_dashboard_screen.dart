import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import 'admin_catalog_menu_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_edit_product_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_promo_codes_screen.dart';
import '../main_navigation_screen.dart';
import '../profile/widgets/profile_management_dialogs.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _handleSignOut(BuildContext context, AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out Admin'),
        content: const Text('Are you sure you want to sign out from the Admin Portal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final productProvider = context.watch<ProductProvider>();
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Dashboard',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined),
            tooltip: 'Admin Account & Security',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryColor),
                          ),
                          title: const Text('Edit Admin Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${authProvider.displayName} • ${authProvider.email}'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.pop(ctx);
                            ProfileManagementDialogs.showEditProfileDialog(context, authProvider);
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.lock_outline_rounded, color: Colors.orange),
                          ),
                          title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Update admin account password'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.pop(ctx);
                            ProfileManagementDialogs.showChangePasswordDialog(context, authProvider);
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.logout_rounded, color: AppTheme.error),
                          ),
                          title: const Text('Sign Out Admin', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
                          subtitle: const Text('Safely log out of admin console'),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.error),
                          onTap: () {
                            Navigator.pop(ctx);
                            _handleSignOut(context, authProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
            tooltip: 'Sign Out Admin',
            onPressed: () => _handleSignOut(context, authProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Executive Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryLight, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authProvider.displayName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const Text(
                                'Store Administrator',
                                style: TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.success.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.fiber_manual_record, color: AppTheme.success, size: 10),
                            SizedBox(width: 6),
                            Text(
                              'Live Store',
                              style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Revenue', style: TextStyle(fontSize: 12, color: Colors.white60)),
                          const SizedBox(height: 4),
                          Text(
                            '\$${orderProvider.totalRevenue.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Active Orders', style: TextStyle(fontSize: 12, color: Colors.white60)),
                          const SizedBox(height: 4),
                          Text(
                            '${orderProvider.pendingOrdersCount} Pending',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Real-Time Analytics Cards Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Orders',
                    value: '${orderProvider.totalOrdersCount}',
                    subtitle: '${orderProvider.pendingOrdersCount} need action',
                    icon: Icons.receipt_long_rounded,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Products',
                    value: '${productProvider.totalProductsCount}',
                    subtitle: '${productProvider.lowStockCount} low stock',
                    icon: Icons.inventory_2_rounded,
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Customers',
                    value: '${adminProvider.totalUsersCount}',
                    subtitle: '${adminProvider.adminUsersCount} admins',
                    icon: Icons.people_rounded,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminCustomersScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Vouchers',
                    value: '${adminProvider.promoCodes.length}',
                    subtitle: '${adminProvider.activePromoCount} active',
                    icon: Icons.local_offer_rounded,
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminPromoCodesScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Store Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickActionBtn(
                    context: context,
                    icon: Icons.add_box_rounded,
                    label: 'Add Product',
                    color: AppTheme.primaryColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminEditProductScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionBtn(
                    context: context,
                    icon: Icons.local_shipping_rounded,
                    label: 'Fulfil Orders',
                    color: Colors.blue.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionBtn(
                    context: context,
                    icon: Icons.discount_rounded,
                    label: 'New Promo',
                    color: Colors.teal.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminPromoCodesScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionBtn(
                    context: context,
                    icon: Icons.refresh_rounded,
                    label: 'Reseed Demo',
                    color: Colors.deepOrange,
                    onTap: () async {
                      await productProvider.reseedSampleProducts();
                      if (context.mounted) {
                        AppToast.showSuccess(context, 'Sample catalog restored! 🚀', title: 'Catalog Reset');
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Low Stock & Restock Alerts Widget
            _buildLowStockAlerts(context, productProvider),

            const SizedBox(height: 10),

            // Management Navigation Modules
            const Text(
              'Store Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildManagementTile(
              context: context,
              icon: Icons.inventory_2_outlined,
              iconColor: Colors.purple,
              title: 'Products & Inventory',
              subtitle: 'Add, edit, adjust stock, manage product catalog',
              badge: '${productProvider.totalProductsCount} items',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _buildManagementTile(
              context: context,
              icon: Icons.local_shipping_outlined,
              iconColor: Colors.blue,
              title: 'Order Fulfilment',
              subtitle: 'Track real-time orders, update delivery status',
              badge: '${orderProvider.totalOrdersCount} orders',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _buildManagementTile(
              context: context,
              icon: Icons.category_outlined,
              iconColor: Colors.deepPurple,
              title: 'Categories, Brands & Variants',
              subtitle: 'Manage product categories, brands, colors & sizes',
              badge: '${adminProvider.totalCategoriesCount} cats, ${adminProvider.totalBrandsCount} brands',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCatalogMenuScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _buildManagementTile(
              context: context,
              icon: Icons.local_offer_outlined,
              iconColor: Colors.teal,
              title: 'Promo Codes & Discounts',
              subtitle: 'Create coupons, manage discounts and expirations',
              badge: '${adminProvider.promoCodes.length} vouchers',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPromoCodesScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _buildManagementTile(
              context: context,
              icon: Icons.people_outline_rounded,
              iconColor: Colors.orange,
              title: 'Registered Shoppers',
              subtitle: 'Manage customer accounts, roles and permissions',
              badge: '${adminProvider.totalUsersCount} users',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCustomersScreen()),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Orders Ticker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Store Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (orderProvider.allOrders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.inbox_rounded, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No store orders yet', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    SizedBox(height: 4),
                    Text('Place a test order from the customer store!', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              )
            else
              ...orderProvider.allOrders.take(3).map((order) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: ListTile(
                      leading: Text(order.status.emoji, style: const TextStyle(fontSize: 22)),
                      title: Text(
                        'Order #${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text('${order.items.length} items • \$${order.grandTotal.toStringAsFixed(2)}'),
                      trailing: Text(
                        order.status.label,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryColor),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                      ),
                    ),
                  )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockAlerts(BuildContext context, ProductProvider productProvider) {
    final lowStockItems = productProvider.lowStockProducts;

    if (lowStockItems.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
            SizedBox(width: 10),
            Text(
              'All products have healthy inventory levels',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Low Stock Alerts',
                            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${lowStockItems.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Items need restocking to prevent lost sales',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
                ),
                child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          ...lowStockItems.take(5).map((p) => _buildLowStockItemTile(context, p, productProvider)),
          if (lowStockItems.length > 5) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: Text(
                  'Manage all ${lowStockItems.length} low stock items in Catalog',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLowStockItemTile(BuildContext context, ProductModel product, ProductProvider productProvider) {
    final isOut = !product.inStock || product.stockCount <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOut ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOut ? const Color(0xFFFECACA) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: kIsWeb
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 150,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isOut ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOut ? 'OUT OF STOCK' : 'ONLY ${product.stockCount} ${product.unit.toUpperCase()} LEFT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (product.displayQuantity.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        product.displayQuantity,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showQuickRestockDialog(context, product, productProvider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOut
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : [AppTheme.primaryColor, const Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isOut ? const Color(0xFFEF4444) : AppTheme.primaryColor).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 13, color: Colors.white),
                  const SizedBox(width: 4),
                  const Text('Restock', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickRestockDialog(BuildContext context, ProductModel product, ProductProvider productProvider) {
    final controller = TextEditingController(text: '${product.stockCount}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_rounded, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Update Inventory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Current stock: ${product.stockCount} ${product.unit}',
              style: TextStyle(
                fontSize: 12,
                color: product.stockCount <= 5 ? AppTheme.error : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New Stock Quantity (${product.unit})',
                hintText: 'Enter new stock count',
                prefixIcon: const Icon(Icons.add_shopping_cart_rounded),
                suffixText: product.unit,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [10, 20, 50, 100].map((addAmount) {
                return ActionChip(
                  label: Text('+$addAmount'),
                  onPressed: () {
                    final curr = int.tryParse(controller.text) ?? 0;
                    controller.text = '${curr + addAmount}';
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newStock = int.tryParse(controller.text.trim());
              if (newStock == null || newStock < 0) {
                AppToast.showError(context, 'Please enter a valid non-negative number');
                return;
              }
              Navigator.pop(ctx);
              final success = await productProvider.updateStock(product.id, newStock);
              if (context.mounted) {
                if (success) {
                  AppToast.showSuccess(
                    context,
                    'Updated inventory for "${product.name}" to $newStock ${product.unit}',
                    title: 'Stock Updated',
                  );
                } else {
                  AppToast.showError(context, 'Failed to update stock');
                }
              }
            },
            child: const Text('Save Stock'),
          ),
        ],
      ),
    );
  }
}
