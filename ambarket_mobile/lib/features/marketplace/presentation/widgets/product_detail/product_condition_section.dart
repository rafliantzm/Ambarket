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
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildInfoRow(theme, 'Kondisi Barang', _mapCondition(product.condition)),
        if (product.usageDuration?.isNotEmpty ?? false)
          _buildInfoRow(theme, 'Lama Pemakaian', product.usageDuration!),
        if (product.completeness?.isNotEmpty ?? false)
          _buildInfoRow(theme, 'Kelengkapan', product.completeness!),
        if (product.defects?.isNotEmpty ?? false)
          _buildInfoRow(theme, 'Minus/Cacat', product.defects!),
      ],
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _mapCondition(String condition) {
    switch (condition) {
      case 'like_new': return 'Seperti Baru (Mulus 99%)';
      case 'good': return 'Baik (Fungsi Normal, Lecet Pemakaian)';
      case 'fair': return 'Cukup (Ada Minus Fungsi/Fisik)';
      case 'need_repair': return 'Perlu Perbaikan (Rusak/Mati Total)';
      default: return condition;
    }
  }
}
