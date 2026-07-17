import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:ambarket_mobile/features/order/domain/repositories/order_repository.dart';
import 'package:ambarket_mobile/features/order/data/repositories/supabase_order_repository.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:ambarket_mobile/features/order/domain/models/checkout_models.dart';
import 'package:ambarket_mobile/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:ambarket_mobile/features/notification/presentation/providers/notification_provider.dart';
import 'package:ambarket_mobile/features/seller/presentation/providers/seller_provider.dart';
import 'package:ambarket_mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:ambarket_mobile/features/wallet/presentation/providers/seller_wallet_provider.dart';

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

final sellerOrderStatusFilterProvider =
    NotifierProvider<SellerOrderStatusFilter, String>(
      () => SellerOrderStatusFilter(),
    );

class SellerPaymentStatusFilter extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String val) => state = val;
}

final sellerPaymentStatusFilterProvider =
    NotifierProvider<SellerPaymentStatusFilter, String>(
      () => SellerPaymentStatusFilter(),
    );

final sellerOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final statusFilter = ref.watch(sellerOrderStatusFilterProvider);
  final paymentFilter = ref.watch(sellerPaymentStatusFilterProvider);

  return ref
      .watch(orderRepositoryProvider)
      .fetchSellerOrdersFiltered(
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
      final productState = ref
          .read(productDetailProvider(input.productId))
          .value;
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

      // Remove from cart if it was there
      try {
        await ref
            .read(cartRepositoryProvider)
            .removeProductFromCart(user.id, input.productId);
        ref.invalidate(cartItemsProvider);
        ref.invalidate(cartCountProvider);
      } catch (_) {}

      // Notify seller
      ref
          .read(notificationRepositoryProvider)
          .createDummyNotification(
            userId: productState.sellerId,
            type: 'order_received',
            title: 'Pesanan Baru',
            body:
                'Anda mendapat pesanan baru untuk produk ${productState.title}',
            relatedType: 'order',
            relatedId: order.id,
          );

      // Notify buyer
      ref
          .read(notificationRepositoryProvider)
          .createDummyNotification(
            userId: user.id,
            type: 'order_created',
            title: 'Pesanan Berhasil Dibuat',
            body:
                'Pesanan Anda untuk ${productState.title} berhasil dibuat dan menunggu konfirmasi/pembayaran.',
            relatedType: 'order',
            relatedId: order.id,
          );

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

      // Notify seller
      final allOrders = [
        ...(ref.read(buyerOrdersProvider).value ?? []),
        ...(ref.read(sellerOrdersProvider).value ?? []),
      ];
      final order = allOrders.where((o) => o.id == orderId).firstOrNull;
      if (order != null) {
        ref
            .read(notificationRepositoryProvider)
            .createDummyNotification(
              userId: order.sellerId,
              type: 'payment_paid',
              title: 'Pembayaran Diterima',
              body: 'Pembeli telah membayar pesanan. Segera proses pengiriman.',
              relatedType: 'order',
              relatedId: order.id,
            );
      }

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
      await ref
          .read(orderRepositoryProvider)
          .updateOrderStatus(orderId, newStatus);

      // Notify buyer
      final allOrders = [
        ...(ref.read(buyerOrdersProvider).value ?? []),
        ...(ref.read(sellerOrdersProvider).value ?? []),
      ];
      final order = allOrders.where((o) => o.id == orderId).firstOrNull;
      if (order != null) {
        String title = 'Status Pesanan Diperbarui';
        String body = 'Pesanan Anda berubah status menjadi $newStatus.';
        if (newStatus == 'packed') {
          title = 'Pesanan Diproses';
          body = 'Penjual sedang menyiapkan barang Anda.';
        } else if (newStatus == 'shipped') {
          title = 'Pesanan Dikirim';
          body = 'Barang Anda sedang dalam perjalanan.';
        } else if (newStatus == 'delivered') {
          title = 'Pesanan Diterima';
          body =
              'Pesanan ditandai diterima. Dana masih ditahan sampai transaksi selesai.';
        } else if (newStatus == 'completed') {
          title = 'Pesanan Selesai';
          body = 'Pesanan telah selesai. Terima kasih!';
        }

        ref
            .read(notificationRepositoryProvider)
            .createDummyNotification(
              userId: order.buyerId,
              type: 'order_$newStatus',
              title: title,
              body: body,
              relatedType: 'order',
              relatedId: order.id,
            );
      }

      ref.invalidate(buyerOrdersProvider);
      ref.invalidate(sellerOrdersProvider);
      ref.invalidate(sellerWalletSummaryProvider);

      if (newStatus == 'completed' && order != null) {
        // Also refresh marketplace and product detail because the DB trigger just marked it as 'sold'
        ref.invalidate(productsProvider);
        ref.invalidate(productDetailProvider(order.productId));

        // If the current user happens to be the seller (e.g., testing with same account or just to be safe)
        ref.invalidate(myProductsProvider);
        ref.invalidate(sellerWalletSummaryProvider);
        ref.invalidate(sellerWithdrawalsProvider);
      }

      // Invalidate seller dashboard stats to update sold/active counts
      ref.invalidate(sellerDashboardStatsProvider);

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
      await ref
          .read(orderRepositoryProvider)
          .cancelSellerOrder(orderId, user.id);

      // Notify buyer
      final allOrders = [
        ...(ref.read(buyerOrdersProvider).value ?? []),
        ...(ref.read(sellerOrdersProvider).value ?? []),
      ];
      final order = allOrders.where((o) => o.id == orderId).firstOrNull;
      if (order != null) {
        ref
            .read(notificationRepositoryProvider)
            .createDummyNotification(
              userId: order.buyerId,
              type: 'order_cancelled',
              title: 'Pesanan Dibatalkan',
              body: 'Penjual membatalkan pesanan Anda.',
              relatedType: 'order',
              relatedId: order.id,
            );
      }

      ref.invalidate(sellerOrdersProvider);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> requestRefund({
    required OrderModel order,
    required String reason,
    required String description,
    required double requestedAmount,
    List<String> evidenceUrls = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref
          .read(orderRepositoryProvider)
          .requestRefund(
            orderId: order.id,
            reason: reason,
            description: description,
            requestedAmount: requestedAmount,
            evidenceUrls: evidenceUrls,
          );

      ref.invalidate(buyerOrdersProvider);
      ref.invalidate(sellerOrdersProvider);
      ref.invalidate(sellerWalletSummaryProvider);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final orderActionControllerProvider =
    NotifierProvider<OrderActionController, OrderActionState>(() {
      return OrderActionController();
    });
