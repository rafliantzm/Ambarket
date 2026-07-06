import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../marketplace/domain/models/product_model.dart';
import '../../domain/models/seller_product_stats.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'seller_provider.dart';

class SellerProductStatusFilter extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String status) {
    state = status;
  }
}

final sellerProductStatusFilterProvider = NotifierProvider<SellerProductStatusFilter, String>(SellerProductStatusFilter.new);

class SellerProductSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final sellerProductSearchQueryProvider = NotifierProvider<SellerProductSearchQuery, String>(SellerProductSearchQuery.new);

class SellerProductListNotifier extends AsyncNotifier<List<ProductModel>> {
  @override
  Future<List<ProductModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final status = ref.watch(sellerProductStatusFilterProvider);
    final query = ref.watch(sellerProductSearchQueryProvider);

    return ref.read(sellerRepositoryProvider).fetchSellerProductsFiltered(
      user.id,
      status: status,
      searchQuery: query,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final sellerProductsProvider = AsyncNotifierProvider<SellerProductListNotifier, List<ProductModel>>(SellerProductListNotifier.new);

class SellerProductStatsNotifier extends AsyncNotifier<SellerProductStats> {
  @override
  Future<SellerProductStats> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return SellerProductStats.empty();

    return ref.read(sellerRepositoryProvider).fetchSellerProductStats(user.id);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final sellerProductStatsProvider = AsyncNotifierProvider<SellerProductStatsNotifier, SellerProductStats>(SellerProductStatsNotifier.new);

class SellerProductActionState {
  final bool isLoading;
  final String? error;
  SellerProductActionState({this.isLoading = false, this.error});
}

class SellerProductActionController extends Notifier<SellerProductActionState> {
  @override
  SellerProductActionState build() => SellerProductActionState();

  Future<bool> archiveProduct(String productId) async {
    state = SellerProductActionState(isLoading: true);
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = SellerProductActionState(error: 'User not authenticated');
      return false;
    }

    try {
      await ref.read(sellerRepositoryProvider).archiveProduct(productId, user.id);
      _refreshDependencies();
      state = SellerProductActionState();
      return true;
    } catch (e) {
      state = SellerProductActionState(error: e.toString());
      return false;
    }
  }

  Future<bool> reactivateProduct(String productId) async {
    state = SellerProductActionState(isLoading: true);
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = SellerProductActionState(error: 'User not authenticated');
      return false;
    }

    try {
      await ref.read(sellerRepositoryProvider).reactivateArchivedProduct(productId, user.id);
      _refreshDependencies();
      state = SellerProductActionState();
      return true;
    } catch (e) {
      state = SellerProductActionState(error: e.toString());
      return false;
    }
  }

  void _refreshDependencies() {
    ref.invalidate(sellerProductsProvider);
    ref.invalidate(sellerProductStatsProvider);
    ref.invalidate(sellerDashboardStatsProvider);
  }
}

final sellerProductActionControllerProvider = NotifierProvider<SellerProductActionController, SellerProductActionState>(SellerProductActionController.new);
