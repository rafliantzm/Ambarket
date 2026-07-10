import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../order/domain/models/checkout_models.dart';

class AdminVoucherNotifier extends AsyncNotifier<List<VoucherModel>> {
  @override
  Future<List<VoucherModel>> build() async {
    final response = await Supabase.instance.client
        .from('vouchers')
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((item) => VoucherModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> toggleVoucherStatus(String id, bool isActive) async {
    try {
      await Supabase.instance.client
          .from('vouchers')
          .update({'is_active': isActive})
          .eq('id', id);
      await refresh();
    } catch (e) {
      throw Exception('Failed to update voucher status: $e');
    }
  }
}

final adminVoucherProvider =
    AsyncNotifierProvider<AdminVoucherNotifier, List<VoucherModel>>(() {
      return AdminVoucherNotifier();
    });
