import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_glass_card.dart';

class ProductSafetySection extends StatelessWidget {
  const ProductSafetySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keamanan Bertransaksi',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppGlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          customBorder: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          child: Column(
            children: [
              _buildSafetyTip(
                context,
                icon: Icons.shield_outlined,
                title: 'Transaksi tercatat di Ambarket',
                subtitle: 'Gunakan fitur chat dan penawaran harga kami agar transaksi tetap aman dan terekam.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSafetyTip(
                context,
                icon: Icons.handshake_outlined,
                title: 'COD atau Metode Aman',
                subtitle: 'Disarankan menggunakan sistem COD (Cash On Delivery) atau dummy payment jika fitur checkout tersedia.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSafetyTip(
                context,
                icon: Icons.report_problem_outlined,
                title: 'Laporkan hal mencurigakan',
                subtitle: 'Jangan ragu melaporkan penjual atau produk jika menemukan indikasi penipuan.',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyTip(BuildContext context, {required IconData icon, required String title, required String subtitle, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              if (!isLast) const SizedBox(height: AppSpacing.sm),
              if (!isLast) const Divider(color: AppColors.border),
            ],
          ),
        ),
      ],
    );
  }
}

