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
    return OfferModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      offerPrice: (json['offer_price'] as num).toDouble(),
      message: json['message'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      product: json['products'] != null
          ? ProductModel.fromJson(json['products'] as Map<String, dynamic>)
          : null,
      buyer: json['buyer'] != null
          ? ProfileModel.fromJson(json['buyer'] as Map<String, dynamic>)
          : null,
      seller: json['seller'] != null
          ? ProfileModel.fromJson(json['seller'] as Map<String, dynamic>)
          : null,
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
