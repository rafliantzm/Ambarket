import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

import '../../../../core/widgets/premium_command_search_bar.dart';

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
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 64 : AppSpacing.md,
        AppSpacing.md,
        isDesktop ? 64 : AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (isDesktop) ...[
              Text(
                'Ambarket',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
            ],
            Expanded(
              child: PremiumCommandSearchBar(
                controller: searchController,
                hintText: 'Cari barang, merek, atau kategori...',
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).updateQuery(value),
                onFilterTap: () {
                  // TODO: Show filter bottom sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Filter belum diimplementasi')),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Cart Icon (Standard E-commerce)
            Consumer(
              builder: (context, ref, child) {
                final cartCount = ref.watch(cartCountProvider);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shopping_cart_outlined,
                        color: context.colors.textPrimary,
                        size: 24,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      onPressed: () => context.push('/cart'),
                    ),
                    if (cartCount > 0)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.colors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.colors.background,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            cartCount > 99 ? '99+' : cartCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

            // Notification Badge
            Consumer(
              builder: (context, ref, child) {
                final unreadCountAsync = ref.watch(
                  unreadNotificationCountProvider,
                );
                final unreadCount = unreadCountAsync.value ?? 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        color: context.colors.textPrimary,
                        size: 24,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      onPressed: () {
                        context.push('/notifications');
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.colors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.colors.background,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

            // Chat Badge
            Consumer(
              builder: (context, ref, child) {
                final unreadChatAsync = ref.watch(totalUnreadChatCountProvider);
                final unreadChat = unreadChatAsync.value ?? 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.chat_bubble_text,
                        color: context.colors.textPrimary,
                        size: 24,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      onPressed: () => context.push('/chats'),
                    ),
                    if (unreadChat > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.colors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.colors.background,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadChat > 99 ? '99+' : unreadChat.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (isDesktop) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: Icon(
                  Icons.person_outline_rounded,
                  color: context.colors.textPrimary,
                  size: 24,
                ),
                onPressed: () => context.push('/profile'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
