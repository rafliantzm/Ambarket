import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'seller offer cards do not execute per-card order FutureBuilder queries',
    () {
      final source = File(
        'lib/features/offer/presentation/screens/seller_offers_screen.dart',
      ).readAsStringSync();

      final cardStart = source.indexOf('class SellerOfferCard');

      expect(cardStart, isNonNegative);

      final cardSource = source.substring(cardStart);

      expect(cardSource, isNot(contains('FutureBuilder')));
      expect(cardSource, isNot(contains('findOrderByOfferId')));
      expect(source, contains('sellerAcceptedOfferOrderIdsProvider'));
    },
  );
}
