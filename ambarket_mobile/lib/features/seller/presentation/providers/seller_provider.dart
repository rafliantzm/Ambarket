import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/create_product_input.dart';
import '../../domain/repositories/seller_repository.dart';
import '../../data/repositories/supabase_seller_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../marketplace/domain/models/product_model.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../domain/models/seller_dashboard_stats.dart';
import '../../../order/domain/models/order_model.dart';
import '../../../offer/domain/models/offer_model.dart';

// Seller Repository Provider
final sellerRepositoryProvider = Provider<SellerRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseSellerRepository(client);
});

class PaginatedSellerProductsState {
  final List<ProductModel> products;
  final bool hasMore;

  PaginatedSellerProductsState({required this.products, required this.hasMore});
}

class MyProductsNotifier extends AsyncNotifier<PaginatedSellerProductsState> {
  static const int _limit = 8;
  int _offset = 0;

  @override
  FutureOr<PaginatedSellerProductsState> build() async {
    return _fetchInitial();
  }

  Future<PaginatedSellerProductsState> _fetchInitial() async {
    _offset = 0;
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return PaginatedSellerProductsState(products: [], hasMore: false);
    }

    final repo = ref.watch(sellerRepositoryProvider);
    final products = await repo.fetchMyProducts(
      user.id,
      offset: _offset,
      limit: _limit,
    );
    return PaginatedSellerProductsState(
      products: products,
      hasMore: products.length == _limit,
    );
  }

  Future<void> fetchMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore || state.isLoading) {
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }

    state = const AsyncLoading();
    try {
      _offset += _limit;
      final repo = ref.read(sellerRepositoryProvider);
      final newProducts = await repo.fetchMyProducts(
        user.id,
        offset: _offset,
        limit: _limit,
      );

      state = AsyncData(
        PaginatedSellerProductsState(
          products: [...currentState.products, ...newProducts],
          hasMore: newProducts.length == _limit,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final myProductsProvider =
    AsyncNotifierProvider<MyProductsNotifier, PaginatedSellerProductsState>(() {
      return MyProductsNotifier();
    });

// Seller Product Detail Provider
final sellerProductDetailProvider = FutureProvider.family<ProductModel, String>(
  (ref, id) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) throw Exception('User not logged in');

    final repo = ref.watch(sellerRepositoryProvider);
    return repo.fetchMyProductDetail(id, user.id);
  },
);

// Product Action Controller
class ProductActionController extends AsyncNotifier<void> {
  late final SellerRepository _repo;

  @override
  FutureOr<void> build() {
    _repo = ref.watch(sellerRepositoryProvider);
  }

  Future<void> createProduct(CreateProductInput input) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      await _repo.createProduct(user.id, input);

      ref.invalidate(myProductsProvider);
      ref.invalidate(productsProvider); // Refresh marketplace
    });
  }

  Future<void> updateProduct(String productId, UpdateProductInput input) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      await _repo.updateProduct(productId, user.id, input);

      ref.invalidate(myProductsProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(sellerProductDetailProvider(productId));
      ref.invalidate(productDetailProvider(productId));
    });
  }

  Future<void> updateProductStatus(String productId, String status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      await _repo.updateProductStatus(productId, user.id, status);

      ref.invalidate(myProductsProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(sellerProductDetailProvider(productId));
      ref.invalidate(productDetailProvider(productId));
    });
  }
}

final productActionControllerProvider =
    AsyncNotifierProvider<ProductActionController, void>(() {
      return ProductActionController();
    });

// Phase 8E.1 Dashboard Providers

final sellerDashboardStatsProvider =
    FutureProvider.autoDispose<SellerDashboardStats>((ref) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) throw Exception('User not logged in');
      final repo = ref.watch(sellerRepositoryProvider);
      return repo.fetchSellerDashboardStats(user.id);
    });

final sellerRecentOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>(
  (ref) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) throw Exception('User not logged in');
    final repo = ref.watch(sellerRepositoryProvider);
    return repo.fetchRecentSellerOrders(user.id, limit: 5);
  },
);

final sellerRecentOffersProvider = FutureProvider.autoDispose<List<OfferModel>>(
  (ref) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) throw Exception('User not logged in');
    final repo = ref.watch(sellerRepositoryProvider);
    return repo.fetchRecentSellerOffers(user.id, limit: 5);
  },
);
