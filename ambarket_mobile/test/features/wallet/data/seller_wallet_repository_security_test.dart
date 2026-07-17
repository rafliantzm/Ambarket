import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wallet RPC failure paths do not mutate seller wallet rows directly', () {
    final source = File(
      'lib/features/wallet/data/repositories/supabase_seller_wallet_repository.dart',
    ).readAsStringSync();

    final ensureStart = source.indexOf('Future<void> ensureSellerWalletExists');
    final syncStart = source.indexOf(
      'Future<void> calculateSellerEarningsFromCompletedOrders',
    );
    final fileEnd = source.length;

    expect(ensureStart, isNonNegative);
    expect(syncStart, isNonNegative);

    final ensureBody = source.substring(ensureStart, syncStart);
    final syncBody = source.substring(syncStart, fileEnd);

    expect(ensureBody, isNot(contains(".from('seller_wallets').insert")));
    expect(ensureBody, isNot(contains(".from('seller_wallets').update")));
    expect(syncBody, isNot(contains(".from('seller_wallets').insert")));
    expect(syncBody, isNot(contains(".from('seller_wallets').update")));
  });
}
