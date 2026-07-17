import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/conversation_model.dart';
import '../../domain/models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _client;
  static const _messageRefreshInterval = Duration(seconds: 2);
  static const _unreadRefreshInterval = Duration(seconds: 5);
  static final Map<String, List<MessageModel>> _messageCache = {};

  SupabaseChatRepository(this._client);

  @override
  Future<List<ConversationModel>> fetchMyConversations(
    String userId, {
    int offset = 0,
    int limit = 30,
  }) async {
    final response = await _client
        .from('conversations')
        .select(
          '*, products(*, product_images(*)), buyer:profiles!buyer_id(*), seller:profiles!seller_id(*), offers(*)',
        )
        .or('buyer_id.eq.$userId,seller_id.eq.$userId')
        .order('last_message_at', ascending: false)
        .range(offset, offset + limit - 1);

    return _parseConversations(response);
  }

  @override
  Future<ConversationModel> fetchConversationDetail(
    String conversationId,
  ) async {
    final response = await _client
        .from('conversations')
        .select(
          '*, products(*, product_images(*)), buyer:profiles!buyer_id(*), seller:profiles!seller_id(*), offers(*)',
        )
        .eq('id', conversationId)
        .or(
          'buyer_id.eq.${_client.auth.currentUser!.id},seller_id.eq.${_client.auth.currentUser!.id}',
        )
        .single();

    return ConversationModel.fromJson(response);
  }

  @override
  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _watchMessagesByPolling(conversationId);
  }

  @override
  Future<ConversationModel> createOrGetConversation(
    String productId,
    String buyerId,
    String sellerId, {
    String? offerId,
  }) async {
    // Check if exists
    final existing = await _client
        .from('conversations')
        .select(
          '*, products(*, product_images(*)), buyer:profiles!buyer_id(*), seller:profiles!seller_id(*), offers(*)',
        )
        .eq('product_id', productId)
        .eq('buyer_id', buyerId)
        .eq('seller_id', sellerId)
        .maybeSingle();

    if (existing != null) {
      if (offerId != null && existing['offer_id'] != offerId) {
        // Link offer if it wasn't linked
        await _client
            .from('conversations')
            .update({'offer_id': offerId})
            .eq('id', existing['id']);
        existing['offer_id'] = offerId;
      }
      return ConversationModel.fromJson(existing);
    }

    // Create new
    final response = await _client
        .from('conversations')
        .insert({
          'product_id': productId,
          'buyer_id': buyerId,
          'seller_id': sellerId,
          'offer_id': offerId,
        })
        .select(
          '*, products(*, product_images(*)), buyer:profiles!buyer_id(*), seller:profiles!seller_id(*), offers(*)',
        )
        .single();

    return ConversationModel.fromJson(response);
  }

  @override
  Future<ConversationModel> createOrGetConversationFromOffer(
    String offerId,
  ) async {
    final offerData = await _client
        .from('offers')
        .select()
        .eq('id', offerId)
        .single();
    return createOrGetConversation(
      offerData['product_id'],
      offerData['buyer_id'],
      offerData['seller_id'],
      offerId: offerId,
    );
  }

  @override
  Future<void> sendMessage(
    String conversationId,
    String senderId,
    String receiverId,
    String message,
  ) async {
    if (message.trim().isEmpty) throw Exception('Pesan tidak boleh kosong');

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message.trim(),
    });
  }

  @override
  Future<ChatAttachment> sendAttachment(
    String conversationId,
    String senderId,
    String receiverId,
    ChatAttachmentUpload attachment,
  ) async {
    if (attachment.bytes.isEmpty) {
      throw Exception('Lampiran tidak boleh kosong');
    }

    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final safeName = _sanitizeFileName(attachment.fileName);
    final storagePath = '$senderId/chat/$conversationId/$timestamp-$safeName';

    await _client.storage
        .from('product-images')
        .uploadBinary(
          storagePath,
          Uint8List.fromList(attachment.bytes),
          fileOptions: FileOptions(contentType: attachment.mimeType),
        );

    final attachmentUrl = _client.storage
        .from('product-images')
        .getPublicUrl(storagePath);

    final savedAttachment = ChatAttachment(
      type: attachment.type,
      url: attachmentUrl,
      fileName: attachment.fileName,
      mimeType: attachment.mimeType,
      sizeBytes: attachment.sizeBytes,
    );

    try {
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': savedAttachment.toMessagePayload(),
      });
    } catch (_) {
      await _client.storage.from('product-images').remove([storagePath]);
      rethrow;
    }

    return savedAttachment;
  }

  @override
  Future<void> markConversationAsRead(
    String conversationId,
    String userId,
  ) async {
    // Update messages sent to me as read
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .eq('receiver_id', userId)
        .eq('is_read', false);
  }

  @override
  Stream<int> watchUnreadCount(String conversationId, String userId) {
    return _watchUnreadCountByPolling(
      conversationId: conversationId,
      userId: userId,
    );
  }

  @override
  Stream<int> watchTotalUnreadCount(String userId) {
    return _watchUnreadCountByPolling(userId: userId);
  }

  Stream<List<MessageModel>> _watchMessagesByPolling(
    String conversationId,
  ) async* {
    final cachedMessages = _messageCache[conversationId];
    var hasYielded = true;
    var lastSignature = _messagesSignature(cachedMessages ?? const []);

    yield cachedMessages ?? const [];

    while (true) {
      try {
        final messages = await _fetchMessages(conversationId);
        final signature = _messagesSignature(messages);
        _messageCache[conversationId] = messages;

        if (!hasYielded || signature != lastSignature) {
          yield messages;
          lastSignature = signature;
          hasYielded = true;
        }
      } catch (_) {
        if (!hasYielded) {
          yield const [];
          hasYielded = true;
        }
      }

      await Future<void>.delayed(_messageRefreshInterval);
    }
  }

  Stream<int> _watchUnreadCountByPolling({
    String? conversationId,
    required String userId,
  }) async* {
    var hasYielded = false;
    int? lastCount;

    while (true) {
      try {
        final count = await _fetchUnreadCount(
          userId: userId,
          conversationId: conversationId,
        );

        if (!hasYielded || count != lastCount) {
          yield count;
          lastCount = count;
          hasYielded = true;
        }
      } catch (_) {
        if (!hasYielded) {
          yield 0;
          lastCount = 0;
          hasYielded = true;
        }
      }

      await Future<void>.delayed(_unreadRefreshInterval);
    }
  }

  Future<List<MessageModel>> _fetchMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List)
        .whereType<Map<String, dynamic>>()
        .map(_tryParseMessage)
        .whereType<MessageModel>()
        .toList(growable: false);
  }

  Future<int> _fetchUnreadCount({
    required String userId,
    String? conversationId,
  }) async {
    var query = _client
        .from('messages')
        .select('id')
        .eq('receiver_id', userId)
        .eq('is_read', false);

    if (conversationId != null) {
      query = query.eq('conversation_id', conversationId);
    }

    final response = await query;
    return (response as List).length;
  }

  List<ConversationModel> _parseConversations(List<dynamic> rows) {
    return rows
        .whereType<Map<String, dynamic>>()
        .map(_tryParseConversation)
        .whereType<ConversationModel>()
        .toList(growable: false);
  }

  ConversationModel? _tryParseConversation(Map<String, dynamic> row) {
    try {
      return ConversationModel.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  MessageModel? _tryParseMessage(Map<String, dynamic> row) {
    try {
      return MessageModel.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  String _messagesSignature(List<MessageModel> messages) {
    return messages
        .map(
          (message) =>
              '${message.id}:${message.isRead}:${message.createdAt.microsecondsSinceEpoch}',
        )
        .join('|');
  }
}

String _sanitizeFileName(String value) {
  final trimmed = value.trim();
  final fallback = trimmed.isEmpty ? 'attachment' : trimmed;
  return fallback
      .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
