import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/seller/presentation/screens/seller_dashboard_screen.dart';
import 'package:ambarket_mobile/features/seller/presentation/providers/seller_provider.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'dart:async';

class MockMyProductsNotifier extends MyProductsNotifier {
  final List<ProductModel> _products;
  MockMyProductsNotifier(this._products);

  @override
  FutureOr<PaginatedSellerProductsState> build() {
    return PaginatedSellerProductsState(products: _products, hasMore: false);
  }
}

void main() {
  group('SellerDashboardScreen Tests', () {
    testWidgets('renders empty state when no products', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myProductsProvider.overrideWith(() => MockMyProductsNotifier([])),
          ],
          child: const MaterialApp(
            home: SellerDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Anda belum memiliki produk'), findsOneWidget);
      expect(find.text('Tambah Produk'), findsWidgets);
    });

    testWidgets('renders products and stats correctly', (WidgetTester tester) async {
      final mockProducts = [
        ProductModel(
          id: '1',
          sellerId: 'user1',
          categoryId: 'cat1',
          title: 'Laptop Bekas',
          description: 'Masih bagus',
          price: 5000000,
          condition: 'good',
          location: 'Jakarta',
          isNegotiable: true,
          status: 'active',
          createdAt: DateTime.now(),
        ),
        ProductModel(
          id: '2',
          sellerId: 'user1',
          categoryId: 'cat1',
          title: 'HP Rusak',
          description: 'Minus LCD',
          price: 500000,
          condition: 'need_repair',
          location: 'Jakarta',
          isNegotiable: false,
          status: 'sold',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myProductsProvider.overrideWith(() => MockMyProductsNotifier(mockProducts)),
          ],
          child: const MaterialApp(
            home: SellerDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Stats
      expect(find.text('2'), findsOneWidget); // Total
      expect(find.text('1'), findsNWidgets(2)); // Active and Sold (both have 1)
      expect(find.text('0'), findsOneWidget); // Archived

      // List
      expect(find.text('Laptop Bekas'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('HP Rusak'), findsOneWidget);
      
      // Status tags
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Sold'), findsWidgets);
    });

    testWidgets('shows confirmation dialog on mark sold', (WidgetTester tester) async {
      final mockProducts = [
        ProductModel(
          id: '1',
          sellerId: 'user1',
          categoryId: 'cat1',
          title: 'Laptop Bekas',
          description: 'Masih bagus',
          price: 5000000,
          condition: 'good',
          location: 'Jakarta',
          isNegotiable: true,
          status: 'active',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myProductsProvider.overrideWith(() => MockMyProductsNotifier(mockProducts)),
          ],
          child: const MaterialApp(
            home: SellerDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final buttonFinder = find.text('Mark Sold');
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Tandai Terjual'), findsOneWidget);
      expect(find.text('Apakah Anda yakin ingin menandai produk ini sebagai terjual?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Ya'), findsOneWidget);
    });
  });
}
