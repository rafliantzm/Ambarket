import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Widget _buildStatCard(BuildContext context, String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: statsAsync.when(
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminDashboardStatsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const Text('Statistik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: _buildStatCard(context, 'Laporan Pending', '${stats['pendingReports']}', Colors.orange)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _buildStatCard(context, 'Total User', '${stats['totalUsers']}', Colors.blue)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _buildStatCard(context, 'Total Produk', '${stats['totalProducts']}', Colors.green),
                const SizedBox(height: AppSpacing.xxl),
                const Text('Menu Moderasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  leading: const Icon(Icons.inventory, color: Colors.green),
                  title: const Text('Moderasi Produk'),
                  subtitle: const Text('Hide/Restore/Reject produk'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/products'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.people, color: Colors.blue),
                  title: const Text('Moderasi Pengguna'),
                  subtitle: const Text('Suspend/Unsuspend pengguna'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/users'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.rate_review, color: Colors.orange),
                  title: const Text('Moderasi Ulasan'),
                  subtitle: const Text('Hide/Restore ulasan'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/reviews'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.red),
                  title: const Text('Daftar Laporan'),
                  subtitle: const Text('Tinjau laporan masuk'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/reports'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.blueGrey),
                  title: const Text('Audit Logs'),
                  subtitle: const Text('Riwayat aksi moderasi admin'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/audit-logs'),
                ),
                const Divider(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Gagal memuat dashboard: $e')),
      ),
    );
  }
}
