import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:ambarket_mobile/features/admin/presentation/widgets/report_target_card.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';

class AdminReportDetailScreen extends ConsumerWidget {
  final String reportId;

  const AdminReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For MVP, we will fetch from the list and find the report by id
    // In a real app, we might fetch specific report by ID
    final reportsAsync = ref.watch(adminReportsProvider);
    final actionState = ref.watch(adminActionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Laporan')),
      body: reportsAsync.when(
        data: (reports) {
          final report = reports.firstWhere((r) => r.id == reportId, orElse: () => throw Exception('Laporan tidak ditemukan'));
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Laporan ID:', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
                Text(report.id),
                const SizedBox(height: AppSpacing.md),
                Text('Target Type:', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
                Text(report.targetType.toUpperCase()),
                const SizedBox(height: AppSpacing.md),
                Text('Target ID:', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
                Text(report.targetId),
                const SizedBox(height: AppSpacing.sm),
                ReportTargetCard(targetType: report.targetType, targetId: report.targetId),
                const SizedBox(height: AppSpacing.md),
                Text('Alasan:', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
                Text(report.reason),
                const SizedBox(height: AppSpacing.md),
                Text('Keterangan:', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
                Text(report.description ?? '-'),
                const SizedBox(height: AppSpacing.md),
                Text('Status:', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
                Text(report.status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                
                const SizedBox(height: AppSpacing.xxl),
                const Divider(),
                const Text('Aksi Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    if (report.status == 'pending')
                      ElevatedButton(
                        onPressed: actionState.isLoading ? null : () {
                          ref.read(adminActionControllerProvider.notifier).updateReportStatus(report.id, 'reviewed');
                        },
                        child: const Text('Tandai Reviewed'),
                      ),
                    if (report.status != 'resolved')
                      ElevatedButton(
                        onPressed: actionState.isLoading ? null : () {
                          ref.read(adminActionControllerProvider.notifier).updateReportStatus(report.id, 'resolved');
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: const Text('Resolve'),
                      ),
                    if (report.status != 'rejected')
                      ElevatedButton(
                        onPressed: actionState.isLoading ? null : () {
                          ref.read(adminActionControllerProvider.notifier).updateReportStatus(report.id, 'rejected');
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text('Reject'),
                      ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                const Divider(),
                const Text('Aksi Moderasi (Sistem)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                if (report.targetType == 'product')
                  ElevatedButton(
                    onPressed: actionState.isLoading ? null : () {
                      _showModerationDialog(context, ref, 'Sembunyikan Produk', () {
                        ref.read(adminActionControllerProvider.notifier).hideProduct(report.targetId, 'Melanggar aturan: ${report.reason}');
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                    child: const Text('Hide Product'),
                  ),
                if (report.targetType == 'user')
                  ElevatedButton(
                    onPressed: actionState.isLoading ? null : () {
                      _showModerationDialog(context, ref, 'Suspend Pengguna', () {
                        ref.read(adminActionControllerProvider.notifier).suspendUser(report.targetId, 'Melanggar aturan: ${report.reason}');
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                    child: const Text('Suspend User'),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Gagal memuat: $e')),
      ),
    );
  }

  void _showModerationDialog(BuildContext context, WidgetRef ref, String title, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text('Apakah Anda yakin ingin melakukan aksi ini? Tindakan ini akan masuk ke audit logs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aksi berhasil dijalankan')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Ya, Lakukan'),
          )
        ],
      ),
    );
  }
}
