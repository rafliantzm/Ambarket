import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../marketplace/domain/models/product_model.dart';
import '../../../marketplace/presentation/widgets/product_card.dart';
import '../../../../core/widgets/app_glass_card.dart';

class HomeProductHorizontalList extends StatelessWidget {
  final AsyncValue<List<ProductModel>> providerState;

  const HomeProductHorizontalList({super.key, required this.providerState});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 296,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: providerState.when(
          data: (products) {
            if (products.isEmpty) {
              return Center(
                child: Text(
                  'Belum ada produk.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              );
            }

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: products.length,
              itemExtent: 196,
              cacheExtent: 700,
              addAutomaticKeepAlives: false, // Save memory on off-screen items
              addRepaintBoundaries: true,
              addSemanticIndexes: false,
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
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: 4,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(right: AppSpacing.md),
              child: _SkeletonCard(),
            ),
          ),
          error: (e, st) => Center(
            child: Text(
              'Gagal memuat produk.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.colors.error),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 140, color: context.colors.border),
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    color: context.colors.border,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Container(
                    height: 16,
                    width: 80,
                    color: context.colors.border,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 20,
                    width: 100,
                    color: context.colors.border,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
