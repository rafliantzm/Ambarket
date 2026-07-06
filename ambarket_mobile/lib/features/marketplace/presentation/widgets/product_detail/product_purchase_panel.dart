import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_glass_card.dart';
import '../../../../../core/widgets/app_status_badge.dart';
import '../../../domain/models/product_model.dart';

class ProductPurchasePanel extends StatelessWidget {
  final ProductModel product;
  final bool isOwner;
  final bool isWishlisted;
  final VoidCallback onToggleWishlist;
  final VoidCallback onChatPressed;
  final VoidCallback onOfferPressed;
  final VoidCallback onCartPressed;
  final VoidCallback onBuyPressed;
  final bool isMobile;

  const ProductPurchasePanel({
    super.key,
    required this.product,
    required this.isOwner,
    required this.isWishlisted,
    required this.onToggleWishlist,
    required this.onChatPressed,
    required this.onOfferPressed,
    required this.onCartPressed,
    required this.onBuyPressed,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    bool isActive = product.status == 'active';
    bool isNegotiable = product.isNegotiable;

    String? offerDisabledReason;
    if (isOwner) {
      offerDisabledReason = 'Produk milik Anda';
    } else if (!isActive) {
      offerDisabledReason = 'Produk tidak aktif';
    } else if (!isNegotiable) {
      offerDisabledReason = 'Harga pas / tidak bisa ditawar';
    }

    String? buyDisabledReason;
    if (isOwner) {
      buyDisabledReason = 'Produk milik Anda';
    } else if (!isActive) {
      buyDisabledReason = 'Produk tidak aktif';
    }

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted ? AppColors.accent : AppColors.textSecondary,
                ),
                onPressed: onToggleWishlist,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            currencyFormatter.format(product.price),
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              AppStatusBadge(
                label: _mapCondition(product.condition),
                status: BadgeStatus.neutral,
              ),
              const SizedBox(width: AppSpacing.sm),
              if (product.isNegotiable)
                const AppStatusBadge(
                  label: 'Bisa Nego',
                  status: BadgeStatus.info,
                ),
              const SizedBox(width: AppSpacing.sm),
              if (product.status != 'active')
                AppStatusBadge(
                  label: _mapStatus(product.status),
                  status: product.status == 'sold' ? BadgeStatus.neutral : BadgeStatus.error,
                ),
            ],
          ),
          if (!isMobile) ...[
            const SizedBox(height: AppSpacing.xl),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppSpacing.xl),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isOwner ? null : onChatPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderStrong),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Icon(Icons.chat_bubble_outline),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: offerDisabledReason != null 
                        ? () => _showTooltip(context, offerDisabledReason!)
                        : onOfferPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: offerDisabledReason != null ? AppColors.surfaceHighlight : AppColors.primary,
                      foregroundColor: offerDisabledReason != null ? AppColors.textMuted : AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Tawar Harga', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: buyDisabledReason != null 
                        ? () => _showTooltip(context, buyDisabledReason!)
                        : onCartPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderStrong),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('+ Keranjang', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: buyDisabledReason != null 
                        ? () => _showTooltip(context, buyDisabledReason!)
                        : onBuyPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buyDisabledReason != null ? AppColors.surfaceHighlight : AppColors.accent,
                      foregroundColor: buyDisabledReason != null ? AppColors.textMuted : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Beli Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  void _showTooltip(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _mapCondition(String condition) {
    switch (condition) {
      case 'like_new': return 'Seperti Baru';
      case 'good': return 'Baik';
      case 'fair': return 'Cukup';
      case 'need_repair': return 'Perlu Perbaikan';
      default: return condition;
    }
  }

  String _mapStatus(String status) {
    switch (status) {
      case 'reserved': return 'Dipesan';
      case 'sold': return 'Terjual';
      case 'archived': return 'Diarsipkan';
      case 'hidden': return 'Disembunyikan';
      case 'rejected': return 'Ditolak';
      default: return status;
    }
  }
}
