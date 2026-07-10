import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ambarket_mobile/features/report/presentation/providers/report_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';
import 'package:ambarket_mobile/core/widgets/app_empty_state.dart';
import 'package:ambarket_mobile/core/widgets/app_button.dart';
import 'package:ambarket_mobile/core/widgets/app_glass_card.dart';
import 'package:ambarket_mobile/core/widgets/app_status_badge.dart';

class UserReportFilter extends Notifier<String> {
  @override
  String build() => 'all';

  void updateFilter(String value) {
    state = value;
  }
}

final userReportFilterProvider = NotifierProvider<UserReportFilter, String>(() {
  return UserReportFilter();
});

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myReportsProvider);
    final filter = ref.watch(userReportFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Saya')),
      body: Column(
        children: [
          _buildFilters(context, ref, filter),
          Expanded(
            child: reportsAsync.when(
              data: (allReports) {
                final reports = filter == 'all'
                    ? allReports
                    : allReports.where((r) => r.status == filter).toList();

                if (reports.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 100),
                      AppEmptyState(
                        icon: Icons.report_problem_outlined,
                        title: 'Belum ada laporan',
                        message: filter == 'all'
                            ? 'Anda belum pernah membuat laporan apapun.'
                            : 'Tidak ada laporan dengan status ini.',
                      ),
                      if (filter == 'all') ...[
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: AppButton(
                            label: 'Buat Laporan',
                            onPressed: () => context.push('/reports/new'),
                          ),
                        ),
                      ],
                    ],
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(myReportsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    cacheExtent: 800,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    itemCount: reports.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      return _ReportCard(report: reports[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/reports/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    WidgetRef ref,
    String currentFilter,
  ) {
    final options = {
      'all': 'Semua',
      'pending': 'Pending',
      'reviewed': 'Ditinjau',
      'in_discussion': 'Diskusi',
      'resolved': 'Selesai',
      'rejected': 'Ditolak',
    };

    return Container(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: options.entries.map((entry) {
            final isSelected = currentFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    ref
                        .read(userReportFilterProvider.notifier)
                        .updateFilter(entry.key);
                  }
                },
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final dynamic report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    BadgeStatus statusColor;
    String statusText;
    switch (report.status) {
      case 'pending':
        statusColor = BadgeStatus.warning;
        statusText = 'Pending';
        break;
      case 'reviewed':
        statusColor = BadgeStatus.info;
        statusText = 'Ditinjau';
        break;
      case 'in_discussion':
        statusColor = BadgeStatus.info;
        statusText = 'Diskusi';
        break;
      case 'resolved':
        statusColor = BadgeStatus.success;
        statusText = 'Selesai';
        break;
      case 'rejected':
        statusColor = BadgeStatus.error;
        statusText = 'Ditolak';
        break;
      default:
        statusColor = BadgeStatus.neutral;
        statusText = report.status;
    }

    String targetLabel = report.targetType == 'product'
        ? 'Produk'
        : report.targetType == 'user'
        ? 'Pengguna'
        : 'Ulasan';

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppStatusBadge(label: statusText, status: statusColor),
              Text(
                dateFormat.format(report.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Target Laporan: $targetLabel',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text('Alasan: ${report.reason}', style: theme.textTheme.bodyMedium),
          if (report.description != null && report.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${report.description}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: 'Lihat Detail',
              onPressed: () => context.push('/reports/${report.id}'),
            ),
          ),
        ],
      ),
    );
  }
}
