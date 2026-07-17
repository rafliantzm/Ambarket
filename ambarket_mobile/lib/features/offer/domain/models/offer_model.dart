import '../../../../features/marketplace/domain/models/product_model.dart';
import '../../../../features/profile/domain/models/profile_model.dart';

class OfferModel {
  final String id;
  final String productId;
  final String buyerId;
  final String sellerId;
  final double offerPrice;
  final String? message;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;
  final DateTime? expiresAt;

  // Relations
  final ProductModel? product;
  final ProfileModel? buyer;
  final ProfileModel? seller;

  OfferModel({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.offerPrice,
    this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.expiresAt,
    this.product,
    this.buyer,
    this.seller,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    final createdAt = _parseDate(json['created_at']);

    return OfferModel(
      id: _stringValue(json['id'], fallback: 'unknown-offer'),
      productId: _stringValue(json['product_id']),
      buyerId: _stringValue(json['buyer_id']),
      sellerId: _stringValue(json['seller_id']),
      offerPrice: _doubleValue(json['offer_price']),
      message: _nullableString(json['message']),
      status: _stringValue(json['status'], fallback: 'pending'),
      createdAt: createdAt,
      updatedAt: _parseDate(json['updated_at'], fallback: createdAt),
      acceptedAt: _parseNullableDate(json['accepted_at']),
      expiresAt: _parseNullableDate(json['expires_at']),
      product: _parseProduct(json['products']),
      buyer: _parseProfile(json['buyer']),
      seller: _parseProfile(json['seller']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'offer_price': offerPrice,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (acceptedAt != null) 'accepted_at': acceptedAt!.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
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

DateTime _parseDate(dynamic value, {DateTime? fallback}) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ??
        fallback ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
  return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _parseNullableDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

ProductModel? _parseProduct(dynamic value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  try {
    return ProductModel.fromJson(value);
  } catch (_) {
    return null;
  }
}

ProfileModel? _parseProfile(dynamic value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  try {
    return ProfileModel.fromJson(value);
  } catch (_) {
    return null;
  }
}

class CreateOfferInput {
  final String productId;
  final String sellerId;
  final double offerPrice;
  final String? message;

  CreateOfferInput({
    required this.productId,
    required this.sellerId,
    required this.offerPrice,
    this.message,
  });

  Map<String, dynamic> toJson(String buyerId) {
    return {
      'product_id': productId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'offer_price': offerPrice,
      'message': message,
    };
  }
}
