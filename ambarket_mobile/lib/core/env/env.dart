import '../config/app_config.dart';

class Env {
  static String get supabaseUrl => AppConfig.fromEnvironment.supabaseUrl;
  static String get supabasePublishableKey =>
      AppConfig.fromEnvironment.supabasePublishableKey;

  static Future<void> init() async {}
}
