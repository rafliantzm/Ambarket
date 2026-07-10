import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_glass_card.dart';
import '../../../../../core/widgets/app_status_badge.dart';
import '../../../../../core/widgets/app_money_text.dart';
import '../../../domain/models/product_model.dart';
import '../../../../offer/domain/models/offer_model.dart';

class ProductHeaderSection extends StatelessWidget {
  final ProductModel product;
  final OfferModel? validOffer;

  const ProductHeaderSection({
    super.key,
    required this.product,
    this.validOffer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppGlassCard(
      padding: EdgeInsets.all(AppSpacing.xl),
      variant: AppGlassCardVariant.elevated,
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
          Text(
            product.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          AppMoneyText(
            amount: validOffer != null ? validOffer!.offerPrice : product.price,
            originalAmount: validOffer != null ? product.price : null,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: context.colors.primary,
          ),
          SizedBox(height: AppSpacing.sm),
          AppStatusBadge(
            label: _mapCondition(product.condition),
            status: BadgeStatus.neutral,
          ),
          SizedBox(height: AppSpacing.xl),
          Divider(color: context.colors.border, height: 1),
          SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                Icons.remove_red_eye_outlined,
                'Dilihat',
                '412',
              ),
              _buildStatItem(
                context,
                Icons.verified_user_outlined,
                'Garansi',
                'Resmi',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: context.colors.textSecondary),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: context.colors.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _mapCondition(String condition) {
    switch (condition) {
      case 'like_new':
        return 'Seperti Baru';
      case 'good':
        return 'Kondisi Baik';
      case 'fair':
        return 'Cukup';
      case 'need_repair':
        return 'Perlu Perbaikan';
      default:
        return condition;
    }
  }
}
