import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/premium_filter_chips.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';

class HomeCategoryStrip extends ConsumerWidget {
  const HomeCategoryStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryIdProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return SizedBox.shrink();

        return SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                    ref
                        .read(selectedCategoryIdProvider.notifier)
                        .updateCategory(null);
                  },
                );
              }

              final category = categories[index - 1];
              final isSelected = selectedCategory == category.id;

              IconData iconData = Icons.category_outlined;
              final name = category.name.toLowerCase();
              if (name.contains('elektronik') || name.contains('gadget')) {
                iconData = Icons.laptop_mac;
              } else if (name.contains('fashion') || name.contains('pakaian')) {
                iconData = Icons.checkroom;
              } else if (name.contains('kendaraan') ||
                  name.contains('otomotif')) {
                iconData = Icons.directions_car;
              } else if (name.contains('hobi') ||
                  name.contains('buku') ||
                  name.contains('mainan')) {
                iconData = Icons.sports_esports;
              } else if (name.contains('perabotan') || name.contains('rumah')) {
                iconData = Icons.chair_outlined;
              }

              return _buildCategoryItem(
                context: context,
                label: category.name,
                icon: iconData,
                isSelected: isSelected,
                onTap: () {
                  ref
                      .read(selectedCategoryIdProvider.notifier)
                      .updateCategory(category.id);
                },
              );
            },
          ),
        );
      },
      loading: () => SizedBox(
        height: 90,
        child: Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
      ),
      error: (e, st) => SizedBox.shrink(),
    );
  }

  Widget _buildCategoryItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: AppSpacing.sm),
      child: Center(
        child: PremiumFilterChip(
          label: label,
          icon: icon,
          isSelected: isSelected,
          onTap: onTap,
        ),
      ),
    );
  }
}
