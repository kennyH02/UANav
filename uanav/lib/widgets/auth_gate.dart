import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth_screen.dart';
import '../screens/map_screen.dart';
import '../services/auth_service.dart';
import '../services/local_user_store.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  final _userStore = LocalUserStore();

  StreamSubscription<AuthState>? _authSubscription;
  Session? _session;
  bool _guestMode = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _authSubscription = _authService.onAuthStateChange.listen((state) {
      _handleAuthStateChange(state.session);
    });
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_session != null) {
      return MapScreen(accountMode: AccountMode.signedIn, onSignOut: _signOut);
    }

    if (_guestMode) {
      return MapScreen(accountMode: AccountMode.guest, onSignOut: _leaveGuest);
    }

    return AuthScreen(
      onSignIn: _signIn,
      onCreateAccount: _createAccount,
      onContinueAsGuest: _continueAsGuest,
    );
  }

  Future<void> _bootstrap() async {
    final guestMode = await _userStore.loadGuestMode();
    final session = _authService.currentSession;

    if (session != null && guestMode) {
      await _userStore.saveGuestMode(false);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _session = session;
      _guestMode = session == null && guestMode;
      _loading = false;
    });
  }

  Future<void> _signIn(String email, String password) async {
    final response = await _authService.signIn(
      email: email,
      password: password,
    );
    await _userStore.saveGuestMode(false);

    if (!mounted) {
      return;
    }

    setState(() {
      _session = response.session ?? _authService.currentSession;
      _guestMode = false;
    });
  }

  Future<void> _createAccount(
    String displayName,
    String email,
    String password,
  ) async {
    final response = await _authService.signUp(
      displayName: displayName,
      email: email,
      password: password,
    );
    await _userStore.saveGuestMode(false);

    if (!mounted || response.session == null) {
      return;
    }

    setState(() {
      _session = response.session;
      _guestMode = false;
    });
  }

  Future<void> _continueAsGuest() async {
    await _userStore.saveGuestMode(true);

    if (!mounted) {
      return;
    }

    setState(() {
      _session = null;
      _guestMode = true;
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    await _userStore.saveGuestMode(false);

    if (!mounted) {
      return;
    }

    setState(() {
      _session = null;
      _guestMode = false;
    });
  }

  Future<void> _leaveGuest() async {
    await _userStore.saveGuestMode(false);

    if (!mounted) {
      return;
    }

    setState(() {
      _session = null;
      _guestMode = false;
    });
  }

  void _handleAuthStateChange(Session? session) {
    if (!mounted) {
      return;
    }

    setState(() {
      _session = session;
      if (session != null) {
        _guestMode = false;
      }
    });

    if (session != null) {
      unawaited(_userStore.saveGuestMode(false));
    }
  }
}
