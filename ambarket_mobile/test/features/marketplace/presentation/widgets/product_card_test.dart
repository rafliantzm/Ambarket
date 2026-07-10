import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/marketplace/presentation/widgets/product_card.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/core/theme/app_theme.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';

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
}
