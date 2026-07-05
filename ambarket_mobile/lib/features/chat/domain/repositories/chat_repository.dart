import '../models/conversation_model.dart';
import '../models/message_model.dart';

abstract class ChatRepository {
  Future<List<ConversationModel>> fetchMyConversations(String userId, {int offset = 0, int limit = 30});
  Future<ConversationModel> fetchConversationDetail(String conversationId);
  Stream<List<MessageModel>> watchMessages(String conversationId);
  Future<ConversationModel> createOrGetConversation(String productId, String buyerId, String sellerId, {String? offerId});
  Future<ConversationModel> createOrGetConversationFromOffer(String offerId);
  Future<void> sendMessage(String conversationId, String senderId, String receiverId, String message);
  Future<void> markConversationAsRead(String conversationId, String userId);
  Stream<int> watchUnreadCount(String conversationId, String userId);
}
