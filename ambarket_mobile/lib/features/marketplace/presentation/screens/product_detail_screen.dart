import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/marketplace_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:ambarket_mobile/features/offer/presentation/widgets/make_offer_dialog.dart';
import 'package:ambarket_mobile/features/chat/presentation/providers/chat_provider.dart';
import 'package:ambarket_mobile/features/review/presentation/providers/review_provider.dart';
import 'package:ambarket_mobile/features/review/presentation/widgets/rating_stars.dart';
import 'package:ambarket_mobile/features/report/presentation/widgets/report_dialog.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productAsync = ref.watch(productDetailProvider(productId));
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share feature coming soon')));
            },
          ),
          if (user != null) 
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report_product') {
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
                  value: 'report_product',
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
          final primaryImage = product.images.where((img) => img.isPrimary).firstOrNull ?? product.images.firstOrNull;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Section
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: primaryImage != null
                      ? CachedNetworkImage(
                          imageUrl: primaryImage.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(child: Icon(Icons.broken_image, size: 64)),
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(child: Icon(Icons.image, size: 64)),
                        ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isWishlisted ? Icons.favorite : Icons.favorite_border,
                              color: isWishlisted ? Colors.red : theme.colorScheme.onSurface,
                            ),
                            onPressed: () async {
                              try {
                                await ref.read(wishlistProductIdsProvider.notifier).toggleWishlist(product.id);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        currencyFormatter.format(product.price),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _buildChip(theme, 'Kondisi: ${_mapCondition(product.condition)}'),
                          if (product.isNegotiable) ...[
                            const SizedBox(width: AppSpacing.sm),
                            _buildChip(theme, 'Bisa Nego'),
                          ]
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Detail Section
                      Text(
                        'Deskripsi', 
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        product.description, 
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Info List
                      if ((product.brand?.isNotEmpty ?? false))
                        _buildInfoRow(theme, 'Merek', product.brand!),
                      _buildInfoRow(theme, 'Lokasi', product.location),
                      if ((product.defects?.isNotEmpty ?? false))
                        _buildInfoRow(theme, 'Minus/Cacat', product.defects!),
                      if ((product.completeness?.isNotEmpty ?? false))
                        _buildInfoRow(theme, 'Kelengkapan', product.completeness!),
                      if ((product.usageDuration?.isNotEmpty ?? false))
                        _buildInfoRow(theme, 'Lama Pemakaian', product.usageDuration!),

                      const SizedBox(height: AppSpacing.xl),
                      // Seller Placeholder
                      Consumer(
                        builder: (context, ref, child) {
                          final ratingAsync = ref.watch(sellerRatingSummaryProvider(product.sellerId));
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer),
                            ),
                            title: const Text('Penjual'),
                            subtitle: ratingAsync.when(
                              data: (summary) {
                                if (summary.totalReviews == 0) return const Text('Belum ada ulasan');
                                return Row(
                                  children: [
                                    RatingStars(rating: summary.averageRating.round(), size: 14),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text('${summary.averageRating.toStringAsFixed(1)} (${summary.totalReviews})', style: const TextStyle(fontSize: 12)),
                                  ],
                                );
                              },
                              loading: () => const Text('Memuat ulasan...'),
                              error: (e, st) => const Text('Gagal memuat ulasan'),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  onPressed: () {},
                                  child: const Text('Profil'),
                                ),
                                if (user != null && user.id != product.sellerId) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  IconButton(
                                    icon: const Icon(Icons.report_problem_outlined, size: 20, color: Colors.grey),
                                    onPressed: () {
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
                                ]
                              ],
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: AppSpacing.xxl * 2), // Spacing for bottom bar
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: productAsync.hasValue ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    final product = productAsync.value;
                    if (product == null) return const SizedBox.shrink();
                    
                    bool isOwner = user?.id == product.sellerId;
                    
                    return OutlinedButton(
                      onPressed: isOwner ? null : () async {
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
                      },
                      child: const Text('Chat Penjual'),
                    );
                  }
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final product = productAsync.value;
                    if (product == null) return const SizedBox.shrink();

                    bool isOwner = user?.id == product.sellerId;
                    bool isActive = product.status == 'active';
                    bool isNegotiable = product.isNegotiable;

                    String? disabledReason;
                    if (isOwner) {
                      disabledReason = 'Produk milik Anda';
                    } else if (!isActive) {
                      disabledReason = 'Produk tidak aktif';
                    } else if (!isNegotiable) {
                      disabledReason = 'Harga pas / tidak bisa ditawar';
                    }

                    return ElevatedButton(
                      onPressed: disabledReason != null ? () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(disabledReason!)));
                      } : () {
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login terlebih dahulu')));
                          return;
                        }
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (ctx) => MakeOfferDialog(
                            productId: product.id,
                            sellerId: product.sellerId,
                            originalPrice: product.price,
                            productName: product.title,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: disabledReason != null ? Colors.grey : theme.colorScheme.primary,
                      ),
                      child: const Text('Tawar Harga'),
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ) : null,
    );
  }

  Widget _buildChip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _mapCondition(String condition) {
    switch (condition) {
      case 'like_new': return 'Like New / Seperti Baru';
      case 'good': return 'Good / Baik';
      case 'fair': return 'Fair / Cukup';
      case 'need_repair': return 'Need Repair / Perlu Perbaikan';
      default: return condition;
    }
  }
}
