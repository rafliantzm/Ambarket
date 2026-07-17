import 'package:flutter/material.dart';
import 'package:ambarket_mobile/core/theme/app_colors.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';

const Color _loadingAccent = Color(0xFF10B981);

/// 1. Page Loader for Full Screens (Initial Routing)
class AmbarketPageLoader extends StatelessWidget {
  final String status;

  const AmbarketPageLoader({super.key, this.status = 'Menyiapkan data...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: _loadingAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _loadingAccent.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 48,
                        color: _loadingAccent,
                      ),
                      Positioned(
                        bottom: 20,
                        child: Icon(
                          Icons.all_inclusive_rounded,
                          size: 30,
                          color: context.colors.primary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Ambarket',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: 220,
                  child: LinearProgressIndicator(
                    backgroundColor: context.colors.surfaceHighlight,
                    color: _loadingAccent,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
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
