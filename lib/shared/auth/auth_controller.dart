import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_providers.dart';
import 'auth_repository.dart';

enum AuthStatus {
  initializing,
  unauthenticated,
  authenticated,
  needsOnboarding,
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(
    repository: ref.watch(authRepositoryProvider),
    client: ref.watch(supabaseClientProvider),
  );
});

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repository,
    required SupabaseClient client,
  })  : _repository = repository,
        _client = client,
        _testStatus = null,
        _testEmailAddress = null,
        _testDisplayName = null {
    unawaited(_initialize());
  }

  AuthController.test({
    AuthStatus status = AuthStatus.authenticated,
    String? emailAddress,
    String? displayName,
    String? pendingVerificationEmail,
  })  : _repository = null,
        _client = null,
        _testStatus = status,
        _testEmailAddress = emailAddress,
        _testDisplayName = displayName,
        _isInitialized = true,
        _hasStoreProfile = status == AuthStatus.authenticated,
        _pendingVerificationEmail = pendingVerificationEmail;

  final AuthRepository? _repository;
  final SupabaseClient? _client;
  final AuthStatus? _testStatus;
  final String? _testEmailAddress;
  final String? _testDisplayName;
  StreamSubscription<AuthState>? _subscription;

  Session? _session;
  User? _user;
  bool _isInitialized = false;
  bool _isCheckingProfile = false;
  bool _hasStoreProfile = false;
  String? _pendingVerificationEmail;

  Session? get session => _session;
  User? get user => _user;
  bool get isInitialized => _isInitialized;
  bool get isCheckingProfile => _isCheckingProfile;
  bool get hasStoreProfile => _hasStoreProfile;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  bool get isAuthenticated {
    if (_testStatus != null) {
      return _testStatus == AuthStatus.authenticated ||
          _testStatus == AuthStatus.needsOnboarding;
    }
    return _session != null && _user != null;
  }

  AuthStatus get status {
    if (_testStatus != null) {
      return _testStatus;
    }
    if (!_isInitialized || _isCheckingProfile) {
      return AuthStatus.initializing;
    }
    if (!isAuthenticated) {
      return AuthStatus.unauthenticated;
    }
    if (!_hasStoreProfile) {
      return AuthStatus.needsOnboarding;
    }
    return AuthStatus.authenticated;
  }

  String get emailAddress =>
      _testEmailAddress ??
      _user?.email ??
      _pendingVerificationEmail ??
      'pengguna@warungkopi.app';

  String? get displayName {
    if (_testDisplayName != null) {
      return _testDisplayName;
    }
    final metadata = _user?.userMetadata;
    final fullName = metadata?['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    return _user?.email?.split('@').first;
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _repository!.signInWithEmail(email: email, password: password);
    _pendingVerificationEmail = null;
    await _syncCurrentAuthState();
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    await _repository!.signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
    );
    _pendingVerificationEmail = email;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    await _repository!.signInWithGoogle();
    _pendingVerificationEmail = null;
    await _syncCurrentAuthState();
  }

  Future<void> resendSignupVerification() async {
    final email = _pendingVerificationEmail;
    if (email == null || email.trim().isEmpty) {
      throw Exception('Email verifikasi belum tersedia.');
    }
    await _repository!.resendSignupVerification(email);
  }

  Future<void> signOut() async {
    await _repository!.signOut();
    _pendingVerificationEmail = null;
    _hasStoreProfile = false;
    notifyListeners();
  }

  Future<void> refreshProfileStatus() async {
    await _refreshProfileStatus();
  }

  Future<void> _initialize() async {
    final repository = _repository!;
    _session = repository.currentSession;
    _user = repository.currentUser;
    _subscription = repository.authStateChanges.listen((event) {
      _session = event.session;
      _user = event.session?.user;
      if (_user == null) {
        _hasStoreProfile = false;
        _pendingVerificationEmail = null;
        _isCheckingProfile = false;
        _isInitialized = true;
        notifyListeners();
        return;
      }
      unawaited(_refreshProfileStatus());
    });

    if (_user != null) {
      await _refreshProfileStatus();
    } else {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _syncCurrentAuthState() async {
    final repository = _repository!;
    _session = repository.currentSession;
    _user = repository.currentUser;
    if (_user != null) {
      await _refreshProfileStatus();
      return;
    }
    _hasStoreProfile = false;
    _isCheckingProfile = false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _refreshProfileStatus() async {
    final userId = _user?.id;
    if (userId == null) {
      _hasStoreProfile = false;
      _isCheckingProfile = false;
      _isInitialized = true;
      notifyListeners();
      return;
    }

    _isCheckingProfile = true;
    notifyListeners();

    try {
      final row = await _client!
          .from('app_profile')
          .select('id')
          .eq('owner_user_id', userId)
          .maybeSingle();
      _hasStoreProfile = row != null;
    } finally {
      _isCheckingProfile = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
