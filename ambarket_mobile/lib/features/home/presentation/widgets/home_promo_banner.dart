import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/premium_promo_card.dart';

class HomePromoBanner extends StatelessWidget {
  final bool enableAnimation;

  const HomePromoBanner({super.key, this.enableAnimation = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: PremiumPromoCard(
        title: 'Promo Akhir Pekan',
        subtitle: 'Klaim voucher dan hemat saat checkout.',
        label: 'Promo Terbatas',
        ctaText: 'Klaim',
        icon: Icons.local_shipping_rounded,
        enableAnimation: enableAnimation,
        onPressed: () {
          context.push('/vouchers');
        },
      ),
    );
  }
}
