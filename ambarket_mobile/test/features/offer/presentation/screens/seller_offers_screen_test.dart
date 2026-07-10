import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/offer/presentation/screens/seller_offers_screen.dart';
import 'package:ambarket_mobile/features/offer/presentation/providers/offer_provider.dart';
import 'package:ambarket_mobile/features/offer/domain/models/offer_model.dart';
import 'package:ambarket_mobile/features/offer/domain/repositories/offer_repository.dart';
import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';

class FakeOfferRepository implements OfferRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<OrderModel?> findOrderByOfferId(String offerId) async {
    return OrderModel(
      id: 'mock_order_for_offer',
      productId: 'p1',
      buyerId: 'b1',
      sellerId: 's1',
      totalPrice: 100,
      subtotal: 100,
      shippingCost: 0,
      serviceFee: 0,
      shippingAddress: 'A',
      receiverPhone: 'P',
      status: 'pending_payment',
      paymentStatus: 'unpaid',
      paymentMethod: 'bca',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  testWidgets('SellerOffersScreen renders actions based on status', (
    WidgetTester tester,
  ) async {
    final mockProduct = ProductModel(
      id: 'p1',
      sellerId: 's1',
      categoryId: 'c1',
      title: 'Item',
      description: 'Desc',
      price: 150,
      condition: 'good',
      location: 'Jakarta',
      isNegotiable: true,
      status: 'active',
      createdAt: DateTime.now(),
      images: [],
    );

    final mockBuyer = ProfileModel(
      id: 'b1',
      username: 'buyer1',
      name: 'Buyer One',
      role: 'user',
      createdAt: DateTime.now(),
    );

    final offers = [
      OfferModel(
        id: 'off1',
        productId: 'p1',
        buyerId: 'b1',
        sellerId: 's1',
        offerPrice: 100,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        product: mockProduct,
        buyer: mockBuyer,
      ),
      OfferModel(
        id: 'off2',
        productId: 'p1',
        buyerId: 'b1',
        sellerId: 's1',
        offerPrice: 120,
        status: 'accepted',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        product: mockProduct,
        buyer: mockBuyer,
      ),
    ];

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredReceivedOffersProvider.overrideWith((ref) => offers),
          offerRepositoryProvider.overrideWith((ref) => FakeOfferRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: SellerOffersScreen())),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tawaran Masuk'), findsOneWidget);
    expect(find.text('Terima Tawaran'), findsOneWidget); // For 'pending' offer
    expect(find.text('Tolak'), findsOneWidget); // For 'pending' offer
    expect(find.text('Lihat Pesanan'), findsOneWidget); // For 'accepted' offer
  });
}
