import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/auth/presentation/screens/register_screen.dart';

void main() {
  testWidgets('RegisterScreen validation works', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterScreen())),
    );

    // Tap the register button without entering anything
    await tester.tap(find.text('Daftar'));
    await tester.pump();

    // Expect validation errors
    expect(find.text('Email tidak boleh kosong'), findsOneWidget);
    expect(find.text('Kata sandi tidak boleh kosong'), findsOneWidget);

    // Enter invalid email
    await tester.enterText(find.byType(TextFormField).first, 'invalidemail');
    await tester.tap(find.text('Daftar'));
    await tester.pump();

    expect(find.text('Format email tidak valid'), findsOneWidget);

    // Enter short password
    await tester.enterText(find.byType(TextFormField).last, '123');
    await tester.tap(find.text('Daftar'));
    await tester.pump();

    expect(find.text('Kata sandi minimal 6 karakter'), findsOneWidget);
  });
}
