class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? relatedType;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedType,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _stringOrFallback(json['id'], 'unknown'),
      userId: _stringOrFallback(json['user_id'], ''),
      type: _stringOrFallback(json['type'], 'general'),
      title: _stringOrFallback(json['title'], 'Notifikasi'),
      body: _stringOrFallback(json['body'], 'Ada pembaruan baru.'),
      relatedType: _nullableString(json['related_type']),
      relatedId: _nullableString(json['related_id']),
      isRead: json['is_read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(_stringOrFallback(json['created_at'], '')) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static String _stringOrFallback(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'related_type': relatedType,
      'related_id': relatedId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    String? relatedType,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      relatedType: relatedType ?? this.relatedType,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
