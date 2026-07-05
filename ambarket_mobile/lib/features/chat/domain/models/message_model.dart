class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}
