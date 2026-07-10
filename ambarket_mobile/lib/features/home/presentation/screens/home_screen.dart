import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import 'package:ambarket_mobile/core/widgets/ambarket_loaders.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../marketplace/presentation/providers/home_providers.dart';
import '../../../marketplace/presentation/widgets/product_card.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

import '../widgets/home_search_header.dart';
import '../widgets/animated_promo_hero_card.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_category_strip.dart';
import '../widgets/home_promo_banner.dart';
import '../widgets/home_coupon_banner.dart';
import '../widgets/home_product_section.dart';
import '../../../profile/presentation/providers/voucher_provider.dart';

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
    _searchController = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
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
    final isSearching =
        ref.watch(searchQueryProvider.select((q) => q.isNotEmpty)) ||
        ref.watch(selectedCategoryIdProvider.select((id) => id != null)) ||
        ref.watch(selectedConditionProvider.select((cond) => cond != null));

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 768;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: context.colors.primary,
          backgroundColor: context.colors.surface,
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            ref.invalidate(productsProvider);
            ref.invalidate(cartCountProvider);
            ref.invalidate(voucherProvider);
            ref.invalidate(homeRecommendedProvider);
            ref.invalidate(homeLatestProductsProvider);
            ref.invalidate(homeBestDealsProvider);
            ref.invalidate(homeNearbyProductsProvider);
          },
          child: CustomScrollView(
            cacheExtent: 900,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: HomeSearchHeader(
                  searchController: _searchController,
                  isDesktop: isDesktop,
                ),
              ),
              if (!isSearching) ...[
                // Discovery Mode
                SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: AnimatedPromoHeroCard(
                      enableAnimation: false,
                      onCtaPressed: () {
                        context.push('/products');
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
                SliverToBoxAdapter(child: const HomeCouponBanner()),
                SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
                SliverToBoxAdapter(child: HomeQuickActions()),
                SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
                SliverToBoxAdapter(child: HomeCategoryStrip()),
                SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

                SliverToBoxAdapter(
                  child: HomeProductSection(
                    title: 'Rekomendasi Untukmu',
                    subtitle: 'Barang preloved pilihan yang mungkin kamu suka',
                    providerState: ref.watch(homeRecommendedProvider),
                    onSeeAll: () {
                      context.push('/products');
                    },
                  ),
                ),

                SliverToBoxAdapter(
                  child: HomePromoBanner(enableAnimation: false),
                ),

                SliverToBoxAdapter(
                  child: HomeProductSection(
                    title: 'Terbaru',
                    subtitle: 'Barang yang baru saja ditambahkan',
                    providerState: ref.watch(homeLatestProductsProvider),
                    onSeeAll: () {
                      context.push('/products');
                    },
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

                SliverToBoxAdapter(
                  child: HomeProductSection(
                    title: 'Harga Terbaik',
                    subtitle: 'Penawaran dengan harga paling bersahabat',
                    providerState: ref.watch(homeBestDealsProvider),
                    onSeeAll: () {
                      context.push('/products');
                    },
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

                SliverToBoxAdapter(
                  child: HomeProductSection(
                    title: 'Dekat Lokasimu',
                    subtitle: 'Barang dari penjual di sekitarmu',
                    providerState: ref.watch(homeNearbyProductsProvider),
                    onSeeAll: () {
                      context.push('/products');
                    },
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
              ] else ...[
                // Search Mode
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 20,
                          color: context.colors.textMuted,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Consumer(
                          builder: (context, ref, child) {
                            final selectedCondition = ref.watch(
                              selectedConditionProvider,
                            );
                            return DropdownButton<String>(
                              value: selectedCondition,
                              hint: Text(
                                'Semua Kondisi',
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                              dropdownColor: context.colors.backgroundDarker,
                              underline: SizedBox(),
                              style: TextStyle(
                                color: context.colors.textPrimary,
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: context.colors.textMuted,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('Semua Kondisi'),
                                ),
                                DropdownMenuItem(
                                  value: 'new',
                                  child: Text('Baru'),
                                ),
                                DropdownMenuItem(
                                  value: 'like_new',
                                  child: Text('Seperti Baru'),
                                ),
                                DropdownMenuItem(
                                  value: 'good',
                                  child: Text('Baik'),
                                ),
                                DropdownMenuItem(
                                  value: 'fair',
                                  child: Text('Cukup'),
                                ),
                              ],
                              onChanged: (val) {
                                ref
                                    .read(selectedConditionProvider.notifier)
                                    .updateCondition(val);
                              },
                            );
                          },
                        ),
                        Spacer(),
                        if (isSearching)
                          TextButton.icon(
                            onPressed: _resetFilters,
                            icon: Icon(
                              Icons.clear,
                              size: 16,
                              color: context.colors.accent,
                            ),
                            label: Text(
                              'Reset',
                              style: TextStyle(color: context.colors.accent),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                Consumer(
                  builder: (context, ref, child) {
                    final productsAsync = ref.watch(productsProvider);
                    final crossAxisCount = width >= 1200
                        ? 5
                        : (isDesktop ? 4 : (width >= 600 ? 3 : 2));

                    return productsAsync.when(
                      data: (products) {
                        if (products.products.isEmpty) {
                          return SliverList(
                            delegate: SliverChildListDelegate([
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.xxl,
                                ),
                                child: AppEmptyState(
                                  icon: Icons.search_off,
                                  title: 'Tidak Ada Produk',
                                  message:
                                      'Kami tidak dapat menemukan produk yang sesuai dengan pencarian Anda.',
                                  buttonText: 'Hapus Filter',
                                  onButtonPressed: _resetFilters,
                                ),
                              ),
                              HomeProductSection(
                                title: 'Mungkin Anda Suka',
                                subtitle: 'Rekomendasi lain untuk Anda',
                                providerState: ref.watch(
                                  homeRecommendedProvider,
                                ),
                                onSeeAll: () {
                                  _resetFilters();
                                  context.push('/products');
                                },
                              ),
                              SizedBox(height: 100),
                            ]),
                          );
                        }

                        return SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop
                                ? MediaQuery.of(context).size.width * 0.1
                                : AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 0.58,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 16,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return ProductCard(
                                  product: products.products[index],
                                );
                              },
                              childCount: products.products.length,
                              addAutomaticKeepAlives: false,
                              addRepaintBoundaries: true,
                            ),
                          ),
                        );
                      },
                      loading: () => const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: AmbarketSectionSkeleton(height: 300),
                        ),
                      ),
                      error: (error, stack) => SliverFillRemaining(
                        hasScrollBody: false,
                        child: AppErrorState(
                          message: error.toString(),
                          onRetry: () => ref.invalidate(productsProvider),
                        ),
                      ),
                    );
                  },
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ), // Safe bottom padding
              ],
            ],
          ),
        ),
      ),
    );
  }
}
