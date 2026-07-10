import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

class AnimatedPromoHeroCard extends StatefulWidget {
  final bool enableAnimation;
  final VoidCallback? onCtaPressed;

  const AnimatedPromoHeroCard({
    super.key,
    this.enableAnimation = true,
    this.onCtaPressed,
  });

  @override
  State<AnimatedPromoHeroCard> createState() => _AnimatedPromoHeroCardState();
}

class _AnimatedPromoHeroCardState extends State<AnimatedPromoHeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    if (widget.enableAnimation) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedPromoHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableAnimation != oldWidget.enableAnimation) {
      if (widget.enableAnimation) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.surface,
              context.colors.surface.withValues(alpha: 0.9),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: context.colors.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Animated background shapes
            if (widget.enableAnimation)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _HeroBackgroundPainter(
                        animationValue: _controller.value,
                        primaryColor: context.colors.primary,
                      ),
                    );
                  },
                ),
              )
            else
              Positioned.fill(
                child: CustomPaint(
                  painter: _HeroBackgroundPainter(
                    animationValue: 0.5,
                    primaryColor: context.colors.primary,
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: context.colors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ambarket Premium',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Preloved Berkualitas,\nHarga Bersahabat',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.colors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Temukan barang bekas pilihan dengan pengalaman belanja yang lebih aman dan terpercaya.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Mulai Belanja',
                    onPressed: widget.onCtaPressed ?? () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBackgroundPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;

  _HeroBackgroundPainter({
    required this.animationValue,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Moving big circle 1
    final center1 = Offset(
      size.width * 0.8 + (10 * animationValue),
      size.height * 0.2 - (15 * animationValue),
    );
    canvas.drawCircle(center1, size.height * 0.6, paint);

    // Moving big circle 2
    final paint2 = Paint()
      ..color = primaryColor.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;
    final center2 = Offset(
      size.width * 0.9 - (20 * animationValue),
      size.height * 0.8 + (10 * animationValue),
    );
    canvas.drawCircle(center2, size.height * 0.4, paint2);

    // Subtle grid pattern
    final gridPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const double step = 20;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double j = 0; j < size.height; j += step) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
