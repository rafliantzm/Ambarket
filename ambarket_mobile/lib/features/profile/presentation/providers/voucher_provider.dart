import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../order/domain/models/checkout_models.dart';
import '../../data/repositories/supabase_voucher_repository.dart';

class VoucherNotifier extends AsyncNotifier<List<VoucherModel>> {
  @override
  Future<List<VoucherModel>> build() async {
    return ref.read(voucherRepositoryProvider).getAvailableVouchers();
  }

  Future<void> claimVoucher(String id) async {
    try {
      await ref.read(voucherRepositoryProvider).claimVoucher(id);

      // Update local state to show it's claimed
      if (state.value != null) {
        state = AsyncData(
          state.value!.map((v) {
            if (v.id == id) {
              return v.copyWith(isClaimed: true);
            }
            return v;
          }).toList(),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final voucherProvider =
    AsyncNotifierProvider<VoucherNotifier, List<VoucherModel>>(() {
      return VoucherNotifier();
    });
