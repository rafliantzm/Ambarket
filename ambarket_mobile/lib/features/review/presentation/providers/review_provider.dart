import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/features/review/domain/models/review_summary_model.dart';
import 'package:ambarket_mobile/features/review/domain/repositories/review_repository.dart';
import 'package:ambarket_mobile/features/review/data/repositories/supabase_review_repository.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:ambarket_mobile/features/order/presentation/providers/order_provider.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return SupabaseReviewRepository(Supabase.instance.client);
});

final sellerRatingSummaryProvider = FutureProvider.family<ReviewSummaryModel, String>((ref, sellerId) async {
  return ref.watch(reviewRepositoryProvider).fetchSellerRatingSummary(sellerId);
});

class CreateReviewState {
  final bool isLoading;
  final String? error;
  
  CreateReviewState({this.isLoading = false, this.error});
}

class CreateReviewController extends Notifier<CreateReviewState> {
  @override
  CreateReviewState build() {
    return CreateReviewState();
  }

  Future<bool> submitReview({
    required String orderId,
    required String productId,
    required String reviewedUserId,
    required int rating,
    String? comment,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    state = CreateReviewState(isLoading: true, error: null);
    try {
      await ref.read(reviewRepositoryProvider).createReview(
        orderId: orderId,
        productId: productId,
        reviewerId: user.id,
        reviewedUserId: reviewedUserId,
        rating: rating,
        comment: comment,
      );

      // Invalidate orders so the UI updates to "Sudah Direview"
      ref.invalidate(buyerOrdersProvider);
      // Also invalidate seller's rating summary
      ref.invalidate(sellerRatingSummaryProvider(reviewedUserId));

      state = CreateReviewState(isLoading: false);
      return true;
    } catch (e) {
      state = CreateReviewState(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final createReviewControllerProvider = NotifierProvider<CreateReviewController, CreateReviewState>(() {
  return CreateReviewController();
});
