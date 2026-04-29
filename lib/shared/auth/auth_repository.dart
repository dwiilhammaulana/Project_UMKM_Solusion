import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

enum AuthFailureCode {
  emailNotConfirmed,
  invalidCredentials,
  network,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  final AuthFailureCode code;
  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository(this._client);

  static const authCallbackUrl = 'com.warungkopi.pos://login-callback';

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          if ((fullName ?? '').trim().isNotEmpty) 'full_name': fullName!.trim(),
        },
        emailRedirectTo: authCallbackUrl,
      );
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: authCallbackUrl,
        authScreenLaunchMode: launcher.LaunchMode.externalApplication,
      );
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  Future<void> resendSignupVerification(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: authCallbackUrl,
      );
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  AuthFailure _mapAuthException(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('email not confirmed') ||
        message.contains('email not verified')) {
      return const AuthFailure(
        AuthFailureCode.emailNotConfirmed,
        'Email belum diverifikasi. Cek inbox kamu lalu coba login lagi.',
      );
    }
    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials')) {
      return const AuthFailure(
        AuthFailureCode.invalidCredentials,
        'Email atau password tidak cocok.',
      );
    }
    if (message.contains('network') || message.contains('socket')) {
      return const AuthFailure(
        AuthFailureCode.network,
        'Koneksi internet bermasalah. Coba lagi beberapa saat.',
      );
    }
    return AuthFailure(AuthFailureCode.unknown, error.message);
  }
}
