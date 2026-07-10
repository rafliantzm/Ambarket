import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_loading_skeleton.dart';
import '../../../domain/models/product_model.dart';
import '../../providers/marketplace_provider.dart';
import '../product_card.dart';

class ProductRelatedSection extends ConsumerWidget {
  final ProductModel product;

  const ProductRelatedSection({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedAsync = ref.watch(
      relatedProductsProvider((
        productId: product.id,
        categoryId: product.categoryId,
      )),
    );

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Produk Serupa',
            style: theme.textTheme.titleMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 296,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: relatedAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada produk serupa.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemExtent: 196,
                  cacheExtent: 700,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: AppSpacing.md),
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemExtent: 196,
                cacheExtent: 500,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                itemCount: 4,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(right: AppSpacing.md),
                  child: SizedBox(
                    width: 180,
                    child: AppLoadingSkeleton(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 16,
                    ),
                  ),
                ),
              ),
              error: (e, st) => Center(
                child: Text(
                  'Gagal memuat produk serupa',
                  style: TextStyle(color: context.colors.error),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
