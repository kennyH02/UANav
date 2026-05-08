import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/campus_graph.dart';

// Storing user-related data locally on the device, the user's display name, whether they are in guest mode,
// route preferences, recent places, and favorite places.
class LocalUserStore {
  static const _recentPlacesKey = 'uanav.recent_places';
  static const _favoritePlacesKey = 'uanav.favorite_places';
  static const _routePreferencesKey = 'uanav.route_preferences';
  static const _profileNameKey = 'uanav.profile_name';
  static const _guestModeKey = 'uanav.guest_mode';

  // Route preferences are stored locally
  // Should be syncing with Supabase, but abandoned for now
  Future<RoutePreferences> loadPreferences() async {
    // Load route preferences from local storage.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_routePreferencesKey);
    // If there is no stored preferences, return default.
    if (raw == null) {
      return const RoutePreferences();
    }

    // Attempt to decode the stored preferences, if it fails return default.
    try {
      return RoutePreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (error) {
      return const RoutePreferences();
    }
  }

  // Save route preferences to local storage.
  Future<void> savePreferences(RoutePreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _routePreferencesKey,
      jsonEncode(preferences.toJson()),
    );
  }

  // Recent and favorite places are stored locally.
  // Should be syncing with Supabase, but abandoned for now
  Future<List<CampusPlace>> loadRecentPlaces() async {
    return _loadPlaceList(_recentPlacesKey);
  }

  // When adding a recent place, we want to ensure it appears at the front of the list and that there are no duplicates.
  Future<void> addRecentPlace(CampusPlace place) async {
    final recents = await loadRecentPlaces();
    final next = <CampusPlace>[
      place,
      ...recents.where((candidate) => candidate.key != place.key),
    ].take(8).toList();
    await _savePlaceList(_recentPlacesKey, next);
  }

  Future<List<CampusPlace>> loadFavoritePlaces() async {
    return _loadPlaceList(_favoritePlacesKey);
  }

  // Adds the place to favorite list of 20 items
  // If the place already exists, it will be removed from the list.
  Future<void> toggleFavorite(CampusPlace place) async {
    final favorites = await loadFavoritePlaces();
    final exists = favorites.any((candidate) => candidate.key == place.key);
    final next = exists
        ? favorites.where((candidate) => candidate.key != place.key).toList()
        : <CampusPlace>[place, ...favorites];

    await _savePlaceList(_favoritePlacesKey, next.take(20).toList());
  }

  // User profile data, such as display name and guest mode, are also stored locally.
  // Should be syncing with Supabase, but abandoned for now
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

  // Boolean flag to indicate if guest mode is enabled
  Future<bool> loadGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestModeKey) ?? false;
  }

  // Save the guest mode flag to local storage.
  Future<void> saveGuestMode(bool input) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, input);
  }

  // Load and save lists of CampusPlace objects as JSON strings in shared preferences.
  Future<List<CampusPlace>> _loadPlaceList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) {
      return const [];
    }

    try {
      final values = jsonDecode(raw) as List<dynamic>;
      return values
          .map(
            (value) =>
                CampusPlace.fromJson(Map<String, dynamic>.from(value as Map)),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  // Save a list of CampusPlace objects to shared preferences as a JSON string.
  Future<void> _savePlaceList(String key, List<CampusPlace> places) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(places.map((place) => place.toJson()).toList()),
    );
  }
}
