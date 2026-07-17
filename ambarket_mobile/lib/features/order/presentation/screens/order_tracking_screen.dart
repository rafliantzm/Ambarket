import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../domain/models/order_model.dart';
import '../../../review/presentation/widgets/create_review_dialog.dart';
import '../providers/order_provider.dart';
import '../widgets/refund_request_dialog.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buyerOrdersAsync = ref.watch(buyerOrdersProvider);
    final sellerOrdersAsync = ref.watch(sellerOrdersProvider);
    final buyerOrders = buyerOrdersAsync.value ?? [];
    final sellerOrders = sellerOrdersAsync.value ?? [];

    final allOrders = [...buyerOrders, ...sellerOrders];
    final matchingOrders = allOrders.where((o) => o.id == orderId).toList();

    if (matchingOrders.isEmpty) {
      final isLoading =
          buyerOrdersAsync.isLoading || sellerOrdersAsync.isLoading;
      final hasError = buyerOrdersAsync.hasError || sellerOrdersAsync.hasError;

      return Scaffold(
        appBar: AppBar(title: const Text('Lacak Pesanan')),
        body: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    hasError
                        ? 'Pesanan gagal dimuat. Coba lagi beberapa saat.'
                        : 'Pesanan tidak ditemukan.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
        ),
      );
    }

    final order = matchingOrders.first;
    final isBuyerOrder = buyerOrders.any((o) => o.id == orderId);
    final isLoading = ref.watch(
      orderActionControllerProvider.select((state) => state.isLoading),
    );

    int currentStep = 0;
    if (order.status == 'pending_payment') {
      currentStep = 0;
    }
    if (order.status == 'paid') {
      currentStep = 1;
    }
    if (order.status == 'packed') {
      currentStep = 2;
    }
    if (order.status == 'shipped') {
      currentStep = 3;
    }
    if (order.status == 'completed') {
      currentStep = 4;
    }
    if (order.status == 'delivered' || order.status == 'disputed') {
      currentStep = 4;
    }

    final isCancelled = order.status == 'cancelled';
    final statusColor = _statusColor(context, order.status);

    return Scaffold(
      appBar: AppBar(title: const Text('Lacak Pesanan')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppGlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: context.colors.accent,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No. Resi / Order ID',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      Text(
                        _shortOrderId(order.id),
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusText(order.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isCancelled)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Pesanan ini telah dibatalkan.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(color: context.colors.error),
                ),
              ),
            )
          else
            AppGlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _buildStep(
                    context,
                    title: 'Pesanan Dibuat',
                    subtitle: 'Pesanan berhasil dibuat oleh pembeli',
                    date: order.createdAt,
                    isActive: currentStep >= 0,
                    isLast: false,
                  ),
                  _buildStep(
                    context,
                    title: 'Pembayaran Diterima',
                    subtitle: 'Pembayaran telah dikonfirmasi',
                    date: order.paidAt,
                    isActive: currentStep >= 1,
                    isLast: false,
                  ),
                  _buildStep(
                    context,
                    title: 'Penjual Menyiapkan Barang',
                    subtitle: 'Barang sedang dikemas oleh penjual',
                    date: currentStep >= 2 ? order.updatedAt : null,
                    isActive: currentStep >= 2,
                    isLast: false,
                  ),
                  _buildStep(
                    context,
                    title: 'Barang Dikirim',
                    subtitle: 'Barang sedang dalam perjalanan',
                    date: currentStep >= 3 ? order.updatedAt : null,
                    isActive: currentStep >= 3,
                    isLast: false,
                  ),
                  _buildStep(
                    context,
                    title: 'Pesanan Selesai',
                    subtitle: 'Barang telah diterima pembeli',
                    date: currentStep >= 4 ? order.updatedAt : null,
                    isActive: currentStep >= 4,
                    isLast: true,
                  ),
                ],
              ),
            ),
          if (isBuyerOrder && order.status == 'shipped') ...[
            const SizedBox(height: AppSpacing.lg),
            _buildReceiveAction(context, ref, isLoading, order),
          ],
          if (isBuyerOrder && order.status == 'delivered') ...[
            const SizedBox(height: AppSpacing.lg),
            _buildDeliveredActions(context, ref, order, isLoading),
          ],
          if (isBuyerOrder && order.status == 'completed') ...[
            const SizedBox(height: AppSpacing.lg),
            _buildReviewAction(context, order),
          ],
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required String title,
    required String subtitle,
    DateTime? date,
    required bool isActive,
    required bool isLast,
  }) {
    final dateFormatter = DateFormat('dd MMM, HH:mm');
    final theme = Theme.of(context);
    final stepColor = isActive
        ? context.colors.primary
        : context.colors.borderStrong;
    final titleColor = isActive
        ? context.colors.textPrimary
        : context.colors.textMuted;
    final subtitleColor = isActive
        ? context.colors.textSecondary
        : context.colors.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? context.colors.primary : Colors.transparent,
                border: Border.all(color: stepColor, width: 2),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: context.colors.primary.withValues(alpha: 0.24),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: isActive
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 72,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            context.colors.primary,
                            context.colors.primary,
                          ],
                        )
                      : null,
                  color: isActive ? null : context.colors.border,
                ),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        if (date != null)
          Text(
            dateFormatter.format(date.toLocal()),
            style: theme.textTheme.bodySmall!.copyWith(
              color: context.colors.textMuted,
            ),
          ),
      ],
    );
  }

  Widget _buildReceiveAction(
    BuildContext context,
    WidgetRef ref,
    bool isLoading,
    OrderModel order,
  ) {
    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Barang sudah sampai?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Konfirmasi penerimaan agar seller tahu barang sudah sampai. Dana tetap tertahan sampai transaksi diselesaikan.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => _confirmReceiveOrder(context, ref),
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.inventory_2_outlined),
              label: const Text('Pesanan Diterima'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveredActions(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    bool isLoading,
  ) {
    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaksi menunggu keputusan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Jika barang aman, selesaikan transaksi agar dana cair ke seller. Jika bermasalah, ajukan refund untuk ditinjau admin.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (_) => RefundRequestDialog(order: order),
                          );
                        },
                  icon: const Icon(Icons.gavel_outlined),
                  label: const Text('Refund'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => _confirmCompleteOrder(context, ref),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Selesai'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewAction(BuildContext context, OrderModel order) {
    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pesanan selesai',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            order.isReviewed
                ? 'Terima kasih, ulasan Anda sudah tersimpan.'
                : 'Bagikan pengalaman Anda untuk membantu pembeli lain.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          if (!order.isReviewed) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => CreateReviewDialog(
                      orderId: order.id,
                      productId: order.productId,
                      reviewedUserId: order.sellerId,
                    ),
                  );
                },
                icon: const Icon(Icons.star_outline),
                label: const Text('Beri Ulasan'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmReceiveOrder(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pesanan Diterima'),
        content: const Text(
          'Konfirmasi bahwa barang sudah Anda terima dengan baik?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _markOrderReceived(context, ref);
            },
            child: const Text('Ya, Terima'),
          ),
        ],
      ),
    );
  }

  Future<void> _markOrderReceived(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(orderActionControllerProvider.notifier)
        .updateStatus(orderId, 'delivered');
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pesanan ditandai diterima. Dana masih ditahan sampai transaksi selesai.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final errorMsg =
          ref.read(orderActionControllerProvider).error ??
          'Gagal menyelesaikan pesanan.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmCompleteOrder(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan Pesanan'),
        content: const Text(
          'Dana akan dicairkan ke saldo seller. Lanjutkan jika tidak ada masalah pada barang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _completeOrder(context, ref);
            },
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOrder(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(orderActionControllerProvider.notifier)
        .updateStatus(orderId, 'completed');
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Pesanan selesai. Anda bisa memberi ulasan.'
              : ref.read(orderActionControllerProvider).error ??
                    'Gagal menyelesaikan pesanan.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  String _shortOrderId(String id) {
    return (id.length > 8 ? id.substring(0, 8) : id).toUpperCase();
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending_payment':
        return 'Menunggu Bayar';
      case 'paid':
        return 'Dibayar';
      case 'packed':
        return 'Dikemas';
      case 'shipped':
        return 'Dikirim';
      case 'completed':
        return 'Selesai';
      case 'delivered':
        return 'Diterima';
      case 'disputed':
        return 'Sengketa';
      case 'refunded':
        return 'Refund';
      case 'partially_refunded':
        return 'Refund Sebagian';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'pending_payment':
      case 'packed':
        return context.colors.warning;
      case 'paid':
      case 'shipped':
        return context.colors.info;
      case 'completed':
        return context.colors.success;
      case 'delivered':
        return context.colors.primary;
      case 'disputed':
        return context.colors.error;
      case 'refunded':
      case 'partially_refunded':
        return context.colors.textMuted;
      case 'cancelled':
        return context.colors.error;
      default:
        return context.colors.textMuted;
    }
  }
}
