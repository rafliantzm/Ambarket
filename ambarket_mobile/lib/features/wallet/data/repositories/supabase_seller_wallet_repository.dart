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
      final response = await _client
          .from('seller_wallets')
          .select()
          .eq('seller_id', sellerId)
          .maybeSingle();
      
      if (response == null) {
        return SellerWalletSummary.empty();
      }

      // We can also compute withdrawal_count and pending_withdrawal_count here
      // by doing a separate query or using rpc. For MVP, let's query it.
      final withdrawalsRes = await _client
          .from('seller_withdrawals')
          .select('status')
          .eq('seller_id', sellerId);
      
      final withdrawals = List<Map<String, dynamic>>.from(withdrawalsRes);
      final withdrawalCount = withdrawals.length;
      final pendingCount = withdrawals.where((w) => w['status'] == 'pending').length;

      final summary = SellerWalletSummary.fromJson(response);
      return SellerWalletSummary(
        availableBalance: summary.availableBalance,
        pendingBalance: summary.pendingBalance,
        totalEarning: summary.totalEarning,
        completedOrderRevenue: summary.completedOrderRevenue,
        withdrawalCount: withdrawalCount,
        pendingWithdrawalCount: pendingCount,
      );
    } catch (e) {
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    }
  }

  @override
  Future<List<SellerWithdrawalModel>> fetchSellerWithdrawals(String sellerId) async {
    try {
      final response = await _client
          .from('seller_withdrawals')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => SellerWithdrawalModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    }
  }

  @override
  Future<void> requestDummyWithdrawal(String sellerId, DummyWithdrawalInput input) async {
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
      await _client.rpc('ensure_seller_wallet_exists', params: {'p_seller_id': sellerId});
    } catch (e) {
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    }
  }

  @override
  Future<void> calculateSellerEarningsFromCompletedOrders(String sellerId) async {
    try {
      await _client.rpc('sync_seller_wallet', params: {'p_seller_id': sellerId});
    } catch (e) {
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    }
  }
}
