import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';

class HomeCategoryStrip extends ConsumerWidget {
  const HomeCategoryStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryIdProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // "Semua" option
                final isSelected = selectedCategory == null;
                return _buildCategoryItem(
                  context: context,
                  label: 'Semua',
                  icon: Icons.grid_view,
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(selectedCategoryIdProvider.notifier).updateCategory(null);
                  },
                );
              }

              final category = categories[index - 1];
              final isSelected = selectedCategory == category.id;
              
              IconData iconData = Icons.category_outlined;
              if (category.name.toLowerCase().contains('elektronik')) {
                iconData = Icons.devices;
              } else if (category.name.toLowerCase().contains('pakaian')) {
                iconData = Icons.checkroom;
              } else if (category.name.toLowerCase().contains('otomotif')) {
                iconData = Icons.directions_car;
              } else if (category.name.toLowerCase().contains('buku')) {
                iconData = Icons.menu_book;
              }

              return _buildCategoryItem(
                context: context,
                label: category.name,
                icon: iconData,
                isSelected: isSelected,
                onTap: () {
                  ref.read(selectedCategoryIdProvider.notifier).updateCategory(category.id);
                },
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategoryItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        child: Column(
          children: [
            AppGlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              customBorder: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
