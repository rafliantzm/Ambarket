// ignore_for_file: avoid_print
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

Future<void> main() async {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    stderr.writeln(
      'Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY dart-define.',
    );
    exit(1);
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  final client = Supabase.instance.client;

  try {
    print('Attempting to sign up...');
    final response = await client.auth.signUp(
      email: 'raflian100@gmail.com',
      password: 'password123',
      data: {'name': 'raflian100'},
    );
    print('SignUp Success! Session: ${response.session != null}');
  } catch (e) {
    print('SignUp Error: $e');
  }
  exit(0);
}
