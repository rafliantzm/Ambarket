// ignore_for_file: avoid_print
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabasePublishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY']!;

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
