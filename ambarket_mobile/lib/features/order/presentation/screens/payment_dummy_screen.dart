import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/order_provider.dart';

class PaymentDummyScreen extends ConsumerWidget {
  final String orderId;

  const PaymentDummyScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app we'd fetch the order details, but since this is just a dummy instruction screen after checkout:
    final orderActionState = ref.watch(orderActionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        automaticallyImplyLeading: false, // Force user to pay or cancel
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppGlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const Icon(Icons.account_balance_wallet, size: 48, color: AppColors.accent),
                const SizedBox(height: AppSpacing.md),
                Text('Selesaikan Pembayaran', style: Theme.of(context).textTheme.headlineMedium!),
                const SizedBox(height: AppSpacing.sm),
                Text('Order ID: ${orderId.substring(0, 8).toUpperCase()}', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white54)),
                const SizedBox(height: AppSpacing.lg),
                
                // Dummy VA
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nomor Virtual Account', style: Theme.of(context).textTheme.bodySmall!),
                          const SizedBox(height: 4),
                          Text('8808 1234 5678 9012', style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: AppColors.accent),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: '8808123456789012'));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor VA disalin')));
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: Colors.white24),
                const SizedBox(height: AppSpacing.md),
                
                // Instructions
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Instruksi Pembayaran Dummy:', style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildInstructionRow(context, '1', 'Buka aplikasi M-Banking Anda.'),
                _buildInstructionRow(context, '2', 'Pilih menu Transfer > Virtual Account.'),
                _buildInstructionRow(context, '3', 'Masukkan nomor Virtual Account di atas.'),
                _buildInstructionRow(context, '4', 'Klik "Saya Sudah Bayar" untuk simulasi.'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          AppButton(label: 'Saya Sudah Bayar',
            isLoading: orderActionState.isLoading,
            onPressed: () {
              ref.read(orderActionControllerProvider.notifier).simulatePayment(orderId).then((success) {
                if (success) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pembayaran berhasil!'), backgroundColor: Colors.green)
                    );
                    context.go('/buyer-orders'); // Wait, the correct path is /buyer-orders
                  }
                }
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () {
              context.go('/buyer-orders');
            },
            child: const Text('Bayar Nanti (Kembali ke Pesanan)'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(BuildContext context, String step, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: Text(step, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(instruction, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70))),
        ],
      ),
    );
  }
}



