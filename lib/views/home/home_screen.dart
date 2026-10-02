import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
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
import '../details/product_details_screen.dart';
import 'widgets/banner_slider.dart';
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

  void _navigateToCatalog({String? category, String? query, bool filterFeatured = false, bool filterDeals = false, bool filterTopRated = false, String title = 'All Products'}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllProductsScreen(
          title: title,
          initialCategory: category,
          initialQuery: query,
          filterFeatured: filterFeatured,
          filterDeals: filterDeals,
          filterTopRated: filterTopRated,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final auth = context.watch<AuthProvider>();
    final allProducts = productProvider.allProducts;

    // Fast memoized slices
    final featuredProducts = allProducts.where((p) => p.isFeatured).take(8).toList();
    final topRated = (List<ProductModel>.from(allProducts)
      ..sort((a, b) => b.rating.compareTo(a.rating)))
      .take(8)
      .toList();
    final deals = (allProducts.where((p) => p.discountPercent >= 10).toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent)))
      .take(8)
      .toList();
    final recentProducts = allProducts.take(8).toList();

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
              // ===== 1. Top Header & Search =====
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.isAuthenticated
                                    ? 'Hello, ${auth.displayName.split(' ').first} 👋'
                                    : 'Welcome to MegaStore 👋',
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
                              // Cart Icon with Badge
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

                              if (!auth.isAuthenticated)
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
                                )
                              else ...[
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
                                  const SizedBox(width: 6),
                                ],

                                // User Profile Avatar with photoUrl support
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
                                      backgroundImage: auth.photoUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(auth.photoUrl)
                                          : null,
                                      child: auth.photoUrl.isEmpty
                                          ? Text(
                                              auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
                                              style: const TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Clean Search Bar with Live Suggestions
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              _navigateToCatalog(query: val.trim(), title: 'Search: ${val.trim()}');
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Search products, brands, deals...',
                            hintStyle: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 22),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  ),
                                Container(
                                  margin: const EdgeInsets.fromLTRB(2, 6, 6, 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                    onPressed: () {
                                      _navigateToCatalog(
                                        query: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),

                      // Live Search Results Dropdown Cards
                      if (_searchController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildLiveSearchResults(context, allProducts),
                      ],
                    ],
                  ),
                ),
              ),

              // ===== 2. Banner Carousel =====
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: BannerSlider(),
                ),
              ),

              // ===== 3. Categories Section =====
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                      InkWell(
                        onTap: () => _navigateToCatalog(title: 'All Categories'),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            'See All',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Horizontal Category Cards — dynamic from Firebase products
              SliverToBoxAdapter(
                child: Builder(
                  builder: (context) {
                    // Build dynamic category list from real Firebase products
                    final dynamicCats = productProvider.allCategories;
                    IconData iconFor(String cat) {
                      final c = cat.toLowerCase();
                      if (c == 'all') return Icons.grid_view_rounded;
                      if (c.contains('electronic') || c.contains('tech')) return Icons.devices_rounded;
                      if (c.contains('audio') || c.contains('headphone') || c.contains('speaker')) return Icons.headphones_rounded;
                      if (c.contains('watch') || c.contains('wearable')) return Icons.watch_outlined;
                      if (c.contains('footwear') || c.contains('shoes') || c.contains('sneaker')) return Icons.roller_skating_outlined;
                      if (c.contains('fashion') || c.contains('cloth') || c.contains('apparel')) return Icons.checkroom_rounded;
                      if (c.contains('beauty') || c.contains('skincare') || c.contains('makeup')) return Icons.face_retouching_natural_rounded;
                      if (c.contains('food') || c.contains('grocery') || c.contains('drink')) return Icons.lunch_dining_rounded;
                      if (c.contains('sport') || c.contains('fitness') || c.contains('gym')) return Icons.fitness_center_rounded;
                      if (c.contains('home') || c.contains('kitchen') || c.contains('furniture')) return Icons.home_outlined;
                      if (c.contains('toy') || c.contains('game') || c.contains('gaming')) return Icons.sports_esports_outlined;
                      if (c.contains('book') || c.contains('stationery')) return Icons.menu_book_rounded;
                      if (c.contains('jewel') || c.contains('accessory') || c.contains('bag')) return Icons.diamond_outlined;
                      return Icons.category_rounded;
                    }
                    return SizedBox(
                      height: 96,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        scrollDirection: Axis.horizontal,
                        itemCount: dynamicCats.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final catName = dynamicCats[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _navigateToCatalog(
                              category: catName == 'All' ? null : catName,
                              title: catName == 'All' ? 'All Products' : catName,
                            ),
                            child: Container(
                              width: 80,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(iconFor(catName), color: AppTheme.primaryColor, size: 20),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    catName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ===== 4. SECTION: Featured Products =====
              if (featuredProducts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: '⭐ Featured Picks',
                    subtitle: 'Top hand-picked choices',
                    onViewAll: () => _navigateToCatalog(filterFeatured: true, title: 'Featured Products'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 295,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: featuredProducts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => ProductCard(
                        product: featuredProducts[index],
                        width: 175,
                        heroTagPrefix: 'home_feat',
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
              ],

              // ===== 5. SECTION: Special Deals =====
              if (deals.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: '🎫 Flash Sale Deals',
                    subtitle: 'Limited time discounted savings',
                    onViewAll: () => _navigateToCatalog(filterDeals: true, title: 'Flash Deals'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 295,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: deals.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => ProductCard(
                        product: deals[index],
                        width: 175,
                        showDiscount: true,
                        heroTagPrefix: 'home_deals',
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
              ],

              // ===== 6. SECTION: Top Rated =====
              if (topRated.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: '🔥 Highest Rated',
                    subtitle: 'Customer certified 5-star picks',
                    onViewAll: () => _navigateToCatalog(filterTopRated: true, title: 'Top Rated Products'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 295,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: topRated.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => ProductCard(
                        product: topRated[index],
                        width: 175,
                        heroTagPrefix: 'home_top',
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
              ],

              // ===== 7. SECTION: Recent Arrivals (Grid) =====
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: '✨ Latest Arrivals',
                  subtitle: '${allProducts.length} items in collection',
                  onViewAll: () => _navigateToCatalog(title: 'All Products'),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ProductCard(
                        product: recentProducts[index],
                        heroTagPrefix: 'home_grid',
                      ),
                      childCount: recentProducts.length,
                    ),
                  ),
                ),

              // View All Button at Bottom
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _navigateToCatalog(title: 'All Products'),
                      icon: const Icon(Icons.explore_rounded, color: AppTheme.primaryColor),
                      label: const Text(
                        'Explore Entire Catalog',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveSearchResults(BuildContext context, List<ProductModel> allProducts) {
    final query = _searchController.text.trim().toLowerCase();
    final results = allProducts.where((p) {
      final name = p.name.toLowerCase();
      final brand = p.brand.toLowerCase();
      final category = p.category.toLowerCase();
      return name.contains(query) || brand.contains(query) || category.contains(query);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  results.isEmpty ? 'No matching products' : 'Found ${results.length} item(s)',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (results.isNotEmpty)
                  InkWell(
                    onTap: () {
                      _navigateToCatalog(
                        query: _searchController.text.trim(),
                        title: 'Search: ${_searchController.text.trim()}',
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'View All in Catalog',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No products found matching "${_searchController.text.trim()}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: results.take(5).map((product) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsScreen(product: product),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              // Product Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: Colors.white,
                                  child: CachedNetworkImage(
                                    imageUrl: product.imageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) => const Icon(
                                      Icons.image_outlined,
                                      size: 20,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Product Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          product.brand.isNotEmpty ? product.brand : product.category,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (product.rating > 0) ...[
                                          const Text(' • ', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                          const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                                          const SizedBox(width: 2),
                                          Text(
                                            product.rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Price and arrow
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppConstants.formatCurrency(product.price),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  if (product.discountPercent > 0)
                                    Text(
                                      AppConstants.formatCurrency(product.originalPrice),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textMuted,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onViewAll;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
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
