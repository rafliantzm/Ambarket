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
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionItem(
            context,
            icon: Icons.add_circle_outline,
            label: 'Jual Barang',
            onTap: () => context.push('/seller/products/new'),
          ),
          _buildActionItem(
            context,
            icon: Icons.shopping_bag_outlined,
            label: 'Pesanan Saya',
            onTap: () => context.push('/buyer-orders'),
          ),
          _buildActionItem(
            context,
            icon: Icons.local_offer_outlined,
            label: 'Tawaran Saya',
            onTap: () => context.push('/offers'),
          ),
          _buildActionItem(
            context,
            icon: Icons.shopping_cart_outlined,
            label: 'Keranjang',
            onTap: () => context.push('/cart'),
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
            padding: EdgeInsets.all(AppSpacing.md),
            child: Icon(icon, color: context.colors.primary, size: 28),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
