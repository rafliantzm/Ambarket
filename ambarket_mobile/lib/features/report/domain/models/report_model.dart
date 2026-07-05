class ReportModel {
  final String id;
  final String reporterId;
  final String targetType; // 'product', 'user', 'review'
  final String targetId;
  final String reason;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      targetType: json['target_type'] as String,
      targetId: json['target_id'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
    };
  }
}
