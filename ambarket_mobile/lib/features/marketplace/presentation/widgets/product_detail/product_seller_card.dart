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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final isNarrow = constraints.maxWidth < 360;

        return AppGlassCard(
          variant: AppGlassCardVariant.elevated,
          padding: EdgeInsets.all(
            isNarrow
                ? AppSpacing.sm
                : (isCompact ? AppSpacing.md : AppSpacing.lg),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: isNarrow ? 48 : (isCompact ? 56 : 64),
                    child: CircleAvatar(
                      radius: isNarrow ? 22 : (isCompact ? 26 : 30),
                      backgroundColor: context.colors.primary.withValues(
                        alpha: 0.1,
                      ),
                      backgroundImage: profileAsync.value?.avatarUrl != null
                          ? CachedNetworkImageProvider(
                              profileAsync.value!.avatarUrl!,
                              maxWidth: 120,
                              maxHeight: 120,
                            )
                          : null,
                      child: profileAsync.value?.avatarUrl == null
                          ? Icon(
                              Icons.storefront_rounded,
                              color: context.colors.primary,
                              size: isNarrow ? 24 : (isCompact ? 28 : 32),
                            )
                          : null,
                    ),
                  ),
                  SizedBox(width: isNarrow ? AppSpacing.sm : AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        profileAsync.when(
                          data: (profile) => _SellerNameWithBadge(
                            name: profile.name ?? profile.username ?? 'Penjual',
                            textStyle: theme.textTheme.titleMedium?.copyWith(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          loading: () => SizedBox(
                            width: 120,
                            height: 16,
                            child: LinearProgressIndicator(
                              color: context.colors.primary,
                            ),
                          ),
                          error: (err, st) => _SellerNameWithBadge(
                            name: 'Penjual',
                            textStyle: theme.textTheme.titleMedium?.copyWith(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.bold,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${summary.totalReviews} ulasan',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: context.colors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => SizedBox(
                            height: 14,
                            width: 70,
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
                  if (!isOwner) ...[
                    SizedBox(width: isNarrow ? AppSpacing.xs : AppSpacing.sm),
                    _ReportSellerButton(onPressed: onReport),
                  ],
                ],
              ),
              if (isCompact) ...[
                SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: _VisitSellerButton(onPressed: onVisitProfile),
                ),
              ] else ...[
                SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: _VisitSellerButton(onPressed: onVisitProfile),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SellerNameWithBadge extends StatelessWidget {
  final String name;
  final TextStyle? textStyle;

  const _SellerNameWithBadge({required this.name, required this.textStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            name,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.verified, size: 16, color: context.colors.primary),
      ],
    );
  }
}

class _VisitSellerButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _VisitSellerButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.storefront_outlined, size: 16),
      label: const Text(
        'Kunjungi',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.colors.primary.withValues(alpha: 0.1),
        foregroundColor: context.colors.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class _ReportSellerButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ReportSellerButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: 'Laporkan Penjual',
      icon: Icon(
        Icons.report_problem_outlined,
        size: 20,
        color: context.colors.textSecondary,
      ),
      style: IconButton.styleFrom(
        backgroundColor: context.colors.surfaceHighlight,
        fixedSize: const Size(40, 40),
        minimumSize: const Size(40, 40),
      ),
    );
  }
}
