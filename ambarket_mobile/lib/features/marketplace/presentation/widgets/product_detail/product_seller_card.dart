import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_glass_card.dart';
import '../../../../review/presentation/providers/review_provider.dart';
import '../../../../review/presentation/widgets/rating_stars.dart';

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
    final theme = Theme.of(context);

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceHighlight,
            child: const Icon(Icons.person, color: AppColors.textPrimary, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Penjual',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                ratingAsync.when(
                  data: (summary) {
                    if (summary.totalReviews == 0) {
                      return Text('Belum ada ulasan', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary));
                    }
                    return Row(
                      children: [
                        RatingStars(rating: summary.averageRating.round(), size: 14),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${summary.averageRating.toStringAsFixed(1)} (${summary.totalReviews})',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    height: 14,
                    width: 60,
                    child: LinearProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, st) => Text('Gagal memuat', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onVisitProfile,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.borderStrong),
            ),
            child: const Text('Profil'),
          ),
          if (!isOwner) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              icon: const Icon(Icons.report_problem_outlined, size: 20, color: AppColors.textMuted),
              onPressed: onReport,
              tooltip: 'Laporkan Penjual',
            ),
          ]
        ],
      ),
    );
  }
}
