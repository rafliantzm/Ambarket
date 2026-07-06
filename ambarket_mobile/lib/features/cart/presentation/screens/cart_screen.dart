import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
    final cartState = ref.watch(cartItemsProvider);
    final actionState = ref.watch(cartActionControllerProvider);

    ref.listen(cartActionControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error, // Replaced errorColor with error if it exists. AppColors uses accent usually or error. Let's use Colors.red
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
      ),
      body: cartState.when(
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
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final product = item.product;
                    
                    if (product == null) return const SizedBox.shrink();

                    final isAvailable = product.status == 'active';

                    return AppGlassCard(
                      // margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: product.images.isNotEmpty
                                ? Image.network(
                                    product.images.first.imageUrl,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image_not_supported, color: Colors.white54),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isAvailable ? Colors.white : Colors.white54,
                                    decoration: isAvailable ? null : TextDecoration.lineThrough,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormatter.format(product.price),
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: isAvailable ? AppColors.accent : Colors.white54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (!isAvailable) ...[
                                      const AppStatusBadge(
                                        status: BadgeStatus.error,
                                        label: 'Tidak Tersedia',
                                      ),
                                    ] else ...[
                                      AppStatusBadge(
                                        status: product.condition == 'new' 
                                            ? BadgeStatus.success 
                                            : BadgeStatus.warning,
                                        label: product.condition == 'new' ? 'Baru' : 'Bekas',
                                      ),
                                    ],
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: actionState.isLoading ? null : () {
                                        ref.read(cartActionControllerProvider.notifier).removeFromCart(item.id);
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
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total Estimasi',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70),
                            ),
                            Text(
                              currencyFormatter.format(subtotal),
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                      AppButton(label: 'Beli Sekarang',
                        onPressed: subtotal > 0 && !actionState.isLoading ? () {
                          // Simple dummy checkout flow: we just checkout all active items.
                          // Real apps would allow selecting items.
                          // However since checkout page is product specific now, we can only checkout 1 product. Let's just use the first item for demo.
                          if (items.isNotEmpty) {
                            final activeItems = items.where((i) => i.product?.status == 'active').toList();
                            if (activeItems.isNotEmpty) {
                              context.push('/checkout/product/${activeItems.first.product!.id}'); 
                            }
                          }
                        } : null,
                        isLoading: actionState.isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 3,
      itemBuilder: (context, index) {
        return AppGlassCard(
          // margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const AppLoadingSkeleton(width: 80, height: 80, borderRadius: 12.0),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    AppLoadingSkeleton(width: 150, height: 16),
                    SizedBox(height: 8),
                    AppLoadingSkeleton(width: 100, height: 14),
                    SizedBox(height: 12),
                    AppLoadingSkeleton(width: 60, height: 24, borderRadius: 12.0),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

