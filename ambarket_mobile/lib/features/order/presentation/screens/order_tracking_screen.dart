import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../providers/order_provider.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buyerOrders = ref.watch(buyerOrdersProvider).value ?? [];
    final sellerOrders = ref.watch(sellerOrdersProvider).value ?? [];

    final allOrders = [...buyerOrders, ...sellerOrders];
    final order = allOrders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => throw Exception('Pesanan tidak ditemukan'),
    );

    // Map status to steps
    int currentStep = 0;
    if (order.status == 'pending_payment') currentStep = 0;
    if (order.status == 'paid') currentStep = 1;
    if (order.status == 'packed') currentStep = 2;
    if (order.status == 'shipped') currentStep = 3;
    if (order.status == 'completed') currentStep = 4;

    final isCancelled = order.status == 'cancelled';

    return Scaffold(
      appBar: AppBar(title: Text('Lacak Pesanan')),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          AppGlassCard(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: context.colors.accent,
                  size: 32,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No. Resi / Order ID',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall!.copyWith(color: Colors.white70),
                      ),
                      Text(
                        order.id.substring(0, 8).toUpperCase(),
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? context.colors.error.withValues(alpha: 0.2)
                        : Colors.green.withValues(
                            alpha: 0.2,
                          ), // Wait, does context.colors.error exist? Let's use Colors.red
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCancelled
                        ? 'Dibatalkan'
                        : (order.status == 'completed'
                              ? 'Selesai'
                              : 'Dalam Proses'),
                    style: TextStyle(
                      color: isCancelled ? Colors.red : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          if (isCancelled)
            Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Pesanan ini telah dibatalkan.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(color: Colors.red),
                ),
              ),
            )
          else
            AppGlassCard(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _buildStep(
                    context,
                    title: 'Pesanan Dibuat',
                    subtitle: 'Menunggu pembayaran dari pembeli',
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
                    date: currentStep >= 2
                        ? order.updatedAt
                        : null, // Simplification
                    isActive: currentStep >= 2,
                    isLast: false,
                  ),
                  _buildStep(
                    context,
                    title: 'Barang Dikirim',
                    subtitle: 'Barang dalam perjalanan / Siap diambil',
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
                color: isActive ? context.colors.accent : Colors.transparent,
                border: Border.all(
                  color: isActive ? context.colors.accent : Colors.white24,
                  width: 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: context.colors.accent.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isActive
                  ? Icon(Icons.check, size: 16, color: Colors.black)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            context.colors.accent,
                            context.colors.accent,
                          ],
                        )
                      : null,
                  color: isActive ? null : Colors.white24,
                ),
              ),
          ],
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.white54,
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: isActive ? Colors.white70 : Colors.white38,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        if (date != null)
          Text(
            dateFormatter.format(date.toLocal()),
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: Colors.white54),
          ),
      ],
    );
  }
}
