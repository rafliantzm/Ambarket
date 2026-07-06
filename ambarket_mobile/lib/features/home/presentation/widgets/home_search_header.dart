import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';

class HomeSearchHeader extends ConsumerWidget {
  final TextEditingController searchController;
  final bool isDesktop;

  const HomeSearchHeader({
    super.key,
    required this.searchController,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (isDesktop) ...[
            Text(
              'Ambarket',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: AppSpacing.xl),
          ],
          Expanded(
            child: AppGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).updateQuery(value),
                decoration: InputDecoration(
                  hintText: 'Cari kaos, laptop, sepatu, kamera...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            searchController.clear();
                            ref.read(searchQueryProvider.notifier).updateQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Dummy Notification Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Belum ada notifikasi baru.')),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.textPrimary),
            onPressed: () => context.push('/chats'),
          ),
          if (isDesktop) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              icon: const Icon(Icons.person_outline, color: AppColors.textPrimary),
              onPressed: () => context.push('/profile'),
            ),
          ]
        ],
      ),
    );
  }
}
