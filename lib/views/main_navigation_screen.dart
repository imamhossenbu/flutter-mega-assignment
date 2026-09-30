import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wishlist_provider.dart';
import 'cart/cart_screen.dart';
import 'home/home_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';
import 'wishlist/wishlist_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final userId = auth.userId;
      _syncProviders(userId);
    });
  }

  void _syncProviders(String userId) {
    context.read<CartProvider>().updateUserId(userId);
    context.read<WishlistProvider>().updateUserId(userId);
    context.read<OrderProvider>().updateUserId(userId);
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.userId;
    // Sync providers on next frame (not during build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncProviders(userId);
    });

    final cartQuantity = context.watch<CartProvider>().totalQuantity;
    final wishlistCount = context.watch<WishlistProvider>().count;

    final pages = [
      const HomeScreen(),
      WishlistScreen(onExploreTap: () => _navigateToTab(0)),
      CartScreen(onExploreTap: () => _navigateToTab(0)),
      const OrdersScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppTheme.cardBorder, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _navigateToTab,
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primaryColor.withOpacity(0.12),
          elevation: 0,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded, color: AppTheme.primaryColor),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: wishlistCount > 0,
                label: Text('$wishlistCount'),
                backgroundColor: AppTheme.accentColor,
                child: const Icon(Icons.favorite_outline_rounded),
              ),
              selectedIcon: Badge(
                isLabelVisible: wishlistCount > 0,
                label: Text('$wishlistCount'),
                backgroundColor: AppTheme.accentColor,
                child: const Icon(Icons.favorite_rounded, color: AppTheme.primaryColor),
              ),
              label: 'Wishlist',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cartQuantity > 0,
                label: Text('$cartQuantity'),
                backgroundColor: AppTheme.primaryColor,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: cartQuantity > 0,
                label: Text('$cartQuantity'),
                backgroundColor: AppTheme.primaryColor,
                child: const Icon(Icons.shopping_cart_rounded, color: AppTheme.primaryColor),
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: AppTheme.primaryColor),
              label: 'Orders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryColor),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
