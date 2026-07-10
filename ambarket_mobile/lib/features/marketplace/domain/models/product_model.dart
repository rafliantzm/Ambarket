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
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      categoryId: json['category_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      condition: json['condition'] as String,
      brand: json['brand'] as String?,
      location: json['location'] as String,
      isNegotiable: json['is_negotiable'] as bool? ?? false,
      defects: json['defects'] as String?,
      completeness: json['completeness'] as String?,
      usageDuration: json['usage_duration'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      category: json['categories'] != null
          ? CategoryModel.fromJson(json['categories'] as Map<String, dynamic>)
          : null,
      images: json['product_images'] != null
          ? (json['product_images'] as List)
                .map(
                  (i) => ProductImageModel.fromJson(i as Map<String, dynamic>),
                )
                .toList()
          : [],
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
