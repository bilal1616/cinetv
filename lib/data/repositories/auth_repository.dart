import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Session? get session => _client.auth.currentSession;
  User? get user => _client.auth.currentUser;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName, // NEW
    required String username, // NEW
  }) {
    // user_metadata içine hem name hem full_name hem username yazıyoruz.
    return _client.auth.signUp(
      email: email,
      password: password,
      // email confirmations kapalıysa anında session gelir.
      data: {
        'name': fullName, // dashboard "Display name" alanı için
        'full_name': fullName,
        'username': username,
      },
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() => _client.auth.signOut();
}
