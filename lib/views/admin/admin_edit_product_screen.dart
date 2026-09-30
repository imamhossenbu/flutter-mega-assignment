import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/cloudinary_service.dart';

class AdminEditProductScreen extends StatefulWidget {
  final ProductModel? product;
  const AdminEditProductScreen({super.key, this.product});

  @override
  State<AdminEditProductScreen> createState() => _AdminEditProductScreenState();
}

class _AdminEditProductScreenState extends State<AdminEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _originalPriceController;
  late TextEditingController _stockController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;

  final Set<String> _selectedColors = {};
  final Set<String> _selectedSizes = {};

  bool _isFeatured = false;
  bool _inStock = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (picked == null) return;

      setState(() => _isUploadingImage = true);

      final bytes = await picked.readAsBytes();
      final uploadedUrl = await CloudinaryService.instance.uploadImageBytes(
        bytes,
        filename: picked.name,
      );

      if (uploadedUrl != null && mounted) {
        setState(() {
          _imageUrlController.text = uploadedUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded to Cloudinary successfully! ☁️'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showCloudinaryConfigDialog(context, error: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showCloudinaryConfigDialog(BuildContext context, {String? error}) {
    final cloudNameCtrl = TextEditingController(text: CloudinaryService.instance.cloudName);
    final apiKeyCtrl = TextEditingController(text: CloudinaryService.instance.apiKey);
    final apiSecretCtrl = TextEditingController(text: CloudinaryService.instance.apiSecret);
    final presetCtrl = TextEditingController(text: CloudinaryService.instance.uploadPreset);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.cloud_queue_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Cloudinary Settings'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(fontSize: 12, color: AppTheme.error),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'Please verify your Cloudinary Cloud Name. API Key and Secret are pre-configured.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cloudNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cloud Name *',
                  hintText: 'e.g. imamhossenbu or dx... (from Cloudinary dashboard)',
                  prefixIcon: Icon(Icons.cloud_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: apiKeyCtrl,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: apiSecretCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Secret',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: presetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Upload Preset (Optional)',
                  hintText: 'e.g. ml_default or unsigned preset',
                  prefixIcon: Icon(Icons.tune_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              CloudinaryService.instance.configure(
                newCloudName: cloudNameCtrl.text,
                newApiKey: apiKeyCtrl.text,
                newApiSecret: apiSecretCtrl.text,
                newPreset: presetCtrl.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cloudinary configuration updated!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Save & Apply'),
          ),
        ],
      ),
    );
  }

  final List<Map<String, String>> _sampleImagePresets = [
    {
      'title': 'Sneakers',
      'url': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80',
    },
    {
      'title': 'Headphones',
      'url': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80',
    },
    {
      'title': 'Smartwatch',
      'url': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80',
    },
    {
      'title': 'Backpack',
      'url': 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800&q=80',
    },
    {
      'title': 'Sunglasses',
      'url': 'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=800&q=80',
    },
    {
      'title': 'Leather Jacket',
      'url': 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _brandController = TextEditingController(text: p?.brand ?? '');
    _categoryController = TextEditingController(text: p?.category ?? 'Electronics');
    _priceController = TextEditingController(text: p != null ? p.price.toStringAsFixed(2) : '');
    _originalPriceController = TextEditingController(
        text: p != null && p.originalPrice > 0 ? p.originalPrice.toStringAsFixed(2) : '');
    _stockController = TextEditingController(text: p != null ? '${p.stockCount}' : '20');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');

    if (p != null) {
      _selectedColors.addAll(p.colors);
      _selectedSizes.addAll(p.sizes);
    } else {
      _selectedColors.addAll(['Black', 'White']);
      _selectedSizes.addAll(['M', 'L']);
    }

    _isFeatured = p?.isFeatured ?? false;
    _inStock = p?.inStock ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<ProductProvider>();

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final origPrice = double.tryParse(_originalPriceController.text.trim()) ?? price;
    final stock = int.tryParse(_stockController.text.trim()) ?? 10;
    final colors = _selectedColors.isNotEmpty ? _selectedColors.toList() : ['Standard'];
    final sizes = _selectedSizes.isNotEmpty ? _selectedSizes.toList() : ['One Size'];

    final productToSave = ProductModel(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      category: _categoryController.text.trim(),
      price: price,
      originalPrice: origPrice,
      rating: widget.product?.rating ?? 4.8,
      reviewCount: widget.product?.reviewCount ?? 12,
      imageUrl: _imageUrlController.text.trim(),
      description: _descriptionController.text.trim(),
      colors: colors,
      sizes: sizes,
      isFeatured: _isFeatured,
      inStock: _inStock && stock > 0,
      stockCount: stock,
    );

    bool success;
    if (widget.product == null) {
      success = await provider.addProduct(productToSave);
    } else {
      success = await provider.updateProduct(productToSave);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.product == null ? 'Product added successfully!' : 'Product updated!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save product. Please try again.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final adminProvider = context.watch<AdminProvider>();
    final dbCategories = (adminProvider.categories).map((c) => c.name).toList();
    final dbBrands = (adminProvider.brands).map((b) => b.name).toList();
    final dbColors = adminProvider.colors;
    final dbSizes = adminProvider.sizes;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveProduct,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                  )
                : const Icon(Icons.check_rounded, color: AppTheme.primaryColor),
            label: Text(
              isEditing ? 'Update' : 'Publish',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image preview & preset picker
              _buildImageSection(),
              const SizedBox(height: 20),

              // Basic details card
              _buildSectionCard(
                title: 'Basic Information',
                icon: Icons.info_outline_rounded,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      hintText: 'e.g., Wireless Noise-Cancelling Headphones',
                      prefixIcon: Icon(Icons.label_outline_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Product name is required';
                      if (v.trim().length < 3) return 'Product name must be at least 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _brandController,
                          decoration: const InputDecoration(
                            labelText: 'Brand *',
                            hintText: 'e.g., Sony, Nike',
                            prefixIcon: Icon(Icons.business_rounded),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Brand is required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            hintText: 'e.g., Audio',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Category is required' : null,
                        ),
                      ),
                    ],
                  ),
                  if (dbBrands.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Select Brand:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: dbBrands.map((b) {
                        final selected = _brandController.text.toLowerCase() == b.toLowerCase();
                        return ChoiceChip(
                          label: Text(b, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppTheme.textSecondary)),
                          selected: selected,
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (_) => setState(() => _brandController.text = b),
                        );
                      }).toList(),
                    ),
                  ],
                  if (dbCategories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Select Category:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: dbCategories.map((cat) {
                        final selected = _categoryController.text.toLowerCase() == cat.toLowerCase();
                        return ChoiceChip(
                          label: Text(cat, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppTheme.textSecondary)),
                          selected: selected,
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (_) => setState(() => _categoryController.text = cat),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Pricing & Stock
              _buildSectionCard(
                title: 'Pricing & Inventory',
                icon: Icons.monetization_on_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Selling Price (\$) *',
                            hintText: '99.99',
                            prefixIcon: Icon(Icons.attach_money_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Price is required';
                            final p = double.tryParse(v.trim());
                            if (p == null || p <= 0) return 'Price must be greater than 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _originalPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Original Price (\$) (Optional)',
                            hintText: '129.99',
                            prefixIcon: Icon(Icons.money_off_rounded),
                          ),
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              final op = double.tryParse(v.trim());
                              if (op == null || op <= 0) return 'Invalid original price';
                              final sp = double.tryParse(_priceController.text.trim()) ?? 0;
                              if (op < sp) return 'Must be >= selling price';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Stock Units *',
                            hintText: '25',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Stock is required';
                            final s = int.tryParse(v.trim());
                            if (s == null || s < 0) return 'Stock must be 0 or more';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('In Stock', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          value: _inStock,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (v) => setState(() => _inStock = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mark as Featured Product', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Appears in the top banner and featured carousel', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    value: _isFeatured,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => setState(() => _isFeatured = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description & Variants (Colors & Sizes)
              _buildSectionCard(
                title: 'Description & Variants',
                icon: Icons.tune_rounded,
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Product Description *',
                      hintText: 'Detailed product specifications, materials, warranty, features...',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Description is required';
                      if (v.trim().length < 10) return 'Description must be at least 10 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Colors Multi-select
                  const Text('Available Colors:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Tap to toggle colors available for this product', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dbColors.map((colorName) {
                      final isSelected = _selectedColors.contains(colorName);
                      return FilterChip(
                        label: Text(colorName),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                        checkmarkColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedColors.add(colorName);
                            } else {
                              _selectedColors.remove(colorName);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Sizes Multi-select
                  const Text('Available Sizes:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Tap to toggle sizes available for this product', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dbSizes.map((sizeName) {
                      final isSelected = _selectedSizes.contains(sizeName);
                      return FilterChip(
                        label: Text(sizeName),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                        checkmarkColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSizes.add(sizeName);
                            } else {
                              _selectedSizes.remove(sizeName);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProduct,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    isEditing ? 'Save Product Changes' : 'Create & Publish Product',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final url = _imageUrlController.text.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.image_outlined, color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text('Product Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 20, color: AppTheme.textSecondary),
                tooltip: 'Cloudinary Settings',
                onPressed: () => _showCloudinaryConfigDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Upload to Cloudinary Hero Action
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.08),
                  AppTheme.primaryLight.withOpacity(0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                if (_isUploadingImage) ...[
                  const CircularProgressIndicator(color: AppTheme.primaryColor),
                  const SizedBox(height: 10),
                  const Text(
                    'Uploading image to Cloudinary...',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: _pickAndUploadImage,
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: const Text('Pick & Upload Image (Cloudinary)', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Picks local image from device ➔ Uploads to Cloudinary ➔ Generates CDN URL',
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (url.isNotEmpty)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  url,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    color: Colors.grey.shade100,
                    child: const Center(child: Text('Invalid image URL', style: TextStyle(color: AppTheme.error))),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _imageUrlController,
            decoration: InputDecoration(
              labelText: 'Generated Image URL *',
              hintText: 'https://res.cloudinary.com/...',
              prefixIcon: const Icon(Icons.link_rounded),
              suffixIcon: url.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _imageUrlController.clear()),
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Image URL is required';
              if (!v.trim().startsWith('http://') && !v.trim().startsWith('https://')) {
                return 'Please enter a valid URL or upload via Cloudinary';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          const Text('Or Select Preset Photo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sampleImagePresets.map((preset) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.photo_size_select_actual_outlined, size: 16),
                    label: Text(preset['title']!),
                    onPressed: () {
                      setState(() {
                        _imageUrlController.text = preset['url']!;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
