import 'package:flutter/material.dart';

class CustomToast {
  static void showSuccess(BuildContext context, String message) {
    _showToast(context, message, Colors.green.shade600, Icons.check_circle_rounded);
  }

  static void showError(BuildContext context, String message) {
    _showToast(context, message, Colors.red.shade600, Icons.error_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    _showToast(context, message, Colors.blue.shade600, Icons.info_rounded);
  }

  static void showWarning(BuildContext context, String message) {
    _showToast(context, message, Colors.orange.shade600, Icons.warning_rounded);
  }

  static void _showToast(BuildContext context, String message, Color color, IconData icon) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.hideCurrentSnackBar();
    scaffold.showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 24,
          left: 16,
          right: 16,
        ),
        dismissDirection: DismissDirection.horizontal,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
