import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_glass_card.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionItem(
            context,
            icon: Icons.add_circle_outline,
            label: 'Jual Barang',
            onTap: () => context.push('/seller/add_product'),
          ),
          _buildActionItem(
            context,
            icon: Icons.shopping_bag_outlined,
            label: 'Pesanan Saya',
            onTap: () => context.push('/buyer_orders'),
          ),
          _buildActionItem(
            context,
            icon: Icons.local_offer_outlined,
            label: 'Tawaran Saya',
            onTap: () => context.push('/my_offers'),
          ),
          _buildActionItem(
            context,
            icon: Icons.favorite_border,
            label: 'Wishlist',
            onTap: () => context.push('/wishlist'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AppGlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
