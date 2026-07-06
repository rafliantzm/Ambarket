import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../providers/order_provider.dart';

class InvoiceScreen extends ConsumerWidget {
  final String orderId;

  const InvoiceScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For simplicity, we just find the order from buyerOrders or sellerOrders
    final buyerOrders = ref.watch(buyerOrdersProvider).value ?? [];
    final sellerOrders = ref.watch(sellerOrdersProvider).value ?? [];
    
    final allOrders = [...buyerOrders, ...sellerOrders];
    final order = allOrders.firstWhere(
      (o) => o.id == orderId, 
      orElse: () => throw Exception('Pesanan tidak ditemukan'),
    );

    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur unduh invoice akan tersedia nanti.'))
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppGlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('AMBARKET', style: Theme.of(context).textTheme.headlineMedium!.copyWith(letterSpacing: 2)),
                    Text('INVOICE', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: AppColors.accent)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('INV/${order.createdAt.year}${order.createdAt.month.toString().padLeft(2, '0')}${order.createdAt.day.toString().padLeft(2, '0')}/${order.id.substring(0, 8).toUpperCase()}', style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white70)),
                const Divider(color: Colors.white24, height: 32),
                
                // Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DITERBITKAN ATAS NAMA', style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white54)),
                          const SizedBox(height: 4),
                          Text('Penjual: ${order.seller?.name ?? "Seller"}', style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                          Text('Tanggal: ${dateFormatter.format(order.createdAt.toLocal())}', style: Theme.of(context).textTheme.bodySmall!),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('UNTUK', style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white54)),
                          const SizedBox(height: 4),
                          Text('Pembeli: ${order.receiverName ?? order.buyer?.name ?? "Buyer"}', style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                          Text('Alamat Pengiriman:', style: Theme.of(context).textTheme.bodySmall!),
                          Text(order.shippingAddress ?? '-', style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 32),

                // Product items (We only have 1 per order currently)
                Text('RINCIAN PRODUK', style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white54)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(order.product?.title ?? 'Produk', style: Theme.of(context).textTheme.bodyMedium!)),
                    Text('1x', style: Theme.of(context).textTheme.bodyMedium!),
                    const SizedBox(width: AppSpacing.lg),
                    Text(currencyFormatter.format(order.subtotal), style: Theme.of(context).textTheme.bodyMedium!),
                  ],
                ),
                const Divider(color: Colors.white24, height: 32),

                // Totals
                _buildTotalRow(context, 'Subtotal Harga Barang', order.subtotal, currencyFormatter),
                _buildTotalRow(context, 'Total Ongkos Kirim', order.shippingCost, currencyFormatter),
                _buildTotalRow(context, 'Biaya Layanan', order.serviceFee, currencyFormatter),
                if (order.discountAmount > 0)
                  _buildTotalRow(context, 'Total Diskon', -order.discountAmount, currencyFormatter, color: Colors.green),
                
                const Divider(color: Colors.white24, height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL BELANJA', style: Theme.of(context).textTheme.titleLarge!),
                    Text(currencyFormatter.format(order.totalPrice), style: Theme.of(context).textTheme.titleLarge!.copyWith(color: AppColors.accent)), // total_price stores the grand total for legacy
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Metode Pembayaran:', style: Theme.of(context).textTheme.bodySmall!),
                      Text(order.paymentMethod.toUpperCase(), style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status Pembayaran:', style: Theme.of(context).textTheme.bodySmall!),
                      Text(order.paymentStatus.toUpperCase(), style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: order.paymentStatus == 'paid' ? Colors.green : Colors.orange,
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, String label, double amount, NumberFormat formatter, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70)),
          Text(formatter.format(amount), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: color ?? Colors.white)),
        ],
      ),
    );
  }
}
