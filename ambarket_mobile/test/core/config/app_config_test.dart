import 'package:ambarket_mobile/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppConfig accepts valid dart-define values', () {
    const config = AppConfig(
      supabaseUrl: 'https://example.supabase.co',
      supabasePublishableKey: 'publishable-key',
    );

    expect(config.validate().isValid, isTrue);
  });

  test('missing URL is invalid', () {
    const config = AppConfig(
      supabaseUrl: '',
      supabasePublishableKey: 'publishable-key',
    );

    expect(config.validate().isValid, isFalse);
    expect(
      config.validate().message,
      contains('Konfigurasi aplikasi belum tersedia'),
    );
  });

  test('missing publishable key is invalid', () {
    const config = AppConfig(
      supabaseUrl: 'https://example.supabase.co',
      supabasePublishableKey: '',
    );

    expect(config.validate().isValid, isFalse);
    expect(
      config.validate().message,
      contains('Konfigurasi aplikasi belum tersedia'),
    );
  });
}
