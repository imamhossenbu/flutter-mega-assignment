import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../admin/admin_main_screen.dart';
import '../all_products/all_products_screen.dart';
import '../auth/login_screen.dart';
import '../cart/cart_screen.dart';
import '../dashboard/customer_dashboard_screen.dart';
import 'widgets/banner_slider.dart';
import 'widgets/category_chips.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onCartTap;
  final VoidCallback? onProfileTap;
  const HomeScreen({super.key, this.onCartTap, this.onProfileTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final auth = context.watch<AuthProvider>();
    final filterOptions = productProvider.filterOptions;
    final filteredProducts = productProvider.filteredProducts;
    final allProducts = productProvider.allProducts;

    // Sections
    final featuredProducts = allProducts.where((p) => p.isFeatured).take(8).toList();
    final topRatedProducts = List<ProductModel>.from(allProducts)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final topRated = topRatedProducts.take(8).toList();
    final specialDeals = allProducts.where((p) => p.discountPercent >= 10).toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    final deals = specialDeals.take(8).toList();

    final isSearching = filterOptions.searchQuery.isNotEmpty || filterOptions.hasActiveFilters;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ===== 1. Header =====
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.isAuthenticated
                                    ? 'Hello, ${auth.displayName.split(' ').first} 👋'
                                    : 'Welcome back 👋',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Discover Products',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // 1. If not authenticated: show Cart & Sign In button (NO profile avatar)
                              if (!auth.isAuthenticated) ...[
                                IconButton(
                                  onPressed: widget.onCartTap ??
                                      () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const CartScreen()),
                                          ),
                                  icon: Badge(
                                    isLabelVisible: context.watch<CartProvider>().totalQuantity > 0,
                                    label: Text('${context.watch<CartProvider>().totalQuantity}'),
                                    backgroundColor: AppTheme.primaryColor,
                                    child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.textPrimary, size: 24),
                                  ),
                                  tooltip: 'Cart',
                                ),
                                const SizedBox(width: 4),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  ),
                                  icon: const Icon(Icons.login_rounded, size: 16),
                                  label: const Text('Sign In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ] else ...[
                                // 2. If authenticated: show Admin button (if admin) + Cart icon + Profile Avatar
                                if (auth.isAdmin) ...[
                                  InkWell(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const AdminMainScreen()),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.admin_panel_settings_rounded, size: 14, color: AppTheme.primaryLight),
                                          SizedBox(width: 4),
                                          Text(
                                            'ADMIN',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                IconButton(
                                  onPressed: widget.onCartTap ??
                                      () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const CartScreen()),
                                          ),
                                  icon: Badge(
                                    isLabelVisible: context.watch<CartProvider>().totalQuantity > 0,
                                    label: Text('${context.watch<CartProvider>().totalQuantity}'),
                                    backgroundColor: AppTheme.primaryColor,
                                    child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.textPrimary, size: 24),
                                  ),
                                  tooltip: 'Cart',
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: widget.onProfileTap ??
                                      () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const CustomerDashboardScreen()),
                                          ),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4), width: 1.5),
                                    ),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                                      child: Text(
                                        auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search + Filter
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.cardBorder),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => productProvider.setSearchQuery(value),
                                decoration: InputDecoration(
                                  hintText: 'Search products, brands...',
                                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 22),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            productProvider.setSearchQuery('');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Material(
                                color: filterOptions.hasActiveFilters ? AppTheme.primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => FilterBottomSheet.show(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: filterOptions.hasActiveFilters ? AppTheme.primaryColor : AppTheme.cardBorder),
                                    ),
                                    child: Icon(Icons.tune_rounded,
                                        color: filterOptions.hasActiveFilters ? Colors.white : AppTheme.textPrimary, size: 22),
                                  ),
                                ),
                              ),
                              if (filterOptions.filterBadgeCount > 0)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
                                    child: Text('${filterOptions.filterBadgeCount}',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ===== 2. Active Filters =====
              if (filterOptions.hasActiveFilters)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (filterOptions.selectedCategory != 'All')
                            _buildFilterChip(label: filterOptions.selectedCategory, onRemove: () => productProvider.setSelectedCategory('All')),
                          if (filterOptions.minRating > 0)
                            _buildFilterChip(
                                label: '★ ${filterOptions.minRating}+',
                                onRemove: () => productProvider.setFilterOptions(filterOptions.copyWith(minRating: 0.0))),
                          if (filterOptions.onlyInStock)
                            _buildFilterChip(
                                label: 'In Stock',
                                onRemove: () => productProvider.setFilterOptions(filterOptions.copyWith(onlyInStock: false))),
                          InkWell(
                            onTap: () {
                              _searchController.clear();
                              productProvider.resetFilters();
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('Clear All', style: TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ===== SHOW EITHER SEARCH RESULTS OR HOME SECTIONS =====
              if (isSearching) ...[
                // ===== Search / Filter Mode =====
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${filteredProducts.length} Results Found',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        InkWell(
                          onTap: () => FilterBottomSheet.show(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                Text(filterOptions.sortBy.label,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppTheme.primaryColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (productProvider.isLoading)
                  const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)))
                else if (filteredProducts.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState(context, productProvider))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, childAspectRatio: 0.60, crossAxisSpacing: 12, mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ProductCard(product: filteredProducts[index]),
                        childCount: filteredProducts.length,
                      ),
                    ),
                  ),
              ] else ...[
                // ===== HOME SECTIONS =====

                // Banner Slider
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: BannerSlider(),
                  ),
                ),

                // Categories
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: CategoryChips(),
                  ),
                ),

                // ===== SECTION: Featured Products =====
                if (featuredProducts.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: '⭐ Featured Products',
                      subtitle: 'Hand-picked just for you',
                      onViewAll: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AllProductsScreen(title: 'Featured Products', products: featuredProducts),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 285,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: featuredProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => ProductCard(product: featuredProducts[index], width: 175),
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ===== SECTION: Top Rated =====
                if (topRated.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: '🔥 Top Rated',
                      subtitle: 'Best reviewed by customers',
                      onViewAll: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AllProductsScreen(title: 'Top Rated Products', products: topRated),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 285,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: topRated.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => ProductCard(product: topRated[index], width: 175),
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ===== SECTION: Special Deals =====
                if (deals.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: '🎫 Special Deals',
                      subtitle: 'Limited time discounts',
                      onViewAll: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AllProductsScreen(title: 'Special Deals', products: deals),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 285,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: deals.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => ProductCard(product: deals[index], width: 175, showDiscount: true),
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ===== SECTION: All Products =====
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: '🛒 All Products',
                    subtitle: '${allProducts.length} products available',
                    onViewAll: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AllProductsScreen(title: 'All Products')),
                    ),
                  ),
                ),

                if (productProvider.isLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, childAspectRatio: 0.60, crossAxisSpacing: 12, mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == allProducts.length) {
                            // View All button at end
                            return _ViewAllTile(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AllProductsScreen(title: 'All Products')),
                              ),
                            );
                          }
                          return ProductCard(product: allProducts[index]);
                        },
                        childCount: allProducts.length > 4 ? 4 + 1 : allProducts.length,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onRemove}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ProductProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.search_off_rounded, size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            const Text('No Products Match', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Try changing your filters or search keywords.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                provider.resetFilters();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Section Header =====
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.subtitle, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppTheme.primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== View All Tile =====
class _ViewAllTile extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewAllTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.grid_view_rounded, color: AppTheme.primaryColor, size: 36),
              SizedBox(height: 10),
              Text('View All\nProducts',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
            ],
          ),
        ),
      ),
    );
  }
}
