import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ambarket_scaffold.dart';
import '../../../../core/widgets/premium_empty_state.dart';
import '../../../../core/widgets/premium_command_search_bar.dart';
import '../../../../core/widgets/premium_filter_chips.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/error/error_mapper.dart';
import '../providers/seller_product_provider.dart';
import '../widgets/seller_product_card.dart';

class SellerProductsScreen extends ConsumerWidget {
  const SellerProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return AmbarketScaffold(
      backgroundColor: context.colors.background,
      showMotionBackground: false,
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop && MediaQuery.of(context).size.width > 1200
                ? (MediaQuery.of(context).size.width - 1200) / 2
                : AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pantau, edit, dan kelola status produk toko Anda.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSearchBar(context, ref),
              const SizedBox(height: AppSpacing.sm),
              _buildFilterChips(context, ref),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildProductList(context, ref, isDesktop)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    return PremiumCommandSearchBar(
      hintText: 'Cari produk jualan...',
      onChanged: (value) {
        ref.read(sellerProductSearchQueryProvider.notifier).setQuery(value);
      },
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(sellerProductStatusFilterProvider);
    final filters = {
      'all': 'Semua',
      'active': 'Aktif',
      'reserved': 'Dipesan',
      'sold': 'Terjual',
      'archived': 'Diarsipkan',
      'hidden': 'Disembunyikan',
      'rejected': 'Ditolak',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final isSelected = currentFilter == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PremiumFilterChip(
              label: entry.value,
              isSelected: isSelected,
              onTap: () {
                ref
                    .read(sellerProductStatusFilterProvider.notifier)
                    .setFilter(entry.key);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductList(
    BuildContext context,
    WidgetRef ref,
    bool isDesktop,
  ) {
    final productsState = ref.watch(sellerProductsProvider);

    return productsState.when(
      data: (products) {
        if (products.isEmpty) {
          return const PremiumEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Tidak Ada Produk',
            message: 'Belum ada produk pada status ini.',
          );
        }

        if (isDesktop) {
          return GridView.builder(
            cacheExtent: 800,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 320,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return SellerProductCard(product: products[index]);
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(sellerProductsProvider.notifier).refresh(),
          child: ListView.separated(
            cacheExtent: 800,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: products.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              return SellerProductCard(product: products[index]);
            },
          ),
        );
      },
      loading: () => ListView.separated(
        itemCount: 5,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) =>
            const AppLoadingSkeleton(width: double.infinity, height: 150),
      ),
      error: (error, stack) => AppErrorState(
        message: ErrorMapper.getFriendlyMessage(error),
        onRetry: () => ref.read(sellerProductsProvider.notifier).refresh(),
      ),
    );
  }
}
