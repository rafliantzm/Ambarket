import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/models/product_model.dart';

class ProductInfoSection extends StatelessWidget {
  final ProductModel product;

  const ProductInfoSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Produk',
          style: theme.textTheme.titleMedium?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    theme,
                    Icons.verified_outlined,
                    'Merek',
                    product.brand ?? '-',
                  ),
                  _buildInfoRow(
                    context,
                    theme,
                    Icons.grid_view_outlined,
                    'Kategori',
                    product.category?.name ?? '-',
                  ),
                  _buildInfoRow(
                    context,
                    theme,
                    Icons.location_on_outlined,
                    'Lokasi',
                    product.location,
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    theme,
                    Icons.sell_outlined,
                    'Kondisi',
                    _mapCondition(product.condition),
                  ),
                  _buildInfoRow(
                    context,
                    theme,
                    Icons.calendar_today_outlined,
                    'Garansi',
                    'Resmi 3 Tahun',
                  ),
                  _buildInfoRow(
                    context,
                    theme,
                    Icons.inventory_2_outlined,
                    'Kelengkapan',
                    product.completeness ?? 'Fullset',
                  ),
                ],
              ),
            ),
          ],
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
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: context.colors.primary),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
