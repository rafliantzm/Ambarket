import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/order/presentation/screens/seller_orders_screen.dart';
import 'package:ambarket_mobile/features/order/presentation/providers/order_provider.dart';
import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';

void main() {
  testWidgets('SellerOrdersScreen renders actions based on status', (WidgetTester tester) async {
    final mockProduct = ProductModel(
      id: 'p1',
      sellerId: 's1',
      categoryId: 'c1',
      title: 'Item',
      description: 'Desc',
      price: 100,
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

    final orders = [
      OrderModel(
        id: 'order_1_mock_id',
        productId: 'p1',
        buyerId: 'b1',
        sellerId: 's1',
        totalPrice: 100,
        receiverName: 'R',
        receiverPhone: 'P',
        shippingAddress: 'A',
        shippingMethod: 'M',
        shippingCost: 10,
        paymentMethod: 'transfer',
        paymentStatus: 'paid',
        status: 'paid',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        product: mockProduct,
        buyer: mockBuyer,
      ),
      OrderModel(
        id: 'order_2_mock_id',
        productId: 'p1',
        buyerId: 'b1',
        sellerId: 's1',
        totalPrice: 100,
        receiverName: 'R',
        receiverPhone: 'P',
        shippingAddress: 'A',
        shippingMethod: 'M',
        shippingCost: 10,
        paymentMethod: 'transfer',
        paymentStatus: 'paid',
        status: 'packed',
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
          sellerOrdersProvider.overrideWith((ref) => orders),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SellerOrdersScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pesanan Masuk'), findsOneWidget);
    expect(find.text('Tandai Dikemas'), findsOneWidget); // For 'paid' order
    expect(find.text('Tandai Dikirim'), findsOneWidget); // For 'packed' order
    expect(find.text('Batalkan'), findsOneWidget); // For 'paid' order (can cancel)
  });
}
