import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';
import 'package:ambarket_mobile/core/widgets/ambarket_scaffold.dart';
import 'package:ambarket_mobile/core/widgets/premium_surface_card.dart';
import 'package:ambarket_mobile/core/widgets/app_loading_skeleton.dart';
import 'package:ambarket_mobile/core/widgets/app_error_state.dart';
import 'package:ambarket_mobile/core/theme/app_colors.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    return PremiumSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PremiumSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return AmbarketScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(adminDashboardStatsProvider.future),
        color: context.colors.primary,
        backgroundColor: context.colors.surface,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Statistik Platform',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Laporan Pending',
                          '${stats['pendingReports']}',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Total User',
                          '${stats['totalUsers']}',
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatCard(
                    context,
                    'Total Produk',
                    '${stats['totalProducts']}',
                    context.colors.primary,
                  ),
                ],
              ),
              loading: () => const AppLoadingSkeleton(
                width: double.infinity,
                height: 180,
                borderRadius: 16,
              ),
              error: (error, stack) => AppErrorState(
                title: 'Gagal Memuat Statistik',
                message: error.toString(),
                onRetry: () => ref.refresh(adminDashboardStatsProvider.future),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Menu Moderasi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _buildMenuTile(
              context,
              icon: Icons.inventory_2_outlined,
              color: context.colors.primary,
              title: 'Moderasi Produk',
              subtitle: 'Hide/Restore/Reject produk',
              onTap: () => context.push('/admin/products'),
            ),
            _buildMenuTile(
              context,
              icon: Icons.people_outline,
              color: Colors.blue,
              title: 'Moderasi Pengguna',
              subtitle: 'Suspend/Unsuspend pengguna',
              onTap: () => context.push('/admin/users'),
            ),
            _buildMenuTile(
              context,
              icon: Icons.rate_review_outlined,
              color: Colors.orange,
              title: 'Moderasi Ulasan',
              subtitle: 'Hide/Restore ulasan pengguna',
              onTap: () => context.push('/admin/reviews'),
            ),
            _buildMenuTile(
              context,
              icon: Icons.report_outlined,
              color: Colors.red,
              title: 'Daftar Laporan',
              subtitle: 'Tinjau laporan masuk',
              onTap: () => context.push('/admin/reports'),
            ),
            _buildMenuTile(
              context,
              icon: Icons.history,
              color: Colors.blueGrey,
              title: 'Audit Logs',
              subtitle: 'Riwayat aksi moderasi admin',
              onTap: () => context.push('/admin/audit-logs'),
            ),
            _buildMenuTile(
              context,
              icon: Icons.local_activity_outlined,
              color: Colors.purple,
              title: 'Manajemen Kupon',
              subtitle: 'Buat dan kelola kupon untuk user',
              onTap: () => context.push('/admin/vouchers'),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
