import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../services/cloudinary_service.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/wishlist_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  String? _selectedColor;
  String? _selectedSize;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.product.colors.isNotEmpty) {
      _selectedColor = widget.product.colors.first;
    }
    if (widget.product.sizes.isNotEmpty) {
      _selectedSize = widget.product.sizes.first;
    }
    // Start listening to reviews
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().listenToReviews(widget.product.id);
    });
  }

  @override
  void dispose() {
    context.read<ReviewProvider>().stopListening(widget.product.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final wishlistProvider = context.watch<WishlistProvider>();
    final isWishlisted = wishlistProvider.isInWishlist(product.id);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. Collapsing App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon: Icon(
                      isWishlisted ? Icons.favorite : Icons.favorite_border_rounded,
                      color: isWishlisted ? AppTheme.error : AppTheme.textPrimary,
                      size: 20,
                    ),
                    onPressed: () {
                      wishlistProvider.toggleWishlist(product);
                      if (isWishlisted) {
                        AppToast.showInfo(context, 'Removed from wishlist', title: 'Wishlist');
                      } else {
                        AppToast.showSuccess(context, 'Added "${product.name}" to wishlist ❤️', title: 'Wishlist');
                      }
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product_image_${product.id}',
                    child: kIsWeb
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.grey.shade100,
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stack) => Container(
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey),
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: CloudinaryService.detail(product.imageUrl),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade100,
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey),
                            ),
                          ),
                  ),
                  // Gradient shadow at bottom of image
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Product Details Body
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Stock Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          if (product.displayQuantity.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                product.displayQuantity,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: product.inStock ? AppTheme.success : AppTheme.error,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            product.inStock ? product.stockDisplay : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: product.inStock ? AppTheme.success : AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Brand & Rating Row
                  Row(
                    children: [
                      Text(
                        'By ${product.brand}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.star_rounded, color: AppTheme.starGold, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product.reviewCount} reviews)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price & Discount row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        AppConstants.formatCurrency(product.price),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      if (product.originalPrice > product.price) ...[
                        const SizedBox(width: 10),
                        Text(
                          AppConstants.formatCurrency(product.originalPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Save ${product.discountPercent.toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.cardBorder),
                  const SizedBox(height: 16),

                  // Color Selector (if product has colors)
                  if (product.colors.isNotEmpty) ...[
                    const Text(
                      'Select Color',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: product.colors.map((colorName) {
                        final isSelected = _selectedColor == colorName;
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Text(colorName),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.cardBorder,
                            width: 1.5,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedColor = colorName);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Size Selector (if product has sizes)
                  if (product.sizes.isNotEmpty) ...[
                    const Text(
                      'Select Size / Variant',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: product.sizes.map((sizeName) {
                        final isSelected = _selectedSize == sizeName;
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Text(sizeName),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryDark,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryDark : AppTheme.cardBorder,
                            width: 1.5,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedSize = sizeName);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Description
                  const Text(
                    'About This Product',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                    maxLines: _isDescriptionExpanded ? null : 3,
                    overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  if (product.description.length > 120) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Text(
                        _isDescriptionExpanded ? 'Read Less' : 'Read More',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],

                  // ===== REVIEWS SECTION =====
                  const SizedBox(height: 28),
                  const Divider(color: AppTheme.cardBorder),
                  const SizedBox(height: 16),
                  _ReviewsSection(product: product),
                ],
              ),
            ),
          ),
        ],
      ),

      // 3. Sticky Bottom Action Bar with Quantity Counter & Add to Cart
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(
            top: BorderSide(color: AppTheme.cardBorder),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Quantity Stepper
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Text(
                      product.unit != 'pcs' ? '$_quantity ${product.unit}' : '$_quantity',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: _quantity < product.stockCount
                          ? () => setState(() => _quantity++)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Add to Cart Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<CartProvider>().addToCart(
                          product,
                          quantity: _quantity,
                          selectedColor: _selectedColor,
                          selectedSize: _selectedSize,
                        );

                    AppToast.showSuccess(
                      context,
                      'Added $_quantity "${product.name}" to cart! 🛍️',
                      title: 'Added to Cart',
                      actionLabel: 'GO TO CART',
                      onAction: () => Navigator.of(context).pop(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Add to Cart • ${AppConstants.formatCurrency(product.price * _quantity)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
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
  }
}

// ===================== REVIEWS SECTION =====================

class _ReviewsSection extends StatefulWidget {
  final ProductModel product;
  const _ReviewsSection({required this.product});

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  double _selectedRating = 5.0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showWriteReviewSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest) {
      AppToast.showWarning(context, 'Please sign in to write a review', title: 'Sign In Required');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Write a Review',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Your Rating',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setModalState(() => _selectedRating = i + 1.0),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          _selectedRating >= i + 1 ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: AppTheme.starGold,
                          size: 34,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Your Review',
                    hintText: 'Share your thoughts about this product...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                Consumer<ReviewProvider>(
                  builder: (ctx, reviewProvider, _) => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: reviewProvider.isSubmitting
                          ? null
                          : () async {
                              if (_commentController.text.trim().isEmpty) return;
                              final success = await reviewProvider.submitReview(
                                productId: widget.product.id,
                                userId: auth.userId,
                                userName: auth.displayName,
                                rating: _selectedRating,
                                comment: _commentController.text.trim(),
                              );
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                _commentController.clear();
                                if (success) {
                                  AppToast.showSuccess(context, 'Review submitted! ⭐', title: 'Thank You');
                                } else {
                                  AppToast.showError(context, 'You have already reviewed this product.', title: 'Duplicate Review');
                                }
                              }
                            },
                      child: reviewProvider.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Submit Review'),
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

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewProvider>().getReviews(widget.product.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer Reviews',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text('${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showWriteReviewSheet(context),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Write Review'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.rate_review_outlined, size: 36, color: AppTheme.textMuted),
                  SizedBox(height: 8),
                  Text('No reviews yet. Be the first!',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          ...reviews.map((review) => _ReviewCard(review: review)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'A',
                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < review.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: AppTheme.starGold,
                          size: 14,
                        )),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(review.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
