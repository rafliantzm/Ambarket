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

import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:ambarket_mobile/features/order/presentation/providers/order_provider.dart';

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

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
              'Pesanan Masuk',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Kelola pesanan pembeli dari pembayaran hingga pengiriman.',
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
          Expanded(child: _buildOrderList(context, ref, isDesktop)),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(sellerOrderStatusFilterProvider);
    final paymentFilter = ref.watch(sellerPaymentStatusFilterProvider);

    final statusOptions = {
      'all': 'Semua',
      'pending_payment': 'Menunggu Pembayaran',
      'paid': 'Dibayar',
      'packed': 'Dikemas',
      'shipped': 'Dikirim',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
    };

    final paymentOptions = {
      'all': 'Semua',
      'unpaid': 'Belum Dibayar',
      'paid': 'Dibayar',
      'cod': 'COD',
    };

    return Container(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
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
                          .read(sellerOrderStatusFilterProvider.notifier)
                          .setFilter(entry.key);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ).copyWith(bottom: AppSpacing.sm),
            child: Row(
              children: paymentOptions.entries.map((entry) {
                final isSelected = paymentFilter == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: PremiumFilterChip(
                    label: entry.value,
                    isSelected: isSelected,
                    onTap: () {
                      ref
                          .read(sellerPaymentStatusFilterProvider.notifier)
                          .setFilter(entry.key);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, WidgetRef ref, bool isDesktop) {
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(sellerOrdersProvider.future),
      child: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                PremiumEmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Belum ada pesanan masuk',
                  message:
                      'Pesanan yang sesuai dengan filter akan muncul di sini.',
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
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return SellerOrderCard(order: orders[index]);
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
                onRetry: () => ref.refresh(sellerOrdersProvider.future),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SellerOrderCard extends ConsumerWidget {
  final OrderModel order;

  const SellerOrderCard({super.key, required this.order});

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
      orderActionControllerProvider.select((state) => state.isLoading),
    );

    // Status Mapping
    PremiumBadgeStatus statusColor;
    String statusText;
    switch (order.status) {
      case 'pending_payment':
        statusColor = PremiumBadgeStatus.warning;
        statusText = 'Menunggu Pembayaran';
        break;
      case 'paid':
        statusColor = PremiumBadgeStatus.info;
        statusText = 'Dibayar';
        break;
      case 'packed':
        statusColor = PremiumBadgeStatus.warning;
        statusText = 'Dikemas';
        break;
      case 'shipped':
        statusColor = PremiumBadgeStatus.info;
        statusText = 'Dikirim';
        break;
      case 'completed':
        statusColor = PremiumBadgeStatus.success;
        statusText = 'Selesai';
        break;
      case 'cancelled':
        statusColor = PremiumBadgeStatus.error;
        statusText = 'Dibatalkan';
        break;
      default:
        statusColor = PremiumBadgeStatus.neutral;
        statusText = order.status;
    }

    // Payment Status Mapping
    PremiumBadgeStatus payStatusColor;
    String payStatusText;
    if (order.paymentMethod == 'cod') {
      payStatusColor = PremiumBadgeStatus.warning;
      payStatusText = 'COD';
    } else if (order.paymentStatus == 'paid') {
      payStatusColor = PremiumBadgeStatus.success;
      payStatusText = 'Dibayar';
    } else {
      payStatusColor = PremiumBadgeStatus.error;
      payStatusText = 'Belum Dibayar';
    }

    final imageUrl = (order.product?.images.isNotEmpty == true)
        ? order.product!.images.first.imageUrl
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PremiumSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PremiumStatusBadge(label: statusText, status: statusColor),
                Text(
                  dateFormat.format(order.createdAt),
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
                        order.product?.title ?? 'Produk Dihapus',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pembeli: ${order.buyer?.name ?? order.buyer?.username ?? "Unknown"}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'INV: ${order.invoiceNumber ?? (order.id.length > 8 ? order.id.substring(0, 8) : order.id).toUpperCase()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Order Details Grid
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    'Total Pendapatan',
                    currencyFormat.format(order.totalPrice),
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    'Pengiriman',
                    '${order.shippingMethod ?? "-"} (${currencyFormat.format(order.shippingCost)})',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Alamat',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          order.shippingAddress ?? "Alamat tidak tersedia",
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pembayaran',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            order.paymentMethod.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          PremiumStatusBadge(
                            label: payStatusText,
                            status: payStatusColor,
                          ),
                        ],
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
                if (order.status != 'pending_payment' &&
                    order.status != 'cancelled')
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/orders/${order.id}/invoice'),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Invoice'),
                  ),
                if (order.status != 'pending_payment' &&
                    order.status != 'cancelled' &&
                    order.status != 'completed')
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/orders/${order.id}/tracking'),
                    icon: const Icon(Icons.local_shipping, size: 18),
                    label: const Text('Lacak'),
                  ),

                // State-specific actions
                if (order.status == 'pending_payment' || order.status == 'paid')
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => _handleCancel(context, ref),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Batalkan'),
                  ),

                if (order.status == 'paid' ||
                    (order.paymentMethod == 'cod' &&
                        order.status == 'pending_payment'))
                  PremiumButton(
                    label: 'Tandai Dikemas',
                    onPressed: isLoading
                        ? () {}
                        : () => _showProcessOrderModal(context, ref),
                    isLoading: isLoading,
                  ),

                if (order.status == 'packed')
                  PremiumButton(
                    label: 'Tandai Dikirim',
                    onPressed: isLoading
                        ? () {}
                        : () => _showShippingModal(context, ref),
                    isLoading: isLoading,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  void _showProcessOrderModal(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Konfirmasi & Proses Pesanan',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Harap siapkan paket untuk dikirim ke alamat berikut:',
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.receiverName ?? 'Tanpa Nama',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.receiverPhone ?? '-',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.shippingAddress ?? 'Alamat tidak tersedia',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 4),
                    Text(
                      'Kurir: ${order.shippingMethod ?? "-"}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PremiumButton(
                label: 'Terima & Proses Pesanan',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _executeUpdateStatus(context, ref, 'packed');
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShippingModal(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Atur Pengiriman',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Kurir pengiriman: ${order.shippingMethod ?? "-"}'),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Nomor Resi (Opsional/Dummy)',
                  hintText: 'Misal: JNT1234567890',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PremiumButton(
                label: 'Tandai Sebagai Dikirim',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _executeUpdateStatus(context, ref, 'shipped');
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pesanan'),
        content: const Text(
          'Yakin ingin membatalkan pesanan ini? Aksi ini tidak dapat diubah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _executeCancel(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeCancel(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(orderActionControllerProvider.notifier)
        .cancelSellerOrder(order.id);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dibatalkan.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final errorMsg =
          ref.read(orderActionControllerProvider).error ??
          'Gagal membatalkan pesanan.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _executeUpdateStatus(
    BuildContext context,
    WidgetRef ref,
    String newStatus,
  ) async {
    final success = await ref
        .read(orderActionControllerProvider.notifier)
        .updateStatus(order.id, newStatus);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status pesanan berhasil diperbarui.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final errorMsg =
          ref.read(orderActionControllerProvider).error ??
          'Gagal memperbarui status.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }
}
