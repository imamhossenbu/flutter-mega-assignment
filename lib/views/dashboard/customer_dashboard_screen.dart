import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../admin/admin_main_screen.dart';
import '../auth/login_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/widgets/profile_management_dialogs.dart';

class CustomerDashboardScreen extends StatefulWidget {
  final VoidCallback? onExploreTap;
  final VoidCallback? onWishlistTap;
  final VoidCallback? onCartTap;

  const CustomerDashboardScreen({
    super.key,
    this.onExploreTap,
    this.onWishlistTap,
    this.onCartTap,
  });

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  Future<void> _pickAndUploadPhoto(BuildContext context, AuthProvider auth) async {
    await ProfileManagementDialogs.showPhotoUploadSheet(context, auth);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Customer Dashboard')),
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
                  child: const Icon(Icons.person_outline_rounded, size: 40, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sign In Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please sign in to view your dashboard, manage orders, and track deliveries.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Sign In Now'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildAuthenticatedCustomerDashboard(context, auth);
  }


  Widget _buildAuthenticatedCustomerDashboard(BuildContext context, AuthProvider auth) {
    final orderProvider = context.watch<OrderProvider>();
    final wishlistProvider = context.watch<WishlistProvider>();
    final cartProvider = context.watch<CartProvider>();
    final activeOrder = orderProvider.latestActiveOrder;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Customer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => ProfileManagementDialogs.showEditProfileDialog(context, auth),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Profile Header Card
            _buildProfileHeaderCard(context, auth),
            const SizedBox(height: 16),

            // Admin Portal Access Banner (Strictly Role-Based)
            if (auth.isAdmin) ...[
              _buildAdminAccessBanner(context, auth),
              const SizedBox(height: 16),
            ],

            // Customer Financial & Shopping KPIs
            _buildShoppingKPIs(orderProvider, wishlistProvider, cartProvider),
            const SizedBox(height: 20),

            // Live In-Progress Order Tracker
            if (activeOrder != null) ...[
              _buildLiveOrderTracker(context, activeOrder),
              const SizedBox(height: 20),
            ],

            // Recent Orders Section
            _buildRecentOrdersSection(context, orderProvider),
            const SizedBox(height: 20),

            // Quick Account Navigation & Settings
            _buildAccountServices(context, auth),
            const SizedBox(height: 20),

            // Sign Out
            _buildSignOutTile(context, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: auth.isUploadingPhoto ? null : () => _pickAndUploadPhoto(context, auth),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: auth.photoUrl.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(auth.photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: auth.isUploadingPhoto
                      ? Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  value: auth.uploadProgress > 0 ? auth.uploadProgress : null,
                                  color: Colors.white,
                                  backgroundColor: Colors.white24,
                                  strokeWidth: 3.5,
                                ),
                              ),
                              Text(
                                '${auth.uploadPercentage}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : (auth.photoUrl.isEmpty
                          ? Center(
                              child: Text(
                                auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            )
                          : null),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        auth.displayName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        auth.isAdmin ? 'ADMIN' : 'VIP MEMBER',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  auth.email,
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                ),
                if (auth.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    auth.phone,
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminAccessBanner(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryLight.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Store Admin Command Center',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage products, orders, stock, vouchers & users',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminMainScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Open Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingKPIs(
    OrderProvider orderProvider,
    WishlistProvider wishlistProvider,
    CartProvider cartProvider,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.monetization_on_rounded,
            iconColor: Colors.green.shade600,
            title: 'Total Spent',
            value: AppConstants.formatCurrency(orderProvider.totalSpent),
            subtitle: '${orderProvider.nonCancelledOrdersCount} orders',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.local_shipping_rounded,
            iconColor: Colors.blue.shade600,
            title: 'In Transit',
            value: '${orderProvider.activeOrdersCount}',
            subtitle: 'Active tracking',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.favorite_rounded,
            iconColor: AppTheme.accentColor,
            title: 'Wishlist',
            value: '${wishlistProvider.count}',
            subtitle: 'Saved items',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveOrderTracker(BuildContext context, OrderModel order) {
    final statusStep = _getOrderStep(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.04),
            blurRadius: 10,
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.navigation_rounded, color: AppTheme.primaryColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Active Order Tracking',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order.status.label.toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4-Step Progress Bar
          Row(
            children: [
              _buildStepNode('Placed', 1, statusStep >= 1),
              _buildStepConnector(statusStep >= 2),
              _buildStepNode('Confirmed', 2, statusStep >= 2),
              _buildStepConnector(statusStep >= 3),
              _buildStepNode('Shipped', 3, statusStep >= 3),
              _buildStepConnector(statusStep >= 4),
              _buildStepNode('Delivered', 4, statusStep >= 4),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.cardBorder, height: 1),
          const SizedBox(height: 12),

          // Preview Item & Info
          Row(
            children: [
              if (order.items.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: order.items.first.productImage,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const Icon(Icons.image),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.items.isNotEmpty ? order.items.first.productName : 'Order Items',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${order.items.length} items • ${AppConstants.formatCurrency(order.grandTotal)}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                ),
                child: const Text('View Status'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getOrderStep(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 1;
      case OrderStatus.processing:
        return 2;
      case OrderStatus.shipped:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return 0;
    }
  }

  Widget _buildStepNode(String label, int step, bool completed) {
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: completed ? AppTheme.primaryColor : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text('$step', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: completed ? FontWeight.bold : FontWeight.normal,
            color: completed ? AppTheme.primaryColor : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool active) {
    return Expanded(
      child: Container(
        height: 3,
        color: active ? AppTheme.primaryColor : Colors.grey.shade200,
        margin: const EdgeInsets.only(bottom: 14),
      ),
    );
  }

  Widget _buildRecentOrdersSection(BuildContext context, OrderProvider provider) {
    final recent = provider.orders.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Purchases',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              ),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              children: [
                Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                const Text('No orders yet', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                const Text('Browse products and enjoy shopping!', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          )
        else
          ...recent.map((order) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  leading: Text(order.status.emoji, style: const TextStyle(fontSize: 22)),
                  title: Text(
                    'Order #${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text('${order.items.length} items • ${AppConstants.formatCurrency(order.grandTotal)}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status.label,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAccountServices(BuildContext context, AuthProvider auth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          _buildServiceTile(
            icon: Icons.receipt_long_outlined,
            iconColor: AppTheme.primaryColor,
            title: 'Order History',
            subtitle: 'View past orders and invoices',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
          const Divider(height: 1, indent: 56, color: AppTheme.cardBorder),
          _buildServiceTile(
            icon: Icons.person_outline_rounded,
            iconColor: Colors.blue,
            title: 'Edit Profile',
            subtitle: 'Update your name and phone number',
            onTap: () => ProfileManagementDialogs.showEditProfileDialog(context, auth),
          ),
          const Divider(height: 1, indent: 56, color: AppTheme.cardBorder),
          _buildServiceTile(
            icon: Icons.lock_outline_rounded,
            iconColor: Colors.orange,
            title: 'Security & Password',
            subtitle: 'Change your account password',
            onTap: () => ProfileManagementDialogs.showChangePasswordDialog(context, auth),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildSignOutTile(BuildContext context, AuthProvider auth) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.error, size: 20),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out from your account?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await auth.signOut();
            }
          },
        ),
      ),
    );
  }

}

