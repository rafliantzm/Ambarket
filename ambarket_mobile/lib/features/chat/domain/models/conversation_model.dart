import '../../../profile/domain/models/profile_model.dart';
import '../../../marketplace/domain/models/product_model.dart';
import '../../../offer/domain/models/offer_model.dart';

class ConversationModel {
  final String id;
  final String productId;
  final String buyerId;
  final String sellerId;
  final String? offerId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final ProductModel? product;
  final ProfileModel? buyer;
  final ProfileModel? seller;
  final OfferModel? offer;

  ConversationModel({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    this.offerId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.product,
    this.buyer,
    this.seller,
    this.offer,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      productId: json['product_id'],
      buyerId: json['buyer_id'],
      sellerId: json['seller_id'],
      offerId: json['offer_id'],
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null ? DateTime.parse(json['last_message_at']).toLocal() : null,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
      product: json['products'] != null ? ProductModel.fromJson(json['products']) : null,
      buyer: json['buyer'] != null ? ProfileModel.fromJson(json['buyer']) : null,
      seller: json['seller'] != null ? ProfileModel.fromJson(json['seller']) : null,
      offer: json['offers'] != null ? OfferModel.fromJson(json['offers']) : null,
    );
  }
}
