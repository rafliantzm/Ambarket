import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  static const googleRedirectTo = 'io.supabase.ambarket://login-callback/';

  final SupabaseClient _supabaseClient;

  SupabaseAuthRepository(this._supabaseClient);

  @override
  Stream<AuthState> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange;

  @override
  User? get currentUser => _supabaseClient.auth.currentUser;

  @override
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<bool> signInWithGoogle() async {
    return _supabaseClient.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : googleRedirectTo,
    );
  }

  @override
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password, {
    String? name,
  }) async {
    return await _supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'name': name} : null,
    );
  }

  @override
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }
}
