import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ambarket_scaffold.dart';
import '../../../../core/widgets/premium_surface_card.dart';
import '../../../../core/widgets/premium_empty_state.dart';
import '../../../profile/presentation/providers/voucher_provider.dart';
import '../providers/admin_voucher_provider.dart';

class AdminVouchersScreen extends ConsumerWidget {
  const AdminVouchersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vouchersAsync = ref.watch(adminVoucherProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return AmbarketScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Manajemen Kupon',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/vouchers/new'),
        child: const Icon(Icons.add),
      ),
      body: vouchersAsync.when(
        data: (vouchers) {
          if (vouchers.isEmpty) {
            return const PremiumEmptyState(
              icon: Icons.local_activity_outlined,
              title: 'Belum ada kupon',
              message: 'Belum ada kupon yang dibuat.',
            );
          }
          return ListView.builder(
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
                child: PremiumSurfaceCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              voucher.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Switch(
                            value: voucher.isActive,
                            onChanged: (value) async {
                              await ref
                                  .read(adminVoucherProvider.notifier)
                                  .toggleVoucherStatus(voucher.id, value);
                              ref.invalidate(voucherProvider);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kode: ${voucher.code}',
                        style: TextStyle(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(voucher.description),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Min. Beli: ${currencyFormatter.format(voucher.minPurchase)}',
                          ),
                          Text(
                            voucher.type == 'percent'
                                ? 'Diskon: ${voucher.discountPercent}%'
                                : 'Diskon: ${currencyFormatter.format(voucher.flatDiscount)}',
                          ),
                        ],
                      ),
                      if (voucher.expiresAt != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Berakhir: ${DateFormat('dd MMM yyyy, HH:mm').format(voucher.expiresAt!)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
