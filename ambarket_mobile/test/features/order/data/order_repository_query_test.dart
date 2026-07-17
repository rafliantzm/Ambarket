import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('order queries select complete product and profile relations', () {
    final orderRepository = File(
      'lib/features/order/data/repositories/supabase_order_repository.dart',
    ).readAsStringSync();
    final offerRepository = File(
      'lib/features/offer/data/repositories/supabase_offer_repository.dart',
    ).readAsStringSync();

    expect(orderRepository, isNot(contains('product:products(id, title')));
    expect(
      orderRepository,
      isNot(contains('profiles!orders_seller_id_fkey(id, name, avatar_url)')),
    );
    expect(
      orderRepository,
      isNot(contains('profiles!orders_buyer_id_fkey(id, name, avatar_url)')),
    );
    expect(
      orderRepository,
      contains('product:products(*, categories(*), product_images(*))'),
    );
    expect(
      orderRepository,
      contains('seller:profiles!orders_seller_id_fkey(*)'),
    );
    expect(orderRepository, contains('buyer:profiles!orders_buyer_id_fkey(*)'));

    expect(offerRepository, isNot(contains('product:products(id, title')));
    expect(
      offerRepository,
      contains('product:products(*, categories(*), product_images(*))'),
    );
    expect(offerRepository, contains('buyer:profiles!orders_buyer_id_fkey(*)'));
    expect(
      offerRepository,
      contains('seller:profiles!orders_seller_id_fkey(*)'),
    );
  });
}
