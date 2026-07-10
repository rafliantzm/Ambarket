import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_animated_background.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';

import '../providers/profile_provider.dart';
import '../../../review/presentation/providers/review_provider.dart';
import '../../../review/presentation/widgets/rating_stars.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../marketplace/presentation/widgets/product_card.dart';

class SellerPublicProfileScreen extends ConsumerStatefulWidget {
  final String sellerId;
  const SellerPublicProfileScreen({super.key, required this.sellerId});

  @override
  ConsumerState<SellerPublicProfileScreen> createState() =>
      _SellerPublicProfileScreenState();
}

class _SellerPublicProfileScreenState
    extends ConsumerState<SellerPublicProfileScreen> {
  String _searchQuery = '';
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(publicProfileProvider(widget.sellerId));
    final currentUser = ref.watch(currentUserProvider);

    return AppAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Profil Penjual',
            style: TextStyle(color: context.colors.textPrimary),
          ),
        ),
        body: profileAsync.when(
          data: (profile) {
            final isOwnProfile = currentUser?.id == widget.sellerId;

            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.colors.primary,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.colors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 16,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor:
                                      context.colors.backgroundDarker,
                                  backgroundImage: profile.avatarUrl != null
                                      ? CachedNetworkImageProvider(
                                          profile.avatarUrl!,
                                        )
                                      : null,
                                  child: profile.avatarUrl == null
                                      ? Icon(
                                          Icons.storefront_outlined,
                                          size: 50,
                                          color: context.colors.textMuted,
                                        )
                                      : null,
                                ),
                              ),
                              SizedBox(height: AppSpacing.md),

                              // Name & Role
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    profile.name ?? 'Penjual',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: context.colors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (profile.role == 'admin') ...[
                                    SizedBox(width: AppSpacing.sm),
                                    AppStatusBadge(
                                      label: 'ADMIN',
                                      status: BadgeStatus.error,
                                    ),
                                  ],
                                ],
                              ),

                              // Username
                              SizedBox(height: AppSpacing.xs),
                              if (profile.username != null &&
                                  profile.username!.isNotEmpty)
                                Text(
                                  '@${profile.username}',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: context.colors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),

                              // Location & Bio
                              if (profile.location != null &&
                                  profile.location!.isNotEmpty) ...[
                                SizedBox(height: AppSpacing.md),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: context.colors.textMuted,
                                    ),
                                    SizedBox(width: AppSpacing.xs),
                                    Text(
                                      profile.location!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: context.colors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                              if (profile.bio != null &&
                                  profile.bio!.isNotEmpty) ...[
                                SizedBox(height: AppSpacing.md),
                                Text(
                                  profile.bio!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: context.colors.textPrimary,
                                      ),
                                ),
                              ],

                              SizedBox(height: AppSpacing.lg),
                              Consumer(
                                builder: (context, ref, child) {
                                  final ratingAsync = ref.watch(
                                    sellerRatingSummaryProvider(
                                      widget.sellerId,
                                    ),
                                  );
                                  return ratingAsync.when(
                                    data: (summary) {
                                      if (summary.totalReviews == 0) {
                                        return Text(
                                          'Belum ada ulasan',
                                          style: TextStyle(
                                            color: context.colors.textMuted,
                                          ),
                                        );
                                      }
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          RatingStars(
                                            rating: summary.averageRating
                                                .round(),
                                            size: 20,
                                          ),
                                          SizedBox(width: AppSpacing.xs),
                                          Text(
                                            '${summary.averageRating.toStringAsFixed(1)} / 5.0 (${summary.totalReviews})',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: context
                                                      .colors
                                                      .textSecondary,
                                                ),
                                          ),
                                        ],
                                      );
                                    },
                                    loading: () => SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    error: (err, st) => SizedBox(),
                                  );
                                },
                              ),

                              if (!isOwnProfile) ...[
                                SizedBox(height: AppSpacing.xl),
                                AppButton(
                                  label: 'Chat Penjual',
                                  onPressed: () async {
                                    if (currentUser == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Silakan login terlebih dahulu',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    try {
                                      // Using a dummy productId for general chat if none is provided, or better, we can modify createOrGetConversation to allow null productId.
                                      // Actually, chat repository requires productId in this app's logic currently.
                                      // Wait, if it requires productId, chatting from profile might be tricky if we don't have a product context.
                                      // Let's pass a generic or empty string if it's not strictly a UUID in DB, or handle it in repo.
                                      // Since we must pass a productId, let's just show a snackbar for now.
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Chat dari profil belum didukung. Silakan chat via produk.',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Gagal: $e')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: AppSpacing.xl),

                        // Search & Categories Section
                        TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari di toko ini...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: context.colors.textMuted,
                            ),
                            filled: true,
                            fillColor: context.colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        Consumer(
                          builder: (context, ref, child) {
                            final categoriesAsync = ref.watch(
                              categoriesProvider,
                            );
                            return categoriesAsync.when(
                              data: (categories) {
                                return SizedBox(
                                  height: 40,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    cacheExtent: 300,
                                    addAutomaticKeepAlives: false,
                                    addRepaintBoundaries: true,
                                    itemCount: categories.length + 1,
                                    itemBuilder: (context, index) {
                                      final isAll = index == 0;
                                      final catId = isAll
                                          ? null
                                          : categories[index - 1].id;
                                      final catName = isAll
                                          ? 'Semua'
                                          : categories[index - 1].name;
                                      final isSelected =
                                          _selectedCategoryId == catId;

                                      return Padding(
                                        padding: EdgeInsets.only(right: 8.0),
                                        child: FilterChip(
                                          label: Text(catName),
                                          selected: isSelected,
                                          onSelected: (val) {
                                            if (val) {
                                              setState(
                                                () =>
                                                    _selectedCategoryId = catId,
                                              );
                                            } else if (!isAll) {
                                              setState(
                                                () =>
                                                    _selectedCategoryId = null,
                                              );
                                            }
                                          },
                                          backgroundColor:
                                              context.colors.surface,
                                          selectedColor: context.colors.primary
                                              .withValues(alpha: 0.2),
                                          checkmarkColor:
                                              context.colors.primary,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                              loading: () => SizedBox(height: 40),
                              error: (err, st) => SizedBox(height: 40),
                            );
                          },
                        ),

                        SizedBox(height: AppSpacing.xl),
                        Text(
                          'Produk Dijual',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        Consumer(
                          builder: (context, ref, child) {
                            final productsAsync = ref.watch(
                              sellerPublicProductsProvider((
                                sellerId: widget.sellerId,
                                query: _searchQuery,
                                categoryId: _selectedCategoryId,
                              )),
                            );

                            return productsAsync.when(
                              data: (products) {
                                if (products.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(AppSpacing.xl),
                                      child: Text(
                                        'Tidak ada produk yang sesuai',
                                        style: TextStyle(
                                          color: context.colors.textMuted,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  cacheExtent: 800,
                                  addAutomaticKeepAlives: false,
                                  addRepaintBoundaries: true,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount:
                                            MediaQuery.of(context).size.width >=
                                                1200
                                            ? 5
                                            : (MediaQuery.of(
                                                        context,
                                                      ).size.width >=
                                                      768
                                                  ? 4
                                                  : (MediaQuery.of(
                                                              context,
                                                            ).size.width >=
                                                            600
                                                        ? 3
                                                        : 2)),
                                        childAspectRatio: 0.58,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 16,
                                      ),
                                  itemCount: products.length,
                                  itemBuilder: (context, index) {
                                    return ProductCard(
                                      product: products[index],
                                    );
                                  },
                                );
                              },
                              loading: () => Center(
                                child: CircularProgressIndicator(
                                  color: context.colors.primary,
                                ),
                              ),
                              error: (err, st) => Center(
                                child: Text('Gagal memuat produk: $err'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: context.colors.primary),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Terjadi kesalahan: $error',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ),
      ),
    );
  }
}
