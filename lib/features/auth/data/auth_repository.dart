import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../domain/app_user.dart';

/// Passwordless sign-in: the client enters an e-mail and the 6-digit code
/// from the letter. No passwords to forget, no extra screens.
abstract interface class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> authStateChanges();
  Future<void> sendCode(String email);
  Future<void> verifyCode(String email, String code);
  Future<void> signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Env.hasSupabase) return SupabaseAuthRepository(Supabase.instance.client);
  return MockAuthRepository();
});

final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._db);
  final SupabaseClient _db;

  static AppUser? _map(User? u) => u == null
      ? null
      : AppUser(
          id: u.id,
          email: u.email,
          name: u.userMetadata?['full_name'] as String?,
        );

  @override
  AppUser? get currentUser => _map(_db.auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() =>
      _db.auth.onAuthStateChange.map((s) => _map(s.session?.user));

  @override
  Future<void> sendCode(String email) =>
      _db.auth.signInWithOtp(email: email, shouldCreateUser: true);

  @override
  Future<void> verifyCode(String email, String code) async {
    await _db.auth.verifyOTP(email: email, token: code, type: OtpType.email);
  }

  @override
  Future<void> signOut() => _db.auth.signOut();
}

/// Demo auth: any e-mail, any 6-digit code.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({AppUser? initialUser}) : _user = initialUser;

  AppUser? _user;
  final _changes = StreamController<AppUser?>.broadcast();

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  Future<void> sendCode(String email) async {}

  @override
  Future<void> verifyCode(String email, String code) async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const AuthFailure('Код должен состоять из 6 цифр');
    }
    _set(AppUser(id: 'demo-user', email: email));
  }

  @override
  Future<void> signOut() async => _set(null);

  void _set(AppUser? user) {
    _user = user;
    _changes.add(user);
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
