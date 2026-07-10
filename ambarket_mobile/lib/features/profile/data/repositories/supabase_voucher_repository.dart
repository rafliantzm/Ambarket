import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../order/domain/models/checkout_models.dart';

class SupabaseVoucherRepository {
  final SupabaseClient _supabase;

  SupabaseVoucherRepository(this._supabase);

  Future<List<VoucherModel>> getAvailableVouchers() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('vouchers')
          .select()
          .eq('is_active', true)
          // We can't easily filter (expires_at is null OR expires_at > now()) via simple Supabase Dart builder without an `or` string.
          // Let's use `or` filter:
          .or(
            'expires_at.is.null,expires_at.gte.${DateTime.now().toUtc().toIso8601String()}',
          )
          .order('created_at', ascending: false);

      // Get claimed vouchers for this user
      final claimedResponse = await _supabase
          .from('user_vouchers')
          .select('voucher_id, is_used')
          .eq('user_id', user.id);

      final claimedMap = {
        for (var item in claimedResponse)
          item['voucher_id'] as String: item['is_used'] as bool,
      };

      final List<VoucherModel> vouchers = [];
      for (var item in response) {
        final id = item['id'] as String;
        // if it's already used, we might want to skip it, but let's just mark it claimed
        final isClaimed = claimedMap.containsKey(id);

        vouchers.add(VoucherModel.fromJson(item, isClaimed: isClaimed));
      }

      return vouchers;
    } catch (e) {
      return [];
    }
  }

  Future<void> claimVoucher(String voucherId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase.from('user_vouchers').insert({
      'user_id': user.id,
      'voucher_id': voucherId,
    });
  }

  Future<void> createVoucher({
    required String title,
    required String description,
    required String code,
    required String type,
    required double discountValue,
    required double minPurchase,
    required double maxDiscount,
    DateTime? expiresAt,
  }) async {
    // Call the RPC that creates voucher and notifies users
    await _supabase.rpc(
      'create_voucher_with_notifications',
      params: {
        'p_title': title,
        'p_description': description,
        'p_code': code,
        'p_type': type,
        'p_discount_value': discountValue,
        'p_min_purchase': minPurchase,
        'p_max_discount': maxDiscount,
        'p_expires_at': expiresAt?.toIso8601String(),
      },
    );
  }
}

final voucherRepositoryProvider = Provider<SupabaseVoucherRepository>((ref) {
  return SupabaseVoucherRepository(Supabase.instance.client);
});
