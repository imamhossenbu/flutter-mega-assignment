import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Pending', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final allOrders = orderProvider.allOrders;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Order Fulfilment'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _tabs.map((tab) {
            int count = 0;
            if (tab == 'All') {
              count = allOrders.length;
            } else {
              count = allOrders.where((o) => o.status.label.toLowerCase() == tab.toLowerCase()).length;
            }
            return Tab(text: '$tab ($count)');
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          final filtered = tab == 'All'
              ? allOrders
              : allOrders.where((o) => o.status.label.toLowerCase() == tab.toLowerCase()).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('No $tab Orders', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  const Text('Orders placed by customers will appear here in real-time.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final order = filtered[index];
              return _buildAdminOrderCard(context, order, orderProvider);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdminOrderCard(BuildContext context, OrderModel order, OrderProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: const Border(bottom: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(order.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                _buildStatusChip(context, order, provider),
              ],
            ),
          ),

          // Order Items Preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 48,
                              height: 48,
                              color: Colors.grey.shade100,
                              child: CachedNetworkImage(
                                imageUrl: item.productImage,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(Icons.image_outlined, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Qty: ${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}'
                                  '${item.selectedColor != null ? ' • ${item.selectedColor}' : ''}'
                                  '${item.selectedSize != null ? ' • ${item.selectedSize}' : ''}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    )),
                const Divider(color: AppTheme.cardBorder, height: 16),

                // Shipping info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.shippingAddress.isNotEmpty ? order.shippingAddress : 'Standard Shipping Address',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Price Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.items.length} items • ${order.promoCode != null ? "Promo: ${order.promoCode}" : "No promo"}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    Row(
                      children: [
                        const Text('Total: ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        Text(
                          '\$${order.grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'User: ${order.userId.length > 8 ? order.userId.substring(0, 8) : order.userId}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showStatusPickerModal(context, order, provider),
                  icon: const Icon(Icons.edit_road_rounded, size: 16),
                  label: const Text('Update Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, OrderModel order, OrderProvider provider) {
    Color bg;
    Color fg;
    switch (order.status) {
      case OrderStatus.pending:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        break;
      case OrderStatus.confirmed:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade900;
        break;
      case OrderStatus.shipped:
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade900;
        break;
      case OrderStatus.delivered:
        bg = Colors.green.shade50;
        fg = Colors.green.shade900;
        break;
      case OrderStatus.cancelled:
        bg = Colors.red.shade50;
        fg = Colors.red.shade900;
        break;
    }

    return InkWell(
      onTap: () => _showStatusPickerModal(context, order, provider),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(order.status.emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              order.status.label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: fg),
          ],
        ),
      ),
    );
  }

  void _showStatusPickerModal(BuildContext context, OrderModel order, OrderProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
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
                const Text('Update Order Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Order #${order.id}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 16),
                ...OrderStatus.values.map((status) {
                  final isCurrent = order.status == status;
                  return ListTile(
                    leading: Text(status.emoji, style: const TextStyle(fontSize: 22)),
                    title: Text(
                      status.label,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppTheme.primaryColor : AppTheme.textPrimary,
                      ),
                    ),
                    trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      final success = await provider.updateOrderStatus(order.id, order.userId, status);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Order updated to ${status.label}!' : 'Failed to update order status'),
                          backgroundColor: success ? AppTheme.success : AppTheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
