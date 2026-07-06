import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_background.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../marketplace/presentation/providers/home_providers.dart';
import '../../../marketplace/presentation/widgets/product_card.dart';

import '../widgets/home_search_header.dart';
import '../widgets/home_hero_carousel.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_category_strip.dart';
import '../widgets/home_promo_banner.dart';
import '../widgets/home_product_section.dart';

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
    final productsAsync = ref.watch(productsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final selectedCondition = ref.watch(selectedConditionProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    final isSearching = searchQuery.isNotEmpty || selectedCategoryId != null || selectedCondition != null;

    return AppAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              ref.invalidate(categoriesProvider);
              ref.invalidate(productsProvider);
              ref.invalidate(wishlistProductIdsProvider);
              ref.invalidate(homeRecommendedProvider);
              ref.invalidate(homeLatestProductsProvider);
              ref.invalidate(homeBestDealsProvider);
              ref.invalidate(homeNearbyProductsProvider);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: HomeSearchHeader(
                    searchController: _searchController,
                    isDesktop: isDesktop,
                  ),
                ),
                if (!isSearching) ...[
                  // Discovery Mode
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
                  const SliverToBoxAdapter(child: HomeHeroCarousel()),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
                  const SliverToBoxAdapter(child: HomeQuickActions()),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
                  const SliverToBoxAdapter(child: HomeCategoryStrip()),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
                  
                  SliverToBoxAdapter(
                    child: HomeProductSection(
                      title: 'Rekomendasi Untukmu',
                      subtitle: 'Barang preloved pilihan yang mungkin kamu suka',
                      providerState: ref.watch(homeRecommendedProvider),
                      onSeeAll: () {
                        // For now just scroll or reset filter to see all active
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Menampilkan semua rekomendasi')),
                        );
                      },
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: HomePromoBanner()),
                  
                  SliverToBoxAdapter(
                    child: HomeProductSection(
                      title: 'Terbaru',
                      subtitle: 'Barang yang baru saja ditambahkan',
                      providerState: ref.watch(homeLatestProductsProvider),
                      onSeeAll: () {},
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
                  
                  SliverToBoxAdapter(
                    child: HomeProductSection(
                      title: 'Harga Terbaik',
                      subtitle: 'Penawaran dengan harga paling bersahabat',
                      providerState: ref.watch(homeBestDealsProvider),
                      onSeeAll: () {},
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

                  SliverToBoxAdapter(
                    child: HomeProductSection(
                      title: 'Dekat Lokasimu',
                      subtitle: 'Barang dari penjual di sekitarmu',
                      providerState: ref.watch(homeNearbyProductsProvider),
                      onSeeAll: () {},
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

                ] else ...[
                  // Search Mode
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list, size: 20, color: AppColors.textMuted),
                          const SizedBox(width: AppSpacing.sm),
                          DropdownButton<String>(
                            value: selectedCondition,
                            hint: const Text('Semua Kondisi', style: TextStyle(color: AppColors.textSecondary)),
                            dropdownColor: AppColors.backgroundDarker,
                            underline: const SizedBox(),
                            style: const TextStyle(color: AppColors.textPrimary),
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Semua Kondisi')),
                              DropdownMenuItem(value: 'new', child: Text('Baru')),
                              DropdownMenuItem(value: 'like_new', child: Text('Seperti Baru')),
                              DropdownMenuItem(value: 'good', child: Text('Baik')),
                              DropdownMenuItem(value: 'fair', child: Text('Cukup')),
                            ],
                            onChanged: (val) {
                              ref.read(selectedConditionProvider.notifier).updateCondition(val);
                            },
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.clear, size: 16, color: AppColors.accent),
                            label: const Text('Reset', style: TextStyle(color: AppColors.accent)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  productsAsync.when(
                    data: (products) {
                      if (products.products.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppEmptyState(
                            icon: Icons.search_off,
                            title: 'Tidak Ada Produk',
                            message: 'Kami tidak dapat menemukan produk yang sesuai dengan pencarian Anda.',
                            buttonText: 'Hapus Filter',
                            onButtonPressed: _resetFilters,
                          ),
                        );
                      }
                      
                      return SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? MediaQuery.of(context).size.width * 0.1 : AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 4 : 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return ProductCard(product: products.products[index]);
                            },
                            childCount: products.products.length,
                          ),
                        ),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    ),
                    error: (error, stack) => SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppErrorState(
                        message: error.toString(),
                        onRetry: () => ref.invalidate(productsProvider),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
