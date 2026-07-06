import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product_model.dart';
import 'marketplace_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

final homeRecommendedProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  return repo.fetchRecommendedProducts();
});

final homeLatestProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  return repo.fetchLatestProducts();
});

final homeBestDealsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  return repo.fetchBestDealProducts();
});

final homeNearbyProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  final profileAsync = ref.watch(currentProfileProvider);
  
  String? location;
  if (profileAsync.value != null && profileAsync.value!.location != null) {
    location = profileAsync.value!.location;
  }
  
  return repo.fetchNearbyProducts(location);
});
