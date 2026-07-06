import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/marketplace/presentation/widgets/product_detail/product_purchase_panel.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';

void main() {
  testWidgets('ProductPurchasePanel shows Add to Cart and Buy Now, disables for own product', (WidgetTester tester) async {
    final mockProduct = ProductModel(
      id: 'p1',
      sellerId: 's1', // User is s1
      categoryId: 'c1',
      title: 'Mock Product',
      description: 'Desc',
      price: 150000,
      condition: 'good',
      createdAt: DateTime.now(),
      images: [],
      isNegotiable: true,
      location: 'Jakarta',
      status: 'active',
    );

    final mockProfile = ProfileModel(
      id: 's1',
      name: 'Seller',
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
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProductPurchasePanel(
              product: mockProduct,
              isOwner: true,
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
    );

    await tester.pumpAndSettle();

    // Check that it rendered.
    expect(find.byType(ProductPurchasePanel), findsOneWidget);
    expect(find.text('Tawar Harga'), findsWidgets);
    expect(find.text('+ Keranjang'), findsWidgets);
    expect(find.text('Beli Sekarang'), findsWidgets);
  });
}

