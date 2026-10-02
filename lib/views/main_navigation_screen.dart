import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/modern_bottom_nav.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wishlist_provider.dart';
import 'auth/login_screen.dart';
import 'cart/cart_screen.dart';
import 'dashboard/customer_dashboard_screen.dart';
import 'home/home_screen.dart';
import 'orders/orders_screen.dart';
import 'wishlist/wishlist_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  String? _lastSyncedUserId;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      _syncProviders(auth.userId);
    });
  }

  void _syncProviders(String userId) {
    if (_lastSyncedUserId == userId) return;
    _lastSyncedUserId = userId;
    context.read<CartProvider>().updateUserId(userId);
    context.read<WishlistProvider>().updateUserId(userId);
    context.read<OrderProvider>().updateUserId(userId);
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildNavProfileAvatar(AuthProvider auth, bool isSelected) {
    if (auth.photoUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.2,
          ),
        ),
        child: CircleAvatar(
          radius: 12,
          backgroundColor: Colors.grey.shade100,
          backgroundImage: CachedNetworkImageProvider(auth.photoUrl),
        ),
      );
    } else if (auth.isAuthenticated && auth.displayName.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: CircleAvatar(
          radius: 12,
          backgroundColor: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.15),
          child: Text(
            auth.displayName[0].toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
            ),
          ),
        ),
      );
    }
    return Icon(
      isSelected ? Icons.person_rounded : Icons.person_outline_rounded,
      color: isSelected ? AppTheme.primaryColor : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.userId;
    // Sync providers only when userId actually changes
    if (_lastSyncedUserId != userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncProviders(userId);
      });
    }

    final cartQuantity = context.watch<CartProvider>().totalQuantity;
    final wishlistCount = context.watch<WishlistProvider>().count;

    final pages = [
      HomeScreen(
        onCartTap: () => _navigateToTab(2),
        onProfileTap: () {
          if (auth.isAuthenticated) {
            _navigateToTab(4);
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        },
      ),
      WishlistScreen(onExploreTap: () => _navigateToTab(0)),
      CartScreen(onExploreTap: () => _navigateToTab(0)),
      const OrdersScreen(),
      if (auth.isAuthenticated)
        CustomerDashboardScreen(
          onExploreTap: () => _navigateToTab(0),
          onWishlistTap: () => _navigateToTab(1),
          onCartTap: () => _navigateToTab(2),
        ),
    ];

    final safeIndex = _currentIndex >= pages.length ? 0 : _currentIndex;

    final navItems = [
      const ModernNavItem(
        icon: Icon(Icons.explore_outlined),
        activeIcon: Icon(Icons.explore_rounded),
        label: 'Explore',
      ),
      ModernNavItem(
        icon: const Icon(Icons.favorite_outline_rounded),
        activeIcon: const Icon(Icons.favorite_rounded),
        label: 'Wishlist',
        badgeCount: wishlistCount,
        badgeColor: AppTheme.accentColor,
      ),
      ModernNavItem(
        icon: const Icon(Icons.shopping_bag_outlined),
        activeIcon: const Icon(Icons.shopping_bag_rounded),
        label: 'Cart',
        badgeCount: cartQuantity,
        badgeColor: AppTheme.primaryColor,
      ),
      const ModernNavItem(
        icon: Icon(Icons.receipt_long_outlined),
        activeIcon: Icon(Icons.receipt_long_rounded),
        label: 'Orders',
      ),
      if (auth.isAuthenticated)
        ModernNavItem(
          icon: _buildNavProfileAvatar(auth, false),
          activeIcon: _buildNavProfileAvatar(auth, true),
          label: 'Dashboard',
        ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: safeIndex,
        onTap: _navigateToTab,
        items: navItems,
      ),
    );
  }
}
