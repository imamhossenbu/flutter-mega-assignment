import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../details/product_details_screen.dart';

/// A unified, high-performance, animated E-Commerce Product Card.
/// Designed for maximum speed (cached image decoding), beautiful micro-animations,
/// and consistent visual aesthetics across GridView and horizontal carousels.
class ProductCard extends StatefulWidget {
  final ProductModel product;
  final double? width;
  final double? height;
  final bool showDiscount;
  final String? heroTagPrefix;

  const ProductCard({
    super.key,
    required this.product,
    this.width,
    this.height,
    this.showDiscount = true,
    this.heroTagPrefix,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _justAdded = false;
  bool _heartAnimating = false;

  void _triggerHeartAnimation() {
    setState(() => _heartAnimating = true);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _heartAnimating = false);
    });
  }

  void _triggerAddAnimation() {
    setState(() => _justAdded = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _justAdded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final wishlistProvider = context.watch<WishlistProvider>();
    final isWishlisted = wishlistProvider.isInWishlist(product.id);
    final hasDiscount = widget.showDiscount && product.discountPercent > 0;
    final isOutOfStock = !product.inStock || product.stockCount == 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? AppTheme.primaryColor.withOpacity(0.12)
                  : const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: _isHovered ? 12 : 6,
              offset: const Offset(0, 2),
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
                  // ===== 1. Image Section with Badges =====
                  _buildImageSection(context, isWishlisted, wishlistProvider, hasDiscount, isOutOfStock),

                  // ===== 2. Product Details & Action =====
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top info: Brand & Rating + Title
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            product.brand.isNotEmpty
                                                ? product.brand.toUpperCase()
                                                : product.category.toUpperCase(),
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
                                        if (product.displayQuantity.isNotEmpty) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              product.displayQuantity,
                                              style: const TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                      const SizedBox(width: 2),
                                      Text(
                                        product.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),

                          // Bottom info: Stock status + Price & Action Button
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isOutOfStock)
                                const Text(
                                  'Out of stock',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.error),
                                )
                              else if (product.stockCount <= 5)
                                Text(
                                  '⚡ Only ${product.stockCount} ${product.unit} left!',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEA580C),
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF10B981)),
                                    const SizedBox(width: 3),
                                    Text(
                                      product.unit != 'pcs'
                                          ? 'In Stock (${product.stockCount} ${product.unit})'
                                          : 'In Stock',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 5),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Price
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (product.originalPrice > product.price)
                                          Text(
                                            '\$${product.originalPrice.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              decoration: TextDecoration.lineThrough,
                                              color: Color(0xFF94A3B8),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        Text(
                                          '\$${product.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),

                                  // Animated Quick Action Button
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
        ),
      );
  }

  Widget _buildImageSection(
    BuildContext context,
    bool isWishlisted,
    WishlistProvider wishlistProvider,
    bool hasDiscount,
    bool isOutOfStock,
  ) {
    final product = widget.product;
    final heroTag = '${widget.heroTagPrefix ?? 'product'}_${product.id}';

    return AspectRatio(
      aspectRatio: 1.15,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image Container
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              child: Hero(
                tag: heroTag,
                child: kIsWeb
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryLight),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                      )
                    : CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 400,
                        memCacheHeight: 400,
                        fadeInDuration: const Duration(milliseconds: 250),
                        placeholder: (_, __) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryLight),
                            ),
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
                  color: AppTheme.primaryColor,
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

          // Animated Wishlist Heart (Top-Right)
          Positioned(
            top: 7,
            right: 7,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  _triggerHeartAnimation();
                  wishlistProvider.toggleWishlist(product);
                  if (isWishlisted) {
                    AppToast.showInfo(context, 'Removed from wishlist', title: 'Wishlist');
                  } else {
                    AppToast.showSuccess(context, 'Saved "${product.name}" to wishlist ❤️', title: 'Wishlist');
                  }
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
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 1.0,
                        end: _heartAnimating ? 1.35 : 1.0,
                      ),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Icon(
                            isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 17,
                            color: isWishlisted ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Out Of Stock Overlay
          if (isOutOfStock)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.48),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              ),
              child: const Center(
                child: ContainerBadge(
                  text: 'SOLD OUT',
                  backgroundColor: Color(0xFF1E293B),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(BuildContext context, bool isOutOfStock) {
    return Material(
      color: isOutOfStock
          ? const Color(0xFFE2E8F0)
          : (_justAdded ? const Color(0xFF10B981) : AppTheme.primaryColor),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: isOutOfStock
            ? () => AppToast.showWarning(context, 'This item is currently out of stock')
            : () => _handleAddToCart(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _justAdded
                ? Icons.check_rounded
                : ((widget.product.colors.length > 1 || widget.product.sizes.length > 1)
                    ? Icons.tune_rounded
                    : Icons.add_shopping_cart_rounded),
            color: isOutOfStock ? const Color(0xFF94A3B8) : Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  void _handleAddToCart(BuildContext context) {
    final product = widget.product;
    if (product.colors.length > 1 || product.sizes.length > 1) {
      _showQuickVariantSelector(context);
    } else {
      _triggerAddAnimation();
      final cartProvider = context.read<CartProvider>();
      cartProvider.addToCart(
        product,
        selectedColor: product.colors.isNotEmpty ? product.colors.first : null,
        selectedSize: product.sizes.isNotEmpty ? product.sizes.first : null,
      );
      AppToast.showSuccess(
        context,
        'Added "${product.name}" to cart! 🛍️',
        title: 'Cart Updated',
      );
    }
  }

  void _showQuickVariantSelector(BuildContext context) {
    final product = widget.product;
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
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: kIsWeb
                            ? Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image),
                              )
                            : CachedNetworkImage(
                                imageUrl: product.imageUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 200,
                                errorWidget: (_, __, ___) => const Icon(Icons.image),
                              ),
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

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      _triggerAddAnimation();
                      context.read<CartProvider>().addToCart(
                            product,
                            selectedColor: chosenColor,
                            selectedSize: chosenSize,
                          );
                      Navigator.pop(ctx);
                      AppToast.showSuccess(
                        context,
                        'Added "${product.name}"${chosenSize != null ? " ($chosenSize)" : ""} to cart! 🛍️',
                        title: 'Cart Updated',
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
}

class ContainerBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;

  const ContainerBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
