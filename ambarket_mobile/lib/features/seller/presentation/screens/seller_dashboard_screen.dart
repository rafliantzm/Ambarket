import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/seller_provider.dart';
import '../../../offer/presentation/providers/offer_provider.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myProductsAsync = ref.watch(myProductsProvider);
    final myOffersAsync = ref.watch(myReceivedOffersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk Saya'),
      ),
      body: myProductsAsync.when(
        data: (paginatedState) {
          final products = paginatedState.products;
          final total = products.length;
          final active = products.where((p) => p.status == 'active').length;
          final sold = products.where((p) => p.status == 'sold').length;
          final archived = products.where((p) => p.status == 'archived').length;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myProductsProvider);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        _buildStatsGrid(context, total, active, sold, archived),
                        const SizedBox(height: AppSpacing.md),
                        myOffersAsync.when(
                          data: (offers) {
                            final pendingOffersCount = offers.where((o) => o.status == 'pending').length;
                            if (pendingOffersCount == 0) return const SizedBox.shrink();
                            
                            return Card(
                              color: theme.colorScheme.primaryContainer,
                              child: ListTile(
                                leading: Icon(Icons.notifications_active, color: theme.colorScheme.onPrimaryContainer),
                                title: Text('$pendingOffersCount Tawaran Baru', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
                                trailing: ElevatedButton(
                                  onPressed: () => context.push('/offers'),
                                  child: const Text('Lihat'),
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (err, stack) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Card(
                          color: theme.colorScheme.tertiaryContainer,
                          child: ListTile(
                            leading: Icon(Icons.shopping_bag, color: theme.colorScheme.onTertiaryContainer),
                            title: Text('Pesanan Masuk', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onTertiaryContainer)),
                            trailing: ElevatedButton(
                              onPressed: () => context.push('/seller-orders'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.tertiary,
                                foregroundColor: theme.colorScheme.onTertiary,
                              ),
                              child: const Text('Kelola'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (products.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Icon(Icons.storefront, size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Anda belum memiliki produk',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/seller/products/new'),
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Produk'),
                          )
                        ],
                      ),
                    ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= products.length) {
                          return Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  ref.read(myProductsProvider.notifier).fetchMore();
                                },
                                child: const Text('Muat Lebih Banyak'),
                              ),
                            ),
                          );
                        }

                        final product = products[index];
                        final primaryImage = product.images.where((i) => i.isPrimary).firstOrNull ?? product.images.firstOrNull;
                        final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          child: InkWell(
                            onTap: () => context.push('/seller/products/${product.id}/edit'),
                            child: Row(
                              children: [
                                // Image
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                  ),
                                  child: primaryImage != null
                                      ? ClipRRect(
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                          child: CachedNetworkImage(
                                            imageUrl: primaryImage.imageUrl, 
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                            errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                                          ),
                                        )
                                      : const Icon(Icons.image),
                                ),
                                // Details
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.title,
                                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            _buildStatusChip(context, product.status),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currencyFormatter.format(product.price),
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (product.status == 'active') ...[
                                              IconButton(
                                                icon: const Icon(Icons.visibility),
                                                tooltip: 'Lihat Produk',
                                                onPressed: () {
                                                  context.push('/products/${product.id}');
                                                },
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  _showConfirmationDialog(
                                                    context,
                                                    title: 'Tandai Terjual',
                                                    content: 'Apakah Anda yakin ingin menandai produk ini sebagai terjual?',
                                                    onConfirm: () {
                                                      ref.read(productActionControllerProvider.notifier).updateProductStatus(product.id, 'sold');
                                                    },
                                                  );
                                                },
                                                style: TextButton.styleFrom(
                                                  minimumSize: Size.zero,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                ),
                                                child: const Text('Mark Sold'),
                                              ),
                                            ],
                                            const SizedBox(width: 8),
                                            if (product.status != 'archived')
                                              TextButton(
                                                onPressed: () {
                                                  _showConfirmationDialog(
                                                    context,
                                                    title: 'Arsipkan Produk',
                                                    content: 'Apakah Anda yakin ingin mengarsipkan produk ini? Produk tidak akan terlihat di marketplace.',
                                                    onConfirm: () {
                                                      ref.read(productActionControllerProvider.notifier).updateProductStatus(product.id, 'archived');
                                                    },
                                                  );
                                                },
                                                style: TextButton.styleFrom(
                                                  minimumSize: Size.zero,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                ),
                                                child: const Text('Archive'),
                                              ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: products.length + (paginatedState.hasMore ? 1 : 0),
                    ),
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Gagal memuat produk: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/seller/products/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final theme = Theme.of(context);
    Color bgColor;
    Color fgColor;
    String label;

    switch (status) {
      case 'active':
        bgColor = theme.colorScheme.primaryContainer;
        fgColor = theme.colorScheme.onPrimaryContainer;
        label = 'Active';
        break;
      case 'sold':
        bgColor = theme.colorScheme.tertiaryContainer;
        fgColor = theme.colorScheme.onTertiaryContainer;
        label = 'Sold';
        break;
      case 'archived':
      default:
        bgColor = theme.colorScheme.surfaceContainerHighest;
        fgColor = theme.colorScheme.onSurfaceVariant;
        label = 'Archived';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: fgColor),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, int total, int active, int sold, int archived) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(context, 'Total', total.toString(), Icons.inventory_2),
        _buildStatCard(context, 'Active', active.toString(), Icons.check_circle, color: Theme.of(context).colorScheme.primary),
        _buildStatCard(context, 'Sold', sold.toString(), Icons.monetization_on, color: Theme.of(context).colorScheme.tertiary),
        _buildStatCard(context, 'Archived', archived.toString(), Icons.archive, color: Theme.of(context).colorScheme.outline),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    final fgColor = color ?? theme.colorScheme.onSurface;
    
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, color: fgColor, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: fgColor)),
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, {required String title, required String content, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }
}
