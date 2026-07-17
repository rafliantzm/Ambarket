import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';
import 'package:ambarket_mobile/core/widgets/ambarket_scaffold.dart';
import 'package:ambarket_mobile/core/widgets/premium_surface_card.dart';
import 'package:ambarket_mobile/core/widgets/premium_empty_state.dart';
import 'package:ambarket_mobile/core/widgets/premium_status_badge.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final query = value.toLowerCase().trim();
      if (query == _searchQuery) return;
      setState(() => _searchQuery = query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final isLoading = ref.watch(
      adminActionControllerProvider.select((state) => state.isLoading),
    );

    return AmbarketScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Moderasi Pengguna',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Cari Pengguna...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: usersAsync.when(
              data: (paginatedState) {
                final users = paginatedState.items;
                final filtered = users
                    .where(
                      (u) =>
                          (u.name?.toLowerCase().contains(_searchQuery) ??
                              false) ||
                          (u.username?.toLowerCase().contains(_searchQuery) ??
                              false),
                    )
                    .toList();

                if (filtered.isEmpty) {
                  return const PremiumEmptyState(
                    icon: Icons.people_outline,
                    title: 'Tidak ada pengguna',
                    message: 'Tidak ada pengguna yang ditemukan.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(adminUsersProvider.future),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (!paginatedState.hasMore) return false;
                      if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent) {
                        ref.read(adminUsersProvider.notifier).loadMore();
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

                        final user = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: PremiumSurfaceCard(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  user.username?[0].toUpperCase() ?? '?',
                                ),
                              ),
                              title: Text(
                                user.name ?? user.username ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    Text('Role: ${user.role}'),
                                    const SizedBox(width: AppSpacing.sm),
                                    PremiumStatusBadge(
                                      label: user.isSuspended
                                          ? 'Suspended'
                                          : 'Active',
                                      status: user.isSuspended
                                          ? PremiumBadgeStatus.error
                                          : PremiumBadgeStatus.success,
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!user.isSuspended && user.role != 'admin')
                                    IconButton(
                                      icon: const Icon(
                                        Icons.block,
                                        color: Colors.red,
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () => _showActionDialog(
                                              'Suspend',
                                              () {
                                                ref
                                                    .read(
                                                      adminActionControllerProvider
                                                          .notifier,
                                                    )
                                                    .suspendUser(
                                                      user.id,
                                                      'Suspended by admin',
                                                    );
                                              },
                                            ),
                                    ),
                                  if (user.isSuspended)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () => _showActionDialog(
                                              'Unsuspend',
                                              () {
                                                ref
                                                    .read(
                                                      adminActionControllerProvider
                                                          .notifier,
                                                    )
                                                    .unsuspendUser(user.id);
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
        title: Text('$actionName Pengguna?'),
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
