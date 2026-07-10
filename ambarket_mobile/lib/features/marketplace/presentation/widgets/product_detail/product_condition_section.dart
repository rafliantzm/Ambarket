import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/models/product_model.dart';

class ProductConditionSection extends StatelessWidget {
  final ProductModel product;

  const ProductConditionSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Kondisi',
          style: theme.textTheme.titleMedium?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: AppSpacing.lg),

        // Condition Highlight Card
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.stars_rounded,
                color: context.colors.primary,
                size: 28,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kondisi Barang',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    Text(
                      _mapCondition(product.condition),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),

        if (product.usageDuration?.isNotEmpty ?? false)
          _buildInfoRow(
            context,
            theme,
            Icons.access_time_rounded,
            'Lama Pemakaian',
            product.usageDuration!,
          ),
        if (product.completeness?.isNotEmpty ?? false)
          _buildInfoRow(
            context,
            theme,
            Icons.inventory_2_outlined,
            'Kelengkapan',
            product.completeness!,
          ),
        if (product.defects?.isNotEmpty ?? false)
          _buildInfoRow(
            context,
            theme,
            Icons.warning_amber_rounded,
            'Minus/Cacat',
            product.defects!,
          ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: context.colors.textSecondary),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _mapCondition(String condition) {
    switch (condition) {
      case 'like_new':
        return 'Seperti Baru (Mulus 99%)';
      case 'good':
        return 'Baik (Fungsi Normal, Lecet Pemakaian)';
      case 'fair':
        return 'Cukup (Ada Minus Fungsi/Fisik)';
      case 'need_repair':
        return 'Perlu Perbaikan (Rusak/Mati Total)';
      default:
        return condition;
    }
  }
}
