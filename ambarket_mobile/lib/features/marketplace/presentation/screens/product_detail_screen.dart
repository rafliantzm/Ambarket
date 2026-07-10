import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_background.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:ambarket_mobile/features/offer/presentation/widgets/make_offer_dialog.dart';
import 'package:ambarket_mobile/features/offer/domain/models/offer_model.dart';
import 'package:ambarket_mobile/features/offer/presentation/providers/offer_provider.dart';

import 'package:ambarket_mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:ambarket_mobile/features/chat/presentation/providers/chat_provider.dart';
import '../../../report/presentation/widgets/report_dialog.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/product_detail/product_image_gallery.dart';
import '../widgets/product_detail/product_header_section.dart';
import '../widgets/product_detail/product_seller_card.dart';
import '../widgets/product_detail/product_info_section.dart';
import '../widgets/product_detail/product_safety_section.dart';
import '../widgets/product_detail/product_bottom_action_bar.dart';
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
          title: Text('Detail Produk'),
          actions: [
            IconButton(
              icon: Icon(Icons.share, color: context.colors.textPrimary),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fitur bagikan segera hadir!')),
                );
              },
            ),
            if (user != null)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: context.colors.textPrimary),
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
                  PopupMenuItem(
                    value: 'report',
                    child: Text('Laporkan Produk'),
                  ),
                ],
              ),
          ],
        ),
        body: productAsync.when(
          data: (product) {
            final validOfferState = ref.watch(
              validAcceptedOfferProvider(product.id),
            );
            final validOffer = validOfferState.value;
            final isOwner = user?.id == product.sellerId;

            void handleChat() async {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Silakan login terlebih dahulu')),
                );
                return;
              }
              try {
                final chat = await ref
                    .read(chatActionControllerProvider.notifier)
                    .createOrGetConversation(
                      product.id,
                      user.id,
                      product.sellerId,
                    );
                if (context.mounted) {
                  context.push('/chats/${chat.id}');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal membuat chat: $e')),
                  );
                }
              }
            }

            void handleOffer() {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Silakan login terlebih dahulu')),
                );
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Silakan login terlebih dahulu')),
                );
                return;
              }
              ref
                  .read(cartActionControllerProvider.notifier)
                  .addToCart(product.id, 1)
                  .then((_) {
                    if (context.mounted &&
                        !ref.read(cartActionControllerProvider).hasError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Produk ditambahkan ke keranjang.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  });
            }

            void handleBuy() {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Silakan login terlebih dahulu')),
                );
                return;
              }
              context.push('/checkout/product/${product.id}');
            }

            if (isDesktop) {
              return _buildDesktopLayout(
                context,
                product: product,
                validOffer: validOffer,
                isOwner: isOwner,
                isWishlisted: false,
                onToggleWishlist: () {},
                onChatPressed: handleChat,
                onOfferPressed: handleOffer,
                onCartPressed: handleAddToCart,
                onBuyPressed: handleBuy,
              );
            }

            return _buildMobileLayout(
              context,
              product: product,
              validOffer: validOffer,
              isOwner: isOwner,
              isWishlisted: false,
              onToggleWishlist: () {},
              onChatPressed: handleChat,
              onOfferPressed: handleOffer,
              onCartPressed: handleAddToCart,
              onBuyPressed: handleBuy,
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: context.colors.primary),
          ),
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
    required OfferModel? validOffer,
    required bool isOwner,
    required bool isWishlisted,
    required VoidCallback onToggleWishlist,
    required VoidCallback onChatPressed,
    required VoidCallback onOfferPressed,
    required VoidCallback onCartPressed,
    required VoidCallback onBuyPressed,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 64, vertical: AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Image Gallery
              Expanded(
                flex: 5,
                child: ProductImageGallery(images: product.images),
              ),
              SizedBox(width: AppSpacing.xxl),
              // Right Column: Details & Actions
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProductHeaderSection(
                      product: product,
                      validOffer: validOffer,
                    ),
                    SizedBox(height: AppSpacing.xl),
                    ProductSellerCard(
                      sellerId: product.sellerId,
                      isOwner: isOwner,
                      onVisitProfile: () {
                        context.push('/seller-profile/${product.sellerId}');
                      },
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
                    SizedBox(height: AppSpacing.xl),
                    AppGlassCard(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      variant: AppGlassCardVariant.elevated,
                      child: _ExpandableDescription(
                        description: product.description,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    AppGlassCard(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      variant: AppGlassCardVariant.elevated,
                      child: ProductInfoSection(product: product),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    ProductSafetySection(),
                    SizedBox(height: AppSpacing.xxl),
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
    required OfferModel? validOffer,
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 140,
          ), // Space for sticky bottom bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProductImageGallery(images: product.images),
              SizedBox(height: AppSpacing.md),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ProductHeaderSection(
                  product: product,
                  validOffer: validOffer,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ProductSellerCard(
                  sellerId: product.sellerId,
                  isOwner: isOwner,
                  onVisitProfile: () {
                    context.push('/seller-profile/${product.sellerId}');
                  },
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
              SizedBox(height: AppSpacing.md),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: AppGlassCard(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  variant: AppGlassCardVariant.elevated,
                  child: _ExpandableDescription(
                    description: product.description,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: AppGlassCard(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  variant: AppGlassCardVariant.elevated,
                  child: ProductInfoSection(product: product),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              ProductSafetySection(),
              SizedBox(height: AppSpacing.xxl),
              ProductRelatedSection(product: product),
            ],
          ),
        ),
        // Sticky Bottom Bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ProductBottomActionBar(
            product: product,
            isOwner: isOwner,
            isWishlisted: isWishlisted,
            onToggleWishlist: onToggleWishlist,
            onChatPressed: onChatPressed,
            onOfferPressed: onOfferPressed,
            onCartPressed: onCartPressed,
            onBuyPressed: onBuyPressed,
          ),
        ),
      ],
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  final String description;
  const _ExpandableDescription({required this.description});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = widget.description.trim().isEmpty;
    final text = isEmpty
        ? 'Penjual belum menambahkan deskripsi detail.'
        : widget.description;

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(
          text: text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isEmpty
                ? context.colors.textSecondary
                : context.colors.textPrimary,
            height: 1.5,
          ),
        );

        final tp = TextPainter(
          text: span,
          maxLines: 3,
          textDirection: TextDirection.ltr,
        );

        tp.layout(maxWidth: constraints.maxWidth);
        final isLongText = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deskripsi Produk',
              style: theme.textTheme.titleMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text.rich(
              span,
              maxLines: _isExpanded ? null : 3,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
            if (isLongText) ...[
              SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? 'Sembunyikan' : 'Selengkapnya',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: context.colors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
