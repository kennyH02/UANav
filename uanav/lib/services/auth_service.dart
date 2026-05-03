import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static const defaultDisplayName = 'Great Dane';

  SupabaseClient get _client => Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  bool get isSignedIn => currentSession != null;

  String currentDisplayName() {
    return displayNameFor(currentUser);
  }

  // Returns a display name for the given user, or a default if not set.
  // Default is "Great Dane" btw
  String displayNameFor(User? user) {
    final metadata = user?.userMetadata;
    final displayName = metadata?['display_name'] ?? metadata?['full_name'];
    if (displayName is String && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    return defaultDisplayName;
  }

  // Sign in with email and password. Trims the email before sending to Supabase.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Sign up with email, password, and display name. Trims the email and display name before sending to Supabase.
  Future<AuthResponse> signUp({
    required String displayName,
    required String email,
    required String password,
  }) {
    final cleanedName = _cleanDisplayName(displayName);
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': cleanedName},
    );
  }

  // Update the current user's display name. Trims the display name before sending to Supabase.
  Future<String> updateDisplayName(String displayName) async {
    final cleanedName = _cleanDisplayName(displayName);
    await _client.auth.updateUser(
      UserAttributes(data: {'display_name': cleanedName}),
    );
    return cleanedName;
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  // Helper method to clean the display name by trimming whitespace and providing a default if empty.
  String _cleanDisplayName(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? defaultDisplayName : trimmed;
  }
}
