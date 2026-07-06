import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/models/product_model.dart';
import '../../providers/marketplace_provider.dart';
import '../product_card.dart';

class ProductRelatedSection extends ConsumerWidget {
  final ProductModel product;

  const ProductRelatedSection({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedAsync = ref.watch(relatedProductsProvider((
      productId: product.id,
      categoryId: product.categoryId,
    )));

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Produk Serupa',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 280,
          child: relatedAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return Center(
                  child: Text(
                    'Tidak ada produk serupa.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: SizedBox(
                      width: 180,
                      child: ProductCard(product: products[index]),
                    ),
                  );
                },
              );
            },
            loading: () => ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Container(
                  width: 180,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(height: 140, color: AppColors.border),
                    ],
                  ),
                ),
              ),
            ),
            error: (e, st) => const Center(child: Text('Gagal memuat produk serupa', style: TextStyle(color: AppColors.error))),
          ),
        ),
      ],
    );
  }
}
