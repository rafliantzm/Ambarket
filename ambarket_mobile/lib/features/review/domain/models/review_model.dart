import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';

class ReviewModel {
  final String id;
  final String orderId;
  final String productId;
  final String reviewerId;
  final String reviewedUserId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isHidden;

  final ProductModel? product;
  final ProfileModel? reviewer;
  final ProfileModel? reviewedUser;

  ReviewModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.reviewerId,
    required this.reviewedUserId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.isHidden = false,
    this.product,
    this.reviewer,
    this.reviewedUser,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      reviewedUserId: json['reviewed_user_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isHidden: json['is_hidden'] as bool? ?? false,
      product: json['product'] != null
          ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      reviewer: json['reviewer'] != null
          ? ProfileModel.fromJson(json['reviewer'] as Map<String, dynamic>)
          : null,
      reviewedUser: json['reviewed_user'] != null
          ? ProfileModel.fromJson(json['reviewed_user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'reviewer_id': reviewerId,
      'reviewed_user_id': reviewedUserId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
