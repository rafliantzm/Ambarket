class ProductImageModel {
  final String id;
  final String productId;
  final String imageUrl;
  final bool isPrimary;
  final DateTime createdAt;

  ProductImageModel({
    required this.id,
    required this.productId,
    required this.imageUrl,
    required this.isPrimary,
    required this.createdAt,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: _stringValue(json['id'], fallback: 'unknown-image'),
      productId: _stringValue(json['product_id']),
      imageUrl: _stringValue(json['image_url']),
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: _dateValue(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'image_url': imageUrl,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
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
