import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Keranjang Saya'),
          bottom: TabBar(
            indicatorColor: context.colors.primary,
            labelColor: context.colors.primary,
            unselectedLabelColor: context.colors.textSecondary,
            tabs: const [
              Tab(text: 'Keranjang'),
              Tab(text: 'Disimpan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildCartTab(context, ref), _buildWishlistTab(context)],
        ),
      ),
    );
  }

  Widget _buildWishlistTab(BuildContext context) {
    return AppEmptyState(
      icon: Icons.favorite_border,
      title: 'Belum Ada Barang Disimpan',
      message: 'Barang yang Anda simpan akan muncul di sini.',
      buttonText: 'Cari Barang',
      onButtonPressed: () => context.go('/'),
    );
  }

  Widget _buildCartTab(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartItemsProvider);
    final actionState = ref.watch(cartActionControllerProvider);

    ref.listen(cartActionControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: context.colors.error,
          ),
        );
      }
    });

    return cartState.when(
      loading: () => _buildLoading(context),
      error: (err, stack) => AppErrorState(
        message: 'Gagal memuat keranjang',
        onRetry: () => ref.refresh(cartItemsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return AppEmptyState(
            icon: Icons.shopping_cart_outlined,
            title: 'Keranjang Kosong',
            message: 'Belum ada barang di keranjangmu.',
            buttonText: 'Mulai Belanja',
            onButtonPressed: () => context.go('/'),
          );
        }

        final currencyFormatter = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp',
          decimalDigits: 0,
        );

        double subtotal = 0;
        for (var item in items) {
          if (item.product != null && item.product!.status == 'active') {
            subtotal += item.product!.price;
          }
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(AppSpacing.md),
                cacheExtent: 700,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final product = item.product;

                  if (product == null) return SizedBox.shrink();

                  final isAvailable = product.status == 'active';

                  return AppGlassCard(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: context.colors.surfaceHighlight,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: product.images.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.images.first.imageUrl,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 160,
                                  memCacheHeight: 160,
                                  fadeInDuration: Duration.zero,
                                  fadeOutDuration: Duration.zero,
                                  placeholder: (context, url) =>
                                      AppLoadingSkeleton(
                                        width: 80,
                                        height: 80,
                                        borderRadius: 12.0,
                                      ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.broken_image,
                                    color: context.colors.textMuted,
                                  ),
                                )
                              : Icon(
                                  Icons.image_not_supported,
                                  color: context.colors.textMuted,
                                ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isAvailable
                                          ? context.colors.textPrimary
                                          : context.colors.textSecondary,
                                      decoration: isAvailable
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                currencyFormatter.format(product.price),
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(
                                      color: isAvailable
                                          ? context.colors.primary
                                          : context.colors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  if (!isAvailable) ...[
                                    AppStatusBadge(
                                      status: BadgeStatus.error,
                                      label: 'Tidak Tersedia',
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.colors.backgroundDarker,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        product.condition == 'new'
                                            ? 'Baru'
                                            : 'Bekas',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color:
                                                  context.colors.textSecondary,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                  ],
                                  Spacer(),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: actionState.isLoading
                                        ? null
                                        : () {
                                            ref
                                                .read(
                                                  cartActionControllerProvider
                                                      .notifier,
                                                )
                                                .removeFromCart(item.id);
                                          },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom Action Bar
            Container(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border(top: BorderSide(color: context.colors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total Estimasi',
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(color: context.colors.textSecondary),
                          ),
                          Text(
                            currencyFormatter.format(subtotal),
                            style: Theme.of(context).textTheme.titleLarge!
                                .copyWith(color: context.colors.primary),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      label: 'Beli Sekarang',
                      onPressed: subtotal > 0 && !actionState.isLoading
                          ? () {
                              if (items.isNotEmpty) {
                                final activeItems = items
                                    .where((i) => i.product?.status == 'active')
                                    .toList();
                                if (activeItems.isNotEmpty) {
                                  context.push(
                                    '/checkout/product/${activeItems.first.product!.id}',
                                  );
                                }
                              }
                            }
                          : null,
                      isLoading: actionState.isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoading(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(AppSpacing.md),
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: AppGlassCard(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                AppLoadingSkeleton(width: 80, height: 80, borderRadius: 12.0),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppLoadingSkeleton(width: 150, height: 16),
                      SizedBox(height: 8),
                      AppLoadingSkeleton(width: 100, height: 14),
                      SizedBox(height: 12),
                      AppLoadingSkeleton(
                        width: 60,
                        height: 24,
                        borderRadius: 12.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
