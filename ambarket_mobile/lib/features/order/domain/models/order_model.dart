import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/offer/domain/models/offer_model.dart';

class OrderModel {
  final String id;
  final String? offerId;
  final String productId;
  final String buyerId;
  final String sellerId;
  final double totalPrice;
  final String shippingAddress;
  final String shippingPhone;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isReviewed;
  
  final ProductModel? product;
  final ProfileModel? buyer;
  final ProfileModel? seller;
  final OfferModel? offer;

  OrderModel({
    required this.id,
    this.offerId,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.totalPrice,
    required this.shippingAddress,
    required this.shippingPhone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.isReviewed = false,
    this.product,
    this.buyer,
    this.seller,
    this.offer,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      offerId: json['offer_id'] as String?,
      productId: json['product_id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      totalPrice: double.parse(json['total_price'].toString()),
      shippingAddress: json['shipping_address'] as String,
      shippingPhone: json['shipping_phone'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isReviewed: json['reviews'] != null && (json['reviews'] as List).isNotEmpty,
      product: json['product'] != null ? ProductModel.fromJson(json['product'] as Map<String, dynamic>) : null,
      buyer: json['buyer'] != null ? ProfileModel.fromJson(json['buyer'] as Map<String, dynamic>) : null,
      seller: json['seller'] != null ? ProfileModel.fromJson(json['seller'] as Map<String, dynamic>) : null,
      offer: json['offer'] != null ? OfferModel.fromJson(json['offer'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offer_id': offerId,
      'product_id': productId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'total_price': totalPrice,
      'shipping_address': shippingAddress,
      'shipping_phone': shippingPhone,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? offerId,
    String? productId,
    String? buyerId,
    String? sellerId,
    double? totalPrice,
    String? shippingAddress,
    String? shippingPhone,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isReviewed,
    ProductModel? product,
    ProfileModel? buyer,
    ProfileModel? seller,
    OfferModel? offer,
  }) {
    return OrderModel(
      id: id ?? this.id,
      offerId: offerId ?? this.offerId,
      productId: productId ?? this.productId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      totalPrice: totalPrice ?? this.totalPrice,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingPhone: shippingPhone ?? this.shippingPhone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isReviewed: isReviewed ?? this.isReviewed,
      product: product ?? this.product,
      buyer: buyer ?? this.buyer,
      seller: seller ?? this.seller,
      offer: offer ?? this.offer,
    );
  }
}
