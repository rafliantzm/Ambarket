import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/cart_item_model.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../data/repositories/supabase_cart_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'dart:async';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return SupabaseCartRepository(Supabase.instance.client);
});

final cartItemsProvider = FutureProvider<List<CartItemModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(cartRepositoryProvider);
  return repository.fetchCartItems(user.id);
});

final cartCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartItemsProvider).value;
  return items?.length ?? 0;
});

class CartActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addToCart(String productId, [int quantity = 1]) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Silakan login terlebih dahulu.');

      final repo = ref.read(cartRepositoryProvider);
      await repo.addToCart(user.id, productId);
      ref.invalidate(cartItemsProvider);
    });
  }

  Future<void> removeFromCart(String cartItemId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(cartRepositoryProvider);
      await repo.removeFromCart(cartItemId);
      ref.invalidate(cartItemsProvider);
    });
  }

  Future<void> clearCart() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final repo = ref.read(cartRepositoryProvider);
      await repo.clearCart(user.id);
      ref.invalidate(cartItemsProvider);
    });
  }
}

final cartActionControllerProvider =
    AsyncNotifierProvider<CartActionController, void>(() {
      return CartActionController();
    });
