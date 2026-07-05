class AdminAuditLogModel {
  final String id;
  final String? adminId;
  final String action;
  final String targetType;
  final String? targetId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  AdminAuditLogModel({
    required this.id,
    this.adminId,
    required this.action,
    required this.targetType,
    this.targetId,
    this.metadata,
    required this.createdAt,
  });

  factory AdminAuditLogModel.fromJson(Map<String, dynamic> json) {
    return AdminAuditLogModel(
      id: json['id'] as String,
      adminId: json['admin_id'] as String?,
      action: json['action'] as String,
      targetType: json['target_type'] as String,
      targetId: json['target_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (adminId != null) 'admin_id': adminId,
      'action': action,
      'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (metadata != null) 'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
