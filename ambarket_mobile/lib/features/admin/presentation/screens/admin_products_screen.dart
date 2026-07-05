import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);
    final actionState = ref.watch(adminActionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Moderasi Produk')),
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
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = products.where((p) => p.title.toLowerCase().contains(_searchQuery)).toList();
                
                if (filtered.isEmpty) {
                  return const Center(child: Text('Tidak ada produk ditemukan.'));
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(adminProductsProvider.future),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return ListTile(
                        title: Text(product.title),
                        subtitle: Text('Status: ${product.status.toUpperCase()}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (product.status != 'hidden')
                              IconButton(
                                icon: const Icon(Icons.visibility_off, color: Colors.orange),
                                onPressed: actionState.isLoading ? null : () => _showActionDialog('Hide', () {
                                  ref.read(adminActionControllerProvider.notifier).hideProduct(product.id, 'Moderated by admin');
                                }),
                              ),
                            if (product.status != 'rejected')
                              IconButton(
                                icon: const Icon(Icons.block, color: Colors.red),
                                onPressed: actionState.isLoading ? null : () => _showActionDialog('Reject', () {
                                  ref.read(adminActionControllerProvider.notifier).rejectProduct(product.id, 'Rejected by admin');
                                }),
                              ),
                            if (product.status == 'hidden' || product.status == 'rejected')
                              IconButton(
                                icon: const Icon(Icons.restore, color: Colors.green),
                                onPressed: actionState.isLoading ? null : () => _showActionDialog('Restore', () {
                                  ref.read(adminActionControllerProvider.notifier).restoreProduct(product.id);
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
        title: Text('$actionName Produk?'),
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
