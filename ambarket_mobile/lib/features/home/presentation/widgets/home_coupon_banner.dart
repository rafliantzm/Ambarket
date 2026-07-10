import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/premium_promo_card.dart';
import '../../../profile/presentation/providers/voucher_provider.dart';
import '../../../order/domain/models/checkout_models.dart';

class HomeCouponBanner extends ConsumerWidget {
  const HomeCouponBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voucherAsync = ref.watch(voucherProvider);

    return voucherAsync.when(
      data: (vouchers) {
        // Find the first active, unclaimed, and not expired voucher
        final VoucherModel? activeVoucher = vouchers.where((v) {
          final isNotExpired =
              v.expiresAt == null || v.expiresAt!.isAfter(DateTime.now());
          return !v.isClaimed && v.isActive && isNotExpired;
        }).firstOrNull;

        if (activeVoucher == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: PremiumPromoCard(
            title: activeVoucher.code,
            subtitle: activeVoucher.description,
            label: 'Kupon Spesial',
            ctaText: 'Klaim',
            icon: Icons.confirmation_number_outlined,
            enableAnimation: false,
            onPressed: () {
              context.push('/vouchers');
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, st) => const SizedBox.shrink(),
    );
  }
}
