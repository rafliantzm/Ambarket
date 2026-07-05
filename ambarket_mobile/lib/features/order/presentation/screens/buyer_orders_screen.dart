import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';
import 'package:ambarket_mobile/features/order/presentation/providers/order_provider.dart';
import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:ambarket_mobile/features/review/presentation/widgets/create_review_dialog.dart';

class BuyerOrdersScreen extends ConsumerWidget {
  const BuyerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(buyerOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(buyerOrdersProvider.future),
        child: ordersAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('Belum ada pesanan.')),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderCard(order: order, isBuyer: true);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(sellerOrdersProvider.future),
        child: ordersAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('Belum ada pesanan masuk.')),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderCard(order: order, isBuyer: false);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderModel order;
  final bool isBuyer;

  const _OrderCard({required this.order, required this.isBuyer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    Color statusColor;
    String statusText;

    switch (order.status) {
      case 'pending_payment':
        statusColor = Colors.orange;
        statusText = 'Belum Dibayar';
        break;
      case 'paid':
        statusColor = Colors.blue;
        statusText = 'Dibayar';
        break;
      case 'shipped':
        statusColor = Colors.purple;
        statusText = 'Dikirim';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Selesai';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Dibatalkan';
        break;
      default:
        statusColor = Colors.grey;
        statusText = order.status;
    }

    final actionState = ref.watch(orderActionControllerProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.product?.title ?? 'Produk',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('ID Pesanan: ${order.id.substring(0, 8).toUpperCase()}', style: theme.textTheme.bodySmall),
            Text('Tanggal: ${dateFormat.format(order.createdAt)}', style: theme.textTheme.bodySmall),
            const Divider(),
            if (isBuyer)
              Text('Toko: ${order.seller?.name ?? "Penjual"}')
            else
              Text('Pembeli: ${order.buyer?.name ?? "Pembeli"}'),
            const SizedBox(height: AppSpacing.xs),
            Text('Total: ${currencyFormat.format(order.totalPrice)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Text('Kirim ke:', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(order.shippingAddress, style: theme.textTheme.bodySmall),
            Text('Telp: ${order.shippingPhone}', style: theme.textTheme.bodySmall),
            
            // Actions
            if (order.status != 'completed' && order.status != 'cancelled') ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel button for both buyer and seller in early stages
                  if (order.status == 'pending_payment' || order.status == 'paid')
                    TextButton(
                      onPressed: actionState.isLoading ? null : () {
                        _showConfirmation(
                          context,
                          'Batalkan Pesanan',
                          'Yakin ingin membatalkan pesanan ini?',
                          () => ref.read(orderActionControllerProvider.notifier).updateStatus(order.id, 'cancelled'),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Batalkan'),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  
                  if (isBuyer && order.status == 'pending_payment')
                    ElevatedButton(
                      onPressed: actionState.isLoading ? null : () {
                        _showConfirmation(
                          context,
                          'Simulasi Pembayaran',
                          'Lanjutkan pembayaran untuk pesanan ini?',
                          () => ref.read(orderActionControllerProvider.notifier).updateStatus(order.id, 'paid'),
                        );
                      },
                      child: const Text('Simulasi Bayar'),
                    ),
                  if (!isBuyer && order.status == 'paid')
                    ElevatedButton(
                      onPressed: actionState.isLoading ? null : () {
                        _showConfirmation(
                          context,
                          'Tandai Dikirim',
                          'Apakah pesanan sudah diserahkan ke kurir?',
                          () => ref.read(orderActionControllerProvider.notifier).updateStatus(order.id, 'shipped'),
                        );
                      },
                      child: const Text('Tandai Dikirim'),
                    ),
                  if (isBuyer && order.status == 'shipped')
                    ElevatedButton(
                      onPressed: actionState.isLoading ? null : () {
                        _showConfirmation(
                          context,
                          'Pesanan Diterima',
                          'Konfirmasi bahwa Anda telah menerima pesanan dengan baik?',
                          () => ref.read(orderActionControllerProvider.notifier).updateStatus(order.id, 'completed'),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('Pesanan Diterima'),
                    ),
                ],
              ),
            ],
            if (isBuyer && order.status == 'completed') ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!order.isReviewed)
                    ElevatedButton(
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                      child: const Text('Beri Ulasan'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('Sudah Diulas', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _showConfirmation(BuildContext context, String title, String content, VoidCallback onConfirm) {
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
