import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ambarket_mobile/features/report/presentation/providers/report_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';
import 'package:ambarket_mobile/core/widgets/premium_empty_state.dart';
import 'package:ambarket_mobile/core/widgets/premium_surface_card.dart';
import 'package:ambarket_mobile/core/widgets/premium_status_badge.dart';
import 'package:ambarket_mobile/core/widgets/ambarket_scaffold.dart';
import 'package:ambarket_mobile/core/widgets/premium_filter_chips.dart';
import 'package:ambarket_mobile/core/widgets/ambarket_loaders.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(adminReportsProvider);
    final filter = ref.watch(reportStatusFilterProvider);
    final theme = Theme.of(context);

    return AmbarketScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Laporan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Tinjau dan selesaikan laporan pengguna.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilters(context, ref, filter),
          Expanded(
            child: reportsAsync.when(
              data: (paginatedState) {
                final reports = paginatedState.items;
                if (reports.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      PremiumEmptyState(
                        icon: Icons.assignment_outlined,
                        title: 'Tidak ada laporan',
                        message: 'Tidak ada laporan pada status ini.',
                      ),
                    ],
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.refresh(adminReportsProvider.future),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (!paginatedState.hasMore) return false;
                      if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent) {
                        ref.read(adminReportsProvider.notifier).loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      cacheExtent: 800,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      itemCount:
                          reports.length + (paginatedState.hasMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        if (index == reports.length) {
                          return const AmbarketLoadMoreIndicator();
                        }
                        return _AdminReportCard(report: reports[index]);
                      },
                    ),
                  ),
                );
              },
              loading: () => const AmbarketListSkeleton(),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
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
              child: PremiumFilterChip(
                label: entry.value,
                isSelected: isSelected,
                onTap: () {
                  ref
                      .read(reportStatusFilterProvider.notifier)
                      .updateFilter(entry.key);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  final dynamic report;

  const _AdminReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
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

    String targetLabel = report.targetType == 'product'
        ? 'Produk'
        : report.targetType == 'user'
        ? 'Pengguna'
        : 'Ulasan';

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
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Target Laporan: $targetLabel',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pelapor: ${report.reporterId}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text('Alasan: ${report.reason}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.rate_review, size: 18),
              label: const Text('Tinjau'),
              onPressed: () => context.push('/admin/reports/${report.id}'),
            ),
          ),
        ],
      ),
    );
  }
}
