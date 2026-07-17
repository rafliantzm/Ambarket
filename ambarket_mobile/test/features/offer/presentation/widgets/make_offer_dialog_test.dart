import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/offer/presentation/widgets/make_offer_dialog.dart';

void main() {
  testWidgets('Make Offer dialog renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MakeOfferDialog(
              productId: '1',
              sellerId: '2',
              originalPrice: 100000,
              productName: 'Sepatu Bekas',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tawar Harga'), findsOneWidget);
    expect(find.text('Sepatu Bekas'), findsOneWidget);
    expect(find.text('Harga Asli: Rp100.000'), findsOneWidget);
    expect(find.text('Kirim Tawaran'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // price and message
  });

  testWidgets('Make Offer dialog validates price', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MakeOfferDialog(
              productId: '1',
              sellerId: '2',
              originalPrice: 100000,
              productName: 'Sepatu Bekas',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final button = find.text('Kirim Tawaran');
    await tester.tap(button);
    await tester.pump(); // trigger validation

    expect(find.text('Wajib diisi'), findsOneWidget);
  });

  testWidgets('Make Offer dialog remains usable on compact screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MakeOfferDialog(
              productId: '1',
              sellerId: '2',
              originalPrice: 1500000,
              productName: 'Hexohm Vapezoo Dengan Nama Produk Panjang',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tawar Harga'), findsOneWidget);
    expect(find.text('Kirim Tawaran'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
