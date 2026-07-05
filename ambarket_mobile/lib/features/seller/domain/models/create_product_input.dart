import 'dart:typed_data';

class CreateProductInput {
  final String title;
  final String description;
  final String categoryId;
  final double price;
  final String condition;
  final String? brand;
  final String location;
  final bool isNegotiable;
  final String? defects;
  final String? completeness;
  final String? usageDuration;
  final String status;

  // Images to upload
  final List<Uint8List> imageBytesList;

  CreateProductInput({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.price,
    required this.condition,
    this.brand,
    required this.location,
    required this.isNegotiable,
    this.defects,
    this.completeness,
    this.usageDuration,
    this.status = 'active',
    this.imageBytesList = const [],
  });

  Map<String, dynamic> toJson(String sellerId) {
    return {
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'price': price,
      'condition': condition,
      'brand': brand,
      'location': location,
      'is_negotiable': isNegotiable,
      'defects': defects,
      'completeness': completeness,
      'usage_duration': usageDuration,
      'status': status,
    };
  }
}

class UpdateProductInput {
  final String title;
  final String description;
  final String categoryId;
  final double price;
  final String condition;
  final String? brand;
  final String location;
  final bool isNegotiable;
  final String? defects;
  final String? completeness;
  final String? usageDuration;
  final String status;

  UpdateProductInput({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.price,
    required this.condition,
    this.brand,
    required this.location,
    required this.isNegotiable,
    this.defects,
    this.completeness,
    this.usageDuration,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category_id': categoryId,
      'price': price,
      'condition': condition,
      'brand': brand,
      'location': location,
      'is_negotiable': isNegotiable,
      'defects': defects,
      'completeness': completeness,
      'usage_duration': usageDuration,
      'status': status,
    };
  }
}
