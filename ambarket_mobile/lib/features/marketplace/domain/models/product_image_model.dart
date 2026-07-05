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
      id: json['id'] as String,
      productId: json['product_id'] as String,
      imageUrl: json['image_url'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
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
