import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';

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
    final actionState = ref.watch(adminActionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Moderasi Ulasan')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Tampilkan Ulasan Disembunyikan'),
            value: _showHidden,
            onChanged: (val) => setState(() => _showHidden = val),
          ),
          Expanded(
            child: reviewsAsync.when(
              data: (reviews) {
                final filtered = reviews.where((r) => r.isHidden == _showHidden).toList();
                
                if (filtered.isEmpty) {
                  return const Center(child: Text('Tidak ada ulasan ditemukan.'));
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(adminReviewsProvider.future),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final review = filtered[index];
                      return ListTile(
                        title: Text('Rating: ${review.rating} Bintang'),
                        subtitle: Text(review.comment ?? 'Tidak ada komentar'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!review.isHidden)
                              IconButton(
                                icon: const Icon(Icons.visibility_off, color: Colors.red),
                                onPressed: actionState.isLoading ? null : () => _showActionDialog('Hide', () {
                                  ref.read(adminActionControllerProvider.notifier).hideReview(review.id, 'Hidden by admin');
                                }),
                              ),
                            if (review.isHidden)
                              IconButton(
                                icon: const Icon(Icons.restore, color: Colors.green),
                                onPressed: actionState.isLoading ? null : () => _showActionDialog('Restore', () {
                                  ref.read(adminActionControllerProvider.notifier).restoreReview(review.id);
                                }),
                              ),
                          ],
                        ),
                      );
                    },
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Ya'),
          )
        ],
      ),
    );
  }
}
