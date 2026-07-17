class RefundRequestModel {
  final String id;
  final String orderId;
  final String buyerId;
  final String sellerId;
  final String reason;
  final String description;
  final List<String> evidenceUrls;
  final double requestedAmount;
  final double approvedAmount;
  final String status;
  final String? sellerResponse;
  final String? adminNote;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RefundRequestModel({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.reason,
    required this.description,
    required this.evidenceUrls,
    required this.requestedAmount,
    required this.approvedAmount,
    required this.status,
    this.sellerResponse,
    this.adminNote,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RefundRequestModel.fromJson(Map<String, dynamic> json) {
    final createdAt = _parseDate(json['created_at']);
    return RefundRequestModel(
      id: _stringValue(json['id'], fallback: 'unknown-refund'),
      orderId: _stringValue(json['order_id']),
      buyerId: _stringValue(json['buyer_id']),
      sellerId: _stringValue(json['seller_id']),
      reason: _stringValue(json['reason'], fallback: 'Refund'),
      description: _stringValue(json['description']),
      evidenceUrls: _stringList(json['evidence_urls']),
      requestedAmount: _doubleValue(json['requested_amount']),
      approvedAmount: _doubleValue(json['approved_amount']),
      status: _stringValue(json['status'], fallback: 'submitted'),
      sellerResponse: _nullableString(json['seller_response']),
      adminNote: _nullableString(json['admin_note']),
      resolvedBy: _nullableString(json['resolved_by']),
      resolvedAt: _parseNullableDate(json['resolved_at']),
      createdAt: createdAt,
      updatedAt: _parseDate(json['updated_at'], fallback: createdAt),
    );
  }

  bool get isOpen {
    return status == 'submitted' ||
        status == 'seller_responded' ||
        status == 'under_review';
  }

  String get statusLabel {
    return switch (status) {
      'submitted' => 'Diajukan',
      'seller_responded' => 'Direspons Seller',
      'under_review' => 'Ditinjau Admin',
      'approved' => 'Disetujui',
      'partially_approved' => 'Disetujui Sebagian',
      'rejected' => 'Ditolak',
      'cancelled' => 'Dibatalkan',
      _ => status,
    };
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

String? _nullableString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return null;
}

double _doubleValue(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

DateTime _parseDate(dynamic value, {DateTime? fallback}) {
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ??
        fallback ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
  return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _parseNullableDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
