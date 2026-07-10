import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/seller/presentation/screens/seller_products_screen.dart';
import 'package:ambarket_mobile/features/seller/presentation/providers/seller_product_provider.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';

// Create a dummy product for testing
final dummyActiveProduct = ProductModel(
  id: 'prod-1',
  sellerId: 'seller-1',
  categoryId: 'cat-1',
  title: 'Dummy Active Product',
  description: 'Test product',
  price: 50000,
  condition: 'Baru',
  location: 'Jakarta',
  isNegotiable: true,
  status: 'active',
  createdAt: DateTime.now(),
);

final dummyArchivedProduct = ProductModel(
  id: 'prod-2',
  sellerId: 'seller-1',
  categoryId: 'cat-1',
  title: 'Dummy Archived Product',
  description: 'Test product',
  price: 50000,
  condition: 'Baru',
  location: 'Jakarta',
  isNegotiable: true,
  status: 'archived',
  createdAt: DateTime.now(),
);

final dummyRejectedProduct = ProductModel(
  id: 'prod-3',
  sellerId: 'seller-1',
  categoryId: 'cat-1',
  title: 'Dummy Rejected Product',
  description: 'Test product',
  price: 50000,
  condition: 'Baru',
  location: 'Jakarta',
  isNegotiable: true,
  status: 'rejected',
  createdAt: DateTime.now(),
);

// Mock providers
final mockEmptyProductsProvider =
    AsyncNotifierProvider<SellerProductListNotifier, List<ProductModel>>(
      () => MockEmptyProductsNotifier(),
    );

class MockEmptyProductsNotifier extends SellerProductListNotifier {
  @override
  Future<List<ProductModel>> build() async => [];
}

final mockDataProductsProvider =
    AsyncNotifierProvider<SellerProductListNotifier, List<ProductModel>>(
      () => MockDataProductsNotifier(),
    );

class MockDataProductsNotifier extends SellerProductListNotifier {
  @override
  Future<List<ProductModel>> build() async => [
    dummyActiveProduct,
    dummyArchivedProduct,
    dummyRejectedProduct,
  ];
}

void main() {
  Widget createTestWidget(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SellerProductsScreen()),
    );
  }

  testWidgets('SellerProductsScreen renders header and filters', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        sellerProductsProvider.overrideWith(() => MockEmptyProductsNotifier()),
      ],
    );

    await tester.pumpWidget(createTestWidget(container));
    await tester.pump();

    expect(find.text('Kelola Produk'), findsOneWidget);
    expect(
      find.text('Pantau, edit, dan kelola status produk toko Anda.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Diarsipkan'), findsOneWidget);
  });

  testWidgets('SellerProductsScreen empty state render', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        sellerProductsProvider.overrideWith(() => MockEmptyProductsNotifier()),
      ],
    );

    await tester.pumpWidget(createTestWidget(container));
    await tester.pump();

    expect(find.text('Tidak Ada Produk'), findsOneWidget);
    expect(find.text('Belum ada produk pada status ini.'), findsOneWidget);
  });

  testWidgets('SellerProductsScreen renders active product card and buttons', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        sellerProductsProvider.overrideWith(() => MockDataProductsNotifier()),
      ],
    );

    await tester.pumpWidget(createTestWidget(container));
    await tester.pump();

    // Verify product titles
    expect(find.text('Dummy Active Product'), findsOneWidget);
    expect(find.text('Dummy Archived Product'), findsOneWidget);

    // Verify Active product buttons (Arsipkan, Edit)
    // Archived doesn't have Arsipkan.
    expect(find.text('Arsipkan'), findsOneWidget);
    expect(find.text('Aktifkan'), findsOneWidget);

    // There are 2 "Edit" buttons (Active and Archived can be edited). Rejected cannot be edited.
    expect(find.text('Edit'), findsNWidgets(2));
  });
}
