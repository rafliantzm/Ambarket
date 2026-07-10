import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_glass_card.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../../../review/presentation/providers/review_provider.dart';

class ProductSellerCard extends ConsumerWidget {
  final String sellerId;
  final bool isOwner;
  final VoidCallback onVisitProfile;
  final VoidCallback onReport;

  const ProductSellerCard({
    super.key,
    required this.sellerId,
    required this.isOwner,
    required this.onVisitProfile,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(sellerRatingSummaryProvider(sellerId));
    final profileAsync = ref.watch(publicProfileProvider(sellerId));
    final theme = Theme.of(context);

    return AppGlassCard(
      variant: AppGlassCardVariant.elevated,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: context.colors.primary.withValues(alpha: 0.1),
            backgroundImage: profileAsync.value?.avatarUrl != null
                ? CachedNetworkImageProvider(
                    profileAsync.value!.avatarUrl!,
                    maxWidth: 104,
                    maxHeight: 104,
                  )
                : null,
            child: profileAsync.value?.avatarUrl == null
                ? Icon(
                    Icons.storefront_rounded,
                    color: context.colors.primary,
                    size: 28,
                  )
                : null,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                profileAsync.when(
                  data: (profile) => Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.name ?? profile.username ?? 'Penjual',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: context.colors.primary,
                      ),
                    ],
                  ),
                  loading: () => SizedBox(
                    width: 100,
                    height: 16,
                    child: LinearProgressIndicator(
                      color: context.colors.primary,
                    ),
                  ),
                  error: (err, st) => Text(
                    'Penjual',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                ratingAsync.when(
                  data: (summary) {
                    if (summary.totalReviews == 0) {
                      return Text(
                        'Belum ada rating',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      );
                    }
                    return Row(
                      children: [
                        Text(
                          summary.averageRating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(
                          '(${summary.totalReviews} ulasan)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => SizedBox(
                    height: 14,
                    width: 60,
                    child: LinearProgressIndicator(
                      color: context.colors.primary,
                    ),
                  ),
                  error: (e, st) => Text(
                    'Gagal memuat',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.colors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onVisitProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary.withValues(alpha: 0.1),
              foregroundColor: context.colors.primary,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kunjungi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
          if (!isOwner) ...[
            SizedBox(width: AppSpacing.sm),
            IconButton(
              icon: Icon(
                Icons.report_problem_outlined,
                size: 20,
                color: context.colors.textMuted,
              ),
              onPressed: onReport,
              tooltip: 'Laporkan Penjual',
            ),
          ],
        ],
      ),
    );
  }
}
