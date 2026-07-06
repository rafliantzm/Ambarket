import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../domain/models/product_model.dart';
import '../providers/marketplace_provider.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryImage = product.images.where((img) => img.isPrimary).firstOrNull ?? product.images.firstOrNull;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    final wishlistsState = ref.watch(wishlistProductIdsProvider);
    final isWishlisted = wishlistsState.maybeWhen(
      data: (wishlists) => wishlists.contains(product.id),
      orElse: () => false,
    );

    return AppGlassCard(
      padding: EdgeInsets.zero,
      onTap: () {
        context.push('/products/${product.id}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                primaryImage != null
                    ? CachedNetworkImage(
                        imageUrl: primaryImage.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.backgroundDarker,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.backgroundDarker,
                          child: const Center(child: Icon(Icons.broken_image, size: 40, color: AppColors.textMuted)),
                        ),
                      )
                    : Container(
                        color: AppColors.backgroundDarker,
                        child: const Center(child: Icon(Icons.image, size: 40, color: AppColors.textMuted)),
                      ),
                
                // Dark gradient overlay at top for icons
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: AppColors.surface,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      icon: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: isWishlisted ? AppColors.accent : AppColors.textPrimary,
                      ),
                      onPressed: () async {
                        try {
                          await ref.read(wishlistProductIdsProvider.notifier).toggleWishlist(product.id);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
                
                if (product.status != 'available')
                  Positioned(
                    top: 8,
                    left: 8,
                    child: AppStatusBadge(
                      label: product.status == 'sold' ? 'Terjual' : 'Dipesan',
                      status: product.status == 'sold' ? BadgeStatus.error : BadgeStatus.warning,
                    ),
                  ),
              ],
            ),
          ),
          
          // Details Section
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    currencyFormatter.format(product.price),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getConditionLabel(product.condition),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (product.isNegotiable) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Nego',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
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

  String _getConditionLabel(String condition) {
    switch (condition) {
      case 'new': return 'Baru';
      case 'like_new': return 'Seperti Baru';
      case 'good': return 'Baik';
      case 'fair': return 'Cukup';
      default: return condition;
    }
  }
}

