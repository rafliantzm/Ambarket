import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/ambarket_scaffold.dart';
import '../providers/order_provider.dart';

class PaymentDummyScreen extends ConsumerWidget {
  final String orderId;

  const PaymentDummyScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app we'd fetch the order details, but since this is just a dummy instruction screen after checkout:
    final orderActionState = ref.watch(orderActionControllerProvider);

    return AmbarketScaffold(
      isDesktopConstrained: MediaQuery.of(context).size.width >= 768,
      appBar: AppBar(
        title: Text('Pembayaran'),
        automaticallyImplyLeading: false, // Force user to pay or cancel
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          AppGlassCard(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 48,
                  color: context.colors.accent,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Selesaikan Pembayaran',
                  style: Theme.of(context).textTheme.headlineMedium!,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Order ID: ${orderId.substring(0, 8).toUpperCase()}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(color: Colors.white54),
                ),
                SizedBox(height: AppSpacing.lg),

                // Dummy VA
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nomor Virtual Account',
                            style: Theme.of(context).textTheme.bodySmall!,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '8808 1234 5678 9012',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: context.colors.accent),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: '8808123456789012'),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Nomor VA disalin')),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSpacing.lg),
                Divider(color: Colors.white24),
                SizedBox(height: AppSpacing.md),

                // Instructions
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Instruksi Pembayaran Dummy:',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                _buildInstructionRow(
                  context,
                  '1',
                  'Buka aplikasi M-Banking Anda.',
                ),
                _buildInstructionRow(
                  context,
                  '2',
                  'Pilih menu Transfer > Virtual Account.',
                ),
                _buildInstructionRow(
                  context,
                  '3',
                  'Masukkan nomor Virtual Account di atas.',
                ),
                _buildInstructionRow(
                  context,
                  '4',
                  'Klik "Saya Sudah Bayar" untuk simulasi.',
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          AppButton(
            label: 'Saya Sudah Bayar',
            isLoading: orderActionState.isLoading,
            onPressed: () {
              ref
                  .read(orderActionControllerProvider.notifier)
                  .simulatePayment(orderId)
                  .then((success) {
                    if (success) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Pembayaran berhasil!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        context.go(
                          '/buyer-orders',
                        ); // Wait, the correct path is /buyer-orders
                      }
                    }
                  });
            },
          ),
          SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () {
              context.go('/buyer-orders');
            },
            child: Text('Bayar Nanti (Kembali ke Pesanan)'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(
    BuildContext context,
    String step,
    String instruction,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.surface,
            ),
            child: Text(
              step,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              instruction,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
