import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'home_product_horizontal_list.dart';
import '../../../marketplace/domain/models/product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeProductSection extends ConsumerWidget {
  final String title;
  final String subtitle;
  final AsyncValue<List<ProductModel>> providerState;
  final VoidCallback onSeeAll;

  const HomeProductSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.providerState,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 310,
          child: HomeProductHorizontalList(providerState: providerState),
        ),
      ],
    );
  }
}
