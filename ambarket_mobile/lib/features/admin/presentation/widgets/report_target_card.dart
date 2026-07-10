import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';

class ReportTargetCard extends ConsumerWidget {
  final String targetType;
  final String targetId;

  const ReportTargetCard({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (targetType == 'product') {
      final productsAsync = ref.watch(adminProductsProvider);
      return productsAsync.when(
        data: (paginatedState) {
          try {
            final p = paginatedState.items.firstWhere((e) => e.id == targetId);
            return Card(
              child: ListTile(
                title: Text(p.title),
                subtitle: Text('Status: ${p.status}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (p.status != 'hidden')
                      IconButton(
                        icon: const Icon(
                          Icons.visibility_off,
                          color: Colors.orange,
                        ),
                        onPressed: () => ref
                            .read(adminActionControllerProvider.notifier)
                            .hideProduct(p.id, 'Reported'),
                      ),
                    if (p.status != 'rejected')
                      IconButton(
                        icon: const Icon(Icons.block, color: Colors.red),
                        onPressed: () => ref
                            .read(adminActionControllerProvider.notifier)
                            .rejectProduct(p.id, 'Reported'),
                      ),
                    if (p.status == 'hidden' || p.status == 'rejected')
                      IconButton(
                        icon: const Icon(Icons.restore, color: Colors.green),
                        onPressed: () => ref
                            .read(adminActionControllerProvider.notifier)
                            .restoreProduct(p.id),
                      ),
                  ],
                ),
              ),
            );
          } catch (e) {
            return const Card(
              child: ListTile(title: Text('Produk tidak ditemukan')),
            );
          }
        },
        loading: () => const CircularProgressIndicator(),
        error: (e, st) => const SizedBox(),
      );
    } else if (targetType == 'user') {
      final usersAsync = ref.watch(adminUsersProvider);
      return usersAsync.when(
        data: (paginatedState) {
          try {
            final u = paginatedState.items.firstWhere((e) => e.id == targetId);
            return Card(
              child: ListTile(
                title: Text(u.username ?? 'Unknown'),
                subtitle: Text('Suspended: ${u.isSuspended}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!u.isSuspended)
                      IconButton(
                        icon: const Icon(Icons.block, color: Colors.red),
                        onPressed: () => ref
                            .read(adminActionControllerProvider.notifier)
                            .suspendUser(u.id, 'Reported'),
                      ),
                    if (u.isSuspended)
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        onPressed: () => ref
                            .read(adminActionControllerProvider.notifier)
                            .unsuspendUser(u.id),
                      ),
                  ],
                ),
              ),
            );
          } catch (e) {
            return const Card(
              child: ListTile(title: Text('Pengguna tidak ditemukan')),
            );
          }
        },
        loading: () => const CircularProgressIndicator(),
        error: (e, st) => const SizedBox(),
      );
    } else if (targetType == 'review') {
      final reviewsAsync = ref.watch(adminReviewsProvider);
      return reviewsAsync.when(
        data: (paginatedState) {
          try {
            final r = paginatedState.items.firstWhere((e) => e.id == targetId);
            return Card(
              child: ListTile(
                title: Text('Rating: ${r.rating}'),
                subtitle: Text(r.comment ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!r.isHidden)
                      IconButton(
                        icon: const Icon(
                          Icons.visibility_off,
                          color: Colors.red,
                        ),
                        onPressed: () => ref
                            .read(adminActionControllerProvider.notifier)
                            .hideReview(r.id, 'Reported'),
                      ),
                    if (r.isHidden)
                      IconButton(
                        icon: const Icon(Icons.restore, color: Colors.green),
                        onPressed: () => ref
                            .read(adminActionControllerProvider.notifier)
                            .restoreReview(r.id),
                      ),
                  ],
                ),
              ),
            );
          } catch (e) {
            return const Card(
              child: ListTile(title: Text('Ulasan tidak ditemukan')),
            );
          }
        },
        loading: () => const CircularProgressIndicator(),
        error: (e, st) => const SizedBox(),
      );
    }

    return const SizedBox();
  }
}
