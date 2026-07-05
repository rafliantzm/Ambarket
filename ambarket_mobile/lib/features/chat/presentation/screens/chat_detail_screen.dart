import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatDetailScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark as read when opened
    Future.microtask(() => ref.read(chatActionControllerProvider.notifier).markAsRead(widget.conversationId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String receiverId) async {
    final currentProfile = ref.read(currentProfileProvider).value;
    if (currentProfile?.isSuspended == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun Anda sedang ditangguhkan.')));
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    try {
      await ref.read(chatActionControllerProvider.notifier).sendMessage(widget.conversationId, receiverId, text);
      
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim pesan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final conversationAsync = ref.watch(conversationDetailProvider(widget.conversationId));
    final messagesAsync = ref.watch(messagesStreamProvider(widget.conversationId));
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Silakan login')));
    }

    return Scaffold(
      appBar: AppBar(
        title: conversationAsync.when(
          data: (chat) {
            final isBuyer = chat.buyerId == user.id;
            final otherUser = isBuyer ? chat.seller : chat.buyer;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(otherUser?.name ?? 'User', style: const TextStyle(fontSize: 16)),
                Text(chat.product?.title ?? 'Produk', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            );
          },
          loading: () => const Text('Memuat...'),
          error: (e, st) => const Text('Error'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('Belum ada pesan. Mulai sapa sekarang!'));
                }
                // Reverse to show latest at bottom if ListView is reversed
                final reversedMessages = messages.reversed.toList();
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: reversedMessages.length,
                  itemBuilder: (context, index) {
                    final msg = reversedMessages[index];
                    final isMe = msg.senderId == user.id;
                    final time = DateFormat('HH:mm').format(msg.createdAt);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                          ),
                        ),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.message,
                              style: TextStyle(
                                color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? theme.colorScheme.onPrimary.withValues(alpha: 0.7) : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          ),
          conversationAsync.maybeWhen(
            data: (chat) {
              final isBuyer = chat.buyerId == user.id;
              final receiverId = isBuyer ? chat.sellerId : chat.buyerId;
              final chatActionState = ref.watch(chatActionControllerProvider);
              final isLoading = chatActionState.isLoading;

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Ketik pesan...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: isLoading ? null : (_) => _sendMessage(receiverId),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                                ),
                              )
                            : IconButton(
                                icon: Icon(Icons.send, color: theme.colorScheme.onPrimary),
                                onPressed: () => _sendMessage(receiverId),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
