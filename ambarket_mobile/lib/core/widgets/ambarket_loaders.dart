import 'package:flutter/material.dart';
import 'package:ambarket_mobile/core/theme/app_colors.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';

const Color _loadingAccent = Color(0xFFE53935);

/// 1. Page Loader for Full Screens (Initial Routing)
class AmbarketPageLoader extends StatelessWidget {
  final String status;

  const AmbarketPageLoader({super.key, this.status = 'Menyiapkan data...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.surfaceHighlight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceHighlight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl * 2,
              ),
              child: LinearProgressIndicator(
                backgroundColor: context.colors.surfaceHighlight,
                color: _loadingAccent,
                minHeight: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              status,
              style: TextStyle(color: context.colors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2. Section Skeleton (For Cards/Dashboards)
class AmbarketSectionSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const AmbarketSectionSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 12.0,
    this.margin,
  });

  @override
  State<AmbarketSectionSkeleton> createState() =>
      _AmbarketSectionSkeletonState();
}

class _AmbarketSectionSkeletonState extends State<AmbarketSectionSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.2,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: context.colors.surfaceHighlight.withValues(
              alpha: _animation.value,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// 3. List Skeleton (For ListViews)
class AmbarketListSkeleton extends StatelessWidget {
  final int itemCount;
  final double rowHeight;

  const AmbarketListSkeleton({
    super.key,
    this.itemCount = 5,
    this.rowHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        return AmbarketSectionSkeleton(height: rowHeight);
      },
    );
  }
}

/// 4. Inline Loader (For Icons/Small spaces)
class AmbarketInlineLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AmbarketInlineLoader({
    super.key,
    this.size = 20.0,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? _loadingAccent),
      ),
    );
  }
}

/// 5. Load More Indicator (For Pagination Bottom)
class AmbarketLoadMoreIndicator extends StatelessWidget {
  const AmbarketLoadMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: AmbarketInlineLoader(size: 24, strokeWidth: 2.5),
      ),
    );
  }
}

/// 6. Action Loader (For Buttons)
class AmbarketActionLoader extends StatelessWidget {
  final Color? color;
  const AmbarketActionLoader({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return AmbarketInlineLoader(
      size: 16,
      strokeWidth: 2,
      color: color ?? Colors.white,
    );
  }
}
