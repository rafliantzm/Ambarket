import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ambarket_mobile/features/marketplace/presentation/widgets/product_card.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/core/theme/app_theme.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:ambarket_mobile/features/cart/domain/models/cart_item_model.dart';
import 'package:ambarket_mobile/features/cart/domain/repositories/cart_repository.dart';
import 'package:ambarket_mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Widget createTestWidget(ProductModel product) {
    return ProviderScope(
      overrides: [currentUserProvider.overrideWith((ref) => null)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 0.62,
            children: [ProductCard(product: product)],
          ),
        ),
      ),
    );
  }

  testWidgets('ProductCard long title renders with maxLines 2 and ellipsis', (
    WidgetTester tester,
  ) async {
    final product = ProductModel(
      id: '1',
      title:
          'This is a very very long product title that should definitely be clamped to two lines because it is just way too long for a premium product card layout',
      description: 'Test description',
      price: 15000000,
      sellerId: 'seller1',
      categoryId: 'cat1',
      location: 'Jakarta',
      condition: 'new',
      status: 'available',
      images: [],
      isNegotiable: false,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(createTestWidget(product));
    await tester.pumpAndSettle();

    final textFinder = find.text(product.title);
    expect(textFinder, findsOneWidget);

    final Text textWidget = tester.widget(textFinder);
    expect(textWidget.maxLines, 2);
    expect(textWidget.overflow, TextOverflow.ellipsis);
  });

  testWidgets('ProductCard empty image renders premium placeholder', (
    WidgetTester tester,
  ) async {
    final product = ProductModel(
      id: '2',
      title: 'Short Title',
      description: 'Test description',
      price: 50000,
      sellerId: 'seller2',
      categoryId: 'cat2',
      location: 'Bandung',
      condition: 'good',
      status: 'available',
      images: [],
      isNegotiable: false,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(createTestWidget(product));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
  });

  testWidgets('ProductCard cart button adds to cart without opening detail', (
    WidgetTester tester,
  ) async {
    final product = ProductModel(
      id: 'product-1',
      title: 'T Stop Kontak',
      description: 'Test description',
      price: 3000,
      sellerId: 'seller-1',
      categoryId: 'cat1',
      location: 'Bandung',
      condition: 'good',
      status: 'active',
      images: [],
      isNegotiable: false,
      createdAt: DateTime.now(),
    );
    final cartRepository = _FakeCartRepository();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              children: [ProductCard(product: product)],
            ),
          ),
        ),
        GoRoute(
          path: '/products/:id',
          builder: (context, state) => const Scaffold(body: Text('Detail')),
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => const Scaffold(body: Text('Cart')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(
            User(
              id: 'buyer-1',
              appMetadata: const {},
              userMetadata: const {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ),
          cartRepositoryProvider.overrideWithValue(cartRepository),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_shopping_cart_outlined));
    await tester.pumpAndSettle();

    expect(cartRepository.addedProductIds, ['product-1']);
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(find.text('Ditambahkan ke keranjang'), findsOneWidget);
    expect(find.text('Detail'), findsNothing);
  });
}

class _FakeCartRepository implements CartRepository {
  final addedProductIds = <String>[];

  @override
  Future<CartItemModel> addToCart(String userId, String productId) async {
    addedProductIds.add(productId);
    final now = DateTime.now();
    return CartItemModel(
      id: 'cart-1',
      userId: userId,
      productId: productId,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> clearCart(String userId) async {}

  @override
  Future<List<CartItemModel>> fetchCartItems(String userId) async => const [];

  @override
  Future<void> removeFromCart(String cartItemId) async {}

  @override
  Future<void> removeProductFromCart(String userId, String productId) async {}
}
