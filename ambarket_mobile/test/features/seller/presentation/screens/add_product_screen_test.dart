import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/seller/presentation/screens/add_product_screen.dart';
import 'package:ambarket_mobile/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/category_model.dart';

void main() {
  group('AddProductScreen Tests', () {
    testWidgets('renders form and validates', (WidgetTester tester) async {
      final mockCategories = [
        CategoryModel(id: 'c1', name: 'Elektronik', createdAt: DateTime.now()),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesProvider.overrideWith((ref) => mockCategories),
          ],
          child: const MaterialApp(
            home: AddProductScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check fields exist
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Simpan Produk'), findsOneWidget);

      // Trigger validation
      final buttonFinder = find.text('Simpan Produk');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Expect validation errors
      expect(find.text('Wajib diisi'), findsWidgets);
    });
  });
}
