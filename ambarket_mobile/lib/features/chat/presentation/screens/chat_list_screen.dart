import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(myConversationsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Saya'),
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.conversations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: AppSpacing.md),
                  Text('Belum ada pesan.'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myConversationsProvider);
            },
            child: ListView.builder(
              itemCount: chats.conversations.length + (chats.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= chats.conversations.length) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(myConversationsProvider.notifier).fetchMore();
                        },
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
                  if (now.day == msgDate.day && now.month == msgDate.month && now.year == msgDate.year) {
                    timeStr = DateFormat('HH:mm').format(msgDate);
                  } else {
                    timeStr = DateFormat('dd/MM').format(msgDate);
                  }
                }

                return ListTile(
                  onTap: () => context.push('/chats/${chat.id}'),
                  leading: CircleAvatar(
                    backgroundImage: otherUser?.avatarUrl != null ? CachedNetworkImageProvider(otherUser!.avatarUrl!) : null,
                    child: otherUser?.avatarUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text('${otherUser?.name ?? 'User'} ($otherRole)'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.product?.title ?? 'Produk',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        chat.lastMessage ?? 'Mulai percakapan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      const SizedBox(height: 4),
                      Consumer(
                        builder: (context, ref, child) {
                          final unreadAsync = ref.watch(unreadCountProvider(chat.id));
                          final count = unreadAsync.value ?? 0;
                          
                          if (count == 0) return const SizedBox(width: 24, height: 24);
                          
                          return Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
