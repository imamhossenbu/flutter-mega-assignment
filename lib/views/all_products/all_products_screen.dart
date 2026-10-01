import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/filter_options.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../home/widgets/product_card.dart';

class AllProductsScreen extends StatefulWidget {
  final String title;
  final List<ProductModel>? products;
  final String? initialCategory;
  final String? initialQuery;
  final bool filterFeatured;
  final bool filterDeals;
  final bool filterTopRated;

  const AllProductsScreen({
    super.key,
    this.title = 'All Products',
    this.products,
    this.initialCategory,
    this.initialQuery,
    this.filterFeatured = false,
    this.filterDeals = false,
    this.filterTopRated = false,
  });

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final _searchController = TextEditingController();
  late String _selectedCategory;
  String _searchQuery = '';
  SortOption _sortBy = SortOption.featured;
  bool _onlyInStock = false;
  double _minRating = 0.0;
  RangeValues _priceRange = const RangeValues(0, 100000);

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
    _searchQuery = widget.initialQuery ?? '';
    _searchController.text = _searchQuery;

    if (widget.filterFeatured) {
      _sortBy = SortOption.featured;
    } else if (widget.filterDeals) {
      _sortBy = SortOption.discountHighToLow;
    } else if (widget.filterTopRated) {
      _sortBy = SortOption.ratingHighToLow;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetAllFilters() {
    setState(() {
      _selectedCategory = 'All';
      _searchQuery = '';
      _searchController.clear();
      _sortBy = SortOption.featured;
      _onlyInStock = false;
      _minRating = 0.0;
      _priceRange = const RangeValues(0, 100000);
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategory != 'All') count++;
    if (_onlyInStock) count++;
    if (_minRating > 0) count++;
    if (_priceRange.start > 0 || _priceRange.end < 100000) count++;
    if (_sortBy != SortOption.featured) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final baseProducts = widget.products ?? productProvider.allProducts;

    // Filter computation
    var filtered = baseProducts.where((product) {
      // Category filter
      if (_selectedCategory != 'All' &&
          !product.category.toLowerCase().contains(_selectedCategory.toLowerCase())) {
        return false;
      }

      // Search keyword filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final inName = product.name.toLowerCase().contains(q);
        final inBrand = product.brand.toLowerCase().contains(q);
        final inDesc = product.description.toLowerCase().contains(q);
        final inCat = product.category.toLowerCase().contains(q);
        if (!inName && !inBrand && !inDesc && !inCat) return false;
      }

      // Feature / Deal constraints if passed from banner
      if (widget.filterFeatured && !product.isFeatured) return false;
      if (widget.filterDeals && product.discountPercent < 10) return false;

      // Price filter
      if (product.price < _priceRange.start || product.price > _priceRange.end) {
        return false;
      }

      // Rating filter
      if (product.rating < _minRating) return false;

      // In-stock filter
      if (_onlyInStock && (!product.inStock || product.stockCount <= 0)) {
        return false;
      }

      return true;
    }).toList();

    // Sort computation
    switch (_sortBy) {
      case SortOption.featured:
        filtered.sort((a, b) {
          if (a.isFeatured == b.isFeatured) {
            return b.rating.compareTo(a.rating);
          }
          return a.isFeatured ? -1 : 1;
        });
        break;
      case SortOption.priceLowToHigh:
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighToLow:
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.ratingHighToLow:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.discountHighToLow:
        filtered.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Filters',
            onPressed: _resetAllFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== 1. Search Bar =====
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search in ${widget.title}...',
                        hintStyle: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Filter Button with Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Material(
                      color: _activeFilterCount > 0 ? AppTheme.primaryColor : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openFilterModal(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _activeFilterCount > 0
                                  ? AppTheme.primaryColor
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: _activeFilterCount > 0 ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppTheme.accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$_activeFilterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ===== 2. Horizontal Category Selector =====
          Container(
            color: Colors.white,
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: AppConstants.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = AppConstants.categories[index];
                final isSelected = cat.id == _selectedCategory;

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _selectedCategory = cat.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.icon,
                          size: 15,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ===== 3. Quick Bar: Sort + In-Stock + Count =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Products Count
                Text(
                  '${filtered.length} ${filtered.length == 1 ? 'Product' : 'Products'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),

                Row(
                  children: [
                    // In-Stock toggle chip
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _onlyInStock = !_onlyInStock),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _onlyInStock ? AppTheme.primaryLight.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _onlyInStock ? AppTheme.primaryColor : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _onlyInStock ? Icons.check_circle_rounded : Icons.circle_outlined,
                              size: 14,
                              color: _onlyInStock ? AppTheme.primaryColor : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'In Stock',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: _onlyInStock ? FontWeight.bold : FontWeight.normal,
                                color: _onlyInStock ? AppTheme.primaryColor : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Sort Dropdown Button
                    PopupMenuButton<SortOption>(
                      initialValue: _sortBy,
                      onSelected: (val) => setState(() => _sortBy = val),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sort_rounded, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              _sortBy.label,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: SortOption.featured, child: Text('Featured')),
                        const PopupMenuItem(value: SortOption.priceLowToHigh, child: Text('Price: Low to High')),
                        const PopupMenuItem(value: SortOption.priceHighToLow, child: Text('Price: High to Low')),
                        const PopupMenuItem(value: SortOption.ratingHighToLow, child: Text('Customer Rating')),
                        const PopupMenuItem(value: SortOption.discountHighToLow, child: Text('Biggest Discount')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ===== 4. Active Filter Tags (if any) =====
          if (_activeFilterCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedCategory != 'All')
                      _buildActiveFilterChip(
                        label: 'Category: $_selectedCategory',
                        onRemove: () => setState(() => _selectedCategory = 'All'),
                      ),
                    if (_onlyInStock)
                      _buildActiveFilterChip(
                        label: 'In Stock Only',
                        onRemove: () => setState(() => _onlyInStock = false),
                      ),
                    if (_minRating > 0)
                      _buildActiveFilterChip(
                        label: '★ $_minRating+',
                        onRemove: () => setState(() => _minRating = 0.0),
                      ),
                    if (_priceRange.start > 0 || _priceRange.end < 100000)
                      _buildActiveFilterChip(
                        label: '${AppConstants.formatCurrency(_priceRange.start)} - ${AppConstants.formatCurrency(_priceRange.end)}',
                        onRemove: () => setState(() => _priceRange = const RangeValues(0, 100000)),
                      ),
                    InkWell(
                      onTap: _resetAllFilters,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ===== 5. Products Grid =====
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search_off_rounded, size: 40, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Products Found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'We couldn\'t find any products matching your filters.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _resetAllFilters,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Reset All Filters'),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return ProductCard(
                        product: product,
                        heroTagPrefix: 'all_prod',
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip({required String label, required VoidCallback onRemove}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  void _openFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filter Products', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCategory = 'All';
                            _onlyInStock = false;
                            _minRating = 0.0;
                            _priceRange = const RangeValues(0, 100000);
                          });
                        },
                        child: const Text('Reset', style: TextStyle(color: AppTheme.error)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Price Range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Price Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${AppConstants.formatCurrency(_priceRange.start)} - ${AppConstants.formatCurrency(_priceRange.end)}',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 100000,
                    divisions: 50,
                    activeColor: AppTheme.primaryColor,
                    labels: RangeLabels(AppConstants.formatCurrency(_priceRange.start), AppConstants.formatCurrency(_priceRange.end)),
                    onChanged: (values) => setModalState(() => _priceRange = values),
                  ),
                  const SizedBox(height: 14),

                  // Minimum Rating
                  const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [0.0, 3.0, 4.0, 4.5].map((rating) {
                      final isSelected = _minRating == rating;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: Text(rating == 0 ? 'All' : '★ $rating+'),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                          onSelected: (_) => setModalState(() => _minRating = rating),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // In Stock Only Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('In Stock Only', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Show only items available for immediate order', style: TextStyle(fontSize: 12)),
                    value: _onlyInStock,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) => setModalState(() => _onlyInStock = val),
                  ),
                  const SizedBox(height: 20),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
