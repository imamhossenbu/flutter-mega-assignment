import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/promo_code_model.dart';
import '../../providers/admin_provider.dart';

class AdminPromoCodesScreen extends StatelessWidget {
  const AdminPromoCodesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final promoCodes = adminProvider.promoCodes;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Promo Codes & Vouchers'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPromoDialog(context, adminProvider),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Voucher', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: promoCodes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.discount_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No Promo Codes Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Create promotional discounts to boost store sales.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: promoCodes.length,
              itemBuilder: (context, index) {
                final promo = promoCodes[index];
                return _buildPromoCard(context, promo, adminProvider);
              },
            ),
    );
  }

  Widget _buildPromoCard(BuildContext context, PromoCodeModel promo, AdminProvider provider) {
    final isExpired = promo.expiresAt != null && DateTime.now().isAfter(promo.expiresAt!);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: (promo.isActive && !isExpired)
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  Icons.local_offer_rounded,
                  color: (promo.isActive && !isExpired) ? AppTheme.primaryColor : Colors.grey,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        promo.code,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(promo.discountPercent * 100).toInt()}% OFF',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.accentColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promo.description,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  if (promo.minOrderAmount != null && promo.minOrderAmount! > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Min order: ৳${promo.minOrderAmount!.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                  if (promo.expiresAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      isExpired
                          ? 'Expired'
                          : 'Valid until ${promo.expiresAt!.day}/${promo.expiresAt!.month}/${promo.expiresAt!.year}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isExpired ? AppTheme.error : AppTheme.textMuted,
                        fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Controls
            Column(
              children: [
                Switch.adaptive(
                  value: promo.isActive,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (val) {
                    provider.togglePromoStatus(promo.code, val);
                  },
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textSecondary),
                      onPressed: () => _showAddPromoDialog(context, provider, existingPromo: promo),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.error),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Voucher'),
                            content: Text('Delete coupon "${promo.code}"?'),
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
                          await provider.deletePromoCode(promo.code);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPromoDialog(BuildContext context, AdminProvider provider, {PromoCodeModel? existingPromo}) {
    final isEdit = existingPromo != null;
    final codeCtrl = TextEditingController(text: existingPromo?.code ?? '');
    final discountCtrl = TextEditingController(
      text: existingPromo != null
          ? (existingPromo.discountPercent <= 1.0
                  ? (existingPromo.discountPercent * 100).toInt()
                  : existingPromo.discountPercent.toInt())
              .toString()
          : '20',
    );
    final minOrderCtrl = TextEditingController(
      text: existingPromo?.minOrderAmount != null ? existingPromo!.minOrderAmount!.toStringAsFixed(0) : '',
    );
    final descCtrl = TextEditingController(text: existingPromo?.description ?? '');
    final daysCtrl = TextEditingController(
      text: existingPromo?.expiresAt != null
          ? existingPromo!.expiresAt!.difference(DateTime.now()).inDays.clamp(1, 365).toString()
          : '30',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Promo Code' : 'Create Promo Code', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                enabled: !isEdit,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Coupon Code (e.g. FLASH30)',
                  hintText: 'SUMMER25',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Discount Percentage (%)',
                  hintText: '20',
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minOrderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min Order Amount (৳, Optional)',
                  hintText: '500',
                  prefixText: '৳ ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: '20% off for holiday season',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: daysCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valid For (Days)',
                  hintText: '30',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final code = codeCtrl.text.trim().toUpperCase();
              final discountVal = double.tryParse(discountCtrl.text.trim()) ?? 0;
              final minOrderVal = double.tryParse(minOrderCtrl.text.trim());
              final desc = descCtrl.text.trim();
              final days = int.tryParse(daysCtrl.text.trim()) ?? 30;

              if (code.isEmpty || discountVal <= 0) return;

              final promo = PromoCodeModel(
                id: code,
                code: code,
                discountPercent: discountVal > 1.0 ? discountVal / 100 : discountVal,
                isActive: existingPromo?.isActive ?? true,
                description: desc.isNotEmpty ? desc : '${discountVal.toInt()}% off discount',
                minOrderAmount: minOrderVal,
                expiresAt: DateTime.now().add(Duration(days: days)),
              );

              await provider.savePromoCode(promo);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Save Changes' : 'Create Code'),
          ),
        ],
      ),
    );
  }
}
