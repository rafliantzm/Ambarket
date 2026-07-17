import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorMapper {
  static String getFriendlyMessage(dynamic error) {
    if (error is SocketException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }

    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      final code = error.code?.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Email atau kata sandi yang Anda masukkan salah.';
      }
      if (code == 'over_email_send_rate_limit' ||
          code == 'over_request_rate_limit' ||
          msg.contains('email rate limit') ||
          msg.contains('email limit') ||
          msg.contains('rate limit') ||
          msg.contains('too many requests')) {
        return 'Batas pengiriman email verifikasi sedang tercapai. Tunggu beberapa menit lalu coba lagi, atau gunakan email lain.';
      }
      if (msg.contains('user already registered') ||
          msg.contains('user_already_exists') ||
          msg.contains('already exists') ||
          msg.contains('already registered')) {
        return 'Email ini sudah terdaftar. Silakan masuk.';
      }
      return error.message; // Show raw message for easier debugging
    }

    if (error is PostgrestException) {
      final code = error.code;
      final msg = error.message.toLowerCase();

      if (code == '23505') {
        // Unique violation
        return 'Data ini sudah pernah dibuat sebelumnya.';
      }
      if (code == '42501' ||
          msg.contains('row-level security') ||
          msg.contains('new row violates')) {
        // RLS or permission error
        return 'Anda tidak memiliki akses untuk melakukan aksi ini.';
      }
      return 'Terjadi kendala saat menyimpan data. Silakan coba beberapa saat lagi.';
    }

    if (error is Exception) {
      final msg = error.toString().toLowerCase();
      if (msg.contains('failed host lookup')) {
        return 'Koneksi internet bermasalah. Pastikan perangkat Anda terhubung ke internet.';
      }
      if (msg.contains('tawaran')) {
        return _cleanExceptionMessage(error);
      }
      if (msg.contains('produk') &&
          (msg.contains('tidak') || msg.contains('gagal'))) {
        return _cleanExceptionMessage(error);
      }
    }

    return 'Terjadi kendala teknis. Silakan coba beberapa saat lagi.';
  }

  static String _cleanExceptionMessage(Exception error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  }
}
