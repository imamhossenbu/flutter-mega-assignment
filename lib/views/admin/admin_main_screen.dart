import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import 'admin_catalog_menu_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';

class AdminMainScreen extends StatefulWidget {
  final int initialIndex;
  const AdminMainScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final pendingOrdersCount = orderProvider.pendingOrdersCount;
    final productProvider = context.watch<ProductProvider>();
    final lowStockCount = productProvider.lowStockCount;

    final pages = [
      const AdminDashboardScreen(),
      const AdminProductsScreen(),
      const AdminOrdersScreen(),
      const AdminCatalogMenuScreen(),
      const AdminCustomersScreen(),
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
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primaryColor.withOpacity(0.12),
          elevation: 0,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primaryColor),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: lowStockCount > 0,
                label: Text('$lowStockCount'),
                backgroundColor: Colors.amber.shade800,
                child: const Icon(Icons.inventory_2_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: lowStockCount > 0,
                label: Text('$lowStockCount'),
                backgroundColor: Colors.amber.shade800,
                child: const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryColor),
              ),
              label: 'Products',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: pendingOrdersCount > 0,
                label: Text('$pendingOrdersCount'),
                backgroundColor: AppTheme.accentColor,
                child: const Icon(Icons.local_shipping_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: pendingOrdersCount > 0,
                label: Text('$pendingOrdersCount'),
                backgroundColor: AppTheme.accentColor,
                child: const Icon(Icons.local_shipping_rounded, color: AppTheme.primaryColor),
              ),
              label: 'Orders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.category_outlined),
              selectedIcon: Icon(Icons.category_rounded, color: AppTheme.primaryColor),
              label: 'Catalog',
            ),
            const NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded, color: AppTheme.primaryColor),
              label: 'Users',
            ),
          ],
        ),
      ),
    );
  }
}
