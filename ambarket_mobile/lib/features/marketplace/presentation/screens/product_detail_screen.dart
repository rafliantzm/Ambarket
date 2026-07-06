import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_background.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:ambarket_mobile/features/offer/presentation/widgets/make_offer_dialog.dart';

import 'package:ambarket_mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:ambarket_mobile/features/chat/presentation/providers/chat_provider.dart';
import '../../../report/presentation/widgets/report_dialog.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/product_detail/product_image_gallery.dart';
import '../widgets/product_detail/product_purchase_panel.dart';
import '../widgets/product_detail/product_seller_card.dart';
import '../widgets/product_detail/product_info_section.dart';
import '../widgets/product_detail/product_condition_section.dart';
import '../widgets/product_detail/product_safety_section.dart';
import '../widgets/product_detail/product_related_section.dart';
import '../../domain/models/product_model.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final user = ref.watch(currentUserProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return AppAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Detail Produk'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: AppColors.textPrimary),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur bagikan segera hadir!')));
              },
            ),
            if (user != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
                onSelected: (value) {
                  if (value == 'report') {
                    showDialog(
                      context: context,
                      builder: (context) => ReportDialog(
                        targetType: 'product',
                        targetId: productId,
                        title: 'Produk',
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Text('Laporkan Produk'),
                  ),
                ],
              ),
          ],
        ),
        body: productAsync.when(
          data: (product) {
            final wishlistsState = ref.watch(wishlistProductIdsProvider);
            final isWishlisted = wishlistsState.maybeWhen(
              data: (wishlists) => wishlists.contains(product.id),
              orElse: () => false,
            );
            final isOwner = user?.id == product.sellerId;

            void handleToggleWishlist() async {
              try {
                await ref.read(wishlistProductIdsProvider.notifier).toggleWishlist(product.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                  );
                }
              }
            }

            void handleChat() async {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login terlebih dahulu')));
                return;
              }
              try {
                final chat = await ref.read(chatActionControllerProvider.notifier)
                    .createOrGetConversation(product.id, user.id, product.sellerId);
                if (context.mounted) {
                  context.push('/chats/${chat.id}');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat chat: $e')));
                }
              }
            }

            void handleOffer() {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login terlebih dahulu')));
                return;
              }
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => MakeOfferDialog(
                  productId: product.id,
                  sellerId: product.sellerId,
                  originalPrice: product.price,
                  productName: product.title,
                ),
              );
            }

            void handleAddToCart() {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login terlebih dahulu')));
                return;
              }
              ref.read(cartActionControllerProvider.notifier).addToCart(product.id, 1).then((_) {
                if (context.mounted && !ref.read(cartActionControllerProvider).hasError) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Produk ditambahkan ke keranjang.'),
                    backgroundColor: Colors.green,
                  ));
                }
              });
            }

            void handleBuy() {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login terlebih dahulu')));
                return;
              }
              context.push('/checkout/product/${product.id}');
            }

            if (isDesktop) {
              return _buildDesktopLayout(
                context,
                product: product,
                isOwner: isOwner,
                isWishlisted: isWishlisted,
                onToggleWishlist: handleToggleWishlist,
                onChatPressed: handleChat,
                onOfferPressed: handleOffer,
                onCartPressed: handleAddToCart,
                onBuyPressed: handleBuy,
              );
            }

              return _buildMobileLayout(
                context,
                product: product,
                isOwner: isOwner,
                isWishlisted: isWishlisted,
                onToggleWishlist: handleToggleWishlist,
                onChatPressed: handleChat,
                onOfferPressed: handleOffer,
                onCartPressed: handleAddToCart,
                onBuyPressed: handleBuy,
              );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, st) => Center(
            child: AppErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(productDetailProvider(productId)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context, {
    required ProductModel product,
    required bool isOwner,
    required bool isWishlisted,
    required VoidCallback onToggleWishlist,
    required VoidCallback onChatPressed,
    required VoidCallback onOfferPressed,
    required VoidCallback onCartPressed,
    required VoidCallback onBuyPressed,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Image Gallery
              Expanded(
                flex: 5,
                child: ProductImageGallery(images: product.images),
              ),
              const SizedBox(width: AppSpacing.xxl),
              // Right Column: Details & Actions
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProductPurchasePanel(
                      product: product,
                      isOwner: isOwner,
                      isWishlisted: isWishlisted,
                      onToggleWishlist: onToggleWishlist,
                      onChatPressed: onChatPressed,
                      onOfferPressed: onOfferPressed,
                      onCartPressed: onCartPressed,
                      onBuyPressed: onBuyPressed,
                      isMobile: false,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ProductSellerCard(
                      sellerId: product.sellerId,
                      isOwner: isOwner,
                      onVisitProfile: () {},
                      onReport: () {
                        showDialog(
                          context: context,
                          builder: (context) => ReportDialog(
                            targetType: 'user',
                            targetId: product.sellerId,
                            title: 'Penjual',
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildDescription(context, product.description),
                    const SizedBox(height: AppSpacing.xl),
                    ProductInfoSection(product: product),
                    const SizedBox(height: AppSpacing.xl),
                    ProductConditionSection(product: product),
                    const SizedBox(height: AppSpacing.xl),
                    const ProductSafetySection(),
                    const SizedBox(height: AppSpacing.xxl),
                    ProductRelatedSection(product: product),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context, {
    required ProductModel product,
    required bool isOwner,
    required bool isWishlisted,
    required VoidCallback onToggleWishlist,
    required VoidCallback onChatPressed,
    required VoidCallback onOfferPressed,
    required VoidCallback onCartPressed,
    required VoidCallback onBuyPressed,
  }) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120), // Space for sticky bottom bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProductImageGallery(images: product.images),
              ProductPurchasePanel(
                product: product,
                isOwner: isOwner,
                isWishlisted: isWishlisted,
                onToggleWishlist: onToggleWishlist,
                onChatPressed: onChatPressed,
                onOfferPressed: onOfferPressed,
                onCartPressed: onCartPressed,
                onBuyPressed: onBuyPressed,
                isMobile: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ProductSellerCard(
                  sellerId: product.sellerId,
                  isOwner: isOwner,
                  onVisitProfile: () {},
                  onReport: () {
                    showDialog(
                      context: context,
                      builder: (context) => ReportDialog(
                        targetType: 'user',
                        targetId: product.sellerId,
                        title: 'Penjual',
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _buildDescription(context, product.description),
              ),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ProductInfoSection(product: product),
              ),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ProductConditionSection(product: product),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ProductSafetySection(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: ProductRelatedSection(product: product),
              ),
            ],
          ),
        ),
        // Sticky Bottom Bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildMobileBottomBar(
            context,
            product: product,
            isOwner: isOwner,
            onChatPressed: onChatPressed,
            onOfferPressed: onOfferPressed,
            onCartPressed: onCartPressed,
            onBuyPressed: onBuyPressed,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deskripsi Produk',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          description.trim().isEmpty ? 'Penjual belum menambahkan deskripsi detail.' : description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: description.trim().isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBottomBar(
    BuildContext context, {
    required ProductModel product,
    required bool isOwner,
    required VoidCallback onChatPressed,
    required VoidCallback onOfferPressed,
    required VoidCallback onCartPressed,
    required VoidCallback onBuyPressed,
  }) {
    bool isActive = product.status == 'active';
    bool isNegotiable = product.isNegotiable;

    String? offerDisabledReason;
    if (isOwner) {
      offerDisabledReason = 'Produk milik Anda';
    } else if (!isActive) {
      offerDisabledReason = 'Produk tidak aktif';
    } else if (!isNegotiable) {
      offerDisabledReason = 'Harga pas / tidak bisa ditawar';
    }

    String? buyDisabledReason;
    if (isOwner) {
      buyDisabledReason = 'Produk milik Anda';
    } else if (!isActive) {
      buyDisabledReason = 'Produk tidak aktif';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarker.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: isOwner ? null : onChatPressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.borderStrong),
                  foregroundColor: AppColors.textPrimary,
                ),
                child: const Icon(Icons.chat_bubble_outline),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: buyDisabledReason != null
                    ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(buyDisabledReason!)))
                    : onCartPressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.borderStrong),
                  foregroundColor: AppColors.textPrimary,
                ),
                child: const Icon(Icons.add_shopping_cart),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: offerDisabledReason != null
                    ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(offerDisabledReason!)))
                    : onOfferPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: offerDisabledReason != null ? AppColors.surfaceHighlight : AppColors.primary,
                  foregroundColor: offerDisabledReason != null ? AppColors.textMuted : AppColors.background,
                ),
                child: const Text('Tawar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: buyDisabledReason != null
                    ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(buyDisabledReason!)))
                    : onBuyPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: buyDisabledReason != null ? AppColors.surfaceHighlight : AppColors.accent,
                  foregroundColor: buyDisabledReason != null ? AppColors.textMuted : Colors.white,
                ),
                child: const Text('Beli', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



