import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ambarket_scaffold.dart';
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
    Future.microtask(
      () => ref
          .read(chatActionControllerProvider.notifier)
          .markAsRead(widget.conversationId),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Akun Anda sedang ditangguhkan.'),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await ref
          .read(chatActionControllerProvider.notifier)
          .sendMessage(widget.conversationId, receiverId, text);

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
          SnackBar(
            content: Text('Gagal mengirim pesan: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final conversationAsync = ref.watch(
      conversationDetailProvider(widget.conversationId),
    );
    final messagesAsync = ref.watch(
      messagesStreamProvider(widget.conversationId),
    );

    final isDesktop = MediaQuery.of(context).size.width >= 768;

    if (user == null) {
      return AmbarketScaffold(
        isDesktopConstrained: isDesktop,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: context.colors.textPrimary),
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Silakan login',
            style: TextStyle(color: context.colors.textPrimary),
          ),
        ),
      );
    }

    return AmbarketScaffold(
      isDesktopConstrained: isDesktop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        title: conversationAsync.when(
          data: (chat) {
            final isBuyer = chat.buyerId == user.id;
            final otherUser = isBuyer ? chat.seller : chat.buyer;
            return Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: context.colors.surfaceHighlight,
                  backgroundImage: otherUser?.avatarUrl != null
                      ? CachedNetworkImageProvider(otherUser!.avatarUrl!)
                      : null,
                  child: otherUser?.avatarUrl == null
                      ? Icon(
                          Icons.person,
                          size: 24,
                          color: context.colors.textSecondary,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUser?.name ?? otherUser?.username ?? 'Pengguna',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        chat.product?.title ?? 'Produk',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: context.colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => Text(
            'Memuat...',
            style: TextStyle(color: context.colors.textPrimary),
          ),
          error: (e, st) => Text(
            'Error',
            style: TextStyle(color: context.colors.textPrimary),
          ),
        ),
      ),
      body: Column(
        children: [
          conversationAsync.maybeWhen(
            data: (chat) {
              if (chat.product == null) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => context.push('/products/${chat.product!.id}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    border: Border(
                      bottom: BorderSide(color: context.colors.border),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: context.colors.surfaceHighlight,
                          border: Border.all(color: context.colors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: chat.product!.images.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: chat.product!.images.first.imageUrl,
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.image_not_supported,
                                color: context.colors.textSecondary,
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chat.product!.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              NumberFormat.currency(
                                locale: 'id',
                                symbol: 'Rp',
                                decimalDigits: 0,
                              ).format(chat.product!.price),
                              style: TextStyle(
                                color: context.colors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: context.colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.chat_bubble_text,
                          size: 48,
                          color: context.colors.textMuted,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Belum ada pesan.\nMulai sapa sekarang!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                final reversedMessages = messages.reversed.toList();
                final chat = conversationAsync.value;
                final isBuyer = chat?.buyerId == user.id;
                final otherUser = isBuyer ? chat?.seller : chat?.buyer;
                final meUser = isBuyer ? chat?.buyer : chat?.seller;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.lg,
                  ),
                  cacheExtent: 900,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  itemCount: reversedMessages.length,
                  itemBuilder: (context, index) {
                    final msg = reversedMessages[index];
                    final isMe = msg.senderId == user.id;
                    final time = DateFormat('HH:mm').format(msg.createdAt);

                    final senderProfile = isMe ? meUser : otherUser;
                    final avatarUrl = senderProfile?.avatarUrl;
                    final senderName =
                        senderProfile?.name ??
                        senderProfile?.username ??
                        (isMe ? 'Saya' : 'Pengguna');

                    // Determine if the previous message was from the same sender to group them visually
                    bool showAvatarAndName = true;
                    if (index < reversedMessages.length - 1) {
                      final prevMsg = reversedMessages[index + 1];
                      if (prevMsg.senderId == msg.senderId) {
                        showAvatarAndName = false;
                      }
                    }

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: showAvatarAndName
                            ? AppSpacing.md
                            : AppSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!isMe && showAvatarAndName) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      context.colors.surfaceHighlight,
                                  backgroundImage: avatarUrl != null
                                      ? CachedNetworkImageProvider(avatarUrl)
                                      : null,
                                  child: avatarUrl == null
                                      ? Icon(
                                          Icons.person,
                                          size: 20,
                                          color: context.colors.textSecondary,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  senderName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                          ],
                          Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                // Add spacing equal to avatar width (36) + padding (12) to align bubble with name
                                const SizedBox(width: 48),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? context.colors.primary
                                        : context.colors.surface,
                                    borderRadius: BorderRadius.circular(16)
                                        .copyWith(
                                          topRight: isMe && !showAvatarAndName
                                              ? const Radius.circular(4)
                                              : const Radius.circular(16),
                                          bottomRight: isMe
                                              ? const Radius.circular(0)
                                              : const Radius.circular(16),
                                          topLeft: !isMe && !showAvatarAndName
                                              ? const Radius.circular(4)
                                              : const Radius.circular(16),
                                          bottomLeft: !isMe
                                              ? const Radius.circular(0)
                                              : const Radius.circular(16),
                                        ),
                                    border: isMe
                                        ? null
                                        : Border.all(
                                            color: context.colors.border,
                                          ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isMe
                                            ? context.colors.primary.withValues(
                                                alpha: 0.2,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          msg.message,
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white
                                                : context.colors.textPrimary,
                                            height: 1.4,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 2,
                                        ),
                                        child: Text(
                                          time,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isMe
                                                ? Colors.white.withValues(
                                                    alpha: 0.7,
                                                  )
                                                : context.colors.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: context.colors.primary),
              ),
              error: (err, st) => Center(
                child: Text(
                  'Error: $err',
                  style: TextStyle(color: context.colors.error),
                ),
              ),
            ),
          ),
          conversationAsync.maybeWhen(
            data: (chat) {
              final isBuyer = chat.buyerId == user.id;
              final receiverId = isBuyer ? chat.sellerId : chat.buyerId;
              final chatActionState = ref.watch(chatActionControllerProvider);
              final isLoading = chatActionState.isLoading;

              return Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border(top: BorderSide(color: context.colors.border)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.colors.background,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: context.colors.border),
                            ),
                            child: TextField(
                              controller: _messageController,
                              maxLines: 4,
                              minLines: 1,
                              textInputAction: TextInputAction.send,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ketik pesan...',
                                hintStyle: TextStyle(
                                  color: context.colors.textSecondary,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                              ),
                              onSubmitted: isLoading
                                  ? null
                                  : (_) => _sendMessage(receiverId),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.primary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  onPressed: () => _sendMessage(receiverId),
                                ),
                        ),
                      ],
                    ),
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
