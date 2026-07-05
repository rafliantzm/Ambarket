import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../marketplace/presentation/widgets/product_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
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
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final selectedCondition = ref.watch(selectedConditionProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambarket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.push('/profile');
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(productsProvider);
          ref.invalidate(wishlistProductIdsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari barang bekas...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).updateQuery(value);
                  },
                ),
              ),
            ),
            
            // Hero Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Temukan Barang Impianmu!',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Barang bekas berkualitas dengan harga terbaik.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.shopping_bag, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                    ],
                  ),
                ),
              ),
            ),
            
            // Filters Section
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.sm),
                    child: Text('Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    height: 40,
                    child: categoriesAsync.when(
                      data: (categories) => ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: categories.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.sm),
                              child: FilterChip(
                                label: const Text('Semua'),
                                selected: selectedCategoryId == null,
                                onSelected: (selected) {
                                  if (selected) {
                                    ref.read(selectedCategoryIdProvider.notifier).updateCategory(null);
                                  }
                                },
                              ),
                            );
                          }
                          final category = categories[index - 1];
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: FilterChip(
                              label: Text(category.name),
                              selected: selectedCategoryId == category.id,
                              onSelected: (selected) {
                                ref.read(selectedCategoryIdProvider.notifier).updateCategory(selected ? category.id : null);
                              },
                            ),
                          );
                        },
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => const Center(child: Text('Gagal memuat kategori')),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        _buildConditionChip(context, ref, 'Semua Kondisi', null, selectedCondition),
                        _buildConditionChip(context, ref, 'Like New', 'like_new', selectedCondition),
                        _buildConditionChip(context, ref, 'Good', 'good', selectedCondition),
                        _buildConditionChip(context, ref, 'Fair', 'fair', selectedCondition),
                        _buildConditionChip(context, ref, 'Need Repair', 'need_repair', selectedCondition),
                        if (selectedCategoryId != null || selectedCondition != null || _searchController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.sm),
                            child: ActionChip(
                              label: Text('Reset Filter', style: TextStyle(color: theme.colorScheme.error)),
                              onPressed: _resetFilters,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Products Title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.sm),
                child: Text('Rekomendasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            
            // Products Grid
            productsAsync.when(
              data: (paginatedState) {
                final products = paginatedState.products;
                if (products.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Tidak ada produk yang ditemukan.',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Coba ubah kata kunci atau filter.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton.icon(
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset Pencarian dan Filter'),
                          )
                        ],
                      ),
                    ),
                  );
                }
                return SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => ProductCard(product: products[index]),
                          childCount: products.length,
                        ),
                      ),
                    ),
                    if (paginatedState.hasMore)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: () {
                                ref.read(productsProvider.notifier).fetchMore();
                              },
                              child: const Text('Muat Lebih Banyak'),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildLoadingSkeleton(theme),
                    childCount: 4,
                  ),
                ),
              ),
              error: (e, st) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: AppSpacing.md),
                        Text('Gagal memuat produk', style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(productsProvider);
                          },
                          child: const Text('Coba Lagi'),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionChip(BuildContext context, WidgetRef ref, String label, String? value, String? selectedValue) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selectedValue == value,
        onSelected: (selected) {
          if (selected) {
            ref.read(selectedConditionProvider.notifier).updateCondition(value);
          } else if (value != null) {
            ref.read(selectedConditionProvider.notifier).updateCondition(null);
          }
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: double.infinity, color: theme.colorScheme.surfaceContainerHighest),
                const SizedBox(height: AppSpacing.sm),
                Container(height: 16, width: 80, color: theme.colorScheme.surfaceContainerHighest),
                const SizedBox(height: AppSpacing.sm),
                Container(height: 20, width: 100, color: theme.colorScheme.surfaceContainerHighest),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
