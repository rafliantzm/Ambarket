import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ambarket_scaffold.dart';
import '../../../../core/widgets/premium_surface_card.dart';
import '../../../../core/widgets/premium_button.dart';
import '../../../../core/widgets/premium_status_badge.dart';
import '../../../../core/widgets/premium_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/error/error_mapper.dart';
import '../providers/seller_wallet_provider.dart';
import '../widgets/dummy_withdrawal_dialog.dart';
import '../../domain/models/seller_wallet_summary.dart';

class SellerWalletScreen extends ConsumerWidget {
  const SellerWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return AmbarketScaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Wallet Seller',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pantau saldo seller dan riwayat penarikan dana.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDisclaimer(theme),
                  const SizedBox(height: AppSpacing.lg),
                  _buildWalletSummarySection(context, ref, isDesktop),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Riwayat Penarikan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.sm)),
          _buildWithdrawalsList(context, ref),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 100),
          ), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildDisclaimer(ThemeData theme) {
    return PremiumSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Saldo diambil dari data wallet seller. Penarikan dana masih simulasi untuk kebutuhan MVP dan tidak memproses uang asli.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSummarySection(
    BuildContext context,
    WidgetRef ref,
    bool isDesktop,
  ) {
    final summaryAsync = ref.watch(sellerWalletSummaryProvider);

    return summaryAsync.when(
      data: (summary) {
        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildSummaryGrid(context, summary, crossAxisCount: 2),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 1, child: _buildWithdrawalCTA(context, summary)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildSummaryGrid(context, summary, crossAxisCount: 2),
              const SizedBox(height: AppSpacing.md),
              _buildWithdrawalCTA(context, summary),
            ],
          );
        }
      },
      loading: () => GridView.count(
        crossAxisCount: isDesktop ? 4 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.5,
        children: List.generate(
          4,
          (index) => const AppLoadingSkeleton(
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
      error: (error, stack) => AppErrorState(
        message: ErrorMapper.getFriendlyMessage(error),
        onRetry: () => ref.refresh(sellerWalletSummaryProvider),
      ),
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context,
    SellerWalletSummary summary, {
    required int crossAxisCount,
  }) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Saldo Tersedia',
          currencyFormatter.format(summary.availableBalance),
          Icons.account_balance_wallet,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Pending Settlement',
          currencyFormatter.format(summary.pendingBalance),
          Icons.pending_actions,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Dana Sengketa',
          currencyFormatter.format(summary.disputedBalance),
          Icons.gavel_outlined,
          Colors.redAccent,
        ),
        _buildStatCard(
          context,
          'Total Pendapatan',
          currencyFormatter.format(summary.totalEarning),
          Icons.payments,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Penarikan Pending',
          '${summary.pendingWithdrawalCount}',
          Icons.hourglass_top,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return PremiumSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalCTA(
    BuildContext context,
    SellerWalletSummary summary,
  ) {
    return PremiumSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tarik Dana',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tarik saldo tersedia Anda ke rekening bank tujuan.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          PremiumButton(
            label: 'Ajukan Penarikan Dummy',
            onPressed: summary.availableBalance > 0
                ? () {
                    showDialog(
                      context: context,
                      builder: (_) => DummyWithdrawalDialog(
                        availableBalance: summary.availableBalance,
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalsList(BuildContext context, WidgetRef ref) {
    final withdrawalsAsync = ref.watch(sellerWithdrawalsProvider);
    return withdrawalsAsync.when(
      data: (withdrawals) {
        if (withdrawals.isEmpty) {
          return const SliverToBoxAdapter(
            child: PremiumEmptyState(
              icon: Icons.receipt_long,
              title: 'Belum ada riwayat penarikan',
              message:
                  'Penarikan dana dummy yang Anda ajukan akan muncul di sini.',
            ),
          );
        }

        final currencyFormatter = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp',
          decimalDigits: 0,
        );
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final w = withdrawals[index];
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: PremiumSurfaceCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          currencyFormatter.format(w.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildStatusBadge(w.status),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('${w.bankName} - ${w.accountNumber}'),
                      Text(
                        w.accountHolder,
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (w.note != null && w.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Catatan: ${w.note}',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(w.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }, childCount: withdrawals.length),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: List.generate(
              3,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppLoadingSkeleton(width: double.infinity, height: 80),
              ),
            ),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: AppErrorState(
          message: ErrorMapper.getFriendlyMessage(error),
          onRetry: () => ref.refresh(sellerWithdrawalsProvider),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'pending') {
      return const PremiumStatusBadge(
        label: 'Pending',
        status: PremiumBadgeStatus.warning,
      );
    } else if (status == 'approved_dummy') {
      return const PremiumStatusBadge(
        label: 'Disetujui',
        status: PremiumBadgeStatus.success,
      );
    } else if (status == 'rejected_dummy') {
      return const PremiumStatusBadge(
        label: 'Ditolak',
        status: PremiumBadgeStatus.error,
      );
    }
    return PremiumStatusBadge(label: status);
  }
}
