class AppConfig {
  static const supabaseUrlKey = 'SUPABASE_URL';
  static const supabasePublishableKeyKey = 'SUPABASE_PUBLISHABLE_KEY';

  static const fromEnvironment = AppConfig(
    supabaseUrl: String.fromEnvironment(supabaseUrlKey),
    supabasePublishableKey: String.fromEnvironment(supabasePublishableKeyKey),
  );

  final String supabaseUrl;
  final String supabasePublishableKey;

  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  AppConfigValidation validate() {
    if (supabaseUrl.trim().isEmpty) {
      return const AppConfigValidation.invalid(
        'Konfigurasi aplikasi belum tersedia. Jalankan Ambarket dengan konfigurasi Supabase yang valid.',
      );
    }

    if (supabasePublishableKey.trim().isEmpty) {
      return const AppConfigValidation.invalid(
        'Konfigurasi aplikasi belum tersedia. Jalankan Ambarket dengan konfigurasi Supabase yang valid.',
      );
    }

    final uri = Uri.tryParse(supabaseUrl.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return const AppConfigValidation.invalid(
        'Konfigurasi Supabase tidak valid. Periksa URL publik aplikasi.',
      );
    }

    return const AppConfigValidation.valid();
  }
}

class AppConfigValidation {
  final bool isValid;
  final String? message;

  const AppConfigValidation._({required this.isValid, this.message});

  const AppConfigValidation.valid() : this._(isValid: true);

  const AppConfigValidation.invalid(String message)
    : this._(isValid: false, message: message);
}
