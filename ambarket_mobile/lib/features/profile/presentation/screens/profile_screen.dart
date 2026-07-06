import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_background.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../review/presentation/providers/review_provider.dart';
import '../../../review/presentation/widgets/rating_stars.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final user = ref.watch(currentUserProvider);

    return AppAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Akun Saya', style: TextStyle(color: AppColors.textPrimary)),
        ),
        body: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found', style: TextStyle(color: AppColors.textPrimary)));
            }

            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppColors.backgroundDarker,
                                  backgroundImage: profile.avatarUrl != null
                                      ? CachedNetworkImageProvider(profile.avatarUrl!)
                                      : null,
                                  child: profile.avatarUrl == null
                                      ? const Icon(Icons.person, size: 50, color: AppColors.textMuted)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              
                              // Name & Role
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    profile.name ?? 'Pengguna',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (profile.role == 'admin') ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    const AppStatusBadge(
                                      label: 'ADMIN',
                                      status: BadgeStatus.error,
                                    ),
                                  ],
                                ],
                              ),
                              
                              // Username & Email
                              const SizedBox(height: AppSpacing.xs),
                              if (profile.username != null && profile.username!.isNotEmpty)
                                Text(
                                  '@${profile.username}',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Text(
                                user?.email ?? '',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              
                              // Location & Bio
                              if (profile.location != null && profile.location!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: AppColors.textMuted),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      profile.location!,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  profile.bio!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                              
                              if (profile.role == 'seller' || profile.role == 'admin') ...[
                                const SizedBox(height: AppSpacing.lg),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final ratingAsync = ref.watch(sellerRatingSummaryProvider(profile.id));
                                    return ratingAsync.when(
                                      data: (summary) {
                                        if (summary.totalReviews == 0) {
                                          return const Text('Belum ada ulasan', style: TextStyle(color: AppColors.textMuted));
                                        }
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            RatingStars(rating: summary.averageRating.round(), size: 20),
                                            const SizedBox(width: AppSpacing.xs),
                                            Text(
                                              '${summary.averageRating.toStringAsFixed(1)} / 5.0 (${summary.totalReviews})',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                      loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                      error: (err, st) => const SizedBox(),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Menus
                        Text(
                          'PENGATURAN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        
                        AppGlassCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _buildMenuTile(
                                icon: Icons.edit,
                                title: 'Edit Profil',
                                onTap: () => context.push('/profile/edit'),
                              ),
                              const Divider(height: 1, color: AppColors.border),
                              _buildMenuTile(
                                icon: Icons.shopping_bag_outlined,
                                title: 'Pesanan Saya',
                                onTap: () => context.push('/buyer-orders'),
                              ),
                              const Divider(height: 1, color: AppColors.border),
                              _buildMenuTile(
                                icon: Icons.local_offer_outlined,
                                title: 'Penawaran Saya',
                                onTap: () => context.push('/offers'),
                              ),
                              const Divider(height: 1, color: AppColors.border),
                              _buildMenuTile(
                                icon: Icons.report_outlined,
                                title: 'Laporan Saya',
                                onTap: () => context.push('/reports'),
                              ),
                              if (profile.role == 'admin') ...[
                                const Divider(height: 1, color: AppColors.border),
                                _buildMenuTile(
                                  icon: Icons.admin_panel_settings,
                                  title: 'Admin Dashboard',
                                  iconColor: AppColors.error,
                                  textColor: AppColors.error,
                                  onTap: () => context.push('/admin'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.xxl),
                        AppButton(
                          label: 'Keluar',
                          variant: AppButtonVariant.outline,
                          onPressed: () {
                            ref.read(authControllerProvider.notifier).signOut();
                          },
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (error, stack) => Center(child: Text('Terjadi kesalahan: $error', style: const TextStyle(color: AppColors.error))),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? AppColors.textPrimary, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}

