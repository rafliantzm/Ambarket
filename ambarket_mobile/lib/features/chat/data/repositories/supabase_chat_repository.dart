import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/conversation_model.dart';
import '../../domain/models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _client;

  SupabaseChatRepository(this._client);

  @override
  Future<List<ConversationModel>> fetchMyConversations(String userId, {int offset = 0, int limit = 30}) async {
    final response = await _client
        .from('conversations')
        .select('*, products(*, product_images(*)), buyer:profiles!buyer_id(*), seller:profiles!seller_id(*), offers(*)')
        .or('buyer_id.eq.$userId,seller_id.eq.$userId')
        .order('last_message_at', ascending: false)
        .range(offset, offset + limit - 1);
        
    return (response as List).map((json) => ConversationModel.fromJson(json)).toList();
  }

  @override
  Future<ConversationModel> fetchConversationDetail(String conversationId) async {
    final response = await _client
        .from('conversations')
        .select('*, products(*, product_images(*)), buyer:profiles!buyer_id(*), seller:profiles!seller_id(*), offers(*)')
        .eq('id', conversationId)
        .or('buyer_id.eq.${_client.auth.currentUser!.id},seller_id.eq.${_client.auth.currentUser!.id}')
        .single();
        
    return ConversationModel.fromJson(response);
  }

  @override
  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((list) => list.map((json) => MessageModel.fromJson(json)).toList());
  }

  @override
  Future<ConversationModel> createOrGetConversation(String productId, String buyerId, String sellerId, {String? offerId}) async {
    // Check if exists
    final existing = await _client
        .from('conversations')
        .select('*, products(*, product_images(*)), buyer:profiles!buyer_id(*), seller:profiles!seller_id(*), offers(*)')
        .eq('product_id', productId)
        .eq('buyer_id', buyerId)
        .eq('seller_id', sellerId)
        .maybeSingle();

    if (existing != null) {
      if (offerId != null && existing['offer_id'] != offerId) {
        // Link offer if it wasn't linked
        await _client.from('conversations').update({'offer_id': offerId}).eq('id', existing['id']);
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
        .select('*, products(*, product_images(*)), buyer:profiles!buyer_id(*), seller:profiles!seller_id(*), offers(*)')
        .single();

    return ConversationModel.fromJson(response);
  }

  @override
  Future<ConversationModel> createOrGetConversationFromOffer(String offerId) async {
    final offerData = await _client.from('offers').select().eq('id', offerId).single();
    return createOrGetConversation(
      offerData['product_id'],
      offerData['buyer_id'],
      offerData['seller_id'],
      offerId: offerId,
    );
  }

  @override
  Future<void> sendMessage(String conversationId, String senderId, String receiverId, String message) async {
    if (message.trim().isEmpty) throw Exception('Pesan tidak boleh kosong');
    
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message.trim(),
    });
  }

  @override
  Future<void> markConversationAsRead(String conversationId, String userId) async {
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
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .map((list) => list.where((msg) => msg['receiver_id'] == userId && msg['is_read'] == false).length);
  }
}
