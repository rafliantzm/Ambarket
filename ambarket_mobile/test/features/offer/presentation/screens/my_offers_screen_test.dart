import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/offer/presentation/screens/my_offers_screen.dart';

import 'package:ambarket_mobile/features/offer/presentation/providers/offer_provider.dart';

void main() {
  testWidgets('MyOffersScreen renders empty states', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mySentOffersProvider.overrideWith((ref) => Future.value([])),
          myReceivedOffersProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: MyOffersScreen(),
        ),
      ),
    );

    // Initial load state
    await tester.pumpAndSettle();

    expect(find.text('Tawaran Saya'), findsOneWidget);
    expect(find.text('Terkirim'), findsOneWidget);
    expect(find.text('Diterima'), findsOneWidget);

    // It should say "Belum ada tawaran terkirim." because it's mocked empty or returns empty by default when not logged in
    expect(find.text('Belum ada tawaran terkirim.'), findsOneWidget);

    // Tap received tab
    await tester.tap(find.text('Diterima'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada tawaran diterima.'), findsOneWidget);
  });
}
