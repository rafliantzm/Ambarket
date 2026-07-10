import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ambarket_scaffold.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/premium_command_search_bar.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/ambarket_loaders.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/product_card.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 600) {
        ref.read(productsProvider.notifier).fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    ref.read(selectedCategoryIdProvider.notifier).updateCategory(null);
    ref.read(selectedConditionProvider.notifier).updateCondition(null);
    ref.read(searchQueryProvider.notifier).updateQuery('');
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final selectedCondition = ref.watch(selectedConditionProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 768;
    final crossAxisCount = width >= 1200
        ? 5
        : (isDesktop ? 4 : (width >= 600 ? 3 : 2));
    if (_searchController.text != searchQuery && searchQuery.isEmpty) {
      _searchController.clear();
    }

    return AmbarketScaffold(
      isDesktopConstrained: isDesktop,
      showMotionBackground: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Semua Produk',
          style: TextStyle(color: context.colors.textPrimary),
        ),
        actions: [
          if (selectedCondition != null ||
              searchQuery.isNotEmpty ||
              selectedCategoryId != null)
            TextButton.icon(
              onPressed: _resetFilters,
              icon: Icon(Icons.clear, size: 16, color: context.colors.accent),
              label: Text(
                'Reset',
                style: TextStyle(color: context.colors.accent),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: PremiumCommandSearchBar(
              controller: _searchController,
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).updateQuery(value),
            ),
          ),
        ),
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.products.isEmpty) {
            return AppEmptyState(
              icon: Icons.search_off,
              title: 'Tidak Ada Produk',
              message: 'Kami tidak dapat menemukan produk yang sesuai.',
              buttonText: 'Hapus Filter',
              onButtonPressed: _resetFilters,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(productsProvider);
            },
            child: GridView.builder(
              controller: _scrollController,
              cacheExtent: 900,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: isDesktop ? width * 0.1 : AppSpacing.md,
                right: isDesktop ? width * 0.1 : AppSpacing.md,
                top: AppSpacing.md,
                bottom:
                    MediaQuery.of(context).padding.bottom + 100, // Safe padding
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.58,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: products.products.length + (products.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= products.products.length) {
                  return const AmbarketLoadMoreIndicator();
                }
                return ProductCard(product: products.products[index]);
              },
            ),
          );
        },
        loading: () => const AmbarketPageLoader(),
        error: (error, stack) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(productsProvider),
        ),
      ),
    );
  }
}
