import 'package:ambarket_mobile/core/config/app_config.dart';
import 'package:ambarket_mobile/core/startup/app_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty configuration never initializes Supabase', () async {
    var initializeCount = 0;

    final result = await initializeAmbarketStartup(
      const AppConfig(supabaseUrl: '', supabasePublishableKey: ''),
      initializeSupabase: (_) async {
        initializeCount++;
      },
    );

    expect(initializeCount, 0);
    expect(result.status, StartupStatus.configurationError);
  });

  testWidgets('missing configuration produces a visible Flutter error screen', (
    tester,
  ) async {
    final result = await initializeAmbarketStartup(
      const AppConfig(supabaseUrl: '', supabasePublishableKey: ''),
      initializeSupabase: (_) async {
        fail('Supabase should not initialize with empty configuration');
      },
    );

    await tester.pumpWidget(AmbarketStartupApp(startupResult: result));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Konfigurasi belum lengkap'), findsOneWidget);
    expect(find.textContaining('Jalankan Ambarket'), findsOneWidget);
  });

  testWidgets(
    'initialization exception produces a visible startup error screen',
    (tester) async {
      final result = await initializeAmbarketStartup(
        const AppConfig(
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: 'publishable-key',
        ),
        initializeSupabase: (_) async {
          throw StateError('secret internal detail');
        },
      );

      await tester.pumpWidget(AmbarketStartupApp(startupResult: result));

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Ambarket belum dapat dimuat'), findsOneWidget);
      expect(find.textContaining('gagal terhubung'), findsOneWidget);
      expect(find.text('Muat Ulang'), findsOneWidget);
      expect(find.textContaining('secret internal detail'), findsNothing);
    },
  );
}
