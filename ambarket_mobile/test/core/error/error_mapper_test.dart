import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/core/error/error_mapper.dart';

void main() {
  group('ErrorMapper', () {
    test('maps Supabase email send rate limit to a friendly message', () {
      final message = ErrorMapper.getFriendlyMessage(
        const AuthException(
          'Email rate limit exceeded',
          code: 'over_email_send_rate_limit',
        ),
      );

      expect(message, contains('Batas pengiriman email verifikasi'));
      expect(message, isNot(contains('Email rate limit exceeded')));
    });

    test(
      'maps generic too many requests auth errors to a friendly message',
      () {
        final message = ErrorMapper.getFriendlyMessage(
          const AuthException('Too many requests'),
        );

        expect(message, contains('Tunggu beberapa menit'));
      },
    );

    test('keeps safe domain exception messages readable', () {
      final message = ErrorMapper.getFriendlyMessage(
        Exception('Tawaran tidak dapat diterima atau statusnya berubah.'),
      );

      expect(message, 'Tawaran tidak dapat diterima atau statusnya berubah.');
    });
  });
}
