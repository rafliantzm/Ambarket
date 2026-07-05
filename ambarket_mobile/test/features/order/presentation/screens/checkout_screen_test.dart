import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/order/presentation/screens/checkout_screen.dart';
import 'package:ambarket_mobile/features/offer/domain/models/offer_model.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';

void main() {
  testWidgets('CheckoutScreen renders correctly and validates form', (WidgetTester tester) async {
    final mockProduct = ProductModel(
      id: 'prod1',
      sellerId: 'seller1',
      categoryId: 'cat1',
      title: 'Mock Product',
      description: 'Desc',
      price: 150000,
      condition: 'good',
      createdAt: DateTime.now(),
      images: [],
      isNegotiable: false,
      location: 'Jakarta',
      status: 'active',
    );

    final mockOffer = OfferModel(
      id: 'offer1',
      productId: 'prod1',
      buyerId: 'buyer1',
      sellerId: 'seller1',
      offerPrice: 100000,
      status: 'accepted',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      product: mockProduct,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CheckoutScreen(offer: mockOffer),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Pembelian'), findsOneWidget);
    expect(find.text('Mock Product'), findsOneWidget);
    expect(find.text('Rp 100.000'), findsOneWidget);
    expect(find.text('Informasi Pengiriman'), findsOneWidget);

    // Tap submit button directly
    await tester.tap(find.text('Buat Pesanan'));
    await tester.pumpAndSettle();

    // Expect validation errors
    expect(find.text('Nomor telepon wajib diisi'), findsOneWidget);
    expect(find.text('Alamat pengiriman wajib diisi'), findsOneWidget);

    // Fill short address
    await tester.enterText(find.byType(TextFormField).first, '081234567890');
    await tester.enterText(find.byType(TextFormField).last, 'Short');
    
    await tester.tap(find.text('Buat Pesanan'));
    await tester.pumpAndSettle();
    
    expect(find.text('Alamat terlalu singkat'), findsOneWidget);
  });
}
