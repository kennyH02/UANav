import 'package:shared_preferences/shared_preferences.dart';

// This class is responsible for storing user-related data locally on the device,
// such as the user's display name and whether they are in guest mode.
class LocalUserStore {
  static const _profileNameKey = 'uanav.profile_name';
  static const _guestModeKey = 'uanav.guest_mode';

  Future<String> loadProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileNameKey) ?? 'Great Dane';
  }

  Future<void> saveProfileName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profileNameKey,
      name.trim().isEmpty ? 'Great Dane' : name.trim(),
    );
  }

  Future<bool> loadGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestModeKey) ?? false;
  }

  Future<void> saveGuestMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, enabled);
  }
}
