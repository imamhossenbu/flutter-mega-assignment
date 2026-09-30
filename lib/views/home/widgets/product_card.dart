import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../details/product_details_screen.dart';

/// A real-world, high-converting E-Commerce Product Card.
/// Can be used both inside GridView and as a fixed-width horizontal carousel item.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double? width;
  final bool showDiscount;

  const ProductCard({
    super.key,
    required this.product,
    this.width,
    this.showDiscount = true,
  });

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = context.watch<WishlistProvider>();
    final isWishlisted = wishlistProvider.isInWishlist(product.id);
    final hasDiscount = showDiscount && product.discountPercent > 0;
    final isOutOfStock = !product.inStock || product.stockCount == 0;

    final cardWidget = Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF2), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(product: product),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== 1. Image Container with Badges =====
              _buildImageSection(context, isWishlisted, wishlistProvider, hasDiscount, isOutOfStock),

              // ===== 2. Product Info & Action Section =====
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Upper block: Brand, Category, Rating & Title
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand & Rating row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  product.brand.isNotEmpty ? product.brand.toUpperCase() : product.category.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    product.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  if (product.reviewCount > 0)
                                    Text(
                                      ' (${product.reviewCount})',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),

                          // Product Title (2 lines)
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Lower block: Trust Badge + Price & Add to Cart
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stock or Delivery Trust Note
                          if (isOutOfStock)
                            const Text(
                              'Out of stock',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.error),
                            )
                          else if (product.stockCount <= 5)
                            Text(
                              '⚡ Only ${product.stockCount} left!',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEA580C),
                              ),
                            )
                          else
                            const Row(
                              children: [
                                Icon(Icons.verified_rounded, size: 11, color: Color(0xFF10B981)),
                                SizedBox(width: 3),
                                Text(
                                  'Free Delivery',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 5),

                          // Price & Cart Button Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Price Column
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (product.originalPrice > product.price)
                                      Text(
                                        '\$${product.originalPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          decoration: TextDecoration.lineThrough,
                                          color: Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    Text(
                                      '\$${product.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Quick Add / Variant Button
                              _buildQuickActionButton(context, isOutOfStock),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return cardWidget;
  }

  Widget _buildImageSection(
    BuildContext context,
    bool isWishlisted,
    WishlistProvider wishlistProvider,
    bool hasDiscount,
    bool isOutOfStock,
  ) {
    return AspectRatio(
      aspectRatio: 1.08,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background & Image
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              child: Hero(
                tag: 'product_image_${product.id}',
                child: kIsWeb
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                      )
                    : CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _buildImagePlaceholder(),
                      ),
              ),
            ),
          ),

          // Discount Badge (Top-Left)
          if (hasDiscount)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '-${product.discountPercent.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            )
          else if (product.isFeatured)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HOT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          // Wishlist Toggle (Top-Right)
          Positioned(
            top: 7,
            right: 7,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  wishlistProvider.toggleWishlist(product);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isWishlisted ? 'Removed from wishlist' : 'Saved to wishlist ❤️',
                      ),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        key: ValueKey<bool>(isWishlisted),
                        size: 17,
                        color: isWishlisted ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Available Variant Swatches (Bottom-Left of Image)
          if (product.colors.isNotEmpty)
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...product.colors.take(3).map((col) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _parseColor(col),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      );
                    }),
                    if (product.colors.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          '+${product.colors.length - 3}',
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Out Of Stock Overlay
          if (isOutOfStock)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  child: Text(
                    'SOLD OUT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(BuildContext context, bool isOutOfStock) {
    return Material(
      color: isOutOfStock ? const Color(0xFFE2E8F0) : AppTheme.primaryColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: isOutOfStock
            ? () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item is currently out of stock'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            : () => _handleAddToCart(context),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            (product.colors.length > 1 || product.sizes.length > 1)
                ? Icons.tune_rounded
                : Icons.add_shopping_cart_rounded,
            color: isOutOfStock ? const Color(0xFF94A3B8) : Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  void _handleAddToCart(BuildContext context) {
    // If the product has multiple color or size variants, open a quick selector modal
    if (product.colors.length > 1 || product.sizes.length > 1) {
      _showQuickVariantSelector(context);
    } else {
      final cartProvider = context.read<CartProvider>();
      cartProvider.addToCart(
        product,
        selectedColor: product.colors.isNotEmpty ? product.colors.first : null,
        selectedSize: product.sizes.isNotEmpty ? product.sizes.first : null,
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${product.name}" to cart! 🛍️'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showQuickVariantSelector(BuildContext context) {
    String? chosenColor = product.colors.isNotEmpty ? product.colors.first : null;
    String? chosenSize = product.sizes.isNotEmpty ? product.sizes.first : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Color Selector
                if (product.colors.isNotEmpty) ...[
                  const Text('Select Color:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.colors.map((c) {
                      final isSelected = c == chosenColor;
                      return ChoiceChip(
                        label: Text(c),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : const Color(0xFF334155),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setModalState(() => chosenColor = c);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                // Size Selector
                if (product.sizes.isNotEmpty) ...[
                  const Text('Select Size:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.sizes.map((s) {
                      final isSelected = s == chosenSize;
                      return ChoiceChip(
                        label: Text(s),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : const Color(0xFF334155),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setModalState(() => chosenSize = s);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                ],

                // Confirm Add to Cart Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      context.read<CartProvider>().addToCart(
                            product,
                            selectedColor: chosenColor,
                            selectedSize: chosenSize,
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added "${product.name}"${chosenSize != null ? " ($chosenSize)" : ""} to cart! 🛍️',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                    label: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 32),
      ),
    );
  }

  static Color _parseColor(String colorName) {
    final name = colorName.trim().toLowerCase();
    switch (name) {
      case 'black':
        return const Color(0xFF18181B);
      case 'white':
        return const Color(0xFFF8FAFC);
      case 'red':
        return const Color(0xFFEF4444);
      case 'blue':
      case 'navy':
        return const Color(0xFF2563EB);
      case 'green':
      case 'olive':
        return const Color(0xFF10B981);
      case 'yellow':
        return const Color(0xFFF59E0B);
      case 'orange':
        return const Color(0xFFF97316);
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'pink':
        return const Color(0xFFEC4899);
      case 'gray':
      case 'grey':
        return const Color(0xFF64748B);
      case 'brown':
        return const Color(0xFF78350F);
      case 'gold':
        return const Color(0xFFD97706);
      case 'silver':
        return const Color(0xFF94A3B8);
      default:
        if (colorName.startsWith('#')) {
          final hex = colorName.replaceAll('#', '');
          if (hex.length == 6) {
            return Color(int.parse('FF$hex', radix: 16));
          }
        }
        return const Color(0xFF6366F1);
    }
  }
}
