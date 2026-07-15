import 'dart:async';

import 'package:finance_app/core/config/app_config.dart';
import 'package:finance_app/features/auth/data/app_user.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Raised for user-facing auth problems (bad credentials, backend off, …).
///
/// [message] is the provider's own text (already human-readable, but always in
/// English — it comes from the server). [isNotConfigured] marks our own
/// "backend isn't wired up" case, which the UI shows localised instead.
class AuthFailure implements Exception {
  AuthFailure(this.message, {this.isNotConfigured = false});

  final String message;
  final bool isNotConfigured;

  @override
  String toString() => message;
}

/// Account layer over Supabase Auth, kept behind an app-owned surface so no
/// other feature depends on Supabase directly.
///
/// When the backend isn't configured yet (placeholder keys in [AppConfig]),
/// the service stays inert: [isAvailable] is false and any auth call throws a
/// friendly [AuthFailure], so the app runs local-first without crashing.
class AuthService {
  AuthService();

  sb.SupabaseClient? _client;
  StreamSubscription<sb.AuthState>? _sub;

  /// Reactive account state. `null` means signed out (or backend off).
  final ValueNotifier<AppUser?> currentUser = ValueNotifier<AppUser?>(null);

  /// Flips true once [bind] has wired up Supabase, so account/sync UI can
  /// refresh from its initial "not ready" state.
  final ValueNotifier<bool> isReady = ValueNotifier<bool>(false);

  bool get isAvailable => _client != null;
  bool get isSignedIn => currentUser.value != null;

  /// Connects to Supabase Auth. Call AFTER `Supabase.initialize` completes
  /// (done off the launch critical path). No-op if the backend isn't set up.
  void bind() {
    if (_client != null || !AppConfig.isBackendConfigured) return;
    final client = sb.Supabase.instance.client;
    _client = client;
    currentUser.value = _map(client.auth.currentUser);
    _sub = client.auth.onAuthStateChange.listen((event) {
      currentUser.value = _map(event.session?.user);
    });
    isReady.value = true;
  }

  AppUser? _map(sb.User? u) =>
      u == null ? null : AppUser(id: u.id, email: u.email ?? '');

  sb.GoTrueClient _auth() {
    final client = _client;
    if (client == null) {
      throw AuthFailure(
        'Sync isn\'t set up yet. Add your Supabase keys in AppConfig to '
        'enable accounts.',
        isNotConfigured: true,
      );
    }
    return client.auth;
  }

  Future<void> signUp(String email, String password) async {
    try {
      await _auth().signUp(email: email.trim(), password: password);
    } on sb.AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth().signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on sb.AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> signOut() async => _auth().signOut();

  void dispose() {
    _sub?.cancel();
    currentUser.dispose();
    isReady.dispose();
  }
}
