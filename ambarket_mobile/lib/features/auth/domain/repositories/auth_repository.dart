import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Stream<AuthState> get authStateChanges;
  User? get currentUser;
  
  Future<AuthResponse> signInWithEmailPassword(String email, String password);
  Future<AuthResponse> signUpWithEmailPassword(String email, String password, {String? name});
  Future<void> signOut();
}
