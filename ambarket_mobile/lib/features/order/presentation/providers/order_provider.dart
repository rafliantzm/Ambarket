import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:ambarket_mobile/features/order/domain/repositories/order_repository.dart';
import 'package:ambarket_mobile/features/order/data/repositories/supabase_order_repository.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:ambarket_mobile/features/order/domain/models/checkout_models.dart';
import 'package:ambarket_mobile/features/marketplace/presentation/providers/marketplace_provider.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return SupabaseOrderRepository(Supabase.instance.client);
});

final buyerOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(orderRepositoryProvider).fetchBuyerOrders(user.id);
});

class SellerOrderStatusFilter extends Notifier<String> {
  @override
  String build() => 'all';
  
  void setFilter(String val) => state = val;
}
final sellerOrderStatusFilterProvider = NotifierProvider<SellerOrderStatusFilter, String>(() => SellerOrderStatusFilter());

class SellerPaymentStatusFilter extends Notifier<String> {
  @override
  String build() => 'all';
  
  void setFilter(String val) => state = val;
}
final sellerPaymentStatusFilterProvider = NotifierProvider<SellerPaymentStatusFilter, String>(() => SellerPaymentStatusFilter());

final sellerOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final statusFilter = ref.watch(sellerOrderStatusFilterProvider);
  final paymentFilter = ref.watch(sellerPaymentStatusFilterProvider);
  
  return ref.watch(orderRepositoryProvider).fetchSellerOrdersFiltered(
    user.id,
    status: statusFilter,
    paymentStatus: paymentFilter,
  );
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

  Future<OrderModel?> createOrder(CheckoutInput input) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return null;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final productState = ref.read(productDetailProvider(input.productId)).value;
      if (productState == null) throw Exception('Product not found');
      
      final repo = ref.read(orderRepositoryProvider);
      final order = await repo.createOrder(
        productId: input.productId,
        buyerId: user.id,
        sellerId: productState.sellerId,
        totalPrice: input.subtotal,
        receiverName: input.receiverName,
        receiverPhone: input.receiverPhone,
        shippingAddress: input.shippingAddress,
        shippingMethod: input.shippingMethod,
        shippingCost: input.shippingCost,
        paymentMethod: input.paymentMethod,
        voucherCode: input.voucherCode,
        discountAmount: input.discountAmount,
        serviceFee: input.serviceFee,
        subtotal: input.subtotal,
        offerId: input.offerId,
      );

      ref.invalidate(buyerOrdersProvider);
      ref.invalidate(productDetailProvider(input.productId));
      
      state = state.copyWith(isLoading: false);
      return order;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> simulatePayment(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(orderRepositoryProvider).simulatePayment(orderId);
      ref.invalidate(buyerOrdersProvider);
      ref.invalidate(sellerOrdersProvider);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateStatus(String orderId, String newStatus) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(orderId, newStatus);
      ref.invalidate(buyerOrdersProvider);
      ref.invalidate(sellerOrdersProvider);
      // Invalidate seller dashboard stats if needed
      // ref.invalidate(sellerDashboardStatsProvider); // Will be handled in screens or directly
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> cancelSellerOrder(String orderId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(orderRepositoryProvider).cancelSellerOrder(orderId, user.id);
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
