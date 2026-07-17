import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ambarket_scaffold.dart';
import '../../../../core/widgets/premium_promo_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../providers/voucher_provider.dart';

class VouchersScreen extends ConsumerWidget {
  const VouchersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vouchersAsync = ref.watch(voucherProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return AmbarketScaffold(
      isDesktopConstrained: isDesktop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        title: Text(
          'Kupon Saya',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: vouchersAsync.when(
        data: (vouchers) {
          if (vouchers.isEmpty) {
            return AppEmptyState(
              icon: Icons.local_activity_outlined,
              title: 'Belum ada kupon',
              message:
                  'Saat ini belum ada kupon promo yang tersedia untuk Anda.',
              buttonText: 'Kembali Berbelanja',
              onButtonPressed: () => Navigator.of(context).pop(),
            );
          }
          return RefreshIndicator(
            color: context.colors.primary,
            backgroundColor: context.colors.surface,
            onRefresh: () async {
              ref.invalidate(voucherProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              cacheExtent: 800,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              itemCount: vouchers.length,
              itemBuilder: (context, index) {
                final voucher = vouchers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: PremiumPromoCard(
                    title: voucher.title,
                    subtitle:
                        '${voucher.description}\nMin. belanja ${currencyFormatter.format(voucher.minPurchase)}'
                        '${voucher.expiresAt != null ? '\nBerlaku hingga: ${DateFormat('dd MMM yyyy, HH:mm').format(voucher.expiresAt!)}' : ''}',
                    label:
                        voucher.type == 'percent' && voucher.discountPercent > 0
                        ? 'Diskon ${voucher.discountPercent.toInt()}%'
                        : (voucher.flatDiscount > 0
                              ? 'Potongan ${currencyFormatter.format(voucher.flatDiscount)}'
                              : ''),
                    ctaText: voucher.isClaimed ? 'DIKLAIM' : 'KLAIM',
                    icon: Icons.local_activity_rounded,
                    isClaimed: voucher.isClaimed,
                    onPressed: voucher.isClaimed
                        ? () {}
                        : () async {
                            try {
                              await ref
                                  .read(voucherProvider.notifier)
                                  .claimVoucher(voucher.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Kupon berhasil diklaim!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Gagal klaim kupon.'),
                                  ),
                                );
                              }
                            }
                          },
                  ),
                );
              },
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: TextStyle(color: context.colors.textPrimary),
          ),
        ),
      ),
    );
  }
}
