import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:ambarket_mobile/core/theme/app_spacing.dart';
import 'package:ambarket_mobile/core/error/error_mapper.dart';
import 'package:ambarket_mobile/core/widgets/ambarket_scaffold.dart';
import 'package:ambarket_mobile/core/widgets/premium_button.dart';
import 'package:ambarket_mobile/core/widgets/premium_empty_state.dart';
import 'package:ambarket_mobile/core/widgets/app_error_state.dart';
import 'package:ambarket_mobile/core/widgets/premium_surface_card.dart';
import 'package:ambarket_mobile/core/widgets/app_loading_skeleton.dart';
import 'package:ambarket_mobile/core/widgets/premium_status_badge.dart';
import 'package:ambarket_mobile/core/widgets/premium_filter_chips.dart';

import 'package:ambarket_mobile/features/offer/domain/models/offer_model.dart';
import 'package:ambarket_mobile/features/offer/presentation/providers/offer_provider.dart';

class SellerOffersScreen extends ConsumerWidget {
  const SellerOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return AmbarketScaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tawaran Masuk',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Kelola negosiasi harga dari calon pembeli.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(context, ref),
          Expanded(child: _buildOfferList(context, ref, isDesktop)),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(sellerOfferStatusFilterProvider);

    final statusOptions = {
      'all': 'Semua',
      'pending': 'Pending',
      'accepted': 'Diterima',
      'rejected': 'Ditolak',
      'cancelled': 'Dibatalkan',
    };

    return Container(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: statusOptions.entries.map((entry) {
            final isSelected = statusFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: PremiumFilterChip(
                label: entry.value,
                isSelected: isSelected,
                onTap: () {
                  ref
                      .read(sellerOfferStatusFilterProvider.notifier)
                      .setFilter(entry.key);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOfferList(BuildContext context, WidgetRef ref, bool isDesktop) {
    final offersAsync = ref.watch(filteredReceivedOffersProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(filteredReceivedOffersProvider.future),
      child: offersAsync.when(
        data: (offers) {
          if (offers.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                PremiumEmptyState(
                  icon: Icons.local_offer_outlined,
                  title: 'Belum ada tawaran masuk',
                  message: 'Tawaran dari calon pembeli akan muncul di sini.',
                ),
              ],
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop && MediaQuery.of(context).size.width > 1200
                  ? (MediaQuery.of(context).size.width - 1200) / 2
                  : AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            cacheExtent: 800,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            itemCount: offers.length,
            itemBuilder: (context, index) {
              return SellerOfferCard(offer: offers[index]);
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          cacheExtent: 500,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          itemCount: 3,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: AppLoadingSkeleton(
              width: double.infinity,
              height: 200,
              borderRadius: 16,
            ),
          ),
        ),
        error: (error, stack) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 400,
              child: AppErrorState(
                title: 'Gagal Memuat',
                message: ErrorMapper.getFriendlyMessage(error),
                onRetry: () =>
                    ref.refresh(filteredReceivedOffersProvider.future),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SellerOfferCard extends ConsumerWidget {
  final OfferModel offer;

  const SellerOfferCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final isLoading = ref.watch(
      offerActionControllerProvider.select((state) => state.isLoading),
    );

    // Status Mapping
    PremiumBadgeStatus statusColor;
    String statusText;
    switch (offer.status) {
      case 'pending':
        statusColor = PremiumBadgeStatus.warning;
        statusText = 'Pending';
        break;
      case 'accepted':
        statusColor = PremiumBadgeStatus.success;
        statusText = 'Diterima';
        break;
      case 'rejected':
        statusColor = PremiumBadgeStatus.error;
        statusText = 'Ditolak';
        break;
      case 'cancelled':
        statusColor = PremiumBadgeStatus.neutral;
        statusText = 'Dibatalkan';
        break;
      default:
        statusColor = PremiumBadgeStatus.neutral;
        statusText = offer.status;
    }

    final imageUrl = (offer.product?.images.isNotEmpty == true)
        ? offer.product!.images.first.imageUrl
        : null;

    final originalPrice = offer.product?.price ?? 0;
    final diffAmount = originalPrice - offer.offerPrice;
    final discountPercent = originalPrice > 0
        ? (diffAmount / originalPrice * 100).toStringAsFixed(1)
        : "0";

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PremiumSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PremiumStatusBadge(label: statusText, status: statusColor),
                Text(
                  dateFormat.format(offer.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Product & Buyer Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 160,
                            memCacheHeight: 160,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            placeholder: (context, url) => ColoredBox(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            errorWidget: (context, url, error) =>
                                const ColoredBox(
                                  color: Colors.black12,
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                          )
                        : ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(
                              Icons.inventory_2,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.product?.title ?? 'Produk Dihapus',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pembeli: ${offer.buyer?.name ?? offer.buyer?.username ?? "Unknown"}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (offer.message != null &&
                          offer.message!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '"${offer.message}"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Offer Price Comparison
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Harga Asli',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        currencyFormat.format(originalPrice),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ditawar',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        currencyFormat.format(offer.offerPrice),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selisih',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      Text(
                        '- ${currencyFormat.format(diffAmount)} (-$discountPercent%)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Action Buttons
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push('/products/${offer.productId}'),
                  icon: const Icon(Icons.inventory_2, size: 18),
                  label: const Text('Produk'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to chat
                    // Implementation depends on Chat integration
                    // context.push('/chats/${offer.buyerId}');
                  },
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Chat'),
                ),
                if (offer.status == 'accepted')
                  FutureBuilder(
                    future: ref
                        .read(offerRepositoryProvider)
                        .findOrderByOfferId(offer.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final orderId = snapshot.data!.id;
                        return PremiumButton(
                          label: 'Lihat Pesanan',
                          onPressed: () => context.push(
                            '/orders/$orderId/tracking',
                          ), // adjust as needed
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                if (offer.status == 'pending') ...[
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => _handleReject(context, ref),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Tolak'),
                  ),
                  PremiumButton(
                    label: 'Terima Tawaran',
                    onPressed: isLoading
                        ? () {}
                        : () => _handleAccept(context, ref),
                    isLoading: isLoading,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleReject(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Tawaran'),
        content: const Text('Yakin ingin menolak tawaran ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _executeAction(
                context,
                ref,
                () => ref
                    .read(offerActionControllerProvider.notifier)
                    .rejectOffer(offer.id),
                'Tawaran ditolak.',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  void _handleAccept(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terima Tawaran'),
        content: const Text(
          'Yakin ingin menerima tawaran ini? Pembeli dapat melakukan checkout dengan harga ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _executeAction(
                context,
                ref,
                () => ref
                    .read(offerActionControllerProvider.notifier)
                    .acceptOffer(offer.id),
                'Tawaran diterima.',
              );
            },
            child: const Text('Ya, Terima'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAction(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String successMsg,
  ) async {
    await action();
    if (!context.mounted) return;

    final errorState = ref.read(offerActionControllerProvider).error;
    if (errorState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
      );
    } else {
      final errorMsg = ErrorMapper.getFriendlyMessage(errorState);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }
}
