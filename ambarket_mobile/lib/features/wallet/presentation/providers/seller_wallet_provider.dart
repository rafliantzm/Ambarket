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
final sellerWalletSummaryProvider = FutureProvider.autoDispose<SellerWalletSummary>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('User not logged in');

  final repo = ref.watch(sellerWalletRepositoryProvider);
  
  // Ensure wallet exists before fetching
  await repo.ensureSellerWalletExists(user.id);
  // Calculate earnings (simulation for MVP)
  await repo.calculateSellerEarningsFromCompletedOrders(user.id);

  return repo.fetchSellerWalletSummary(user.id);
});

// 3. Seller Withdrawals Provider
final sellerWithdrawalsProvider = FutureProvider.autoDispose<List<SellerWithdrawalModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  return ref.watch(sellerWalletRepositoryProvider).fetchSellerWithdrawals(user.id);
});

// 4. Action Controller
class SellerWithdrawalActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submitDummyWithdrawal(DummyWithdrawalInput input) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      await ref.read(sellerWalletRepositoryProvider).requestDummyWithdrawal(user.id, input);
      
      // Notify seller
      ref.read(notificationRepositoryProvider).createDummyNotification(
        userId: user.id,
        type: 'withdrawal_requested',
        title: 'Penarikan Diproses',
        body: 'Permintaan penarikan saldo sedang diproses (Dummy).',
        relatedType: 'withdrawal',
      );
      
      // Invalidate to refresh lists and summary
      ref.invalidate(sellerWalletSummaryProvider);
      ref.invalidate(sellerWithdrawalsProvider);
    });
  }
}

final sellerWithdrawalActionControllerProvider = AsyncNotifierProvider<SellerWithdrawalActionController, void>(
  () => SellerWithdrawalActionController(),
);
