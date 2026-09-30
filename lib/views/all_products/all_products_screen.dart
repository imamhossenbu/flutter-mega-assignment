import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../details/product_details_screen.dart';

class AllProductsScreen extends StatefulWidget {
  final String title;
  final List<ProductModel>? products;
  const AllProductsScreen({super.key, required this.title, this.products});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allProds = widget.products ?? context.watch<ProductProvider>().allProducts;
    final filtered = _query.isEmpty
        ? allProds
        : allProds.where((p) =>
            p.name.toLowerCase().contains(_query) ||
            p.brand.toLowerCase().contains(_query) ||
            p.category.toLowerCase().contains(_query)).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
                  SizedBox(height: 12),
                  Text('No products found', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final product = filtered[index];
                return _ProductTile(product: product);
              },
            ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final discountPercent = product.discountPercent.toInt();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 140,
                    child: kIsWeb
                        ? Image.network(product.imageUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
                            ))
                        : Image.network(product.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                if (discountPercent > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('-$discountPercent%',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.brand.toUpperCase(),
                        style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(product.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Text('\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
