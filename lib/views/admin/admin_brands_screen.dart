import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/brand_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/product_provider.dart';

class AdminBrandsScreen extends StatelessWidget {
  const AdminBrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final productProvider = context.watch<ProductProvider>();
    final brands = adminProvider.brands;
    final allProducts = productProvider.allProducts;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Manage Brands'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBrandDialog(context, adminProvider),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Brand', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: brands.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No Brands Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Add manufacturer brands to your store catalog.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: brands.length,
              itemBuilder: (context, index) {
                final brand = brands[index];
                final count = allProducts
                    .where((p) => p.brand.toLowerCase() == brand.name.toLowerCase())
                    .length;
                return _buildBrandCard(context, brand, count, adminProvider);
              },
            ),
    );
  }

  Widget _buildBrandCard(
    BuildContext context,
    BrandModel brand,
    int productCount,
    AdminProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              brand.name.isNotEmpty ? brand.name[0].toUpperCase() : 'B',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
            ),
          ),
        ),
        title: Text(
          brand.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '$productCount products from this brand',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Brand'),
                content: Text('Are you sure you want to delete brand "${brand.name}"?'),
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
              await provider.deleteBrand(brand.id);
            }
          },
        ),
      ),
    );
  }

  void _showAddBrandDialog(BuildContext context, AdminProvider provider) {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Brand', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Brand Name',
            hintText: 'e.g. Apple, Nike, Sony, Dell',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                await provider.addBrand(name);
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add Brand'),
          ),
        ],
      ),
    );
  }
}
