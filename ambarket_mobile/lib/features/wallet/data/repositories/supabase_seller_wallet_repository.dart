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
      // 1. Calculate total revenue from completed orders
      final completedOrders = await _client
          .from('orders')
          .select('total_price')
          .eq('seller_id', sellerId)
          .eq('status', 'completed');

      double totalRevenue = 0;
      for (var row in completedOrders) {
        if (row['total_price'] != null) {
          totalRevenue += (row['total_price'] as num).toDouble();
        }
      }

      // 2. Fetch withdrawals
      final withdrawalsRes = await _client
          .from('seller_withdrawals')
          .select('amount, status')
          .eq('seller_id', sellerId);

      final withdrawals = List<Map<String, dynamic>>.from(withdrawalsRes);

      double pendingBalance = 0;
      double withdrawnBalance = 0;
      int pendingCount = 0;

      for (var w in withdrawals) {
        final amount = (w['amount'] as num).toDouble();
        if (w['status'] == 'pending') {
          pendingBalance += amount;
          pendingCount++;
        } else if (w['status'] == 'approved_dummy') {
          withdrawnBalance += amount;
        }
      }

      double availableBalance =
          totalRevenue - pendingBalance - withdrawnBalance;
      if (availableBalance < 0) availableBalance = 0;

      return SellerWalletSummary(
        availableBalance: availableBalance,
        pendingBalance: pendingBalance,
        totalEarning: totalRevenue,
        completedOrderRevenue: totalRevenue,
        withdrawalCount: withdrawals.length,
        pendingWithdrawalCount: pendingCount,
      );
    } catch (e) {
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    }
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
  Future<void> requestDummyWithdrawal(
    String sellerId,
    DummyWithdrawalInput input,
  ) async {
    try {
      await _client.from('seller_withdrawals').insert({
        'seller_id': sellerId,
        ...input.toJson(),
      });
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
      // Fallback if RPC doesn't exist
      try {
        final existing = await _client
            .from('seller_wallets')
            .select('id')
            .eq('seller_id', sellerId)
            .maybeSingle();
        if (existing == null) {
          await _client.from('seller_wallets').insert({
            'seller_id': sellerId,
            'available_balance': 0,
            'pending_balance': 0,
            'total_earning': 0,
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (_) {}
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
      // Fallback: Compute in Dart if RPC doesn't exist
      try {
        // 1. Calculate total revenue from completed orders
        final completedOrders = await _client
            .from('orders')
            .select('total_price')
            .eq('seller_id', sellerId)
            .eq('status', 'completed');

        double totalRevenue = 0;
        for (var row in completedOrders) {
          if (row['total_price'] != null) {
            totalRevenue += (row['total_price'] as num).toDouble();
          }
        }

        // 2. Calculate pending and approved withdrawals
        final withdrawals = await _client
            .from('seller_withdrawals')
            .select('amount, status')
            .eq('seller_id', sellerId);

        double pending = 0;
        double withdrawn = 0;
        for (var row in withdrawals) {
          if (row['status'] == 'pending') {
            pending += (row['amount'] as num).toDouble();
          } else if (row['status'] == 'approved_dummy') {
            withdrawn += (row['amount'] as num).toDouble();
          }
        }

        double availableBalance = totalRevenue - pending - withdrawn;
        if (availableBalance < 0) availableBalance = 0;

        // 3. Upsert into seller_wallets
        final existing = await _client
            .from('seller_wallets')
            .select('id')
            .eq('seller_id', sellerId)
            .maybeSingle();
        if (existing == null) {
          await _client.from('seller_wallets').insert({
            'seller_id': sellerId,
            'total_earning': totalRevenue,
            'pending_balance': pending,
            'available_balance': availableBalance,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } else {
          await _client
              .from('seller_wallets')
              .update({
                'total_earning': totalRevenue,
                'pending_balance': pending,
                'available_balance': availableBalance,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('seller_id', sellerId);
        }
      } catch (innerE) {
        // Ignore if error
      }
    }
  }
}
