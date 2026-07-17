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
    void openDetail() {
      Future.microtask(() {
        if (context.mounted) context.push('/products/${product.id}');
      });
    }

    return AppGlassCard(
      padding: EdgeInsets.zero,
      variant: AppGlassCardVariant.soft,
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
                              .clamp(160, 360)
                              .round();
                      final cacheHeight =
                          (constraints.maxHeight * devicePixelRatio)
                              .clamp(160, 360)
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

                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: openDetail,
                      splashColor: context.colors.primary.withValues(
                        alpha: 0.08,
                      ),
                      highlightColor: context.colors.primary.withValues(
                        alpha: 0.04,
                      ),
                    ),
                  ),
                ),

                // Badges
                if (!isActive)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: AppStatusBadge(
                      label: product.status == 'sold' ? 'Terjual' : 'Dipesan',
                      status: product.status == 'sold'
                          ? BadgeStatus.error
                          : BadgeStatus.warning,
                    ),
                  ),

                if (isOwner)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildOwnerProductBadge(context),
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
                        onPressed: () => _addToCart(context, ref),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Details Section
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: openDetail,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.28,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                      const SizedBox(height: 4),
                      AppMoneyText(amount: product.price, fontSize: 15),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              AppStatusBadge(
                                label: _getConditionLabel(product.condition),
                                status: BadgeStatus.neutral,
                              ),
                              if (product.isNegotiable) ...[
                                const SizedBox(width: 4),
                                const AppStatusBadge(
                                  label: 'Nego',
                                  status: BadgeStatus.success,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(cartActionControllerProvider.notifier)
          .addToCart(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ditambahkan ke keranjang'),
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
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
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

  Widget _buildOwnerProductBadge(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.storefront_rounded, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'Toko Anda',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
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
