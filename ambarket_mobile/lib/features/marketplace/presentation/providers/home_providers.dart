import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product_model.dart';
import 'marketplace_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

final homeRecommendedProvider = FutureProvider.autoDispose<List<ProductModel>>((
  ref,
) async {
  ref.keepAlive();
  final repo = ref.watch(marketplaceRepositoryProvider);
  return repo.fetchRecommendedProducts(limit: 6);
});

final homeLatestProductsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
      ref.keepAlive();
      final repo = ref.watch(marketplaceRepositoryProvider);
      return repo.fetchLatestProducts(limit: 6);
    });

final homeBestDealsProvider = FutureProvider.autoDispose<List<ProductModel>>((
  ref,
) async {
  ref.keepAlive();
  final repo = ref.watch(marketplaceRepositoryProvider);
  return repo.fetchBestDealProducts(limit: 6);
});

final homeNearbyProductsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
      ref.keepAlive();
      final repo = ref.watch(marketplaceRepositoryProvider);
      final profileAsync = ref.watch(currentProfileProvider);

      String? location;
      if (profileAsync.value != null && profileAsync.value!.location != null) {
        location = profileAsync.value!.location;
      }

      return repo.fetchNearbyProducts(location, limit: 6);
    });
