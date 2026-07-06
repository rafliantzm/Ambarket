import 'package:flutter/material.dart';

enum BadgeStatus {
  success,
  warning,
  error,
  info,
  neutral,
}

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
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.15); // Emerald
        textColor = const Color(0xFF34D399);
        break;
      case BadgeStatus.warning:
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15); // Amber
        textColor = const Color(0xFFFBBF24);
        break;
      case BadgeStatus.error:
        bgColor = const Color(0xFFF43F5E).withValues(alpha: 0.15); // Rose
        textColor = const Color(0xFFFB7185);
        break;
      case BadgeStatus.info:
        bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.15); // Blue
        textColor = const Color(0xFF60A5FA);
        break;
      case BadgeStatus.neutral:
        bgColor = Colors.white.withValues(alpha: 0.1);
        textColor = Colors.white70;
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

