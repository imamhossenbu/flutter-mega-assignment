import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AdminCustomersScreen extends StatelessWidget {
  const AdminCustomersScreen({super.key});

  static const String rootAdminEmail = 'admin@megastore.com';

  void _showPurgeDialog(BuildContext context, AdminProvider adminProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('Purge All Users?'),
          ],
        ),
        content: const Text(
          'This will permanently delete all customer accounts from Firestore except root admin (admin@megastore.com).\n\nAre you sure you want to proceed?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final deleted = await adminProvider.clearAllUsersExceptAdmin();
              if (context.mounted) {
                AppToast.showSuccess(
                  context,
                  'Successfully deleted $deleted test user accounts. Root admin preserved!',
                  title: 'Users Purged',
                );
              }
            },
            child: const Text('Purge Users'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, AdminProvider adminProvider, String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete User Account'),
        content: Text('Are you sure you want to delete "$name"? This action cannot be reversed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await adminProvider.deleteUser(userId);
              if (context.mounted) {
                if (success) {
                  AppToast.showSuccess(context, 'User "$name" deleted.', title: 'User Deleted');
                } else {
                  AppToast.showError(context, 'Failed to delete user.');
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final authProvider = context.watch<AuthProvider>();
    final users = adminProvider.users;

    final adminCount = users.where((u) {
      final role = (u['role'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').trim().toLowerCase();
      return role == 'admin' || email == rootAdminEmail;
    }).length;

    final customerCount = users.length - adminCount;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Users & Role Management'),
        actions: [
          IconButton(
            tooltip: 'Purge all users except root admin',
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            onPressed: () => _showPurgeDialog(context, adminProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Stats Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Users', '${users.length}', Icons.people_alt_rounded),
                Container(height: 30, width: 1, color: Colors.white24),
                _buildStatItem('Admins', '$adminCount', Icons.admin_panel_settings_rounded),
                Container(height: 30, width: 1, color: Colors.white24),
                _buildStatItem('Customers', '$customerCount', Icons.shopping_bag_outlined),
              ],
            ),
          ),

          Expanded(
            child: users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No Users Registered Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('When shoppers sign in, their profiles and roles appear here.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final uid = user['id'] as String? ?? '';
                      final name = user['name'] as String? ?? 'Shopper';
                      final email = (user['email'] as String? ?? 'No email').trim();
                      final isRootAdmin = email.toLowerCase() == rootAdminEmail;
                      final role = isRootAdmin ? 'admin' : (user['role'] as String? ?? 'customer');
                      final isAdmin = role == 'admin';
                      final isCurrent = uid == authProvider.userId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: isRootAdmin
                                  ? AppTheme.primaryColor.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: isAdmin
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade200,
                                    foregroundColor: isAdmin ? Colors.white : AppTheme.textPrimary,
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isCurrent) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('You', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          email,
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Role Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isRootAdmin
                                          ? Colors.amber.shade100
                                          : (isAdmin ? AppTheme.primaryColor.withOpacity(0.12) : Colors.grey.shade100),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isRootAdmin ? 'ROOT ADMIN' : (isAdmin ? 'ADMIN' : 'CUSTOMER'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: isRootAdmin
                                            ? Colors.amber.shade900
                                            : (isAdmin ? AppTheme.primaryColor : AppTheme.textSecondary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              // Role Switch Action Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.security_rounded, size: 16, color: AppTheme.textMuted),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Role: ${isAdmin ? 'Admin' : 'Customer'}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      if (!isRootAdmin) ...[
                                        // Quick Role Toggle Button
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            visualDensity: VisualDensity.compact,
                                            backgroundColor: isAdmin ? const Color(0xFFFFF7ED) : AppTheme.primaryColor.withOpacity(0.1),
                                            foregroundColor: isAdmin ? Colors.deepOrange : AppTheme.primaryColor,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          icon: Icon(
                                            isAdmin ? Icons.person_outline : Icons.admin_panel_settings_outlined,
                                            size: 14,
                                            color: isAdmin ? Colors.deepOrange : AppTheme.primaryColor,
                                          ),
                                          label: Text(
                                            isAdmin ? 'Make Customer' : 'Make Admin',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isAdmin ? Colors.deepOrange : AppTheme.primaryColor,
                                            ),
                                          ),
                                          onPressed: () async {
                                            final newRole = isAdmin ? 'customer' : 'admin';
                                            await adminProvider.updateUserRole(uid, newRole);
                                            if (context.mounted) {
                                              AppToast.showSuccess(
                                                context,
                                                'Updated $name role to $newRole.',
                                                title: 'Role Updated',
                                              );
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        // Delete Button
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                          tooltip: 'Delete User',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _confirmDeleteUser(context, adminProvider, uid, name),
                                        ),
                                       ] else ...[
                                         Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                           decoration: BoxDecoration(
                                             color: Colors.amber.shade50,
                                             borderRadius: BorderRadius.circular(8),
                                           ),
                                           child: Row(
                                             mainAxisSize: MainAxisSize.min,
                                             children: [
                                               Icon(Icons.lock_rounded, size: 12, color: Colors.amber.shade700),
                                               const SizedBox(width: 4),
                                               Text(
                                                 'Permanent Admin',
                                                 style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                                               ),
                                             ],
                                           ),
                                         ),
                                       ],
                                    ],
                                  ),
                                ],
                              ),
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
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
