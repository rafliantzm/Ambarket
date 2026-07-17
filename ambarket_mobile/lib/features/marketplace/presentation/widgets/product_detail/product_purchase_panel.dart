import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_glass_card.dart';
import '../../../../../core/widgets/app_status_badge.dart';
import '../../../../../core/widgets/app_money_text.dart';
import '../../../domain/models/product_model.dart';
import '../../../../offer/domain/models/offer_model.dart';

class ProductPurchasePanel extends StatelessWidget {
  final ProductModel product;
  final OfferModel? validOffer;
  final bool isOwner;
  final VoidCallback onChatPressed;
  final VoidCallback onOfferPressed;
  final VoidCallback onCartPressed;
  final VoidCallback onBuyPressed;
  final bool isMobile;

  const ProductPurchasePanel({
    super.key,
    required this.product,
    this.validOffer,
    required this.isOwner,
    required this.onChatPressed,
    required this.onOfferPressed,
    required this.onCartPressed,
    required this.onBuyPressed,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      padding: EdgeInsets.all(AppSpacing.lg),
      variant: AppGlassCardVariant.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (validOffer != null)
            Container(
              margin: EdgeInsets.only(bottom: AppSpacing.md),
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer, color: Colors.amber, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Tawaran disetujui! Sisa waktu: ${validOffer!.expiresAt?.difference(DateTime.now()).inHours ?? 0} jam',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          AppMoneyText(
            amount: validOffer != null ? validOffer!.offerPrice : product.price,
            originalAmount: validOffer != null ? product.price : null,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: context.colors.primary,
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              AppStatusBadge(
                label: _mapCondition(product.condition),
                status: BadgeStatus.neutral,
              ),
              SizedBox(width: AppSpacing.sm),
              if (product.isNegotiable)
                AppStatusBadge(label: 'Bisa Nego', status: BadgeStatus.info),
              SizedBox(width: AppSpacing.sm),
              if (product.status != 'active')
                AppStatusBadge(
                  label: _mapStatus(product.status),
                  status: product.status == 'sold'
                      ? BadgeStatus.neutral
                      : BadgeStatus.error,
                ),
            ],
          ),
          if (!isMobile) ...[
            SizedBox(height: AppSpacing.xl),
            Divider(color: context.colors.border),
            SizedBox(height: AppSpacing.xl),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isOwner ? null : onChatPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isOwner
                          ? context.colors.textMuted
                          : context.colors.textPrimary,
                      side: BorderSide(
                        color: isOwner
                            ? context.colors.border
                            : context.colors.borderStrong,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Icon(CupertinoIcons.chat_bubble_text),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: offerDisabledReason != null
                        ? () => _showTooltip(context, offerDisabledReason!)
                        : onOfferPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: offerDisabledReason != null
                          ? context.colors.surfaceHighlight
                          : context.colors.primary,
                      foregroundColor: offerDisabledReason != null
                          ? context.colors.textMuted
                          : context.colors.background,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Tawar Harga',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: buyDisabledReason != null
                        ? () => _showTooltip(context, buyDisabledReason!)
                        : onCartPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: buyDisabledReason != null
                          ? context.colors.textMuted
                          : context.colors.textPrimary,
                      side: BorderSide(
                        color: buyDisabledReason != null
                            ? context.colors.border
                            : context.colors.borderStrong,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      '+ Keranjang',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: buyDisabledReason != null
                        ? () => _showTooltip(context, buyDisabledReason!)
                        : onBuyPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buyDisabledReason != null
                          ? context.colors.surfaceHighlight
                          : context.colors.accent,
                      foregroundColor: buyDisabledReason != null
                          ? context.colors.textMuted
                          : Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Beli Sekarang',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showTooltip(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _mapCondition(String condition) {
    switch (condition) {
      case 'like_new':
        return 'Seperti Baru';
      case 'good':
        return 'Baik';
      case 'fair':
        return 'Cukup';
      case 'need_repair':
        return 'Perlu Perbaikan';
      default:
        return condition;
    }
  }

  String _mapStatus(String status) {
    switch (status) {
      case 'reserved':
        return 'Dipesan';
      case 'sold':
        return 'Terjual';
      case 'archived':
        return 'Diarsipkan';
      case 'hidden':
        return 'Disembunyikan';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }
}
