import '../models/seller_wallet_summary.dart';
import '../models/seller_withdrawal_model.dart';
import '../models/dummy_withdrawal_input.dart';

abstract class SellerWalletRepository {
  /// Fetches the wallet summary for the given seller.
  Future<SellerWalletSummary> fetchSellerWalletSummary(String sellerId);

  /// Fetches the list of withdrawals requested by the given seller.
  Future<List<SellerWithdrawalModel>> fetchSellerWithdrawals(String sellerId);

  /// Submits a dummy withdrawal request.
  Future<void> requestDummyWithdrawal(
    String sellerId,
    DummyWithdrawalInput input,
  );

  /// Ensures a wallet record exists for the seller.
  Future<void> ensureSellerWalletExists(String sellerId);

  /// Calculates completed order earnings and updates wallet (dummy MVP behavior).
  Future<void> calculateSellerEarningsFromCompletedOrders(String sellerId);
}
