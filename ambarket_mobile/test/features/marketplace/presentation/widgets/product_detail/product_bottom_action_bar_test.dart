import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/marketplace/presentation/widgets/product_detail/product_bottom_action_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProductBottomActionBar fits narrow phone widths', (
    tester,
  ) async {
    final product = ProductModel(
      id: 'product-1',
      sellerId: 'seller-1',
      categoryId: 'category-1',
      title: 'Produk',
      description: 'Deskripsi',
      price: 17000,
      condition: 'like_new',
      location: 'Jakarta',
      isNegotiable: true,
      status: 'active',
      createdAt: DateTime(2026),
    );

    tester.view.physicalSize = const Size(720, 1440);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 720),
            padding: EdgeInsets.only(bottom: 24),
            textScaler: TextScaler.linear(1.2),
          ),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ProductBottomActionBar(
                product: product,
                isOwner: false,
                isWishlisted: false,
                onToggleWishlist: () {},
                onChatPressed: () {},
                onOfferPressed: () {},
                onCartPressed: () {},
                onBuyPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ProductBottomActionBar), findsOneWidget);
    expect(find.text('Beli'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
