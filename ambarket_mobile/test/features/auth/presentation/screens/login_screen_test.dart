import 'package:ambarket_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:ambarket_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('LoginScreen shows Google sign-in option', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(_FakeAuthRepo())],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Masuk dengan Google'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}

class _FakeAuthRepo implements AuthRepository {
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<AuthResponse> signInWithEmailPassword(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password, {
    String? name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}
