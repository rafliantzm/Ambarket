import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec does not bundle local .env as a Flutter asset', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(
      pubspec,
      isNot(contains(RegExp(r'^\s*-\s*\.env\s*$', multiLine: true))),
    );
  });

  test('runtime config supports dart-define fallback keys', () {
    final configSource = File(
      'lib/core/config/app_config.dart',
    ).readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();
    final envSource = File('lib/core/env/env.dart').readAsStringSync();

    expect(configSource, contains("String.fromEnvironment(supabaseUrlKey)"));
    expect(configSource, contains('SUPABASE_URL'));
    expect(configSource, contains('SUPABASE_PUBLISHABLE_KEY'));
    expect(mainSource, isNot(contains('flutter_dotenv')));
    expect(envSource, isNot(contains('flutter_dotenv')));
  });

  test('no service_role or private runtime configuration support exists', () {
    final configSource = File(
      'lib/core/config/app_config.dart',
    ).readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    final combined = '$configSource\n$mainSource\n$pubspec'.toLowerCase();

    expect(combined, isNot(contains('service_role')));
    expect(combined, isNot(contains('service-role')));
    expect(combined, isNot(contains('supabase_service')));
  });
}
