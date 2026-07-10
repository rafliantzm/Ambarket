import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BadgeStatus { success, warning, error, info, neutral }

class AppStatusBadge extends StatelessWidget {
  final String label;
  final BadgeStatus status;
  final IconData? icon;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.status = BadgeStatus.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case BadgeStatus.success:
        bgColor = context.colors.success.withValues(alpha: 0.15);
        textColor = context.colors.success;
        break;
      case BadgeStatus.warning:
        bgColor = context.colors.warning.withValues(alpha: 0.15);
        textColor = context.colors.warning;
        break;
      case BadgeStatus.error:
        bgColor = context.colors.error.withValues(alpha: 0.15);
        textColor = context.colors.error;
        break;
      case BadgeStatus.info:
        bgColor = context.colors.info.withValues(alpha: 0.15);
        textColor = context.colors.info;
        break;
      case BadgeStatus.neutral:
        bgColor = context.colors.borderStrong.withValues(alpha: 0.5);
        textColor = context.colors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
