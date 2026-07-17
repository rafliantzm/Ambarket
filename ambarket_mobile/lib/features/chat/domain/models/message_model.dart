import 'dart:convert';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final ChatAttachment? attachment;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.createdAt,
    ChatAttachment? attachment,
  }) : attachment = attachment ?? ChatAttachment.tryParse(message);

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: _stringValue(json['id'], fallback: 'unknown-message'),
      conversationId: _stringValue(json['conversation_id']),
      senderId: _stringValue(json['sender_id']),
      receiverId: _stringValue(json['receiver_id']),
      message: _stringValue(json['message']),
      isRead: json['is_read'] ?? false,
      createdAt: _dateValue(json['created_at']).toLocal(),
    );
  }

  factory MessageModel.pendingAttachment({
    required String id,
    required String conversationId,
    required String senderId,
    required String receiverId,
    required ChatAttachment attachment,
    required DateTime createdAt,
  }) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      message: attachment.toMessagePayload(),
      isRead: true,
      createdAt: createdAt,
      attachment: attachment,
    );
  }

  String get displayMessage => attachment?.previewLabel ?? message;
  bool get hasAttachment => attachment != null;
}

class ChatAttachment {
  static const marker = '__AMBARKET_ATTACHMENT_V1__';

  final String type;
  final String url;
  final String fileName;
  final String mimeType;
  final int sizeBytes;

  const ChatAttachment({
    required this.type,
    required this.url,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });

  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
  bool get isDocument => type == 'document';

  String get previewLabel {
    if (isImage) return 'Foto';
    if (isVideo) return 'Video';
    return 'Dokumen';
  }

  String get formattedSize {
    if (sizeBytes <= 0) return '';
    final mb = sizeBytes / (1024 * 1024);
    if (mb >= 1) {
      return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
    }
    return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      'fileName': fileName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
    };
  }

  String toMessagePayload() => '$marker${jsonEncode(toJson())}';

  static ChatAttachment? tryParse(String value) {
    if (!value.startsWith(marker)) return null;

    try {
      final parsed = jsonDecode(value.substring(marker.length));
      if (parsed is! Map<String, dynamic>) return null;

      final type = _stringValue(parsed['type']);
      final url = _stringValue(parsed['url']);
      if (type.isEmpty || url.isEmpty) return null;

      return ChatAttachment(
        type: type,
        url: url,
        fileName: _stringValue(parsed['fileName'], fallback: 'Lampiran'),
        mimeType: _stringValue(parsed['mimeType']),
        sizeBytes: _intValue(parsed['sizeBytes']),
      );
    } catch (_) {
      return null;
    }
  }
}

class ChatAttachmentUpload {
  final String type;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final List<int> bytes;

  const ChatAttachmentUpload({
    required this.type,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.bytes,
  });

  ChatAttachment toPendingAttachment() {
    return ChatAttachment(
      type: type,
      url: '',
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
    );
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

int _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime _dateValue(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
