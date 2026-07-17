import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';
import 'package:ambarket_mobile/core/widgets/ambarket_scaffold.dart';
import 'package:ambarket_mobile/core/widgets/premium_surface_card.dart';
import 'package:ambarket_mobile/core/widgets/premium_empty_state.dart';
import 'package:ambarket_mobile/core/widgets/premium_status_badge.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
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
    final productsAsync = ref.watch(adminProductsProvider);
    final isLoading = ref.watch(
      adminActionControllerProvider.select((state) => state.isLoading),
    );

    return AmbarketScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Moderasi Produk',
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
                labelText: 'Cari Produk...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (paginatedState) {
                final products = paginatedState.items;
                final filtered = products
                    .where((p) => p.title.toLowerCase().contains(_searchQuery))
                    .toList();

                if (filtered.isEmpty) {
                  return const PremiumEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Tidak ada produk',
                    message: 'Tidak ada produk yang ditemukan.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.refresh(adminProductsProvider.future),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (!paginatedState.hasMore) return false;
                      if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent) {
                        ref.read(adminProductsProvider.notifier).loadMore();
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

                        final product = filtered[index];
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
                                product.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: PremiumStatusBadge(
                                    label: product.status.toUpperCase(),
                                    status:
                                        product.status == 'hidden' ||
                                            product.status == 'rejected'
                                        ? PremiumBadgeStatus.error
                                        : PremiumBadgeStatus.success,
                                  ),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (product.status != 'hidden')
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility_off,
                                        color: Colors.orange,
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () => _showActionDialog('Hide', () {
                                              ref
                                                  .read(
                                                    adminActionControllerProvider
                                                        .notifier,
                                                  )
                                                  .hideProduct(
                                                    product.id,
                                                    'Moderated by admin',
                                                  );
                                            }),
                                    ),
                                  if (product.status != 'rejected')
                                    IconButton(
                                      icon: const Icon(
                                        Icons.block,
                                        color: Colors.red,
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () => _showActionDialog('Reject', () {
                                              ref
                                                  .read(
                                                    adminActionControllerProvider
                                                        .notifier,
                                                  )
                                                  .rejectProduct(
                                                    product.id,
                                                    'Rejected by admin',
                                                  );
                                            }),
                                    ),
                                  if (product.status == 'hidden' ||
                                      product.status == 'rejected')
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
                                                    .restoreProduct(product.id);
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
        title: Text('$actionName Produk?'),
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
