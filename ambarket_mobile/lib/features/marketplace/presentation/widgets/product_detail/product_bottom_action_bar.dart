import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/models/product_model.dart';

class ProductBottomActionBar extends StatelessWidget {
  final ProductModel product;
  final bool isOwner;
  final bool isWishlisted;
  final VoidCallback onToggleWishlist;
  final VoidCallback onChatPressed;
  final VoidCallback onOfferPressed;
  final VoidCallback onCartPressed;
  final VoidCallback onBuyPressed;

  const ProductBottomActionBar({
    super.key,
    required this.product,
    required this.isOwner,
    required this.isWishlisted,
    required this.onToggleWishlist,
    required this.onChatPressed,
    required this.onOfferPressed,
    required this.onCartPressed,
    required this.onBuyPressed,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = product.status == 'active';
    bool isNegotiable = product.isNegotiable;

    String? chatDisabledReason;
    if (isOwner) {
      chatDisabledReason = 'Produk milik Anda';
    }

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
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 480;
          final iconOnlySecondary = constraints.maxWidth < 480;
          final primaryLabel = compact ? 'Beli' : 'Beli / Keranjang';
          final gap = compact ? AppSpacing.xs : AppSpacing.sm;

          Widget secondaryButton({
            required IconData icon,
            required String label,
            required String? disabledReason,
            required VoidCallback onPressed,
          }) {
            final button = OutlinedButton(
              onPressed: disabledReason != null
                  ? () => _showTooltip(context, disabledReason)
                  : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: disabledReason != null
                    ? context.colors.textMuted
                    : context.colors.textPrimary,
                side: BorderSide(
                  color: disabledReason != null
                      ? context.colors.border
                      : context.colors.borderStrong,
                ),
                padding: EdgeInsets.symmetric(
                  vertical: compact ? 12 : 14,
                  horizontal: iconOnlySecondary ? 12 : 14,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: compact ? 20 : 24),
                  if (!iconOnlySecondary) ...[
                    SizedBox(width: 6),
                    Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            );

            return Tooltip(
              message: label,
              child: SizedBox(
                width: iconOnlySecondary ? 50 : null,
                child: button,
              ),
            );
          }

          return Row(
            children: [
              secondaryButton(
                icon: CupertinoIcons.chat_bubble_text,
                label: 'Chat',
                disabledReason: chatDisabledReason,
                onPressed: onChatPressed,
              ),
              SizedBox(width: gap),
              secondaryButton(
                icon: Icons.local_offer_outlined,
                label: 'Tawar',
                disabledReason: offerDisabledReason,
                onPressed: onOfferPressed,
              ),
              SizedBox(width: gap),
              Expanded(
                child: ElevatedButton(
                  onPressed: buyDisabledReason != null
                      ? () => _showTooltip(context, buyDisabledReason!)
                      : () {
                          _showPurchaseOptions(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buyDisabledReason != null
                        ? context.colors.surfaceHighlight
                        : context.colors.primary,
                    foregroundColor: buyDisabledReason != null
                        ? context.colors.textMuted
                        : Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: compact ? 12 : 14,
                      horizontal: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_shopping_cart_rounded),
                        SizedBox(width: 8),
                        Text(
                          primaryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTooltip(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showPurchaseOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pilih Tindakan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onCartPressed();
                  },
                  icon: Icon(Icons.add_shopping_cart_rounded),
                  label: Text('Masukkan Keranjang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.surfaceHighlight,
                    foregroundColor: context.colors.primary,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onBuyPressed();
                  },
                  icon: Icon(Icons.shopping_bag_rounded),
                  label: Text('Beli Langsung'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 16),
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
