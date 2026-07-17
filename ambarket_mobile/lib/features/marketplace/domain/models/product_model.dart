import 'category_model.dart';
import 'product_image_model.dart';

class ProductModel {
  final String id;
  final String sellerId;
  final String categoryId;
  final String title;
  final String description;
  final double price;
  final String condition;
  final String? brand;
  final String location;
  final bool isNegotiable;
  final String? defects;
  final String? completeness;
  final String? usageDuration;
  final String status;
  final DateTime createdAt;

  // Relations
  final CategoryModel? category;
  final List<ProductImageModel> images;

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
    this.brand,
    required this.location,
    required this.isNegotiable,
    this.defects,
    this.completeness,
    this.usageDuration,
    required this.status,
    required this.createdAt,
    this.category,
    this.images = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: _stringValue(json['id'], fallback: 'unknown-product'),
      sellerId: _stringValue(json['seller_id']),
      categoryId: _stringValue(json['category_id']),
      title: _stringValue(json['title'], fallback: 'Produk'),
      description: _stringValue(json['description']),
      price: _doubleValue(json['price']),
      condition: _stringValue(json['condition'], fallback: 'good'),
      brand: _nullableString(json['brand']),
      location: _stringValue(json['location']),
      isNegotiable: json['is_negotiable'] as bool? ?? false,
      defects: _nullableString(json['defects']),
      completeness: _nullableString(json['completeness']),
      usageDuration: _nullableString(json['usage_duration']),
      status: _stringValue(json['status'], fallback: 'active'),
      createdAt: _dateValue(json['created_at']),
      category: _parseCategory(json['categories']),
      images: _parseImages(json['product_images']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'price': price,
      'condition': condition,
      'brand': brand,
      'location': location,
      'is_negotiable': isNegotiable,
      'defects': defects,
      'completeness': completeness,
      'usage_duration': usageDuration,
      'status': status,
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

String? _nullableString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return null;
}

double _doubleValue(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
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

CategoryModel? _parseCategory(dynamic value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  try {
    return CategoryModel.fromJson(value);
  } catch (_) {
    return null;
  }
}

List<ProductImageModel> _parseImages(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(ProductImageModel.fromJson)
      .where((image) => image.imageUrl.isNotEmpty)
      .toList(growable: false);
}
