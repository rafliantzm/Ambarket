import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ambarket_scaffold.dart';
import '../../../../core/widgets/premium_surface_card.dart';
import '../../../../core/widgets/premium_status_badge.dart';
import '../../../../core/widgets/premium_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/seller_provider.dart';
import 'package:ambarket_mobile/features/wallet/presentation/providers/seller_wallet_provider.dart';
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
    return AmbarketScaffold(
      backgroundColor: context.colors.background,
      showMotionBackground: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Seller Center',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_business, color: context.colors.primary),
            onPressed: () => context.push('/seller/products/new'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;
          return RefreshIndicator(
            color: context.colors.primary,
            backgroundColor: context.colors.surface,
            onRefresh: () => _onRefresh(ref),
            child: isDesktop
                ? _buildDesktopLayout(context, ref)
                : _buildMobileLayout(context, ref),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSellerHeader(context, ref),
            SizedBox(height: AppSpacing.lg),
            _buildQuickActions(context),
            SizedBox(height: AppSpacing.lg),
            _buildStatsOverview(context, ref, crossAxisCount: 2),
            SizedBox(height: AppSpacing.lg),
            _buildRecentOffers(context, ref),
            SizedBox(height: AppSpacing.lg),
            _buildRecentOrders(context, ref),
            SizedBox(height: AppSpacing.lg),
            _buildProductPerformance(context, ref),
            SizedBox(height: AppSpacing.lg),
            SellerReviewInsights(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildSellerHeader(context, ref),
                    SizedBox(height: AppSpacing.lg),
                    _buildQuickActions(context),
                    SizedBox(height: AppSpacing.lg),
                    _buildStatsOverview(context, ref, crossAxisCount: 3),
                    SizedBox(height: AppSpacing.lg),
                    _buildProductPerformance(context, ref),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  children: [
                    _buildRecentOffers(context, ref),
                    SizedBox(height: AppSpacing.lg),
                    _buildRecentOrders(context, ref),
                    SizedBox(height: AppSpacing.lg),
                    SellerReviewInsights(),
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
    if (user == null) return SizedBox.shrink();

    return PremiumSurfaceCard(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: context.colors.primary.withValues(alpha: 0.2),
            child: user.avatarUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: user.avatarUrl!,
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                    ),
                  )
                : Icon(
                    Icons.storefront,
                    size: 30,
                    color: context.colors.primary,
                  ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? user.username ?? "Seller",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '@${user.username ?? "seller"}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          PremiumStatusBadge(
            label: user.role == 'admin' ? 'Admin' : 'Terverifikasi',
            status: PremiumBadgeStatus.success,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.md,
          alignment: WrapAlignment.start,
          children: [
            _buildQuickActionItem(
              context,
              'Wallet',
              Icons.account_balance_wallet_outlined,
              () => context.push('/seller/wallet'),
            ),
            _buildQuickActionItem(
              context,
              'Kelola Produk',
              Icons.inventory_2_outlined,
              () => context.push('/seller/products'),
            ),
            _buildQuickActionItem(
              context,
              'Tambah Produk',
              Icons.add_box_outlined,
              () => context.push('/seller/products/new'),
            ),
            _buildQuickActionItem(
              context,
              'Pesanan',
              Icons.shopping_bag_outlined,
              () => context.push('/seller/orders'),
            ),
            _buildQuickActionItem(
              context,
              'Tawaran',
              Icons.local_offer_outlined,
              () => context.push('/seller/offers'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PremiumSurfaceCard(
                padding: EdgeInsets.all(14),
                child: Icon(icon, size: 24, color: context.colors.primary),
              ),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview(
    BuildContext context,
    WidgetRef ref, {
    required int crossAxisCount,
  }) {
    final statsAsync = ref.watch(sellerDashboardStatsProvider);
    final walletAsync = ref.watch(sellerWalletSummaryProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Performa',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: AppSpacing.sm),
        statsAsync.when(
          loading: () => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppLoadingSkeleton(
                      width: double.infinity,
                      height: 200,
                      borderRadius: 12,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppLoadingSkeleton(
                      width: double.infinity,
                      height: 200,
                      borderRadius: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppLoadingSkeleton(
                      width: double.infinity,
                      height: 200,
                      borderRadius: 12,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppLoadingSkeleton(
                      width: double.infinity,
                      height: 200,
                      borderRadius: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          error: (err, stack) => AppErrorState(
            title: 'Gagal memuat statistik',
            message: ErrorMapper.getFriendlyMessage(err),
            onRetry: () => ref.invalidate(sellerDashboardStatsProvider),
          ),
          data: (stats) {
            final walletBalance = walletAsync.maybeWhen(
              data: (summary) => summary.availableBalance,
              orElse: () => 0.0,
            );

            return Column(
              children: [
                _buildFinancialOverview(
                  context,
                  stats,
                  walletBalance,
                  currencyFormatter,
                ),
                SizedBox(height: AppSpacing.lg),
                _buildSalesChartCard(context),
                SizedBox(height: AppSpacing.lg),
                _buildOperationalMetrics(context, stats),
                SizedBox(height: AppSpacing.lg),
                _buildStorePerformance(context, stats),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFinancialOverview(
    BuildContext context,
    dynamic stats,
    double walletBalance,
    NumberFormat currencyFormatter,
  ) {
    return PremiumSurfaceCard(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pendapatan Bersih',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  currencyFormatter.format(stats.totalRevenueDummy),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: context.colors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: context.colors.border.withValues(alpha: 0.5),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo Aktif',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  currencyFormatter.format(walletBalance),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: context.colors.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChartCard(BuildContext context) {
    return RepaintBoundary(
      child: PremiumSurfaceCard(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grafik Penjualan (7 Hari)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final days = [
                            'Sen',
                            'Sel',
                            'Rab',
                            'Kam',
                            'Jum',
                            'Sab',
                            'Min',
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < days.length) {
                            return SideTitleWidget(
                              meta: meta,
                              space: 8,
                              child: Text(
                                days[value.toInt()],
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 10,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(1, 1),
                        FlSpot(2, 4),
                        FlSpot(3, 2),
                        FlSpot(4, 5),
                        FlSpot(5, 7),
                        FlSpot(6, 6),
                      ],
                      isCurved: true,
                      color: context.colors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: context.colors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalMetrics(BuildContext context, dynamic stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operasional',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 2.2,
          children: [
            _buildMetricTile(
              context,
              'Pesanan Baru',
              '${stats.pendingOrdersCount + stats.paidOrdersCount}',
              Icons.fiber_new,
              Colors.blue,
            ),
            _buildMetricTile(
              context,
              'Perlu Dikirim',
              '${stats.packedOrdersCount}',
              Icons.inventory,
              Colors.orange,
            ),
            _buildMetricTile(
              context,
              'Selesai',
              '${stats.completedOrdersCount}',
              Icons.check_circle,
              Colors.green,
            ),
            _buildMetricTile(
              context,
              'Dibatalkan/Retur',
              '${stats.cancelledOrdersCount + stats.returnedOrdersCount}',
              Icons.cancel,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStorePerformance(BuildContext context, dynamic stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performa Toko',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                context,
                'Rating',
                stats.averageRating > 0
                    ? stats.averageRating.toStringAsFixed(1)
                    : '-',
                Icons.star,
                Colors.amber,
                subtitle: '${stats.totalReviews} Ulasan',
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildMetricTile(
                context,
                'Produk Aktif',
                '${stats.activeProductsCount}',
                Icons.storefront,
                context.colors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return PremiumSurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(width: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: context.colors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
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
            Text(
              'Pesanan Terbaru',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.push('/seller/orders'),
              child: Text('Lihat Semua'),
            ),
          ],
        ),
        ordersAsync.when(
          loading: () => AppLoadingSkeleton(
            width: double.infinity,
            height: 120,
            borderRadius: 12,
          ),
          error: (err, stack) => AppErrorState(
            title: 'Gagal memuat pesanan',
            message: ErrorMapper.getFriendlyMessage(err),
            onRetry: () => ref.invalidate(sellerRecentOrdersProvider),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return PremiumEmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'Belum Ada Pesanan',
                message: 'Pesanan yang masuk akan muncul di sini.',
              );
            }
            return Column(
              children: orders.map((order) {
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: PremiumSurfaceCard(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            color: context.colors.primary,
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INV/...${order.id.substring(0, 8).toUpperCase()}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                order.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PremiumStatusBadge(
                          label: order.paymentStatus.toUpperCase(),
                          status: order.paymentStatus == 'paid'
                              ? PremiumBadgeStatus.success
                              : PremiumBadgeStatus.neutral,
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
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tawaran Pending',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.push('/seller/offers'),
              child: Text('Lihat Semua'),
            ),
          ],
        ),
        offersAsync.when(
          loading: () => AppLoadingSkeleton(
            width: double.infinity,
            height: 120,
            borderRadius: 12,
          ),
          error: (err, stack) => AppErrorState(
            title: 'Gagal memuat tawaran',
            message: ErrorMapper.getFriendlyMessage(err),
            onRetry: () => ref.invalidate(sellerRecentOffersProvider),
          ),
          data: (offers) {
            if (offers.isEmpty) {
              return PremiumEmptyState(
                icon: Icons.local_offer_outlined,
                title: 'Tidak Ada Tawaran Pending',
                message: 'Tawaran baru akan muncul di sini.',
              );
            }
            return Column(
              children: offers.map((offer) {
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: PremiumSurfaceCard(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.local_offer, color: Colors.orange),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currencyFormatter.format(offer.offerPrice),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.accent,
                                ),
                              ),
                              Text(
                                'Status: ${offer.status}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.textSecondary,
                                ),
                              ),
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
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performa Produk',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        if (productsAsync.isLoading && !productsAsync.hasValue)
          AppLoadingSkeleton(
            width: double.infinity,
            height: 200,
            borderRadius: 12,
          )
        else if (productsAsync.hasError)
          AppErrorState(
            title: 'Gagal memuat produk',
            message: ErrorMapper.getFriendlyMessage(productsAsync.error!),
            onRetry: () => ref.invalidate(myProductsProvider),
          )
        else if (productsAsync.hasValue)
          Builder(
            builder: (context) {
              final products = productsAsync.value!.products;
              if (products.isEmpty) {
                return PremiumEmptyState(
                  icon: Icons.storefront,
                  title: 'Belum Ada Produk',
                  message:
                      'Mulai hasilkan uang dengan menjual barang preloved Anda.',
                  buttonText: 'Tambah Produk',
                  onButtonPressed: () => context.push('/seller/products/new'),
                );
              }
              final previewProducts = products.take(5).toList();
              return Column(
                children: [
                  ...previewProducts.map((product) {
                    final primaryImage =
                        product.images.where((i) => i.isPrimary).firstOrNull ??
                        product.images.firstOrNull;
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: PremiumSurfaceCard(
                        padding: EdgeInsets.zero,
                        onTap: () =>
                            context.push('/seller/products/${product.id}/edit'),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: context.colors.backgroundDarker,
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(12),
                                ),
                              ),
                              child: primaryImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.horizontal(
                                        left: Radius.circular(12),
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: primaryImage.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Icon(
                                              Icons.broken_image,
                                              color: context.colors.textMuted,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.image,
                                      color: context.colors.textMuted,
                                    ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.sm),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      currencyFormatter.format(product.price),
                                      style: TextStyle(
                                        color: context.colors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              child: PremiumStatusBadge(
                                label: _getStatusLabel(product.status),
                                status: _getBadgeStatus(product.status),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (products.length > previewProducts.length)
                    TextButton(
                      onPressed: () => context.push('/seller/products'),
                      child: const Text('Lihat Semua Produk'),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'sold':
        return 'Terjual';
      case 'reserved':
        return 'Dipesan';
      case 'archived':
        return 'Diarsipkan';
      default:
        return status;
    }
  }

  PremiumBadgeStatus _getBadgeStatus(String status) {
    switch (status) {
      case 'active':
        return PremiumBadgeStatus.success;
      case 'sold':
        return PremiumBadgeStatus.error;
      case 'reserved':
        return PremiumBadgeStatus.warning;
      case 'archived':
        return PremiumBadgeStatus.neutral;
      default:
        return PremiumBadgeStatus.info;
    }
  }
}
