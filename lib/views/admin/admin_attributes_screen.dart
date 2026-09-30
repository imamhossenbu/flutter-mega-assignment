import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';

class AdminAttributesScreen extends StatefulWidget {
  const AdminAttributesScreen({super.key});

  @override
  State<AdminAttributesScreen> createState() => _AdminAttributesScreenState();
}

class _AdminAttributesScreenState extends State<AdminAttributesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _parseColor(String colorName) {
    switch (colorName.toLowerCase().trim()) {
      case 'black':
      case 'midnight':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'navy blue':
      case 'blue':
        return const Color(0xFF1E3A8A);
      case 'crimson red':
      case 'red':
        return const Color(0xFFDC2626);
      case 'forest green':
      case 'green':
        return const Color(0xFF15803D);
      case 'space grey':
      case 'grey':
      case 'gray':
        return const Color(0xFF64748B);
      case 'rose gold':
        return const Color(0xFFB76E79);
      case 'silver':
        return const Color(0xFFCBD5E1);
      case 'beige':
        return const Color(0xFFF5F5DC);
      case 'yellow':
        return const Color(0xFFFACC15);
      case 'orange':
        return const Color(0xFFEA580C);
      case 'purple':
        return const Color(0xFF7E22CE);
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final colors = adminProvider.colors;
    final sizes = adminProvider.sizes;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Colors & Sizes'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(text: 'Colors (${colors.length})'),
            Tab(text: 'Sizes (${sizes.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddItemDialog(context, 'Color', (val) => adminProvider.addColor(val));
          } else {
            _showAddItemDialog(context, 'Size', (val) => adminProvider.addSize(val));
          }
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Add Color' : 'Add Size',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Colors Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Product Colors',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'These colors can be selected as options when adding or editing products.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: colors.map((c) {
                        final chipColor = _parseColor(c);
                        final isLight = chipColor == Colors.white || chipColor == const Color(0xFFF5F5DC);

                        return Container(
                          padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: chipColor,
                                  shape: BoxShape.circle,
                                  border: isLight ? Border.all(color: Colors.grey.shade400) : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(c, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => adminProvider.removeColor(c),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sizes Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Product Sizes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Standard apparel, footwear, and accessory sizes available in store.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: sizes.map((s) {
                        return Container(
                          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(s, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => adminProvider.removeSize(s),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, String type, Function(String) onAdd) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add $type', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: '$type Name',
            hintText: type == 'Color' ? 'e.g. Lavender, Teal' : 'e.g. XXL, US 13',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) {
                onAdd(val);
                Navigator.pop(ctx);
              }
            },
            child: Text('Add $type'),
          ),
        ],
      ),
    );
  }
}
