import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:ambarket_mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:ambarket_mobile/features/cart/domain/models/cart_item_model.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';

void main() {
  testWidgets('CartScreen empty state render', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cartItemsProvider.overrideWith((ref) => Future.value([]))],
        child: const MaterialApp(home: CartScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Keranjang'), findsOneWidget); // App bar
    expect(find.text('Keranjang Kosong'), findsOneWidget); // Empty state title
  });

  testWidgets('CartScreen item render', (WidgetTester tester) async {
    final mockProduct = ProductModel(
      id: 'p1',
      sellerId: 's1',
      categoryId: 'c1',
      title: 'Mock Item',
      description: 'Desc',
      price: 150000,
      condition: 'good',
      createdAt: DateTime.now(),
      images: [],
      isNegotiable: false,
      location: 'Jakarta',
      status: 'active',
    );

    final mockItems = [
      CartItemModel(
        id: 'c1',
        userId: 'u1',
        productId: 'p1',
        quantity: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        product: mockProduct,
      ),
    ];

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cartItemsProvider.overrideWith((ref) => Future.value(mockItems)),
        ],
        child: const MaterialApp(home: CartScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Keranjang'), findsOneWidget);
    expect(find.text('Mock Item'), findsOneWidget);
  });
}
