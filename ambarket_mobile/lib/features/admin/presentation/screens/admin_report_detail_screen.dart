import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';
import 'package:ambarket_mobile/features/report/presentation/providers/report_provider.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';
import 'package:ambarket_mobile/core/widgets/ambarket_scaffold.dart';
import 'package:ambarket_mobile/core/widgets/premium_surface_card.dart';
import 'package:ambarket_mobile/core/widgets/premium_status_badge.dart';
import 'package:ambarket_mobile/core/widgets/premium_button.dart';

class AdminReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;
  const AdminReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<AdminReportDetailScreen> createState() =>
      _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState
    extends ConsumerState<AdminReportDetailScreen> {
  final _messageController = TextEditingController();
  final _finalResolutionController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _finalResolutionController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final success = await ref
        .read(reportActionControllerProvider.notifier)
        .adminSendMessage(widget.reportId, message);
    if (success && mounted) {
      _messageController.clear();
      // Ensure status is at least in_discussion
      ref
          .read(reportActionControllerProvider.notifier)
          .adminUpdateStatus(widget.reportId, 'in_discussion');
    } else if (mounted) {
      final error =
          ref.read(reportActionControllerProvider).error ??
          'Gagal mengirim pesan';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateStatus(String status) async {
    final success = await ref
        .read(reportActionControllerProvider.notifier)
        .adminUpdateStatus(widget.reportId, status);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status diperbarui menjadi $status'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      final error =
          ref.read(reportActionControllerProvider).error ??
          'Gagal memperbarui status';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showFinalResolutionModal(
    BuildContext context,
    String status,
  ) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          status == 'resolved' ? 'Selesaikan Laporan' : 'Tolak Laporan',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Masukkan hasil penyelesaian yang akan dikirim ke pelapor:'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _finalResolutionController,
              decoration: const InputDecoration(
                labelText: 'Hasil Penyelesaian',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(reportActionControllerProvider.notifier)
                  .adminSendFinalResolution(
                    widget.reportId,
                    _finalResolutionController.text.trim(),
                    status,
                  );
              if (success && mounted) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Laporan diselesaikan.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else if (mounted) {
                final error =
                    ref.read(reportActionControllerProvider).error ??
                    'Gagal menyelesaikan laporan';
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Kirim Final Report'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportDetailProvider(widget.reportId));
    final messagesAsync = ref.watch(reportMessagesProvider(widget.reportId));
    final actionState = ref.watch(reportActionControllerProvider);
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);

    return AmbarketScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Admin Report Detail',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: reportAsync.when(
        data: (report) {
          final isResolved =
              report.status == 'resolved' || report.status == 'rejected';

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _buildReportInfo(context, report),
                    const SizedBox(height: AppSpacing.md),
                    if (!isResolved)
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          if (report.status == 'pending')
                            PremiumButton(
                              onPressed: actionState.isLoading
                                  ? () {}
                                  : () => _updateStatus('reviewed'),
                              label: 'Tandai Ditinjau',
                              isLoading: actionState.isLoading,
                            ),
                          PremiumButton(
                            onPressed: actionState.isLoading
                                ? () {}
                                : () => _showFinalResolutionModal(
                                    context,
                                    'resolved',
                                  ),
                            label: 'Selesaikan',
                            isLoading: actionState.isLoading,
                          ),
                          PremiumButton(
                            onPressed: actionState.isLoading
                                ? () {}
                                : () => _showFinalResolutionModal(
                                    context,
                                    'rejected',
                                  ),
                            label: 'Tolak',
                            isLoading: actionState.isLoading,
                          ),
                        ],
                      ),

                    if (isResolved && report.finalResolution != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildFinalResolution(context, report),
                    ],

                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Thread Diskusi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    messagesAsync.when(
                      data: (messages) {
                        if (messages.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            child: Center(
                              child: Text('Belum ada pesan diskusi.'),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: messages.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe =
                                msg.senderId == currentUser?.id; // Admin is me

                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? theme.colorScheme.primaryContainer
                                      : theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16)
                                      .copyWith(
                                        bottomRight: isMe
                                            ? const Radius.circular(0)
                                            : null,
                                        bottomLeft: !isMe
                                            ? const Radius.circular(0)
                                            : null,
                                      ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Text(
                                        'Pelapor',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    const SizedBox(height: 2),
                                    Text(
                                      msg.message,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: isMe
                                                ? theme
                                                      .colorScheme
                                                      .onPrimaryContainer
                                                : theme.colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('HH:mm').format(msg.createdAt),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: isMe
                                                ? theme
                                                      .colorScheme
                                                      .onPrimaryContainer
                                                      .withValues(alpha: 0.7)
                                                : theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Text('Error loading messages: $e'),
                    ),
                  ],
                ),
              ),

              if (!isResolved)
                Container(
                  padding: EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: AppSpacing.sm,
                    bottom:
                        MediaQuery.of(context).padding.bottom + AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        offset: const Offset(0, -2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Minta keterangan ke pelapor...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(24),
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      actionState.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send),
                              color: theme.colorScheme.primary,
                              onPressed: _sendMessage,
                            ),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildReportInfo(BuildContext context, ReportModel report) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    PremiumBadgeStatus statusColor;
    String statusText;
    switch (report.status) {
      case 'pending':
        statusColor = PremiumBadgeStatus.warning;
        statusText = 'Pending';
        break;
      case 'reviewed':
        statusColor = PremiumBadgeStatus.info;
        statusText = 'Ditinjau';
        break;
      case 'in_discussion':
        statusColor = PremiumBadgeStatus.info;
        statusText = 'Diskusi';
        break;
      case 'resolved':
        statusColor = PremiumBadgeStatus.success;
        statusText = 'Selesai';
        break;
      case 'rejected':
        statusColor = PremiumBadgeStatus.error;
        statusText = 'Ditolak';
        break;
      default:
        statusColor = PremiumBadgeStatus.neutral;
        statusText = report.status;
    }

    return PremiumSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PremiumStatusBadge(label: statusText, status: statusColor),
              Text(
                dateFormat.format(report.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'Pelapor ID', value: report.reporterId),
          const SizedBox(height: 4),
          _InfoRow(
            label: 'Target Laporan',
            value: '${report.targetType} (${report.targetId})',
          ),
          const SizedBox(height: 4),
          _InfoRow(label: 'Alasan', value: report.reason),
          if (report.description != null && report.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _InfoRow(label: 'Keterangan', value: report.description!),
          ],
        ],
      ),
    );
  }

  Widget _buildFinalResolution(BuildContext context, ReportModel report) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: report.status == 'resolved'
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: report.status == 'resolved' ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                report.status == 'resolved' ? Icons.check_circle : Icons.cancel,
                color: report.status == 'resolved' ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Final Resolution',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: report.status == 'resolved'
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ],
          ),
          const Divider(),
          Text(report.finalResolution ?? ''),
          if (report.resolvedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Diselesaikan pada: ${DateFormat('dd MMM yyyy, HH:mm').format(report.resolvedAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
