import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';
import 'package:ambarket_mobile/core/widgets/ambarket_scaffold.dart';
import 'package:ambarket_mobile/core/widgets/premium_surface_card.dart';
import 'package:ambarket_mobile/core/widgets/premium_empty_state.dart';

class AdminAuditLogsScreen extends ConsumerWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(adminAuditLogsProvider);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');

    return AmbarketScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Audit Logs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const PremiumEmptyState(
              icon: Icons.history,
              title: 'Belum ada log moderasi',
              message: 'Riwayat aksi admin akan muncul di sini.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminAuditLogsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              cacheExtent: 800,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              itemCount: logs.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final log = logs[index];
                return PremiumSurfaceCard(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: ListTile(
                    title: Text(
                      log.action.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target: ${log.targetType} (${log.targetId ?? "-"})',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (log.metadata != null)
                          Text(
                            'Meta: ${log.metadata.toString()}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    trailing: Text(
                      dateFormat.format(log.createdAt),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
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
