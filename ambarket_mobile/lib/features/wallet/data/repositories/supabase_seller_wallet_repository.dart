import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/seller_wallet_summary.dart';
import '../../domain/models/seller_withdrawal_model.dart';
import '../../domain/models/dummy_withdrawal_input.dart';
import '../../domain/repositories/seller_wallet_repository.dart';
import '../../../../core/error/error_mapper.dart';

class SupabaseSellerWalletRepository implements SellerWalletRepository {
  final SupabaseClient _client;

  SupabaseSellerWalletRepository(this._client);

  @override
  Future<SellerWalletSummary> fetchSellerWalletSummary(String sellerId) async {
    try {
      // Seller wallets can be stale if the sync RPC has not run or failed.
      // Completed orders are the authoritative source for seller earnings.
      final results = await Future.wait<dynamic>([
        _fetchCompletedOrderRevenue(sellerId),
        _fetchPendingSettlementRevenue(sellerId),
        _fetchDisputedOrderRevenue(sellerId),
        _fetchWithdrawalsSummary(sellerId),
      ]);
      final totalRevenue = results[0] as double;
      final pendingSettlement = results[1] as double;
      final disputedBalance = results[2] as double;
      final withdrawalsSummary = results[3] as _WithdrawalsSummary;

      var availableBalance =
          totalRevenue -
          withdrawalsSummary.pendingBalance -
          withdrawalsSummary.withdrawnBalance;
      if (availableBalance < 0) availableBalance = 0;

      return SellerWalletSummary(
        availableBalance: availableBalance,
        pendingBalance: pendingSettlement,
        disputedBalance: disputedBalance,
        totalEarning: totalRevenue,
        completedOrderRevenue: totalRevenue,
        withdrawalCount: withdrawalsSummary.withdrawalCount,
        pendingWithdrawalCount: withdrawalsSummary.pendingWithdrawalCount,
      );
    } catch (e) {
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    }
  }

  Future<double> _fetchPendingSettlementRevenue(String sellerId) async {
    final activeOrders = await _client
        .from('orders')
        .select('total_price')
        .eq('seller_id', sellerId)
        .inFilter('status', ['paid', 'packed', 'shipped', 'delivered']);

    var pending = 0.0;
    for (final row in activeOrders) {
      pending += _asDouble(row['total_price']);
    }
    return pending;
  }

  Future<double> _fetchDisputedOrderRevenue(String sellerId) async {
    final disputedOrders = await _client
        .from('orders')
        .select('total_price')
        .eq('seller_id', sellerId)
        .eq('status', 'disputed');

    var disputed = 0.0;
    for (final row in disputedOrders) {
      disputed += _asDouble(row['total_price']);
    }
    return disputed;
  }

  Future<double> _fetchCompletedOrderRevenue(String sellerId) async {
    final completedOrders = await _client
        .from('orders')
        .select(
          'total_price, status, refund_requests:order_refund_requests(status, approved_amount)',
        )
        .eq('seller_id', sellerId)
        .inFilter('status', ['completed', 'partially_refunded']);

    var totalRevenue = 0.0;
    for (final row in completedOrders) {
      final totalPrice = _asDouble(row['total_price']);
      if (row['status'] == 'partially_refunded') {
        final sellerShare = totalPrice - _approvedRefundAmount(row);
        totalRevenue += sellerShare < 0 ? 0 : sellerShare;
      } else {
        totalRevenue += totalPrice;
      }
    }

    return totalRevenue;
  }

  double _approvedRefundAmount(Map<String, dynamic> orderRow) {
    final refunds = orderRow['refund_requests'];
    if (refunds is! List) return 0;

    var approved = 0.0;
    for (final item in refunds) {
      if (item is Map<String, dynamic> &&
          item['status'] == 'partially_approved') {
        approved = _asDouble(item['approved_amount']);
      }
    }
    return approved;
  }

  @override
  Future<List<SellerWithdrawalModel>> fetchSellerWithdrawals(
    String sellerId,
  ) async {
    try {
      final response = await _client
          .from('seller_withdrawals')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SellerWithdrawalModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    }
  }

  @override
  Future<SellerWithdrawalModel> requestDummyWithdrawal(
    String sellerId,
    DummyWithdrawalInput input,
  ) async {
    try {
      final response = await _client
          .from('seller_withdrawals')
          .insert({'seller_id': sellerId, ...input.toJson()})
          .select()
          .single();
      return SellerWithdrawalModel.fromJson(response);
    } catch (e) {
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    }
  }

  @override
  Future<void> ensureSellerWalletExists(String sellerId) async {
    try {
      await _client.rpc(
        'ensure_seller_wallet_exists',
        params: {'p_seller_id': sellerId},
      );
    } catch (e) {
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    }
  }

  @override
  Future<void> calculateSellerEarningsFromCompletedOrders(
    String sellerId,
  ) async {
    try {
      await _client.rpc(
        'sync_seller_wallet',
        params: {'p_seller_id': sellerId},
      );
    } catch (e) {
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    }
  }

  Future<_WithdrawalsSummary> _fetchWithdrawalsSummary(String sellerId) async {
    final withdrawalsRes = await _client
        .from('seller_withdrawals')
        .select('amount, status')
        .eq('seller_id', sellerId);

    final withdrawals = List<Map<String, dynamic>>.from(withdrawalsRes);

    double pendingBalance = 0;
    double withdrawnBalance = 0;
    int pendingCount = 0;

    for (final withdrawal in withdrawals) {
      final amount = _asDouble(withdrawal['amount']);
      if (withdrawal['status'] == 'pending') {
        pendingBalance += amount;
        pendingCount++;
      } else if (withdrawal['status'] == 'approved_dummy') {
        withdrawnBalance += amount;
      }
    }

    return _WithdrawalsSummary(
      pendingBalance: pendingBalance,
      withdrawnBalance: withdrawnBalance,
      withdrawalCount: withdrawals.length,
      pendingWithdrawalCount: pendingCount,
    );
  }

  double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _WithdrawalsSummary {
  final double pendingBalance;
  final double withdrawnBalance;
  final int withdrawalCount;
  final int pendingWithdrawalCount;

  const _WithdrawalsSummary({
    required this.pendingBalance,
    required this.withdrawnBalance,
    required this.withdrawalCount,
    required this.pendingWithdrawalCount,
  });
}
