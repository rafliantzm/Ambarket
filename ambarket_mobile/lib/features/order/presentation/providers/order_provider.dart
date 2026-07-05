import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:ambarket_mobile/features/order/domain/repositories/order_repository.dart';
import 'package:ambarket_mobile/features/order/data/repositories/supabase_order_repository.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return SupabaseOrderRepository(Supabase.instance.client);
});

final buyerOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(orderRepositoryProvider).fetchBuyerOrders(user.id);
});

final sellerOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(orderRepositoryProvider).fetchSellerOrders(user.id);
});

class OrderActionState {
  final bool isLoading;
  final String? error;

  OrderActionState({this.isLoading = false, this.error});

  OrderActionState copyWith({bool? isLoading, String? error}) {
    return OrderActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OrderActionController extends Notifier<OrderActionState> {
  @override
  OrderActionState build() {
    return OrderActionState();
  }

  Future<OrderModel?> checkout({
    required String productId,
    required String sellerId,
    required double totalPrice,
    required String shippingAddress,
    required String shippingPhone,
    String? offerId,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return null;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(orderRepositoryProvider);
      final order = await repo.createOrder(
        productId: productId,
        buyerId: user.id,
        sellerId: sellerId,
        totalPrice: totalPrice,
        shippingAddress: shippingAddress,
        shippingPhone: shippingPhone,
        offerId: offerId,
      );
      
      // Refresh buyer orders
      ref.invalidate(buyerOrdersProvider);
      // Refresh profile to potentially use the new address next time, but we don't save it automatically here yet,
      // it should be saved in EditProfileScreen. Or we can just update profile if they changed it during checkout.
      // But let's just leave it simple.
      
      state = state.copyWith(isLoading: false);
      return order;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> updateStatus(String orderId, String newStatus) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(orderId, newStatus);
      ref.invalidate(buyerOrdersProvider);
      ref.invalidate(sellerOrdersProvider);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final orderActionControllerProvider = NotifierProvider<OrderActionController, OrderActionState>(() {
  return OrderActionController();
});
