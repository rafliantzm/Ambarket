import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/ambarket_scaffold.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/premium_command_search_bar.dart';
import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(myConversationsProvider);
    final user = ref.watch(currentUserProvider);

    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return AmbarketScaffold(
      isDesktopConstrained: isDesktop,
      appBar: AppBar(
        title: Text(
          'Chat Saya',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: PremiumCommandSearchBar(
              controller: _searchController,
              hintText: 'Cari percakapan...',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Diskusi produk dan transaksi dengan pembeli/penjual.',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: chatsAsync.when(
              data: (chats) {
                if (chats.conversations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: AppEmptyState(
                        icon: CupertinoIcons.chat_bubble_text,
                        title: 'Belum Ada Pesan',
                        message:
                            'Mulai cari produk dan diskusikan dengan penjual/pembeli sekarang.',
                        buttonText: 'Mulai Cari Produk',
                        onButtonPressed: () {
                          context.go('/');
                        },
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(myConversationsProvider);
                  },
                  color: context.colors.primary,
                  backgroundColor: context.colors.surface,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    cacheExtent: 800,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    itemCount:
                        chats.conversations.length + (chats.hasMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index >= chats.conversations.length) {
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Center(
                            child: TextButton(
                              onPressed: () {
                                ref
                                    .read(myConversationsProvider.notifier)
                                    .fetchMore();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: context.colors.primary,
                              ),
                              child: const Text('Muat Lebih Banyak'),
                            ),
                          ),
                        );
                      }

                      final chat = chats.conversations[index];
                      if (user == null) return const SizedBox.shrink();

                      // Determine the other participant
                      final isBuyer = chat.buyerId == user.id;
                      final otherUser = isBuyer ? chat.seller : chat.buyer;
                      final otherRole = isBuyer ? 'Penjual' : 'Pembeli';

                      String timeStr = '';
                      if (chat.lastMessageAt != null) {
                        final now = DateTime.now();
                        final msgDate = chat.lastMessageAt!;
                        if (now.day == msgDate.day &&
                            now.month == msgDate.month &&
                            now.year == msgDate.year) {
                          timeStr = DateFormat('HH:mm').format(msgDate);
                        } else {
                          timeStr = DateFormat('dd/MM').format(msgDate);
                        }
                      }

                      return AppGlassCard(
                        padding: EdgeInsets.zero,
                        variant: AppGlassCardVariant.soft,
                        child: InkWell(
                          onTap: () => context.push('/chats/${chat.id}'),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: context.colors.border,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        context.colors.surfaceHighlight,
                                    backgroundImage:
                                        otherUser?.avatarUrl != null
                                        ? CachedNetworkImageProvider(
                                            otherUser!.avatarUrl!,
                                          )
                                        : null,
                                    child: otherUser?.avatarUrl == null
                                        ? Icon(
                                            Icons.person,
                                            color: context.colors.textSecondary,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              otherUser?.name ??
                                                  otherUser?.username ??
                                                  otherRole,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color:
                                                    context.colors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (timeStr.isNotEmpty) ...[
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            Text(
                                              timeStr,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: context.colors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        chat.product?.title ?? 'Produk',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: context.colors.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              chat.lastMessagePreview,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: context
                                                    .colors
                                                    .textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Consumer(
                                            builder: (context, ref, child) {
                                              final unreadAsync = ref.watch(
                                                unreadCountProvider(chat.id),
                                              );
                                              final count =
                                                  unreadAsync.value ?? 0;

                                              if (count == 0) {
                                                return const SizedBox.shrink();
                                              }

                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  left: AppSpacing.sm,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: context.colors.accent,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  count > 99
                                                      ? '99+'
                                                      : count.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: context.colors.primary),
              ),
              error: (e, st) => Center(
                child: Text(
                  'Error: $e',
                  style: TextStyle(color: context.colors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
