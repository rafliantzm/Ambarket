import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/features/review/domain/models/review_model.dart';
import 'package:ambarket_mobile/features/review/domain/models/review_summary_model.dart';
import 'package:ambarket_mobile/features/review/domain/repositories/review_repository.dart';

class SupabaseReviewRepository implements ReviewRepository {
  final SupabaseClient _client;

  SupabaseReviewRepository(this._client);

  @override
  Future<ReviewModel> createReview({
    required String orderId,
    required String productId,
    required String reviewerId,
    required String reviewedUserId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _client.from('reviews').insert({
        'order_id': orderId,
        'product_id': productId,
        'reviewer_id': reviewerId,
        'reviewed_user_id': reviewedUserId,
        'rating': rating,
        'comment': comment,
      }).select().single();

      return ReviewModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Anda sudah memberikan ulasan untuk pesanan ini.');
      }
      rethrow;
    }
  }

  @override
  Future<List<ReviewModel>> fetchReviewsForUser(String userId) async {
    final response = await _client
        .from('reviews')
        .select('*, reviewer:profiles!reviews_reviewer_id_fkey(*)')
        .eq('reviewed_user_id', userId)
        .order('created_at', ascending: false);
    
    return response.map((json) => ReviewModel.fromJson(json)).toList();
  }

  @override
  Future<ReviewSummaryModel> fetchSellerRatingSummary(String sellerId) async {
    // To fetch average and count, we can use Supabase aggregate functions or just fetch all ratings.
    // For MVP, we can query just the ratings to calculate client-side if it's small, 
    // or use Supabase RPC if we created one.
    // Let's just fetch the ratings to compute average here for simplicity.
    final response = await _client
        .from('reviews')
        .select('rating')
        .eq('reviewed_user_id', sellerId);
        
    if (response.isEmpty) {
      return ReviewSummaryModel(averageRating: 0.0, totalReviews: 0);
    }
    
    double total = 0;
    for (var row in response) {
      total += row['rating'] as int;
    }
    
    return ReviewSummaryModel(
      averageRating: total / response.length,
      totalReviews: response.length,
    );
  }
}
