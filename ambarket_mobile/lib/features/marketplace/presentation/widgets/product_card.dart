import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_money_text.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/product_model.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryImage =
        product.images.where((img) => img.isPrimary).firstOrNull ??
        product.images.firstOrNull;

    final userId = ref.watch(currentUserProvider.select((user) => user?.id));
    final isOwner = userId == product.sellerId;
    final isActive = product.status == 'active';

    return AppGlassCard(
      padding: EdgeInsets.zero,
      variant: AppGlassCardVariant.soft,
      onTap: () {
        // Use Future.microtask so the InkWell ripple finishes its first frame before heavy navigation
        Future.microtask(() {
          if (context.mounted) context.push('/products/${product.id}');
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          AspectRatio(
            aspectRatio: 1.05,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (primaryImage != null)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final devicePixelRatio = MediaQuery.devicePixelRatioOf(
                        context,
                      );
                      final cacheWidth =
                          (constraints.maxWidth * devicePixelRatio)
                              .clamp(180, 520)
                              .round();
                      final cacheHeight =
                          (constraints.maxHeight * devicePixelRatio)
                              .clamp(180, 520)
                              .round();

                      return CachedNetworkImage(
                        imageUrl: primaryImage.imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: cacheWidth,
                        memCacheHeight: cacheHeight,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholder: (context, url) =>
                            _buildImagePlaceholder(context),
                        errorWidget: (context, url, error) =>
                            _buildImagePlaceholder(context, isError: true),
                      );
                    },
                  )
                else
                  _buildImagePlaceholder(context),

                // Overlay Gradient at bottom of image
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),

                // Badges
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isActive)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: AppStatusBadge(
                            label: product.status == 'sold'
                                ? 'Terjual'
                                : 'Dipesan',
                            status: product.status == 'sold'
                                ? BadgeStatus.error
                                : BadgeStatus.warning,
                          ),
                        ),
                      if (isOwner)
                        const AppStatusBadge(
                          label: 'Toko Anda',
                          status: BadgeStatus
                              .info, // Changed to info as primary isn't in BadgeStatus
                        ),
                    ],
                  ),
                ),

                // Cart Button
                if (!isOwner && isActive)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colors.surface.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        iconSize: 18,
                        icon: Icon(
                          Icons.add_shopping_cart_outlined,
                          color: context.colors.textPrimary,
                        ),
                        onPressed: () async {
                          try {
                            await ref
                                .read(cartActionControllerProvider.notifier)
                                .addToCart(product.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Ditambahkan ke keranjang',
                                  ),
                                  action: SnackBarAction(
                                    label: 'Lihat',
                                    onPressed: () => context.push('/cart'),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceAll('Exception: ', ''),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Details Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(
                10,
              ), // Fixed 10px padding for mobile
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Push content properly
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height:
                            42, // Fixed height for 2 lines (14px * 1.35 * 2 approx + padding)
                        child: Text(
                          product.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AppMoneyText(
                        amount: product.price,
                        fontSize:
                            15, // Slightly smaller to prevent overflow, but bold
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      AppStatusBadge(
                        label: _getConditionLabel(product.condition),
                        status: BadgeStatus.neutral,
                      ),
                      if (product.isNegotiable)
                        const AppStatusBadge(
                          label: 'Nego',
                          status: BadgeStatus.success,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context, {bool isError = false}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.colors.surfaceHighlight, context.colors.surface],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isError
                  ? Icons.broken_image_rounded
                  : Icons.shopping_bag_outlined,
              size: 32,
              color: context.colors.textMuted.withValues(alpha: 0.5),
            ),
            if (isError) ...[
              const SizedBox(height: 8),
              Text(
                'Gambar tidak tersedia',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.colors.textMuted.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getConditionLabel(String condition) {
    switch (condition) {
      case 'new':
        return 'Baru';
      case 'like_new':
        return 'Spt. Baru';
      case 'good':
        return 'Baik';
      case 'fair':
        return 'Cukup';
      default:
        return condition;
    }
  }
}
