import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppGlassCardVariant { elevated, soft, outlined, filled }

class AppGlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BoxBorder? customBorder;
  final AppGlassCardVariant variant;

  const AppGlassCard({
    super.key,
    required this.child,
    this.blur = 16.0, // Retained for compatibility, but ignored in light theme
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.width,
    this.height,
    this.customBorder,
    this.variant = AppGlassCardVariant.elevated,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    BoxBorder? border;
    List<BoxShadow>? shadow;

    switch (variant) {
      case AppGlassCardVariant.elevated:
        bgColor = context.colors.surface;
        border =
            customBorder ?? Border.all(color: context.colors.border, width: 1);
        shadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case AppGlassCardVariant.soft:
        bgColor = context.colors.surface;
        border =
            customBorder ?? Border.all(color: context.colors.border, width: 1);
        shadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];
        break;
      case AppGlassCardVariant.outlined:
        bgColor = Colors.transparent;
        border = customBorder ?? Border.all(color: context.colors.borderStrong);
        shadow = null;
        break;
      case AppGlassCardVariant.filled:
        bgColor = context.colors.backgroundDarker;
        border = null;
        shadow = null;
        break;
    }

    Widget content = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Padding(padding: padding, child: child),
            if (onTap != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    splashColor: context.colors.primary.withValues(alpha: 0.1),
                    highlightColor: context.colors.primary.withValues(
                      alpha: 0.05,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return content;
  }
}
