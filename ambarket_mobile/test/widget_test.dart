import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:ambarket_mobile/main.dart';
import 'package:ambarket_mobile/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/marketplace/presentation/widgets/product_card.dart';

void main() {
  testWidgets('App should render correctly', (WidgetTester tester) async {
    // Setup a mock router for testing
    final mockRouter = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('Login Screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRouterProvider.overrideWithValue(mockRouter)],
        child: const AmbarketApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('ProductCard should render correctly with mock data', (
    WidgetTester tester,
  ) async {
    final mockProduct = ProductModel(
      id: '1',
      sellerId: 'user1',
      categoryId: 'cat1',
      title: 'Mock Product',
      description: 'A mock description',
      price: 150000,
      condition: 'good',
      isNegotiable: true,
      location: 'Jakarta',
      status: 'active',
      images: [],
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(null)],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 350,
                child: ProductCard(product: mockProduct),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Mock Product'), findsOneWidget);
    expect(find.text('Baik'), findsOneWidget);
    expect(find.text('Nego'), findsOneWidget);
  });
}
