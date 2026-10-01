import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../models/category_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/product_provider.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  String _searchQuery = '';
  final Set<String> _expandedCategoryIds = {};

  @override
  void initState() {
    super.initState();
    // Default expand all categories initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cats = context.read<AdminProvider>().categories;
      setState(() {
        _expandedCategoryIds.addAll(cats.map((c) => c.id));
      });
    });
  }

  void _toggleExpanded(String categoryId) {
    setState(() {
      if (_expandedCategoryIds.contains(categoryId)) {
        _expandedCategoryIds.remove(categoryId);
      } else {
        _expandedCategoryIds.add(categoryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final productProvider = context.watch<ProductProvider>();
    final categories = adminProvider.categories;
    final allProducts = productProvider.allProducts;

    final query = _searchQuery.trim().toLowerCase();
    final filteredCategories = categories.where((cat) {
      if (query.isEmpty) return true;
      final matchParent = cat.name.toLowerCase().contains(query);
      final matchSub = cat.subcategories.any((s) => s.toLowerCase().contains(query));
      return matchParent || matchSub;
    }).toList();

    int totalSubcategories = 0;
    for (final c in categories) {
      totalSubcategories += c.subcategories.length;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Category Tree & Taxonomy'),
        actions: [
          IconButton(
            icon: Icon(
              _expandedCategoryIds.length == categories.length
                  ? Icons.unfold_less_rounded
                  : Icons.unfold_more_rounded,
            ),
            tooltip: _expandedCategoryIds.length == categories.length ? 'Collapse All' : 'Expand All',
            onPressed: () {
              setState(() {
                if (_expandedCategoryIds.length == categories.length) {
                  _expandedCategoryIds.clear();
                } else {
                  _expandedCategoryIds.addAll(categories.map((c) => c.id));
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context, adminProvider),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.create_new_folder_rounded, color: Colors.white),
        label: const Text('New Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Summary Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search categories & subcategories...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatPill(
                      icon: Icons.folder_rounded,
                      color: AppTheme.primaryColor,
                      label: '${categories.length} Parent Categories',
                    ),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      icon: Icons.subdirectory_arrow_right_rounded,
                      color: Colors.teal.shade700,
                      label: '$totalSubcategories Subcategories',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Categories Tree List
          Expanded(
            child: filteredCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_tree_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No Categories Found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          query.isNotEmpty ? 'Try changing your search term' : 'Add categories to build your catalog tree',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final cat = filteredCategories[index];
                      final isExpanded = _expandedCategoryIds.contains(cat.id);
                      final productCount = allProducts
                          .where((p) => p.category.toLowerCase().contains(cat.name.toLowerCase()))
                          .length;
                      return _buildCategoryTreeNode(
                        context: context,
                        category: cat,
                        isExpanded: isExpanded,
                        productCount: productCount,
                        allProducts: allProducts,
                        adminProvider: adminProvider,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({required IconData icon, required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTreeNode({
    required BuildContext context,
    required CategoryModel category,
    required bool isExpanded,
    required int productCount,
    required List<dynamic> allProducts,
    required AdminProvider adminProvider,
  }) {
    final subcategories = category.subcategories;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? AppTheme.primaryColor.withOpacity(0.4) : const Color(0xFFE2E8F0),
          width: isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent Node Header
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: Radius.circular(isExpanded ? 0 : 16),
            ),
            onTap: () => _toggleExpanded(category.id),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Folder icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.folder_rounded, color: AppTheme.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Title & Meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${subcategories.length} sub',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$productCount products assigned',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  // Add Subcategory Button
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Sub', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showAddSubcategoryDialog(context, adminProvider, category),
                  ),
                  // Delete Category
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
                    tooltip: 'Delete Category',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _confirmDeleteCategory(context, adminProvider, category),
                  ),
                  // Expand arrow
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                  ),
                ],
              ),
            ),
          ),

          // Child Subcategories (Tree Branch Nodes)
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              color: const Color(0xFFFAFBFD),
              child: subcategories.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          const Text(
                            'No subcategories yet. ',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          InkWell(
                            onTap: () => _showAddSubcategoryDialog(context, adminProvider, category),
                            child: const Text(
                              '+ Add Subcategory',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: subcategories.map((subName) {
                        return _buildSubcategoryTreeItem(
                          context: context,
                          parentCategory: category,
                          subName: subName,
                          adminProvider: adminProvider,
                        );
                      }).toList(),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubcategoryTreeItem({
    required BuildContext context,
    required CategoryModel parentCategory,
    required String subName,
    required AdminProvider adminProvider,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Branch line indicator
          const Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
            tooltip: 'Remove subcategory',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove Subcategory'),
                  content: Text('Remove "$subName" from "${parentCategory.name}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await adminProvider.deleteSubcategory(parentCategory.id, subName);
                if (context.mounted) {
                  AppToast.showSuccess(context, 'Removed subcategory "$subName"');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, AdminProvider provider) {
    final nameCtrl = TextEditingController();
    final subcategoriesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.create_new_folder_rounded, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('New Root Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Category Name *',
                hintText: 'e.g. Gaming, Beauty & Care, Groceries',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: subcategoriesCtrl,
              decoration: const InputDecoration(
                labelText: 'Initial Subcategories (Optional)',
                hintText: 'Comma separated e.g. Laptops, Monitors, Keyboards',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You can also add subcategories anytime later.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await provider.addCategory(name);

              // If initial subcategories specified, add them
              final subs = subcategoriesCtrl.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              if (subs.isNotEmpty) {
                // Find created category and append subcategories
                final created = provider.categories.firstWhere(
                  (c) => c.name.toLowerCase() == name.toLowerCase(),
                  orElse: () => CategoryModel(id: '', name: name, createdAt: DateTime.now()),
                );
                if (created.id.isNotEmpty) {
                  for (final sub in subs) {
                    await provider.addSubcategory(created.id, sub);
                  }
                }
              }

              if (context.mounted) {
                AppToast.showSuccess(context, 'Category "$name" created successfully! 🎉', title: 'Category Created');
              }
            },
            child: const Text('Create Category'),
          ),
        ],
      ),
    );
  }

  void _showAddSubcategoryDialog(BuildContext context, AdminProvider provider, CategoryModel parentCat) {
    final subNameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.subdirectory_arrow_right_rounded, color: Colors.teal, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Add to ${parentCat.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parent Category: ${parentCat.name}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subNameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Subcategory Name *',
                hintText: 'e.g. Wireless Earbuds, Running Shoes',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final subName = subNameCtrl.text.trim();
              if (subName.isEmpty) return;
              Navigator.pop(ctx);
              await provider.addSubcategory(parentCat.id, subName);
              if (context.mounted) {
                AppToast.showSuccess(
                  context,
                  'Added "$subName" under "${parentCat.name}"',
                  title: 'Subcategory Added',
                );
              }
            },
            child: const Text('Add Subcategory'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCategory(BuildContext context, AdminProvider provider, CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}" and all its ${category.subcategories.length} subcategories? This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await provider.deleteCategory(category.id);
      if (context.mounted) {
        AppToast.showSuccess(context, 'Category "${category.name}" deleted');
      }
    }
  }
}
