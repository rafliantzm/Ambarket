import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/order/presentation/screens/buyer_orders_screen.dart';
import 'package:ambarket_mobile/features/order/presentation/providers/order_provider.dart';
import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';

void main() {
  testWidgets('BuyerOrdersScreen renders actions based on status', (WidgetTester tester) async {
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
    final mockBuyer = ProfileModel(id: 'b1', name: 'Buyer', role: 'user', createdAt: DateTime.now());
    final mockSeller = ProfileModel(id: 's1', name: 'Seller', role: 'user', createdAt: DateTime.now());

    final mockOrders = [
      OrderModel(
        id: 'order_1_uuid_string',
        productId: 'p1',
        buyerId: 'b1',
        sellerId: 's1',
        totalPrice: 100,
        subtotal: 100,
        shippingCost: 12000,
        serviceFee: 2000,
        shippingAddress: 'Address',
        receiverPhone: '0800',
        status: 'pending_payment',
        paymentStatus: 'unpaid',
        paymentMethod: 'bca',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        product: mockProduct,
        buyer: mockBuyer,
        seller: mockSeller,
      ),
      OrderModel(
        id: 'order_2_uuid_string',
        productId: 'p1',
        buyerId: 'b1',
        sellerId: 's1',
        totalPrice: 100,
        subtotal: 100,
        shippingCost: 12000,
        serviceFee: 2000,
        shippingAddress: 'Address',
        receiverPhone: '0800',
        status: 'shipped',
        paymentStatus: 'paid',
        paymentMethod: 'bca',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        product: mockProduct,
        buyer: mockBuyer,
        seller: mockSeller,
      ),
    ];

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buyerOrdersProvider.overrideWith((ref) => mockOrders),
        ],
        child: const MaterialApp(
          home: BuyerOrdersScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pesanan Saya'), findsOneWidget);
    
    expect(find.text('Belum Dibayar'), findsOneWidget);
    expect(find.text('Dikirim'), findsOneWidget);
    
    // Check buttons
    expect(find.text('Bayar Sekarang'), findsOneWidget);
    expect(find.text('Lacak'), findsWidgets);
    expect(find.text('Invoice'), findsWidgets);
    expect(find.text('Pesanan Diterima'), findsOneWidget);
  });
}
