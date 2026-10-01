import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../providers/auth_provider.dart';

class ProfileManagementDialogs {
  /// Opens a versatile sheet to choose Gallery, Camera, Image URL, or Remove Photo
  static Future<void> showPhotoUploadSheet(
    BuildContext context,
    AuthProvider auth, {
    VoidCallback? onUpdated,
  }) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Profile Picture',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryColor),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select a picture from your device storage'),
                onTap: () async {
                  Navigator.pop(ctx);
                  AppToast.showInfo(context, 'Uploading profile photo... ⏳', title: 'Uploading');
                  final url = await auth.uploadProfileImage(source: ImageSource.gallery);
                  if (context.mounted) {
                    if (url != null) {
                      AppToast.showSuccess(context, 'Profile picture updated! ✨', title: 'Profile Updated');
                      onUpdated?.call();
                    } else {
                      AppToast.showError(
                        context,
                        'Upload failed. You can also paste an image URL.',
                        title: 'Upload Failed',
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.blue),
                ),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use your device camera to take a new picture'),
                onTap: () async {
                  Navigator.pop(ctx);
                  AppToast.showInfo(context, 'Uploading profile photo... ⏳', title: 'Uploading');
                  final url = await auth.uploadProfileImage(source: ImageSource.camera);
                  if (context.mounted) {
                    if (url != null) {
                      AppToast.showSuccess(context, 'Profile picture updated! ✨', title: 'Profile Updated');
                      onUpdated?.call();
                    } else {
                      AppToast.showError(context, 'Failed to capture photo.', title: 'Upload Failed');
                    }
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.link_rounded, color: Colors.purple),
                ),
                title: const Text('Enter Image URL'),
                subtitle: const Text('Paste direct URL to a web photo or avatar'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showImageUrlDialog(context, auth, onUpdated: onUpdated);
                },
              ),
              if (auth.photoUrl.isNotEmpty) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Revert back to default avatar'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await auth.updateProfile(photoUrl: '');
                    if (context.mounted) {
                      AppToast.showSuccess(context, 'Profile photo removed.', title: 'Photo Removed');
                      onUpdated?.call();
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void _showImageUrlDialog(
    BuildContext context,
    AuthProvider auth, {
    VoidCallback? onUpdated,
  }) {
    final urlCtrl = TextEditingController(text: auth.photoUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set Profile Image URL', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a direct public URL for your profile picture (JPG, PNG, WebP):',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                hintText: 'https://images.unsplash.com/...',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newUrl = urlCtrl.text.trim();
              Navigator.pop(ctx);
              if (newUrl.isNotEmpty) {
                await auth.updateProfile(photoUrl: newUrl);
                if (context.mounted) {
                  AppToast.showSuccess(context, 'Profile image updated! ✨', title: 'Profile Updated');
                  onUpdated?.call();
                }
              }
            },
            child: const Text('Save URL'),
          ),
        ],
      ),
    );
  }

  /// Opens a fully validated dialog for updating name, phone number, and photo
  static void showEditProfileDialog(BuildContext context, AuthProvider auth) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: auth.displayName);
    final phoneCtrl = TextEditingController(text: auth.phone);
    bool isSaving = false;

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
                          radius: 38,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                          backgroundImage: auth.photoUrl.isNotEmpty
                              ? CachedNetworkImageProvider(auth.photoUrl)
                              : null,
                          child: auth.photoUrl.isEmpty
                              ? Text(
                                  auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: InkWell(
                            onTap: () {
                              showPhotoUploadSheet(
                                context,
                                auth,
                                onUpdated: () => setState(() {}),
                              );
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      showPhotoUploadSheet(
                        context,
                        auth,
                        onUpdated: () => setState(() {}),
                      );
                    },
                    icon: const Icon(Icons.photo_camera_rounded, size: 16),
                    label: const Text('Change Photo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
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
                          AppToast.showSuccess(
                            context,
                            'Profile updated successfully! ✨',
                            title: 'Profile Updated',
                          );
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
                          AppToast.showSuccess(
                            context,
                            'Password updated successfully! 🔒',
                            title: 'Password Changed',
                          );
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
