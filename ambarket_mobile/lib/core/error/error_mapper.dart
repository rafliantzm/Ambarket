import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorMapper {
  static String getFriendlyMessage(dynamic error) {
    if (error is SocketException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Email atau kata sandi yang Anda masukkan salah.';
      }
      if (msg.contains('user already registered')) {
        return 'Email ini sudah terdaftar. Silakan masuk.';
      }
      return 'Autentikasi gagal. Silakan coba lagi.';
    }

    if (error is PostgrestException) {
      final code = error.code;
      final msg = error.message.toLowerCase();

      if (code == '23505') {
        // Unique violation
        return 'Data ini sudah pernah dibuat sebelumnya.';
      }
      if (code == '42501' || msg.contains('row-level security') || msg.contains('new row violates')) {
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
    }

    return 'Terjadi kendala teknis. Silakan coba beberapa saat lagi.';
  }
}
