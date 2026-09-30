import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../auth/login_screen.dart';
import '../orders/orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isReseeding = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isGuest) {
      return _buildGuestView(context);
    }
    return _buildAuthenticatedView(context, auth);
  }

  Widget _buildGuestView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Account')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded, size: 52, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 20),
              const Text(
                'Join MegaStore',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to track orders, save wishlist, and manage your account.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  icon: const Icon(Icons.person_add_outlined, size: 20),
                  label: const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticatedView(BuildContext context, AuthProvider auth) {
    final cartProvider = context.watch<CartProvider>();
    final wishlistProvider = context.watch<WishlistProvider>();
    final productProvider = context.read<ProductProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditProfileDialog(context, auth),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        child: Column(
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.email,
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                        ),
                        if (auth.phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            auth.phone,
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                Expanded(child: _buildStatCard(
                  icon: Icons.favorite_rounded,
                  iconColor: AppTheme.accentColor,
                  value: '${wishlistProvider.count}',
                  label: 'Wishlisted',
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(
                  icon: Icons.shopping_cart_rounded,
                  iconColor: AppTheme.primaryColor,
                  value: '${cartProvider.totalQuantity}',
                  label: 'In Cart',
                )),
              ],
            ),
            const SizedBox(height: 16),

            // Menu items
            _buildMenuSection(
              title: 'Shopping',
              items: [
                _MenuItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'My Orders',
                  subtitle: 'Track and view order history',
                  color: AppTheme.primaryColor,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  ),
                ),
                _MenuItem(
                  icon: Icons.favorite_outline_rounded,
                  label: 'My Wishlist',
                  subtitle: '${wishlistProvider.count} saved items',
                  color: AppTheme.accentColor,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildMenuSection(
              title: 'Account',
              items: [
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profile',
                  subtitle: 'Name, email, phone number',
                  color: Colors.blue,
                  onTap: () => _showEditProfileDialog(context, auth),
                ),
                _MenuItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  subtitle: 'Update your password',
                  color: Colors.orange,
                  onTap: () => _showChangePasswordDialog(context, auth),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildMenuSection(
              title: 'App',
              items: [
                _MenuItem(
                  icon: Icons.cloud_sync_rounded,
                  label: 'Re-seed Demo Products',
                  subtitle: 'Restore products to Firestore',
                  color: Colors.teal,
                  trailing: _isReseeding
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                  onTap: _isReseeding
                      ? null
                      : () async {
                          setState(() => _isReseeding = true);
                          await productProvider.reseedSampleProducts();
                          if (!mounted) return;
                          setState(() => _isReseeding = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Products seeded to Firestore! 🚀'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sign Out
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                ),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600, fontSize: 15),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.error),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await context.read<AuthProvider>().signOut();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required Color iconColor, required String value, required String label}) {
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
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMenuSection({required String title, required List<_MenuItem> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5),
            ),
          ),
          ...items.asMap().entries.map((e) {
            final item = e.value;
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: isLast ? const Radius.circular(17) : Radius.zero,
                    ),
                  ),
                  onTap: item.onTap,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  title: Text(item.label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  trailing: item.trailing ?? const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                ),
                if (!isLast) const Divider(height: 0, indent: 68),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider auth) {
    final nameController = TextEditingController(text: auth.displayName);
    final phoneController = TextEditingController(text: auth.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
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
                  const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await auth.updateProfile(
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated!'), behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthProvider auth) {
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure1 = true;
    bool obscure2 = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscure1,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setModalState(() => obscure1 = !obscure1),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: confirmController,
                    obscureText: obscure2,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setModalState(() => obscure2 = !obscure2),
                      ),
                    ),
                    validator: (v) {
                      if (v != newPasswordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final success = await auth.changePassword(newPasswordController.text);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Password changed successfully!' : auth.errorMessage ?? 'Failed'),
                              backgroundColor: success ? AppTheme.success : AppTheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.trailing,
  });
}
