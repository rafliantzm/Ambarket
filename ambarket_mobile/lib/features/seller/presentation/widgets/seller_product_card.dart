import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
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
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final imageUrl = product.images.isNotEmpty
        ? product.images.first.imageUrl
        : null;
    final isLoading = ref.watch(
      sellerProductActionControllerProvider.select((state) => state.isLoading),
    );

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth:
                            (88 * MediaQuery.devicePixelRatioOf(context))
                                .round(),
                        memCacheHeight:
                            (88 * MediaQuery.devicePixelRatioOf(context))
                                .round(),
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholder: (context, url) => const SizedBox.shrink(),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : const Icon(Icons.inventory_2, color: Colors.grey),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(product.price),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildStatusBadge(),
                        if (product.condition.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Text(
                              _formatCondition(product.condition),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: theme.colorScheme.outlineVariant, height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/products/${product.id}'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Lihat Detail'),
                ),
              ),
              if (product.status != 'rejected' &&
                  product.status != 'hidden') ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        context.push('/seller/products/${product.id}/edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Edit'),
                  ),
                ),
              ],
            ],
          ),
          if (product.status == 'active' || product.status == 'archived') ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 180),
                child: product.status == 'active'
                    ? AppButton(
                        label: 'Arsipkan',
                        isLoading: isLoading,
                        onPressed: () => _handleArchive(context, ref),
                      )
                    : AppButton(
                        label: 'Aktifkan',
                        isLoading: isLoading,
                        onPressed: () => _handleReactivate(context, ref),
                      ),
              ),
            ),
          ],
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

  String _formatCondition(String condition) {
    final normalized = condition.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return condition;
    return normalized
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  void _handleArchive(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arsipkan Produk'),
        content: const Text(
          'Produk yang diarsipkan tidak akan tampil di pencarian pembeli. Anda yakin?',
        ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
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
        content: const Text(
          'Produk ini akan kembali tampil dan bisa dibeli oleh pembeli. Anda yakin?',
        ),
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
    final success = await ref
        .read(sellerProductActionControllerProvider.notifier)
        .archiveProduct(product.id);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil diarsipkan.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final errorMsg =
          ref.read(sellerProductActionControllerProvider).error ??
          'Gagal mengarsipkan produk.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _executeReactivate(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(sellerProductActionControllerProvider.notifier)
        .reactivateProduct(product.id);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil diaktifkan.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final errorMsg =
          ref.read(sellerProductActionControllerProvider).error ??
          'Gagal mengaktifkan produk.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }
}
