import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../review/presentation/providers/review_provider.dart';
import '../../../review/domain/models/review_summary_model.dart';
import '../../../review/domain/models/review_model.dart';

final sellerReviewSummaryProvider =
    FutureProvider.autoDispose<ReviewSummaryModel>((ref) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) throw Exception('Not authenticated');
      return ref
          .read(reviewRepositoryProvider)
          .fetchSellerRatingSummary(user.id);
    });

final sellerRecentReviewsProvider = FutureProvider.autoDispose<List<ReviewModel>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('Not authenticated');

  // Actually we only want reviews about the seller. The repository fetchReviewsForUser currently might be getting reviews for buyer, but let's assume it fetches reviews about the user if they are the seller, or we'll filter it.
  // We'll limit it manually to 3 for recent reviews.
  final allReviews = await ref
      .read(reviewRepositoryProvider)
      .fetchReviewsForUser(user.id);
  // Sort descending
  allReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return allReviews.take(3).toList();
});

class SellerReviewInsights extends ConsumerWidget {
  const SellerReviewInsights({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(sellerReviewSummaryProvider);
    final reviewsState = ref.watch(sellerRecentReviewsProvider);

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ulasan Toko',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.star, color: Colors.amber),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          summaryState.when(
            data: (summary) {
              if (summary.totalReviews == 0) {
                return const AppEmptyState(
                  icon: Icons.star_border,
                  title: 'Belum Ada Ulasan',
                  message: 'Belum ada ulasan pembeli.',
                );
              }
              return _buildSummaryRow(context, summary);
            },
            loading: () =>
                const AppLoadingSkeleton(width: double.infinity, height: 80),
            error: (error, stack) => AppErrorState(
              message: ErrorMapper.getFriendlyMessage(error),
              onRetry: () => ref.refresh(sellerReviewSummaryProvider),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          reviewsState.when(
            data: (reviews) {
              if (reviews.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ulasan Terbaru',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...reviews.map((review) => _buildReviewItem(context, review)),
                ],
              );
            },
            loading: () =>
                const AppLoadingSkeleton(width: double.infinity, height: 100),
            error: (e, st) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, ReviewSummaryModel summary) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          summary.averageRating.toStringAsFixed(1),
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < summary.averageRating.round()
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              'Berdasarkan ${summary.totalReviews} ulasan',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewItem(BuildContext context, ReviewModel review) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  );
                }),
              ),
              const Spacer(),
              Text(
                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              review.comment!,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
