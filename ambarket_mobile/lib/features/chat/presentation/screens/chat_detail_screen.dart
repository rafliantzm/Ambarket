import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/widgets/ambarket_scaffold.dart';
import '../../data/services/chat_video_compressor.dart';
import '../../domain/models/conversation_model.dart';
import '../../domain/models/message_model.dart';
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
  static const int _maxAttachmentBytes = 20 * 1024 * 1024;

  final _messageController = TextEditingController();
  final _messageFocusNode = FocusNode();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  bool _isUploadingAttachment = false;

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
    _messageFocusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String receiverId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

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
    final pendingId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final pendingMessage = MessageModel(
      id: pendingId,
      conversationId: widget.conversationId,
      senderId: user.id,
      receiverId: receiverId,
      message: text,
      isRead: true,
      createdAt: DateTime.now(),
    );

    ref
        .read(pendingMessagesProvider(widget.conversationId).notifier)
        .add(pendingMessage);

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }

    try {
      await ref
          .read(chatActionControllerProvider.notifier)
          .sendMessage(widget.conversationId, receiverId, text);

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
      Future<void>.delayed(const Duration(seconds: 8), () {
        if (!mounted) return;
        ref
            .read(pendingMessagesProvider(widget.conversationId).notifier)
            .remove(pendingId);
      });
    } catch (e) {
      if (mounted) {
        ref
            .read(pendingMessagesProvider(widget.conversationId).notifier)
            .remove(pendingId);
        if (_messageController.text.trim().isEmpty) {
          _messageController.text = text;
          _messageController.selection = TextSelection.collapsed(
            offset: _messageController.text.length,
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengirim pesan: ${ErrorMapper.getFriendlyMessage(e)}',
            ),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendAttachment(
    String receiverId,
    ChatAttachmentUpload attachment,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null || _isUploadingAttachment) return;

    final currentProfile = ref.read(currentProfileProvider).value;
    if (currentProfile?.isSuspended == true) {
      _showSnackBar('Akun Anda sedang ditangguhkan.', isError: true);
      return;
    }

    final pendingId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final pendingMessage = MessageModel.pendingAttachment(
      id: pendingId,
      conversationId: widget.conversationId,
      senderId: user.id,
      receiverId: receiverId,
      attachment: attachment.toPendingAttachment(),
      createdAt: DateTime.now(),
    );

    setState(() => _isUploadingAttachment = true);
    ref
        .read(pendingMessagesProvider(widget.conversationId).notifier)
        .add(pendingMessage);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }

    try {
      await ref
          .read(chatActionControllerProvider.notifier)
          .sendAttachment(widget.conversationId, receiverId, attachment);
      Future<void>.delayed(const Duration(seconds: 8), () {
        if (!mounted) return;
        ref
            .read(pendingMessagesProvider(widget.conversationId).notifier)
            .remove(pendingId);
      });
    } catch (e) {
      if (!mounted) return;
      ref
          .read(pendingMessagesProvider(widget.conversationId).notifier)
          .remove(pendingId);
      _showSnackBar(
        'Gagal mengirim lampiran: ${ErrorMapper.getFriendlyMessage(e)}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingAttachment = false);
      }
    }
  }

  Future<void> _pickDocument(String receiverId) async {
    if (_isUploadingAttachment) return;

    final result = await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'txt',
        'zip',
      ],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes =
        file.bytes ??
        (file.path == null ? null : await XFile(file.path!).readAsBytes());
    if (bytes == null || bytes.isEmpty) {
      _showSnackBar('Dokumen tidak dapat dibaca.', isError: true);
      return;
    }
    if (bytes.length > _maxAttachmentBytes) {
      _showSnackBar('Ukuran dokumen maksimal 20 MB.', isError: true);
      return;
    }

    await _sendAttachment(
      receiverId,
      ChatAttachmentUpload(
        type: 'document',
        fileName: file.name,
        mimeType: _mimeTypeForFile(
          file.name,
          fallback: 'application/octet-stream',
        ),
        sizeBytes: bytes.length,
        bytes: bytes,
      ),
    );
  }

  Future<void> _showMediaOptions(String receiverId) async {
    if (_isUploadingAttachment) return;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                _AttachmentActionTile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Ambil Foto',
                  subtitle: 'Gunakan kamera untuk bukti barang.',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(receiverId, ImageSource.camera);
                  },
                ),
                _AttachmentActionTile(
                  icon: Icons.image_outlined,
                  title: 'Pilih Foto',
                  subtitle: 'Kirim foto dari galeri.',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(receiverId, ImageSource.gallery);
                  },
                ),
                _AttachmentActionTile(
                  icon: Icons.videocam_outlined,
                  title: 'Rekam Video',
                  subtitle: 'Video akan dikompres jika lebih dari 20 MB.',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickVideo(receiverId, ImageSource.camera);
                  },
                ),
                _AttachmentActionTile(
                  icon: Icons.video_library_outlined,
                  title: 'Pilih Video',
                  subtitle: 'Kirim video bukti kondisi produk.',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickVideo(receiverId, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(String receiverId, ImageSource source) async {
    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (bytes.length > _maxAttachmentBytes) {
      _showSnackBar('Ukuran foto maksimal 20 MB.', isError: true);
      return;
    }

    await _sendAttachment(
      receiverId,
      ChatAttachmentUpload(
        type: 'image',
        fileName: _safePickedFileName(file.name, fallback: 'foto.jpg'),
        mimeType: file.mimeType ?? 'image/jpeg',
        sizeBytes: bytes.length,
        bytes: bytes,
      ),
    );
  }

  Future<void> _pickVideo(String receiverId, ImageSource source) async {
    final file = await _imagePicker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 5),
    );
    if (file == null) return;

    var uploadFile = file;
    var size = await uploadFile.length();
    if (size > _maxAttachmentBytes) {
      _showSnackBar('Mengompres video agar maksimal 20 MB...');
      final compressed = await compressChatVideoUnderLimit(
        path: file.path,
        maxBytes: _maxAttachmentBytes,
      );
      if (compressed == null) {
        _showSnackBar(
          'Video masih lebih dari 20 MB setelah kompresi.',
          isError: true,
        );
        return;
      }
      uploadFile = XFile(compressed.path, mimeType: file.mimeType);
      size = compressed.sizeBytes;
    }

    final bytes = await uploadFile.readAsBytes();
    await _sendAttachment(
      receiverId,
      ChatAttachmentUpload(
        type: 'video',
        fileName: _safePickedFileName(file.name, fallback: 'video.mp4'),
        mimeType: file.mimeType ?? 'video/mp4',
        sizeBytes: size,
        bytes: bytes,
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? context.colors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final conversationAsync = ref.watch(
      conversationDetailProvider(widget.conversationId),
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
      resizeToAvoidBottomInset: false,
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
      body: _ChatDetailBody(
        conversationId: widget.conversationId,
        currentUserId: user.id,
        conversationAsync: conversationAsync,
        messageController: _messageController,
        messageFocusNode: _messageFocusNode,
        scrollController: _scrollController,
        onSend: _sendMessage,
        onPickDocument: _pickDocument,
        onPickMedia: _showMediaOptions,
        isUploadingAttachment: _isUploadingAttachment,
      ),
    );
  }
}

class _ChatDetailBody extends StatelessWidget {
  static const double _composerReservedHeight = 92;

  final String conversationId;
  final String currentUserId;
  final AsyncValue<ConversationModel> conversationAsync;
  final TextEditingController messageController;
  final FocusNode messageFocusNode;
  final ScrollController scrollController;
  final ValueChanged<String> onSend;
  final ValueChanged<String> onPickDocument;
  final ValueChanged<String> onPickMedia;
  final bool isUploadingAttachment;

  const _ChatDetailBody({
    required this.conversationId,
    required this.currentUserId,
    required this.conversationAsync,
    required this.messageController,
    required this.messageFocusNode,
    required this.scrollController,
    required this.onSend,
    required this.onPickDocument,
    required this.onPickMedia,
    required this.isUploadingAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        const Positioned.fill(child: _ChatWallpaper()),
        Positioned.fill(
          child: Column(
            children: [
              _ProductSummaryStrip(conversationAsync: conversationAsync),
              Expanded(
                child: _ChatMessagesList(
                  conversationId: conversationId,
                  currentUserId: currentUserId,
                  conversation: conversationAsync.value,
                  scrollController: scrollController,
                  bottomPadding:
                      _composerReservedHeight + safeBottom + keyboardInset,
                ),
              ),
            ],
          ),
        ),
        conversationAsync.maybeWhen(
          data: (chat) {
            final isBuyer = chat.buyerId == currentUserId;
            final receiverId = isBuyer ? chat.sellerId : chat.buyerId;
            return Positioned(
              left: 0,
              right: 0,
              bottom: keyboardInset,
              child: _ChatComposer(
                controller: messageController,
                focusNode: messageFocusNode,
                onSend: () => onSend(receiverId),
                onPickDocument: () => onPickDocument(receiverId),
                onPickMedia: () => onPickMedia(receiverId),
                isUploadingAttachment: isUploadingAttachment,
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ProductSummaryStrip extends StatelessWidget {
  final AsyncValue<ConversationModel> conversationAsync;

  const _ProductSummaryStrip({required this.conversationAsync});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: conversationAsync.maybeWhen(
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
    );
  }
}

class _ChatMessagesList extends ConsumerWidget {
  final String conversationId;
  final String currentUserId;
  final ConversationModel? conversation;
  final ScrollController scrollController;
  final double bottomPadding;

  const _ChatMessagesList({
    required this.conversationId,
    required this.currentUserId,
    required this.conversation,
    required this.scrollController,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(visibleMessagesProvider(conversationId));

    return messagesAsync.when(
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

        final isBuyer = conversation?.buyerId == currentUserId;
        final otherUser = isBuyer ? conversation?.seller : conversation?.buyer;
        final meUser = isBuyer ? conversation?.buyer : conversation?.seller;

        return ListView.builder(
          controller: scrollController,
          reverse: true,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            bottomPadding,
          ),
          cacheExtent: 500,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final sourceIndex = messages.length - 1 - index;
            final msg = messages[sourceIndex];
            final isMe = msg.senderId == currentUserId;
            final time = DateFormat('HH:mm').format(msg.createdAt);

            final senderProfile = isMe ? meUser : otherUser;
            final avatarUrl = senderProfile?.avatarUrl;
            final senderName =
                senderProfile?.name ??
                senderProfile?.username ??
                (isMe ? 'Saya' : 'Pengguna');

            var showAvatarAndName = true;
            if (sourceIndex > 0) {
              final newerVisiblePrevious = messages[sourceIndex - 1];
              if (newerVisiblePrevious.senderId == msg.senderId) {
                showAvatarAndName = false;
              }
            }

            return _MessageBubble(
              message: msg,
              time: time,
              isMe: isMe,
              showAvatarAndName: showAvatarAndName,
              avatarUrl: avatarUrl,
              senderName: senderName,
            );
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: context.colors.primary),
      ),
      error: (err, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 42,
                color: context.colors.textMuted,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Chat belum dapat dimuat',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                ErrorMapper.getFriendlyMessage(err),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final String time;
  final bool isMe;
  final bool showAvatarAndName;
  final String? avatarUrl;
  final String senderName;

  const _MessageBubble({
    required this.message,
    required this.time,
    required this.isMe,
    required this.showAvatarAndName,
    required this.avatarUrl,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = message.id.startsWith('local-');

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: showAvatarAndName ? AppSpacing.md : AppSpacing.xs,
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
                    backgroundColor: context.colors.surfaceHighlight,
                    backgroundImage: avatarUrl != null
                        ? CachedNetworkImageProvider(avatarUrl!)
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
                  Flexible(
                    child: Text(
                      senderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
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
                if (!isMe) const SizedBox(width: 48),
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
                      borderRadius: BorderRadius.circular(16).copyWith(
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
                          : Border.all(color: context.colors.border),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                    ),
                    child: message.hasAttachment
                        ? _AttachmentMessageContent(
                            attachment: message.attachment!,
                            isMe: isMe,
                            time: time,
                            isPending: isPending,
                            isRead: message.isRead,
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  message.message,
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
                                padding: const EdgeInsets.only(bottom: 2),
                                child: _MessageMeta(
                                  time: time,
                                  isMe: isMe,
                                  isPending: isPending,
                                  isRead: message.isRead,
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
      ),
    );
  }
}

class _AttachmentMessageContent extends StatelessWidget {
  final ChatAttachment attachment;
  final bool isMe;
  final String time;
  final bool isPending;
  final bool isRead;

  const _AttachmentMessageContent({
    required this.attachment,
    required this.isMe,
    required this.time,
    required this.isPending,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    final meta = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Align(
        alignment: Alignment.centerRight,
        child: _MessageMeta(
          time: time,
          isMe: isMe,
          isPending: isPending,
          isRead: isRead,
        ),
      ),
    );

    if (attachment.isImage && attachment.url.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: attachment.url,
              width: 220,
              height: 170,
              fit: BoxFit.cover,
            ),
          ),
          meta,
        ],
      );
    }

    final icon = attachment.isVideo
        ? Icons.play_circle_outline_rounded
        : attachment.isDocument
        ? Icons.description_outlined
        : Icons.attach_file_rounded;

    final title = attachment.url.isEmpty
        ? 'Mengunggah...'
        : attachment.fileName;
    final sizeText = attachment.formattedSize;
    final subtitle = sizeText.isEmpty
        ? attachment.previewLabel
        : '${attachment.previewLabel} - $sizeText';

    return InkWell(
      onTap: attachment.url.isEmpty
          ? null
          : () => _openAttachment(context, attachment),
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 210, maxWidth: 240),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (isMe ? Colors.white : context.colors.primary)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isMe ? Colors.white : context.colors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : context.colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.72)
                              : context.colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            meta,
          ],
        ),
      ),
    );
  }
}

class _MessageMeta extends StatelessWidget {
  final String time;
  final bool isMe;
  final bool isPending;
  final bool isRead;

  const _MessageMeta({
    required this.time,
    required this.isMe,
    required this.isPending,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: 10,
            color: isMe
                ? Colors.white.withValues(alpha: 0.7)
                : context.colors.textMuted,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            isPending ? Icons.schedule_rounded : Icons.done_all_rounded,
            size: 14,
            color: isPending
                ? Colors.white.withValues(alpha: 0.65)
                : isRead
                ? const Color(0xFF7DD3FC)
                : Colors.white.withValues(alpha: 0.72),
          ),
        ],
      ],
    );
  }
}

class _ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onPickDocument;
  final VoidCallback onPickMedia;
  final bool isUploadingAttachment;

  const _ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onPickDocument,
    required this.onPickMedia,
    required this.isUploadingAttachment,
  });

  @override
  State<_ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<_ChatComposer> {
  late bool _hasText;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant _ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      _hasText = widget.controller.text.trim().isNotEmpty;
      widget.controller.addListener(_handleTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText == _hasText) return;
    setState(() {
      _hasText = hasText;
    });
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature segera hadir.')));
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: widget.controller,
                              focusNode: widget.focusNode,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.newline,
                              keyboardType: TextInputType.multiline,
                              scrollPadding: EdgeInsets.zero,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ketik pesan',
                                hintStyle: TextStyle(
                                  color: context.colors.textSecondary,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 13,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Lampiran',
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.attach_file_rounded,
                              color: context.colors.textSecondary,
                            ),
                            onPressed: widget.isUploadingAttachment
                                ? null
                                : widget.onPickDocument,
                          ),
                          IconButton(
                            tooltip: 'Kamera',
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.photo_camera_outlined,
                              color: context.colors.textSecondary,
                            ),
                            onPressed: widget.isUploadingAttachment
                                ? null
                                : widget.onPickMedia,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.primary.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: _hasText ? 'Kirim' : 'Pesan suara',
                      icon: widget.isUploadingAttachment
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _hasText ? Icons.send_rounded : Icons.mic_rounded,
                              color: Colors.white,
                            ),
                      padding: const EdgeInsets.all(13),
                      onPressed: widget.isUploadingAttachment
                          ? null
                          : _hasText
                          ? widget.onSend
                          : () => _showComingSoon(context, 'Pesan suara'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChatWallpaper extends StatelessWidget {
  const _ChatWallpaper();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: context.colors.background),
      child: CustomPaint(painter: _ChatWallpaperPainter(context.colors)),
    );
  }
}

class _ChatWallpaperPainter extends CustomPainter {
  final AppColorsExtension colors;

  const _ChatWallpaperPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = colors.primary.withValues(alpha: 0.022)
      ..style = PaintingStyle.fill;

    const step = 42.0;
    for (double y = 24; y < size.height + step; y += step) {
      for (double x = 20; x < size.width + step; x += step) {
        final shiftedX = x + ((y / step).round().isEven ? 0 : step / 2);
        canvas.drawCircle(Offset(shiftedX, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChatWallpaperPainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}

class _AttachmentActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AttachmentActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: context.colors.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: context.colors.textSecondary),
      ),
      onTap: onTap,
    );
  }
}

Future<void> _openAttachment(
  BuildContext context,
  ChatAttachment attachment,
) async {
  final uri = Uri.tryParse(attachment.url);
  if (uri == null) return;

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lampiran tidak dapat dibuka.')),
    );
  }
}

String _safePickedFileName(String value, {required String fallback}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return fallback;
  return trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9._ -]+'), '-');
}

String _mimeTypeForFile(String fileName, {required String fallback}) {
  final extension = fileName.split('.').last.toLowerCase();
  return switch (extension) {
    'pdf' => 'application/pdf',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'txt' => 'text/plain',
    'zip' => 'application/zip',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'mp4' => 'video/mp4',
    'mov' => 'video/quicktime',
    _ => fallback,
  };
}
