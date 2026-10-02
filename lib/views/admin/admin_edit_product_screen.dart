import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../models/category_model.dart';
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
  late TextEditingController _unitSizeController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;

  String _selectedUnit = 'pcs';
  final Set<String> _selectedColors = {};
  final Set<String> _selectedSizes = {};

  bool _isFeatured = false;
  bool _inStock = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  double _imageUploadProgress = 0.0;

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

      setState(() {
        _isUploadingImage = true;
        _imageUploadProgress = 0.10;
      });

      final bytes = await picked.readAsBytes();
      final uploadedUrl = await CloudinaryService.instance.uploadImageBytes(
        bytes,
        filename: picked.name,
        onProgress: (p) {
          if (mounted) setState(() => _imageUploadProgress = p);
        },
      );

      if (uploadedUrl != null && mounted) {
        setState(() {
          _imageUrlController.text = uploadedUrl;
          _imageUploadProgress = 1.0;
        });
        AppToast.showSuccess(
          context,
          'Image uploaded to Cloudinary successfully! ☁️',
          title: 'Upload Complete',
        );
      }
    } catch (e) {
      if (mounted) {
        _showCloudinaryConfigDialog(context, error: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _imageUploadProgress = 0.0;
        });
      }
    }
  }

  void _showCloudinaryConfigDialog(BuildContext context, {String? error}) {
    final cloudNameCtrl = TextEditingController(text: CloudinaryService.instance.cloudName);
    final presetCtrl = TextEditingController(text: CloudinaryService.instance.uploadPreset);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_queue_rounded, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Cloudinary Settings',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'Uses Unsigned Upload Preset. Configure via .env or update values below.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: cloudNameCtrl,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: 'Cloud Name *',
                  hintText: 'e.g. your_cloud_name',
                  prefixIcon: const Icon(Icons.cloud_outlined, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: presetCtrl,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: 'Upload Preset *',
                  hintText: 'e.g. flutter_upload (Unsigned)',
                  prefixIcon: const Icon(Icons.tune_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              CloudinaryService.instance.configure(
                newCloudName: cloudNameCtrl.text,
                newPreset: presetCtrl.text,
              );
              Navigator.pop(ctx);
              AppToast.showSuccess(context, 'Cloudinary settings updated!', title: 'Saved');
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save & Apply', style: TextStyle(fontWeight: FontWeight.bold)),
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

  static const List<Map<String, String>> unitOptions = [
    {'key': 'pcs', 'label': 'Pieces (pcs)', 'short': 'pcs'},
    {'key': 'ml', 'label': 'Milliliters (ml)', 'short': 'ml'},
    {'key': 'L', 'label': 'Liters (L)', 'short': 'L'},
    {'key': 'g', 'label': 'Grams (g)', 'short': 'g'},
    {'key': 'kg', 'label': 'Kilograms (kg)', 'short': 'kg'},
    {'key': 'pack', 'label': 'Pack / Bundle', 'short': 'pack'},
    {'key': 'pair', 'label': 'Pairs (pair)', 'short': 'pair'},
    {'key': 'box', 'label': 'Boxes (box)', 'short': 'box'},
  ];

  Future<void> _showAddCategoryDialog(BuildContext context, AdminProvider adminProvider) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g. Perfume, Skincare, Groceries',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await adminProvider.addCategory(name);
      setState(() => _categoryController.text = name);
      if (context.mounted) {
        AppToast.showSuccess(context, 'Category "$name" added and selected! 🎉', title: 'Category Created');
      }
    }
  }

  void _openCategorySearchModal(BuildContext context, AdminProvider adminProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            // Deduplicate categories by name (keep the one with most subcategories)
            final allCats = adminProvider.categories;
            final Map<String, CategoryModel> seen = {};
            for (final cat in allCats) {
              if (!seen.containsKey(cat.name) || cat.subcategories.length > seen[cat.name]!.subcategories.length) {
                seen[cat.name] = cat;
              }
            }
            final categories = seen.values.toList();
            final q = query.trim().toLowerCase();
            final filtered = categories.where((cat) {
              if (q.isEmpty) return true;
              final parentMatch = cat.name.toLowerCase().contains(q);
              final subMatch = cat.subcategories.any((s) => s.toLowerCase().contains(q));
              return parentMatch || subMatch;
            }).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.78,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Select Category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text(
                            'New Category',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddCategoryDialog(context, adminProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search category or subcategory...',
                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (val) => setModalState(() => query = val),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.category_outlined, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text('No category found matching search', style: TextStyle(color: AppTheme.textMuted)),
                                const SizedBox(height: 10),
                                if (query.trim().isNotEmpty)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: Text('Create "$query"'),
                                    onPressed: () async {
                                      final newName = query.trim();
                                      Navigator.pop(ctx);
                                      await adminProvider.addCategory(newName);
                                      setState(() => _categoryController.text = newName);
                                      if (context.mounted) {
                                        AppToast.showSuccess(context, 'Created and selected category "$newName"');
                                      }
                                    },
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final cat = filtered[i];
                              final isSelected = _categoryController.text.toLowerCase() == cat.name.toLowerCase();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryColor.withOpacity(0.06) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Theme(
                                  data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
                                  child: cat.subcategories.isEmpty
                                      ? ListTile(
                                          leading: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.folder_rounded, color: AppTheme.primaryColor, size: 18),
                                          ),
                                          title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor) : null,
                                          onTap: () {
                                            setState(() => _categoryController.text = cat.name);
                                            Navigator.pop(ctx);
                                          },
                                        )
                                      : ExpansionTile(
                                          shape: const RoundedRectangleBorder(side: BorderSide.none),
                                          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                                          initiallyExpanded: q.isNotEmpty || isSelected,
                                          leading: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.folder_rounded, color: AppTheme.primaryColor, size: 18),
                                          ),
                                          title: Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  cat.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${cat.subcategories.length} sub',
                                                  style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  visualDensity: VisualDensity.compact,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  foregroundColor: AppTheme.primaryColor,
                                                ),
                                                onPressed: () {
                                                  setState(() => _categoryController.text = cat.name);
                                                  Navigator.pop(ctx);
                                                },
                                                child: const Text('Select', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              ),
                                              const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                                            ],
                                          ),
                                          children: [
                                            ListTile(
                                              contentPadding: const EdgeInsets.only(left: 36, right: 16),
                                              leading: const Icon(Icons.done_all_rounded, size: 18, color: AppTheme.primaryColor),
                                              title: Text(
                                                'All in ${cat.name}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                  color: isSelected ? AppTheme.primaryColor : const Color(0xFF1E293B),
                                                ),
                                              ),
                                              trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 18) : null,
                                              onTap: () {
                                                setState(() => _categoryController.text = cat.name);
                                                Navigator.pop(ctx);
                                              },
                                            ),
                                            ...cat.subcategories.map((sub) {
                                            final isSubSelected = _categoryController.text.toLowerCase() == sub.toLowerCase() ||
                                                _categoryController.text.toLowerCase() == '${cat.name} > $sub'.toLowerCase();
                                            return ListTile(
                                              contentPadding: const EdgeInsets.only(left: 36, right: 16),
                                              leading: const Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: AppTheme.primaryColor),
                                              title: Text(
                                                sub,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: isSubSelected ? FontWeight.bold : FontWeight.w500,
                                                  color: isSubSelected ? AppTheme.primaryColor : const Color(0xFF1E293B),
                                                ),
                                              ),
                                              trailing: isSubSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 18) : null,
                                              onTap: () {
                                                setState(() => _categoryController.text = '${cat.name} > $sub');
                                                Navigator.pop(ctx);
                                              },
                                            );
                                          }),
                                        ],
                                      ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openBrandSearchModal(BuildContext context, AdminProvider adminProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final brands = adminProvider.brands.map((b) => b.name).toList();
            if (brands.isEmpty) {
              brands.addAll(['Apple', 'Sony', 'Nike', 'Samsung', 'Adidas', 'Logitech', 'Bose']);
            }
            final q = query.trim().toLowerCase();
            final filtered = brands.where((b) => q.isEmpty || b.toLowerCase().contains(q)).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.72,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Select Brand',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text(
                            'New Brand',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddBrandDialog(context, adminProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search brands (e.g. Nike, Apple, Sony)...',
                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (val) => setModalState(() => query = val),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.business_outlined, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text('No brand found', style: TextStyle(color: AppTheme.textMuted)),
                                const SizedBox(height: 10),
                                if (query.trim().isNotEmpty)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: Text('Create Brand "$query"'),
                                    onPressed: () async {
                                      final newBrand = query.trim();
                                      Navigator.pop(ctx);
                                      await adminProvider.addBrand(newBrand);
                                      setState(() => _brandController.text = newBrand);
                                      if (context.mounted) {
                                        AppToast.showSuccess(context, 'Created and selected brand "$newBrand"');
                                      }
                                    },
                                  ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (ctx, i) {
                              final brandName = filtered[i];
                              final isSelected = _brandController.text.toLowerCase() == brandName.toLowerCase();
                              return ListTile(
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      brandName.isNotEmpty ? brandName[0].toUpperCase() : 'B',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  brandName,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? AppTheme.primaryColor : const Color(0xFF0F172A),
                                  ),
                                ),
                                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor) : null,
                                onTap: () {
                                  setState(() => _brandController.text = brandName);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddBrandDialog(BuildContext context, AdminProvider adminProvider) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Brand'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Brand Name',
            hintText: 'e.g. Dior, Gucci, Nestlé',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await adminProvider.addBrand(name);
      setState(() => _brandController.text = name);
      if (context.mounted) {
        AppToast.showSuccess(context, 'Brand "$name" added and selected! 🏷️', title: 'Brand Created');
      }
    }
  }

  Future<void> _showAddSizeDialog(BuildContext context, AdminProvider adminProvider) async {
    final controller = TextEditingController();
    final size = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Size / Capacity'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Size / Volume / Weight',
            hintText: 'e.g. 100ml, 250ml, 1L, 500g, XL, 42',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (size != null && size.isNotEmpty) {
      await adminProvider.addSize(size);
      setState(() => _selectedSizes.add(size));
    }
  }

  Future<void> _showAddColorDialog(BuildContext context, AdminProvider adminProvider) async {
    final controller = TextEditingController();
    final color = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Color'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Color Name',
            hintText: 'e.g. Ocean Blue, Rose Gold',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (color != null && color.isNotEmpty) {
      await adminProvider.addColor(color);
      setState(() => _selectedColors.add(color));
    }
  }

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
    _unitSizeController = TextEditingController(text: p?.unitSize ?? '');
    _selectedUnit = p?.unit ?? 'pcs';
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
    _unitSizeController.dispose();
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
      unit: _selectedUnit,
      unitSize: _unitSizeController.text.trim().isNotEmpty ? _unitSizeController.text.trim() : null,
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
      AppToast.showSuccess(
        context,
        widget.product == null ? 'Product added to catalog successfully!' : 'Product updated successfully!',
        title: 'Catalog Saved',
      );
      Navigator.of(context).pop();
    } else {
      AppToast.showError(
        context,
        'Failed to save product. Please try again.',
        title: 'Save Failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final adminProvider = context.watch<AdminProvider>();
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

                  // 1. Searchable Category & Subcategory Picker Dropdown
                  const Text(
                    'Category & Subcategory *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openCategorySearchModal(context, adminProvider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _categoryController.text.isNotEmpty ? AppTheme.primaryColor.withOpacity(0.6) : AppTheme.cardBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.category_rounded, color: AppTheme.primaryColor, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _categoryController.text.isNotEmpty
                                  ? _categoryController.text
                                  : 'Select Category / Subcategory (Tap to search)...',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: _categoryController.text.isNotEmpty ? FontWeight.w700 : FontWeight.normal,
                                color: _categoryController.text.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B), size: 24),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Searchable Brand Picker Dropdown
                  const Text(
                    'Brand *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openBrandSearchModal(context, adminProvider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _brandController.text.isNotEmpty ? AppTheme.primaryColor.withOpacity(0.6) : AppTheme.cardBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.business_rounded, color: Colors.blue, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _brandController.text.isNotEmpty
                                  ? _brandController.text
                                  : 'Select Brand (Tap to search)...',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: _brandController.text.isNotEmpty ? FontWeight.w700 : FontWeight.normal,
                                color: _brandController.text.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B), size: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pricing & Stock & Measurement Unit
              _buildSectionCard(
                title: 'Pricing & Inventory Measurement',
                icon: Icons.monetization_on_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Selling Price (৳) *',
                            hintText: '1200',
                            prefixIcon: Icon(Icons.payments_outlined),
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
                            labelText: 'Original Price (৳) (Optional)',
                            hintText: '1500',
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
                  const SizedBox(height: 16),

                  // Measurement Unit Selection (Pieces vs ml vs kg vs pack)
                  const Text(
                    'Quantity Unit / Measurement System:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select the unit for this product (e.g. piece for clothes/electronics, ml for liquid/perfumes, kg for weight)',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: unitOptions.map((opt) {
                      final isSelected = _selectedUnit == opt['key'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedUnit = opt['key']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected ? [
                              BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                            ] : null,
                          ),
                          child: Text(
                            opt['label']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      // Unit package volume/weight (e.g. 250 for 250ml)
                      Expanded(
                        child: TextFormField(
                          controller: _unitSizeController,
                          decoration: InputDecoration(
                            labelText: 'Package Capacity / Size',
                            hintText: 'e.g. 250, 500, 1.5',
                            prefixIcon: const Icon(Icons.straighten_rounded),
                            suffixText: _selectedUnit,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Available stock count
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Available Stock *',
                            hintText: '25',
                            prefixIcon: const Icon(Icons.inventory_2_outlined),
                            suffixText: _selectedUnit,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Stock is required';
                            final s = int.tryParse(v.trim());
                            if (s == null || s < 0) return 'Stock must be >= 0';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Dynamic Stock Preview Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_outlined, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Inventory Display: ${_stockController.text.trim().isEmpty ? '0' : _stockController.text.trim()} '
                            '${_unitSizeController.text.trim().isNotEmpty ? "($_unitSizeController.text $_selectedUnit) units" : _selectedUnit} in stock',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('In Stock Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    value: _inStock,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => setState(() => _inStock = v),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mark as Featured Product', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Appears in top banner and featured carousel', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
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

                  // Colors Multi-select with + Add Color Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Colors:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: const Text('Add Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _showAddColorDialog(context, adminProvider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                   Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dbColors.map((colorName) {
                      final isSelected = _selectedColors.contains(colorName);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedColors.remove(colorName);
                            } else {
                              _selectedColors.add(colorName);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected ? [
                              BoxShadow(color: AppTheme.primaryColor.withOpacity(0.28), blurRadius: 6, offset: const Offset(0, 2)),
                            ] : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                colorName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Sizes Multi-select with + Add Size Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Sizes / Capacities:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: const Text('Add Size / Volume', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _showAddSizeDialog(context, adminProvider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Select or add sizes (e.g. S, M, XL) or volumes (e.g. 100ml, 250ml, 1L)', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dbSizes.map((sizeName) {
                      final isSelected = _selectedSizes.contains(sizeName);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedSizes.remove(sizeName);
                            } else {
                              _selectedSizes.add(sizeName);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected ? [
                              BoxShadow(color: AppTheme.primaryColor.withOpacity(0.28), blurRadius: 6, offset: const Offset(0, 2)),
                            ] : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                sizeName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
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
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: CircularProgressIndicator(
                          value: _imageUploadProgress > 0 ? _imageUploadProgress : null,
                          color: AppTheme.primaryColor,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                          strokeWidth: 4,
                        ),
                      ),
                      Text(
                        '${(_imageUploadProgress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Uploading image to Cloudinary (${(_imageUploadProgress * 100).toInt()}%)...',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _imageUploadProgress > 0 ? _imageUploadProgress : null,
                        minHeight: 6,
                        backgroundColor: Colors.blue.shade50,
                        color: AppTheme.primaryColor,
                      ),
                    ),
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sampleImagePresets.map((preset) {
              final isActive = _imageUrlController.text == preset['url'];
              return GestureDetector(
                onTap: () => setState(() => _imageUrlController.text = preset['url']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: isActive ? [
                      BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                    ] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_size_select_actual_outlined, size: 14,
                        color: isActive ? Colors.white : const Color(0xFF64748B)),
                      const SizedBox(width: 5),
                      Text(
                        preset['title']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 17),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF1F5F9), height: 16),
          ...children,
        ],
      ),
    );
  }
}
