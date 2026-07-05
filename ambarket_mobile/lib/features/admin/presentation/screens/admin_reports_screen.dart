import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _selectedStatus = 'pending';

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(adminReportsByStatusProvider(_selectedStatus));
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Laporan'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                'pending',
                'reviewed',
                'resolved',
                'rejected'
              ].map((status) {
                return ChoiceChip(
                  label: Text(status.toUpperCase()),
                  selected: _selectedStatus == status,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedStatus = status);
                  },
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: reportsAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return const Center(child: Text('Tidak ada laporan.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(adminReportsByStatusProvider(_selectedStatus).future),
                  child: ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(report.targetType == 'product' ? Icons.inventory : Icons.person),
                        ),
                        title: Text('Target: ${report.targetType} - ${report.reason}'),
                        subtitle: Text(dateFormat.format(report.createdAt)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.push('/admin/reports/${report.id}');
                        },
                      );
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
    );
  }
}
