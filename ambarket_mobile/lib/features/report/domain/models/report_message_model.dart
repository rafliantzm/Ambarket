class ReportMessageModel {
  final String id;
  final String reportId;
  final String senderId;
  final String senderRole; // 'user' or 'admin'
  final String message;
  final String? attachmentUrl;
  final DateTime createdAt;

  ReportMessageModel({
    required this.id,
    required this.reportId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    this.attachmentUrl,
    required this.createdAt,
  });

  factory ReportMessageModel.fromJson(Map<String, dynamic> json) {
    return ReportMessageModel(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      senderId: json['sender_id'] as String,
      senderRole: json['sender_role'] as String,
      message: json['message'] as String,
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'message': message,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
