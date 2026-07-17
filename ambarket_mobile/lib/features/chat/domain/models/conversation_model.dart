import '../../../profile/domain/models/profile_model.dart';
import '../../../marketplace/domain/models/product_model.dart';
import '../../../offer/domain/models/offer_model.dart';
import 'message_model.dart';

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
      id: _stringValue(json['id'], fallback: 'unknown-conversation'),
      productId: _stringValue(json['product_id']),
      buyerId: _stringValue(json['buyer_id']),
      sellerId: _stringValue(json['seller_id']),
      offerId: _nullableString(json['offer_id']),
      lastMessage: _nullableString(json['last_message']),
      lastMessageAt: _nullableDate(json['last_message_at'])?.toLocal(),
      createdAt: _dateValue(json['created_at']).toLocal(),
      updatedAt: _dateValue(json['updated_at']).toLocal(),
      product: _parseProduct(json['products']),
      buyer: _parseProfile(json['buyer']),
      seller: _parseProfile(json['seller']),
      offer: _parseOffer(json['offers']),
    );
  }

  String get lastMessagePreview {
    final value = lastMessage;
    if (value == null || value.trim().isEmpty) {
      return 'Mulai percakapan';
    }
    return ChatAttachment.tryParse(value)?.previewLabel ?? value;
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

DateTime _dateValue(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _nullableDate(dynamic value) {
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

OfferModel? _parseOffer(dynamic value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }
  try {
    return OfferModel.fromJson(value);
  } catch (_) {
    return null;
  }
}
