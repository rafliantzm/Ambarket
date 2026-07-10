import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../review/presentation/providers/review_provider.dart';
import '../../../review/presentation/widgets/rating_stars.dart';
import '../../../home/presentation/widgets/home_coupon_banner.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Akun Saya',
          style: TextStyle(color: context.colors.textPrimary),
        ),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                'Profile not found',
                style: TextStyle(color: context.colors.textPrimary),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
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
                                  border: Border.all(
                                    color: context.colors.primary,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.colors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 16,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor:
                                      context.colors.backgroundDarker,
                                  backgroundImage: profile.avatarUrl != null
                                      ? CachedNetworkImageProvider(
                                          profile.avatarUrl!,
                                        )
                                      : null,
                                  child: profile.avatarUrl == null
                                      ? Icon(
                                          Icons.person,
                                          size: 50,
                                          color: context.colors.textMuted,
                                        )
                                      : null,
                                ),
                              ),
                              SizedBox(height: AppSpacing.md),

                              // Name & Role
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    profile.name ?? 'Pengguna',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: context.colors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (profile.role == 'admin') ...[
                                    SizedBox(width: AppSpacing.sm),
                                    AppStatusBadge(
                                      label: 'ADMIN',
                                      status: BadgeStatus.error,
                                    ),
                                  ],
                                ],
                              ),

                              // Username & Email
                              SizedBox(height: AppSpacing.xs),
                              if (profile.username != null &&
                                  profile.username!.isNotEmpty)
                                Text(
                                  '@${profile.username}',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: context.colors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              Text(
                                user?.email ?? '',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: context.colors.textMuted),
                              ),

                              // Location & Bio
                              if (profile.location != null &&
                                  profile.location!.isNotEmpty) ...[
                                SizedBox(height: AppSpacing.md),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: context.colors.textMuted,
                                    ),
                                    SizedBox(width: AppSpacing.xs),
                                    Text(
                                      profile.location!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: context.colors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                              if (profile.bio != null &&
                                  profile.bio!.isNotEmpty) ...[
                                SizedBox(height: AppSpacing.md),
                                Text(
                                  profile.bio!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: context.colors.textPrimary,
                                      ),
                                ),
                              ],

                              if (profile.role == 'seller' ||
                                  profile.role == 'admin') ...[
                                SizedBox(height: AppSpacing.lg),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final ratingAsync = ref.watch(
                                      sellerRatingSummaryProvider(profile.id),
                                    );
                                    return ratingAsync.when(
                                      data: (summary) {
                                        if (summary.totalReviews == 0) {
                                          return Text(
                                            'Belum ada ulasan',
                                            style: TextStyle(
                                              color: context.colors.textMuted,
                                            ),
                                          );
                                        }
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            RatingStars(
                                              rating: summary.averageRating
                                                  .round(),
                                              size: 20,
                                            ),
                                            SizedBox(width: AppSpacing.xs),
                                            Text(
                                              '${summary.averageRating.toStringAsFixed(1)} / 5.0 (${summary.totalReviews})',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: context
                                                        .colors
                                                        .textSecondary,
                                                  ),
                                            ),
                                          ],
                                        );
                                      },
                                      loading: () => SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      error: (err, st) => SizedBox(),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(height: AppSpacing.md),
                        const HomeCouponBanner(),
                        SizedBox(height: AppSpacing.xl),

                        // Menus
                        Text(
                          'PENGATURAN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textMuted,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),

                        AppGlassCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _buildMenuTile(
                                context,
                                icon: Icons.edit,
                                title: 'Edit Profil',
                                onTap: () => context.push('/profile/edit'),
                              ),
                              Divider(height: 1, color: context.colors.border),
                              _buildMenuTile(
                                context,
                                icon: Icons.shopping_bag_outlined,
                                title: 'Pesanan Saya',
                                onTap: () => context.push('/buyer-orders'),
                              ),
                              Divider(height: 1, color: context.colors.border),
                              _buildMenuTile(
                                context,
                                icon: Icons.local_offer_outlined,
                                title: 'Penawaran Saya',
                                onTap: () => context.push('/offers'),
                              ),
                              Divider(height: 1, color: context.colors.border),
                              _buildMenuTile(
                                context,
                                icon: Icons.local_activity_outlined,
                                title: 'Kupon Saya',
                                onTap: () => context.push('/vouchers'),
                              ),
                              Divider(height: 1, color: context.colors.border),
                              _buildMenuTile(
                                context,
                                icon: Icons.report_outlined,
                                title: 'Laporan Saya',
                                onTap: () => context.push('/reports'),
                              ),
                              Divider(height: 1, color: context.colors.border),
                              if (profile.role == 'admin') ...[
                                Divider(
                                  height: 1,
                                  color: context.colors.border,
                                ),
                                _buildMenuTile(
                                  context,
                                  icon: Icons.admin_panel_settings,
                                  title: 'Admin Dashboard',
                                  iconColor: context.colors.error,
                                  textColor: context.colors.error,
                                  onTap: () => context.push('/admin'),
                                ),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(height: AppSpacing.xxl),
                        AppButton(
                          label: 'Keluar',
                          variant: AppButtonVariant.outline,
                          onPressed: () {
                            ref.read(authControllerProvider.notifier).signOut();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Terjadi kesalahan: $error',
            style: TextStyle(color: context.colors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? context.colors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? context.colors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: context.colors.textMuted),
      onTap: onTap,
    );
  }
}
