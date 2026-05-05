import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_environment.dart';

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
  static Future<void>? _googleSignInInit;

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
      final googleAccount = await _authenticateWithNativeGoogle();
      if (googleAccount == null) {
        return;
      }
      final idToken = googleAccount.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthFailure(
          AuthFailureCode.unknown,
          'Token login Google tidak tersedia. Coba lagi.',
        );
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure(
          AuthFailureCode.unknown,
          'Login Google gagal setelah akun dipilih. Pastikan Android OAuth client memakai package com.warungkopi.pos, SHA-1 debug/release yang benar, dan GOOGLE_WEB_CLIENT_ID dari Web OAuth client project yang sama.',
        );
      }
      throw AuthFailure(
        AuthFailureCode.unknown,
        error.description ?? 'Login Google dibatalkan atau gagal.',
      );
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  Future<GoogleSignInAccount?> _authenticateWithNativeGoogle() async {
    final serverClientId = AppEnvironment.googleWebClientId;
    if (serverClientId == null) {
      throw const AuthFailure(
        AuthFailureCode.unknown,
        'GOOGLE_WEB_CLIENT_ID belum diatur. Isi Web OAuth Client ID agar login Google native bisa dipakai.',
      );
    }

    _googleSignInInit ??= GoogleSignIn.instance.initialize(
      serverClientId: serverClientId,
    );
    await _googleSignInInit;

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const AuthFailure(
        AuthFailureCode.unknown,
        'Login Google native belum didukung di platform ini.',
      );
    }

    try {
      return await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw const AuthFailure(
          AuthFailureCode.unknown,
          'Konfigurasi Google Sign-In belum cocok. Pastikan GOOGLE_WEB_CLIENT_ID adalah Web OAuth client ID dan Android OAuth client memakai package com.warungkopi.pos dengan SHA-1 aplikasi ini.',
        );
      }
      rethrow;
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

  Future<void> signOut() async {
    await _client.auth.signOut();
    final googleSignInInit = _googleSignInInit;
    if (googleSignInInit == null) {
      return;
    }
    try {
      await googleSignInInit;
      await GoogleSignIn.instance.signOut();
    } on GoogleSignInException {
      // Supabase logout already succeeded; Google cache cleanup can be retried.
    }
  }

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
