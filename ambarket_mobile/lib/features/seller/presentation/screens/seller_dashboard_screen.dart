import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_background.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/seller_provider.dart';
import '../widgets/seller_review_insights.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(sellerDashboardStatsProvider);
    ref.invalidate(sellerRecentOrdersProvider);
    ref.invalidate(sellerRecentOffersProvider);
    ref.invalidate(myProductsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Seller Center', style: TextStyle(color: AppColors.textPrimary)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_business, color: AppColors.textPrimary),
              onPressed: () => context.push('/seller/products/new'),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () => _onRefresh(ref),
              child: isDesktop ? _buildDesktopLayout(context, ref) : _buildMobileLayout(context, ref),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSellerHeader(context, ref),
          const SizedBox(height: AppSpacing.lg),
          _buildQuickActions(context),
          const SizedBox(height: AppSpacing.lg),
          _buildStatsOverview(context, ref, crossAxisCount: 2),
          const SizedBox(height: AppSpacing.lg),
          _buildRecentOffers(context, ref),
          const SizedBox(height: AppSpacing.lg),
          _buildRecentOrders(context, ref),
          const SizedBox(height: AppSpacing.lg),
          _buildProductPerformance(context, ref),
          const SizedBox(height: AppSpacing.lg),
          const SellerReviewInsights(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildSellerHeader(context, ref),
                    const SizedBox(height: AppSpacing.lg),
                    _buildQuickActions(context),
                    const SizedBox(height: AppSpacing.lg),
                    _buildStatsOverview(context, ref, crossAxisCount: 3),
                    const SizedBox(height: AppSpacing.lg),
                    _buildProductPerformance(context, ref),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  children: [
                    _buildRecentOffers(context, ref),
                    const SizedBox(height: AppSpacing.lg),
                    _buildRecentOrders(context, ref),
                    const SizedBox(height: AppSpacing.lg),
                    const SellerReviewInsights(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSellerHeader(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentProfileProvider).value;
    if (user == null) return const SizedBox.shrink();

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: user.avatarUrl != null
                ? ClipOval(child: CachedNetworkImage(imageUrl: user.avatarUrl!, fit: BoxFit.cover, width: 60, height: 60))
                : const Icon(Icons.storefront, size: 30, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? user.username ?? "Seller",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '@${user.username ?? "seller"}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          AppStatusBadge(
            label: user.role == 'admin' ? 'Admin' : 'Terverifikasi',
            status: BadgeStatus.success,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aksi Cepat', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildActionChip(context, 'Kelola Produk', Icons.inventory_2, () => context.push('/seller/products')),
              _buildActionChip(context, 'Tambah Produk', Icons.add_box, () => context.push('/seller/products/new')),
              _buildActionChip(context, 'Pesanan', Icons.shopping_bag, () => context.push('/seller/orders')),
              _buildActionChip(context, 'Tawaran', Icons.local_offer, () => context.push('/seller/offers')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context, WidgetRef ref, {required int crossAxisCount}) {
    final statsAsync = ref.watch(sellerDashboardStatsProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ringkasan Performa', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.sm),
        statsAsync.when(
          loading: () => GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.5,
            children: List.generate(4, (index) => const AppLoadingSkeleton(width: double.infinity, height: 100, borderRadius: 12)),
          ),
          error: (err, stack) => AppErrorState(
            title: 'Gagal memuat statistik',
            message: ErrorMapper.getFriendlyMessage(err),
            onRetry: () => ref.invalidate(sellerDashboardStatsProvider),
          ),
          data: (stats) {
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.8,
              children: [
                _buildStatCard(context, 'Produk Aktif', '${stats.activeProductsCount}', Icons.inventory_2),
                _buildStatCard(context, 'Pesanan Baru', '${stats.pendingOrdersCount + stats.paidOrdersCount}', Icons.shopping_cart, color: AppColors.primary),
                _buildStatCard(context, 'Perlu Dikirim', '${stats.packedOrdersCount}', Icons.local_shipping, color: AppColors.accent),
                _buildStatCard(context, 'Tawaran Masuk', '${stats.pendingOffersCount}', Icons.local_offer, color: Colors.orange),
                _buildStatCard(context, 'Pesanan Selesai', '${stats.completedOrdersCount}', Icons.check_circle, color: Colors.green),
                _buildStatCard(context, 'Rating Toko', stats.averageRating > 0 ? stats.averageRating.toStringAsFixed(1) : '-', Icons.star, color: Colors.amber),
                _buildStatCard(context, 'Total Ulasan', '${stats.totalReviews}', Icons.rate_review),
                _buildStatCard(context, 'Pendapatan (Dummy)', currencyFormatter.format(stats.totalRevenueDummy), Icons.account_balance_wallet, color: AppColors.primary),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, {Color? color}) {
    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color ?? AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(sellerRecentOrdersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pesanan Terbaru', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => context.push('/seller/orders'), child: const Text('Lihat Semua')),
          ],
        ),
        ordersAsync.when(
          loading: () => const AppLoadingSkeleton(width: double.infinity, height: 120, borderRadius: 12),
          error: (err, stack) => AppErrorState(
            title: 'Gagal memuat pesanan',
            message: ErrorMapper.getFriendlyMessage(err),
            onRetry: () => ref.invalidate(sellerRecentOrdersProvider),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return AppEmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'Belum Ada Pesanan',
                message: 'Pesanan yang masuk akan muncul di sini.',
              );
            }
            return Column(
              children: orders.map((order) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.receipt_long, color: AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('INV/...${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(order.status.toUpperCase(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        AppStatusBadge(
                          label: order.paymentStatus.toUpperCase(),
                          status: order.paymentStatus == 'paid' ? BadgeStatus.success : BadgeStatus.neutral,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentOffers(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(sellerRecentOffersProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tawaran Pending', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => context.push('/seller/offers'), child: const Text('Lihat Semua')),
          ],
        ),
        offersAsync.when(
          loading: () => const AppLoadingSkeleton(width: double.infinity, height: 120, borderRadius: 12),
          error: (err, stack) => AppErrorState(
            title: 'Gagal memuat tawaran',
            message: ErrorMapper.getFriendlyMessage(err),
            onRetry: () => ref.invalidate(sellerRecentOffersProvider),
          ),
          data: (offers) {
            if (offers.isEmpty) {
              return AppEmptyState(
                icon: Icons.local_offer_outlined,
                title: 'Tidak Ada Tawaran Pending',
                message: 'Tawaran baru akan muncul di sini.',
              );
            }
            return Column(
              children: offers.map((offer) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.local_offer, color: Colors.orange),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(currencyFormatter.format(offer.offerPrice), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
                              Text('Status: ${offer.status}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductPerformance(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(myProductsProvider);
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Performa Produk', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        productsAsync.when(
          loading: () => const AppLoadingSkeleton(width: double.infinity, height: 200, borderRadius: 12),
          error: (err, stack) => AppErrorState(
            title: 'Gagal memuat produk',
            message: ErrorMapper.getFriendlyMessage(err),
            onRetry: () => ref.invalidate(myProductsProvider),
          ),
          data: (paginatedState) {
            final products = paginatedState.products;
            if (products.isEmpty) {
              return AppEmptyState(
                icon: Icons.storefront,
                title: 'Belum Ada Produk',
                message: 'Mulai hasilkan uang dengan menjual barang preloved Anda.',
                buttonText: 'Tambah Produk',
                onButtonPressed: () => context.push('/seller/products/new'),
              );
            }
            return Column(
              children: products.map((product) {
                final primaryImage = product.images.where((i) => i.isPrimary).firstOrNull ?? product.images.firstOrNull;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppGlassCard(
                    padding: EdgeInsets.zero,
                    onTap: () => context.push('/seller/products/${product.id}/edit'),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDarker,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                          ),
                          child: primaryImage != null
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                  child: CachedNetworkImage(
                                    imageUrl: primaryImage.imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: AppColors.textMuted),
                                  ),
                                )
                              : const Icon(Icons.image, color: AppColors.textMuted),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(currencyFormatter.format(product.price), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: AppStatusBadge(
                            label: _getStatusLabel(product.status),
                            status: _getBadgeStatus(product.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'available': return 'Aktif';
      case 'sold': return 'Terjual';
      case 'reserved': return 'Dipesan';
      case 'archived': return 'Diarsipkan';
      default: return status;
    }
  }

  BadgeStatus _getBadgeStatus(String status) {
    switch (status) {
      case 'available': return BadgeStatus.success;
      case 'sold': return BadgeStatus.error;
      case 'reserved': return BadgeStatus.warning;
      case 'archived': return BadgeStatus.neutral;
      default: return BadgeStatus.info;
    }
  }
}
