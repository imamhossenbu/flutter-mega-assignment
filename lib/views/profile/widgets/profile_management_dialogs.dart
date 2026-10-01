import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../providers/auth_provider.dart';

class ProfileManagementDialogs {
  /// Opens a fully validated dialog for updating name, phone number, and photo
  static void showEditProfileDialog(BuildContext context, AuthProvider auth) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: auth.displayName);
    final phoneCtrl = TextEditingController(text: auth.phone);
    bool isSaving = false;
    bool isUploadingPhoto = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.person_outline_rounded, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Photo Avatar with Upload
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                          backgroundImage: auth.photoUrl.isNotEmpty
                              ? CachedNetworkImageProvider(auth.photoUrl)
                              : null,
                          child: isUploadingPhoto
                              ? const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)
                              : (auth.photoUrl.isEmpty
                                  ? Text(
                                      auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                    )
                                  : null),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: InkWell(
                            onTap: isUploadingPhoto
                                ? null
                                : () async {
                                    setState(() => isUploadingPhoto = true);
                                    await auth.uploadProfileImage(source: ImageSource.gallery);
                                    setState(() => isUploadingPhoto = false);
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'e.g. John Doe',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Full Name is required';
                      if (v.trim().length < 2) return 'Name must be at least 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+880 1712 345678',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
                        if (!phoneRegex.hasMatch(v.trim())) {
                          return 'Enter a valid phone number (7-15 digits)';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isSaving = true);
                      final success = await auth.updateProfile(
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        if (success) {
                          AppToast.showSuccess(context, 'Profile updated successfully! ✨', title: 'Profile Updated');
                        } else {
                          AppToast.showError(context, 'Failed to update profile.', title: 'Update Failed');
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens a securely validated dialog for changing account password
  static void showChangePasswordDialog(BuildContext context, AuthProvider auth) {
    final formKey = GlobalKey<FormState>();
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;
    String? localError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.lock_reset_rounded, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (localError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                      ),
                      child: Text(
                        localError!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.error),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: currentPassCtrl,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password *',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                        onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Current password is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPassCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password *',
                      hintText: 'At least 6 characters',
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                        onPressed: () => setState(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'New password is required';
                      if (v.length < 6) return 'Password must be at least 6 characters';
                      if (v == currentPassCtrl.text) return 'New password cannot match current password';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPassCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password *',
                      prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                        onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please confirm your new password';
                      if (v != newPassCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() {
                        isSaving = true;
                        localError = null;
                      });

                      final success = await auth.changePassword(
                        newPassCtrl.text,
                        currentPassword: currentPassCtrl.text,
                      );

                      if (success) {
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          AppToast.showSuccess(context, 'Password updated successfully! 🔒', title: 'Password Changed');
                        }
                      } else {
                        setState(() {
                          isSaving = false;
                          localError = auth.errorMessage ?? 'Failed to update password. Check current password.';
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}
