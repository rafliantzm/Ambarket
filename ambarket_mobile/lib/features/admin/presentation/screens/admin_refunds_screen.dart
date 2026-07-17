import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/premium_empty_state.dart';
import '../../../../core/widgets/premium_status_badge.dart';
import 'package:ambarket_mobile/features/order/domain/models/refund_request_model.dart';
import '../providers/admin_provider.dart';

class AdminRefundsScreen extends ConsumerWidget {
  const AdminRefundsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refundsAsync = ref.watch(adminRefundsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Refund & Sengketa')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminRefundsProvider.future),
        child: refundsAsync.when(
          data: (state) {
            if (state.items.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  const PremiumEmptyState(
                    icon: Icons.gavel_outlined,
                    title: 'Belum ada refund',
                    message:
                        'Pengajuan refund dan sengketa buyer akan muncul di sini.',
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.items.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                return _RefundCard(refund: state.items[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => AppErrorState(
            title: 'Refund Belum Dapat Dimuat',
            message: ErrorMapper.getFriendlyMessage(error),
            onRetry: () => ref.invalidate(adminRefundsProvider),
          ),
        ),
      ),
    );
  }
}

class _RefundCard extends ConsumerWidget {
  const _RefundCard({required this.refund});

  final RefundRequestModel refund;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final date = DateFormat('dd MMM yyyy, HH:mm').format(refund.createdAt);
    final isOpen = refund.isOpen;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    refund.reason,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _statusBadge(refund.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              date,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: AppSpacing.lg),
            _InfoRow(label: 'Order ID', value: refund.orderId),
            _InfoRow(label: 'Buyer ID', value: refund.buyerId),
            _InfoRow(label: 'Seller ID', value: refund.sellerId),
            _InfoRow(
              label: 'Diminta',
              value: currency.format(refund.requestedAmount),
            ),
            if (refund.approvedAmount > 0)
              _InfoRow(
                label: 'Disetujui',
                value: currency.format(refund.approvedAmount),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(refund.description, style: theme.textTheme.bodyMedium),
            if (refund.evidenceUrls.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Bukti: ${refund.evidenceUrls.length} lampiran/link',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if ((refund.adminNote ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Catatan admin: ${refund.adminNote}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (isOpen) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton(
                    onPressed: () => _resolve(
                      context,
                      ref,
                      decision: 'approved',
                      approvedAmount: refund.requestedAmount,
                    ),
                    child: const Text('Refund Penuh'),
                  ),
                  OutlinedButton(
                    onPressed: () => _showPartialDialog(context, ref),
                    child: const Text('Refund Sebagian'),
                  ),
                  TextButton(
                    onPressed: () =>
                        _resolve(context, ref, decision: 'rejected'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    child: const Text('Tolak'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  PremiumStatusBadge _statusBadge(String status) {
    if (status == 'approved' || status == 'partially_approved') {
      return PremiumStatusBadge(
        label: refund.statusLabel,
        status: PremiumBadgeStatus.success,
      );
    }
    if (status == 'rejected' || status == 'cancelled') {
      return PremiumStatusBadge(
        label: refund.statusLabel,
        status: PremiumBadgeStatus.error,
      );
    }
    return PremiumStatusBadge(
      label: refund.statusLabel,
      status: PremiumBadgeStatus.warning,
    );
  }

  Future<void> _showPartialDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final noteController = TextEditingController();
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Refund Sebagian'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Maks: ${currency.format(refund.requestedAmount)}'),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal disetujui',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Catatan admin'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(
                  controller.text.replaceAll(RegExp(r'[^0-9]'), ''),
                );
                if (amount == null || amount <= 0) return;
                Navigator.of(dialogContext).pop();
                _resolve(
                  context,
                  ref,
                  decision: 'partially_approved',
                  approvedAmount: amount,
                  adminNote: noteController.text,
                );
              },
              child: const Text('Setujui'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref, {
    required String decision,
    double approvedAmount = 0,
    String? adminNote,
  }) async {
    final success = await ref
        .read(adminActionControllerProvider.notifier)
        .resolveRefund(
          refundId: refund.id,
          decision: decision,
          approvedAmount: approvedAmount,
          adminNote: adminNote,
        );
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Keputusan refund berhasil disimpan.'
              : ref.read(adminActionControllerProvider).error ??
                    'Gagal menyimpan keputusan refund.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
