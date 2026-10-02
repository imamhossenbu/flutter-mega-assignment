import 'package:flutter/material.dart';

enum ToastType { success, error, warning, info }

class AppToast {
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(
      context,
      type: ToastType.success,
      message: message,
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      type: ToastType.error,
      message: message,
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      type: ToastType.warning,
      message: message,
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(
      context,
      type: ToastType.info,
      message: message,
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required ToastType type,
    required String message,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();

    Color iconColor;
    Color iconBgColor;
    IconData icon;
    String defaultTitle;

    switch (type) {
      case ToastType.success:
        iconColor = const Color(0xFF10B981);
        iconBgColor = const Color(0xFF10B981).withOpacity(0.18);
        icon = Icons.check_circle_rounded;
        defaultTitle = 'Success';
        break;
      case ToastType.error:
        iconColor = const Color(0xFFEF4444);
        iconBgColor = const Color(0xFFEF4444).withOpacity(0.18);
        icon = Icons.error_rounded;
        defaultTitle = 'Error';
        break;
      case ToastType.warning:
        iconColor = const Color(0xFFF59E0B);
        iconBgColor = const Color(0xFFF59E0B).withOpacity(0.18);
        icon = Icons.warning_rounded;
        defaultTitle = 'Attention';
        break;
      case ToastType.info:
        iconColor = const Color(0xFF3B82F6);
        iconBgColor = const Color(0xFF3B82F6).withOpacity(0.18);
        icon = Icons.info_rounded;
        defaultTitle = 'Notice';
        break;
    }

    final effectiveTitle = title ?? defaultTitle;

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: duration,
      content: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // Premium obsidian slate
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: iconColor.withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: iconColor.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (effectiveTitle.isNotEmpty)
                        Text(
                          effectiveTitle,
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(width: 10),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: iconColor,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      messenger.hideCurrentSnackBar();
                      onAction();
                    },
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    messenger.showSnackBar(snackBar);
  }
}
