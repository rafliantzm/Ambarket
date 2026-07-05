import 'package:ambarket_mobile/features/review/domain/models/review_model.dart';
import 'package:ambarket_mobile/features/review/domain/models/review_summary_model.dart';

abstract class ReviewRepository {
  Future<ReviewModel> createReview({
    required String orderId,
    required String productId,
    required String reviewerId,
    required String reviewedUserId,
    required int rating,
    String? comment,
  });

  Future<List<ReviewModel>> fetchReviewsForUser(String userId);
  Future<ReviewSummaryModel> fetchSellerRatingSummary(String sellerId);
}
