import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../marketplace/domain/models/product_model.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/seller_product_provider.dart';

class SellerProductCard extends ConsumerWidget {
  final ProductModel product;

  const SellerProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final imageUrl = product.images.isNotEmpty ? product.images.first.imageUrl : null;
    final actionState = ref.watch(sellerProductActionControllerProvider);
    final isLoading = actionState.isLoading;

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surfaceContainerHighest,
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null ? const Icon(Icons.inventory_2, color: Colors.grey) : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${product.price.toStringAsFixed(0)}',
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildStatusBadge(),
                        if (product.condition.isNotEmpty)
                          Text(
                            product.condition,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => context.push('/products/${product.id}'),
                child: const Text('Lihat Detail'),
              ),
              if (product.status != 'rejected' && product.status != 'hidden')
                OutlinedButton(
                  onPressed: () => context.push('/seller/products/${product.id}/edit'),
                  child: const Text('Edit'),
                ),
              if (product.status == 'active')
                AppButton(
                  label: 'Arsipkan',
                  isLoading: isLoading,
                  onPressed: isLoading ? () {} : () => _handleArchive(context, ref),
                ),
              if (product.status == 'archived')
                AppButton(
                  label: 'Aktifkan',
                  isLoading: isLoading,
                  onPressed: isLoading ? () {} : () => _handleReactivate(context, ref),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    BadgeStatus badgeStatus;
    String badgeText;

    switch (product.status) {
      case 'active':
        badgeStatus = BadgeStatus.success;
        badgeText = 'Aktif';
        break;
      case 'reserved':
        badgeStatus = BadgeStatus.warning;
        badgeText = 'Dipesan';
        break;
      case 'sold':
        badgeStatus = BadgeStatus.info;
        badgeText = 'Terjual';
        break;
      case 'archived':
        badgeStatus = BadgeStatus.neutral;
        badgeText = 'Diarsipkan';
        break;
      case 'hidden':
        badgeStatus = BadgeStatus.error;
        badgeText = 'Disembunyikan';
        break;
      case 'rejected':
        badgeStatus = BadgeStatus.error;
        badgeText = 'Ditolak';
        break;
      default:
        badgeStatus = BadgeStatus.neutral;
        badgeText = product.status;
    }

    return AppStatusBadge(status: badgeStatus, label: badgeText);
  }

  void _handleArchive(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arsipkan Produk'),
        content: const Text('Produk yang diarsipkan tidak akan tampil di pencarian pembeli. Anda yakin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _executeArchive(context, ref);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );
  }

  void _handleReactivate(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aktifkan Produk'),
        content: const Text('Produk ini akan kembali tampil dan bisa dibeli oleh pembeli. Anda yakin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _executeReactivate(context, ref);
            },
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeArchive(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(sellerProductActionControllerProvider.notifier).archiveProduct(product.id);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil diarsipkan.'), backgroundColor: Colors.green),
      );
    } else {
      final errorMsg = ref.read(sellerProductActionControllerProvider).error ?? 'Gagal mengarsipkan produk.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _executeReactivate(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(sellerProductActionControllerProvider.notifier).reactivateProduct(product.id);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil diaktifkan.'), backgroundColor: Colors.green),
      );
    } else {
      final errorMsg = ref.read(sellerProductActionControllerProvider).error ?? 'Gagal mengaktifkan produk.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }
}
