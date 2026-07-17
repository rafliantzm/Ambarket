import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/seller_wallet_summary.dart';
import '../../domain/models/seller_withdrawal_model.dart';
import '../../domain/models/dummy_withdrawal_input.dart';
import '../../domain/repositories/seller_wallet_repository.dart';
import '../../data/repositories/supabase_seller_wallet_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../features/notification/presentation/providers/notification_provider.dart';

// 1. Repository Provider
final sellerWalletRepositoryProvider = Provider<SellerWalletRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseSellerWalletRepository(client);
});

// 2. Wallet Summary Provider
final sellerWalletSummaryProvider =
    FutureProvider.autoDispose<SellerWalletSummary>((ref) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      final repo = ref.watch(sellerWalletRepositoryProvider);

      try {
        await repo
            .ensureSellerWalletExists(user.id)
            .timeout(const Duration(seconds: 4));
        await repo
            .calculateSellerEarningsFromCompletedOrders(user.id)
            .timeout(const Duration(seconds: 4));
      } catch (_) {
        // Wallet rendering should not be blocked by best-effort sync RPCs.
      }

      return repo.fetchSellerWalletSummary(user.id);
    });

// 3. Seller Withdrawals Provider
final sellerWithdrawalsProvider =
    FutureProvider.autoDispose<List<SellerWithdrawalModel>>((ref) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) return [];

      return ref
          .watch(sellerWalletRepositoryProvider)
          .fetchSellerWithdrawals(user.id);
    });

// 4. Action Controller
class SellerWithdrawalActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> submitDummyWithdrawal(DummyWithdrawalInput input) async {
    state = const AsyncValue.loading();
    final nextState = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      final repo = ref.read(sellerWalletRepositoryProvider);
      await repo.ensureSellerWalletExists(user.id);
      await repo.calculateSellerEarningsFromCompletedOrders(user.id);
      final withdrawal = await repo.requestDummyWithdrawal(user.id, input);

      // Notify seller
      ref
          .read(notificationRepositoryProvider)
          .createDummyNotification(
            userId: user.id,
            type: 'withdrawal_requested',
            title: 'Penarikan Diproses',
            body: 'Permintaan penarikan saldo sedang diproses (Dummy).',
            relatedType: 'withdrawal',
            relatedId: withdrawal.id,
          );

      await _notifyAdminsAboutWithdrawal(user.id, withdrawal.id, input.amount);

      // Invalidate to refresh lists and summary
      ref.invalidate(sellerWalletSummaryProvider);
      ref.invalidate(sellerWithdrawalsProvider);
    });
    state = nextState;
    return !nextState.hasError;
  }

  Future<void> _notifyAdminsAboutWithdrawal(
    String sellerId,
    String withdrawalId,
    double amount,
  ) async {
    try {
      final admins = await ref
          .read(supabaseClientProvider)
          .from('profiles')
          .select('id')
          .eq('role', 'admin');
      final adminIds = (admins as List)
          .map((row) => row['id']?.toString())
          .whereType<String>()
          .where((adminId) => adminId != sellerId)
          .toList();

      for (final adminId in adminIds) {
        try {
          await ref
              .read(notificationRepositoryProvider)
              .createDummyNotification(
                userId: adminId,
                type: 'withdrawal_requested',
                title: 'Pengajuan Penarikan Baru',
                body:
                    'Seller mengajukan penarikan dana dummy Rp${amount.toStringAsFixed(0)}.',
                relatedType: 'withdrawal',
                relatedId: withdrawalId,
              );
        } catch (_) {
          // Notification delivery is best effort; the withdrawal request itself
          // must stay successful.
        }
      }
    } catch (_) {
      // Admin lookup can fail under older RLS/RPC setups. The admin queue still
      // reads directly from seller_withdrawals after policies are applied.
    }
  }
}

final sellerWithdrawalActionControllerProvider =
    AsyncNotifierProvider<SellerWithdrawalActionController, void>(
      () => SellerWithdrawalActionController(),
    );
