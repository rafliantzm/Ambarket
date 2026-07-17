import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/product_model.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../data/repositories/supabase_marketplace_repository.dart';

// Repository Provider
final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseMarketplaceRepository(client);
});

// Categories Provider
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(marketplaceRepositoryProvider);
  return repo.fetchCategories();
});

// Search Query Provider
class SearchQueryNotifier extends Notifier<String> {
  Timer? _debounceTimer;

  @override
  String build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return '';
  }

  void updateQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      state = query;
    });
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

// Category Filter Provider
class SelectedCategoryIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void updateCategory(String? categoryId) {
    state = categoryId;
  }
}

final selectedCategoryIdProvider =
    NotifierProvider<SelectedCategoryIdNotifier, String?>(() {
      return SelectedCategoryIdNotifier();
    });

// Condition Filter Provider
class SelectedConditionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void updateCondition(String? condition) {
    state = condition;
  }
}

final selectedConditionProvider =
    NotifierProvider<SelectedConditionNotifier, String?>(() {
      return SelectedConditionNotifier();
    });

class PaginatedProductsState {
  final List<ProductModel> products;
  final bool hasMore;
  final bool isFetchingMore;

  PaginatedProductsState({
    required this.products,
    required this.hasMore,
    this.isFetchingMore = false,
  });

  PaginatedProductsState copyWith({
    List<ProductModel>? products,
    bool? hasMore,
    bool? isFetchingMore,
  }) {
    return PaginatedProductsState(
      products: products ?? this.products,
      hasMore: hasMore ?? this.hasMore,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }
}

class ProductsNotifier extends AsyncNotifier<PaginatedProductsState> {
  static const int _limit = 12;
  int _offset = 0;

  @override
  FutureOr<PaginatedProductsState> build() async {
    return _fetchInitial();
  }

  Future<PaginatedProductsState> _fetchInitial() async {
    _offset = 0;
    final repo = ref.read(marketplaceRepositoryProvider);
    final query = ref.watch(searchQueryProvider);
    final categoryId = ref.watch(selectedCategoryIdProvider);
    final condition = ref.watch(selectedConditionProvider);

    final products = await repo.getProducts(
      query: query,
      categoryId: categoryId,
      condition: condition,
      offset: _offset,
      limit: _limit,
    );

    return PaginatedProductsState(
      products: products,
      hasMore: products.length == _limit,
    );
  }

  Future<void> fetchMore() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isFetchingMore ||
        state.isLoading) {
      return;
    }

    state = AsyncData(currentState.copyWith(isFetchingMore: true));
    try {
      _offset += _limit;
      final repo = ref.read(marketplaceRepositoryProvider);
      final query = ref.read(searchQueryProvider);
      final categoryId = ref.read(selectedCategoryIdProvider);
      final condition = ref.read(selectedConditionProvider);

      final newProducts = await repo.getProducts(
        query: query,
        categoryId: categoryId,
        condition: condition,
        offset: _offset,
        limit: _limit,
      );

      state = AsyncData(
        PaginatedProductsState(
          products: [...currentState.products, ...newProducts],
          hasMore: newProducts.length == _limit,
        ),
      );
    } catch (_) {
      _offset -= _limit;
      state = AsyncData(currentState.copyWith(isFetchingMore: false));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final newState = await _fetchInitial();
      state = AsyncData(newState);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, PaginatedProductsState>(() {
      return ProductsNotifier();
    });

// Product Detail Provider
final productDetailProvider = FutureProvider.family<ProductModel, String>((
  ref,
  id,
) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  return repo.fetchProductDetail(id);
});

// Related Products Provider
// Takes a tuple of (productId, categoryId)
final relatedProductsProvider =
    FutureProvider.family<
      List<ProductModel>,
      ({String productId, String categoryId})
    >((ref, args) async {
      final repo = ref.watch(marketplaceRepositoryProvider);
      return repo.fetchRelatedProducts(args.productId, args.categoryId);
    });

// Seller Public Products Provider
final sellerPublicProductsProvider =
    FutureProvider.family<
      List<ProductModel>,
      ({String sellerId, String? query, String? categoryId})
    >((ref, args) async {
      final repo = ref.watch(marketplaceRepositoryProvider);
      return repo.fetchSellerActiveProducts(
        args.sellerId,
        query: args.query,
        categoryId: args.categoryId,
      );
    });
