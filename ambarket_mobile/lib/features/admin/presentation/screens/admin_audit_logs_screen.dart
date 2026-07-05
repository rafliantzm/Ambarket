import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';

class AdminAuditLogsScreen extends ConsumerWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(adminAuditLogsProvider);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Logs')),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('Belum ada log moderasi.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminAuditLogsProvider.future),
            child: ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  title: Text(log.action.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target: ${log.targetType} (${log.targetId ?? "-"})', style: const TextStyle(fontSize: 12)),
                      if (log.metadata != null)
                        Text('Meta: ${log.metadata.toString()}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  trailing: Text(dateFormat.format(log.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Gagal memuat log: $e')),
      ),
    );
  }
}
