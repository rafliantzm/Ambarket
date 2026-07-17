import 'package:ambarket_mobile/features/offer/domain/models/offer_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfferModel.fromJson', () {
    test('parses legacy rows with incomplete relations safely', () {
      final offer = OfferModel.fromJson({
        'id': 'offer-1',
        'product_id': 'product-1',
        'buyer_id': 'buyer-1',
        'seller_id': 'seller-1',
        'offer_price': 8000,
        'status': null,
        'created_at': null,
        'updated_at': null,
        'products': {'id': 'product-1', 'seller_id': 'seller-1', 'title': null},
        'buyer': {'id': 'buyer-1', 'name': 'Pembeli', 'created_at': null},
        'seller': null,
      });

      expect(offer.id, 'offer-1');
      expect(offer.productId, 'product-1');
      expect(offer.offerPrice, 8000);
      expect(offer.status, 'pending');
      expect(offer.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(offer.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(offer.product?.title, 'Produk');
      expect(offer.buyer?.name, 'Pembeli');
      expect(offer.seller, isNull);
    });

    test('keeps valid product and profile relations', () {
      final offer = OfferModel.fromJson({
        'id': 'offer-2',
        'product_id': 'product-2',
        'buyer_id': 'buyer-2',
        'seller_id': 'seller-2',
        'offer_price': '12000',
        'status': 'accepted',
        'created_at': '2026-07-12T10:00:00.000Z',
        'products': {
          'id': 'product-2',
          'seller_id': 'seller-2',
          'category_id': 'category-1',
          'title': 'Mouse',
          'description': 'Mouse bekas',
          'price': 17000,
          'condition': 'like_new',
          'location': 'Jakarta',
          'created_at': '2026-07-12T09:00:00.000Z',
        },
        'buyer': {
          'id': 'buyer-2',
          'name': 'Pembeli',
          'role': 'user',
          'created_at': '2026-07-12T09:00:00.000Z',
        },
      });

      expect(offer.offerPrice, 12000);
      expect(offer.status, 'accepted');
      expect(offer.product?.title, 'Mouse');
      expect(offer.buyer?.name, 'Pembeli');
    });
  });
}
