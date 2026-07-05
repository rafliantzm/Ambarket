import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ambarket_mobile/features/report/presentation/providers/report_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myReportsProvider);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Saya'),
      ),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(child: Text('Anda belum membuat laporan apapun.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(myReportsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: reports.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final report = reports[index];
                
                Color statusColor;
                String statusText;
                switch (report.status) {
                  case 'pending':
                    statusColor = Colors.orange;
                    statusText = 'Menunggu Tinjauan';
                    break;
                  case 'reviewed':
                    statusColor = Colors.blue;
                    statusText = 'Sedang Ditinjau';
                    break;
                  case 'resolved':
                    statusColor = Colors.green;
                    statusText = 'Selesai';
                    break;
                  case 'rejected':
                    statusColor = Colors.red;
                    statusText = 'Ditolak';
                    break;
                  default:
                    statusColor = Colors.grey;
                    statusText = report.status;
                }

                String targetLabel = report.targetType == 'product' 
                    ? 'Produk' 
                    : report.targetType == 'user' 
                        ? 'Pengguna' 
                        : 'Ulasan';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Target: $targetLabel',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Tanggal: ${dateFormat.format(report.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Alasan: ${report.reason}'),
                        if (report.description != null && report.description!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text('Keterangan: ${report.description}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
