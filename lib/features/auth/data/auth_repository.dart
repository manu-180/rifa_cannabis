import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signInWithPassword(String email, String password) async {
    if (kDebugMode) {
      print('🔐 [LOGIN DEBUG] Intentando login con email: $email');
    }
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      if (kDebugMode) {
        print('🔐 [LOGIN DEBUG] Login exitoso');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('🔐 [LOGIN DEBUG] Error en signInWithPassword: $e');
        print('🔐 [LOGIN DEBUG] Tipo: ${e.runtimeType}');
        print('🔐 [LOGIN DEBUG] Stack: $stack');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
