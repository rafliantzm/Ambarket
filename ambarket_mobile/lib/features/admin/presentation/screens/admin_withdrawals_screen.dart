import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ambarket_scaffold.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/premium_empty_state.dart';
import '../../../../core/widgets/premium_status_badge.dart';
import '../../../../core/widgets/premium_surface_card.dart';
import '../../../wallet/domain/models/seller_withdrawal_model.dart';
import '../providers/admin_provider.dart';

class AdminWithdrawalsScreen extends ConsumerWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withdrawalsAsync = ref.watch(adminWithdrawalsProvider);
    final isActionLoading = ref.watch(
      adminActionControllerProvider.select((state) => state.isLoading),
    );

    return AmbarketScaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text(
          'Penarikan Dana',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: withdrawalsAsync.when(
        data: (state) {
          if (state.items.isEmpty) {
            return PremiumEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Belum ada pengajuan',
              message: 'Pengajuan penarikan dana seller akan muncul di sini.',
              buttonText: 'Muat Ulang',
              onButtonPressed: () => ref.refresh(adminWithdrawalsProvider),
            );
          }

          return RefreshIndicator(
            color: context.colors.primary,
            backgroundColor: context.colors.surface,
            onRefresh: () async => ref.refresh(adminWithdrawalsProvider.future),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >
                    notification.metrics.maxScrollExtent - 300) {
                  ref.read(adminWithdrawalsProvider.notifier).loadMore();
                }
                return false;
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                cacheExtent: 900,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: state.items.length + (state.hasMore ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: AppLoadingSkeleton(
                        width: double.infinity,
                        height: 88,
                      ),
                    );
                  }
                  return _WithdrawalCard(
                    withdrawal: state.items[index],
                    isActionLoading: isActionLoading,
                  );
                },
              ),
            ),
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemBuilder: (context, index) =>
              const AppLoadingSkeleton(width: double.infinity, height: 132),
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.sm),
          itemCount: 4,
        ),
        error: (error, stack) => AppErrorState(
          message: ErrorMapper.getFriendlyMessage(error),
          onRetry: () => ref.refresh(adminWithdrawalsProvider),
        ),
      ),
    );
  }
}

class _WithdrawalCard extends ConsumerWidget {
  const _WithdrawalCard({
    required this.withdrawal,
    required this.isActionLoading,
  });

  final SellerWithdrawalModel withdrawal;
  final bool isActionLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');
    final isPending = withdrawal.status == 'pending';

    return PremiumSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currencyFormatter.format(withdrawal.amount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormatter.format(withdrawal.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(withdrawal.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'Seller ID', value: withdrawal.sellerId),
          _InfoRow(label: 'Bank', value: withdrawal.bankName),
          _InfoRow(label: 'No. Rekening', value: withdrawal.accountNumber),
          _InfoRow(label: 'Pemilik Rekening', value: withdrawal.accountHolder),
          if ((withdrawal.note ?? '').trim().isNotEmpty)
            _InfoRow(label: 'Catatan', value: withdrawal.note!.trim()),
          if (isPending) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isActionLoading
                        ? null
                        : () => _rejectWithdrawal(context, ref),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isActionLoading
                        ? null
                        : () => _approveWithdrawal(context, ref),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Setujui'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _approveWithdrawal(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(adminActionControllerProvider.notifier)
        .approveWithdrawal(withdrawal.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Penarikan disetujui.' : 'Gagal menyetujui penarikan.',
        ),
      ),
    );
  }

  Future<void> _rejectWithdrawal(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(adminActionControllerProvider.notifier)
        .rejectWithdrawal(withdrawal.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Penarikan ditolak.' : 'Gagal menolak penarikan.'),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'pending') {
      return const PremiumStatusBadge(
        label: 'Pending',
        status: PremiumBadgeStatus.warning,
      );
    }
    if (status == 'approved_dummy') {
      return const PremiumStatusBadge(
        label: 'Disetujui',
        status: PremiumBadgeStatus.success,
      );
    }
    if (status == 'rejected_dummy') {
      return const PremiumStatusBadge(
        label: 'Ditolak',
        status: PremiumBadgeStatus.error,
      );
    }
    return PremiumStatusBadge(label: status);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
