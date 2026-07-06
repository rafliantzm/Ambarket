import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/order/presentation/screens/checkout_screen.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';

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

    final mockProfile = ProfileModel(
      id: 'buyer1',
      name: 'Buyer',
      role: 'user',
      createdAt: DateTime.now(),
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentProfileProvider.overrideWith((ref) => mockProfile),
          productDetailProvider('prod1').overrideWith((ref) => mockProduct),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CheckoutScreen(productId: 'prod1', offerId: null),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Mock Product'), findsOneWidget);

    // Fill the short address
    await tester.enterText(find.byType(TextFormField).at(1), '081234567890');
    await tester.enterText(find.byType(TextFormField).last, '');
    
    // Need to scroll if it's offscreen, but we set physicalSize large enough.
    // Still, let's make sure we find 'Buat Pesanan'.
    final buatPesananFinder = find.text('Buat Pesanan');
    expect(buatPesananFinder, findsOneWidget);
    
    await tester.tap(buatPesananFinder);
    await tester.pumpAndSettle();
    
    expect(find.text('Wajib diisi'), findsOneWidget);
  });
}


