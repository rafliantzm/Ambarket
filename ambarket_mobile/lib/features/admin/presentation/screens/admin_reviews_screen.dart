import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';
import 'package:ambarket_mobile/core/widgets/ambarket_scaffold.dart';
import 'package:ambarket_mobile/core/widgets/premium_surface_card.dart';
import 'package:ambarket_mobile/core/widgets/premium_empty_state.dart';

class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen> {
  bool _showHidden = false;

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(adminReviewsProvider);
    final isLoading = ref.watch(
      adminActionControllerProvider.select((state) => state.isLoading),
    );

    return AmbarketScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Moderasi Ulasan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Tampilkan Ulasan Disembunyikan'),
            value: _showHidden,
            onChanged: (val) => setState(() => _showHidden = val),
          ),
          Expanded(
            child: reviewsAsync.when(
              data: (paginatedState) {
                final reviews = paginatedState.items;
                final filtered = reviews
                    .where((r) => r.isHidden == _showHidden)
                    .toList();
                if (filtered.isEmpty) {
                  return const PremiumEmptyState(
                    icon: Icons.rate_review_outlined,
                    title: 'Tidak ada ulasan',
                    message: 'Tidak ada ulasan ditemukan.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.refresh(adminReviewsProvider.future),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (!paginatedState.hasMore) return false;
                      if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent) {
                        ref.read(adminReviewsProvider.notifier).loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      cacheExtent: 800,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      itemCount:
                          filtered.length + (paginatedState.hasMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index == filtered.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final review = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: PremiumSurfaceCard(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            child: ListTile(
                              title: Text(
                                'Rating: ${review.rating} Bintang',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                review.comment ?? 'Tidak ada komentar',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!review.isHidden)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility_off,
                                        color: Colors.red,
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () => _showActionDialog('Hide', () {
                                              ref
                                                  .read(
                                                    adminActionControllerProvider
                                                        .notifier,
                                                  )
                                                  .hideReview(
                                                    review.id,
                                                    'Hidden by admin',
                                                  );
                                            }),
                                    ),
                                  if (review.isHidden)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.restore,
                                        color: Colors.green,
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () => _showActionDialog(
                                              'Restore',
                                              () {
                                                ref
                                                    .read(
                                                      adminActionControllerProvider
                                                          .notifier,
                                                    )
                                                    .restoreReview(review.id);
                                              },
                                            ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionDialog(String actionName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionName Ulasan?'),
        content: const Text('Tindakan ini akan dicatat dalam audit logs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }
}
