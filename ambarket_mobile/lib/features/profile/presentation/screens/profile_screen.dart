import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../review/presentation/providers/review_provider.dart';
import '../../../review/presentation/widgets/rating_stars.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: profile.avatarUrl != null
                            ? CachedNetworkImageProvider(profile.avatarUrl!)
                            : null,
                        child: profile.avatarUrl == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      // Name & Role
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            profile.name ?? 'No Name',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          if (profile.role == 'admin') ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
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
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      
                      // Location & Bio
                      if (profile.location != null && profile.location!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              profile.location!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          style: Theme.of(context).textTheme.bodyMedium,
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
                                  return const Text('Belum ada ulasan toko', style: TextStyle(color: Colors.grey));
                                }
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    RatingStars(rating: summary.averageRating.round(), size: 20),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      '${summary.averageRating.toStringAsFixed(1)} / 5.0 (${summary.totalReviews} ulasan)',
                                      style: Theme.of(context).textTheme.bodySmall,
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

                      const SizedBox(height: AppSpacing.xl),
                      
                      if (profile.role == 'admin') ...[
                        _buildActionItem(
                          context,
                          icon: Icons.admin_panel_settings,
                          title: 'Admin Dashboard',
                          subtitle: 'Moderasi dan audit laporan',
                          onTap: () => context.push('/admin'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Actions
                      _buildActionItem(
                        context,
                        icon: Icons.edit,
                        title: 'Edit Profile',
                        onTap: () => context.push('/profile/edit'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildActionItem(
                        context,
                        icon: Icons.favorite,
                        title: 'My Wishlist',
                        onTap: () => context.push('/wishlist'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildActionItem(
                        context,
                        icon: Icons.handshake,
                        title: 'Tawaran Saya',
                        onTap: () => context.push('/offers'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildActionItem(
                        context,
                        icon: Icons.shopping_bag,
                        title: 'Pesanan Saya',
                        onTap: () => context.push('/buyer-orders'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const SizedBox(height: AppSpacing.md),
                      _buildActionItem(
                        context,
                        icon: Icons.chat,
                        title: 'Chat Saya',
                        onTap: () => context.push('/chats'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildActionItem(
                        context,
                        icon: Icons.report,
                        title: 'Laporan Saya',
                        onTap: () => context.push('/reports'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildActionItem(
                        context,
                        icon: Icons.store,
                        title: 'Produk Saya',
                        subtitle: 'Kelola produk jualan Anda',
                        onTap: () {
                          context.push('/seller');
                        },
                      ),
                      
                      const SizedBox(height: AppSpacing.xxl),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ref.read(authControllerProvider.notifier).signOut();
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                            side: BorderSide(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading profile: $error'),
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
