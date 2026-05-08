import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/campus_graph.dart';
import '../services/auth_service.dart';
import '../services/campus_graph_loader.dart';
import '../services/local_user_store.dart';
import 'map/map_controls.dart';
import 'map/map_layers.dart';
import 'map/map_route_panel.dart';
import 'map/map_search_panel.dart';
import 'map/profile_sheet.dart';
import 'map/route_options_sheet.dart';

enum AccountMode { guest, signedIn }

// The main screen of the app, showing the campus map, user location, and route search UI.
class MapScreen extends StatefulWidget {
  const MapScreen({
    this.accountMode = AccountMode.guest,
    this.onSignOut,
    super.key,
  });

  final AccountMode accountMode;
  final Future<void> Function()? onSignOut;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _initialCenter = LatLng(42.6866, -73.8241);
  static const _fallbackLocation = LatLng(42.686868, -73.825094);
  static const _initialZoom = 16.0;
  static const _minZoom = 3.0;
  static const _maxZoom = 19.0;
  static const _rerouteDistanceThresholdMeters = 10.0;

  final _mapController = MapController();
  final _graphLoader = CampusGraphLoader();
  final _authService = AuthService();
  final _userStore = LocalUserStore();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _fromController = TextEditingController();
  final _fromFocusNode = FocusNode();

  StreamSubscription<Position>? _positionSubscription;

  CampusGraph? _graph;
  CampusRoute? _route;
  CampusPlace? _selectedPlace;
  RoutePreferences _preferences = const RoutePreferences();
  LatLng _currentLocation = _fallbackLocation;
  LatLng? _lastRoutedLocation;
  String? _lastRoutedStartNodeId;
  bool _destinationIsCurrentLocation = false;
  List<CampusPlace> _recentPlaces = const [];
  List<CampusPlace> _favoritePlaces = const [];
  String _profileName = 'Great Dane';
  String? _statusMessage;
  bool _loading = true;
  bool _routing = false;
  bool _signingOut = false;
  bool _usingFallbackLocation = true;
  bool _searchExpanded = false;
  bool _editingStart = false;
  CampusPlace? _customStart;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && !_searchExpanded) {
        setState(() {
          _searchExpanded = true;
          _editingStart = false;
        });
      }
    });
    _fromFocusNode.addListener(() {
      if (_fromFocusNode.hasFocus && !_searchExpanded) {
        setState(() {
          _searchExpanded = true;
          _editingStart = true;
        });
      }
    });
    unawaited(_bootstrap());
  }

  // Clean up resources when the widget is removed
  @override
  void dispose() {
    _positionSubscription?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _fromFocusNode.dispose();
    _fromController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final route = _route;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      body: Stack(
        children: [
          // The map widget
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onTap: (_, _) => _collapseSearch(),
            ),
            children: [
              Container(color: const Color(0xFFF5F1E8)),
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.uanav',
                maxZoom: 19,
                tileProvider: kIsWeb
                    ? NetworkTileProvider()
                    : FMTCTileProvider(
                        stores: const {
                          'osmStore': BrowseStoreStrategy.readUpdateCreate,
                        },
                        loadingStrategy: BrowseLoadingStrategy.cacheFirst,
                      ),
              ),
              if (route != null) CampusRouteLayer(route: route),
              CampusMarkerLayer(
                currentLocation: _currentLocation,
                usingFallbackLocation: _usingFallbackLocation,
                customStart: _customStart,
                route: route,
              ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          // The search panel, route options, and profile button are layered on top of the map
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 14,
            right: 14,
            child: MapSearchPanel(
              route: route,
              searchExpanded: _searchExpanded,
              editingStart: _editingStart,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              fromController: _fromController,
              fromFocusNode: _fromFocusNode,
              suggestions: _visibleSuggestions,
              fromSuggestions: _fromSuggestions,
              favoritePlaces: _favoritePlaces,
              recentPlaces: _recentPlaces,
              startLabel: _startLabel,
              onShowProfile: () => unawaited(_showProfileSheet()),
              onSearchTap: _openDestinationSearch,
              onSearchChanged: _openDestinationSearch,
              onRouteToFirstSuggestion: () =>
                  unawaited(_routeToFirstSuggestion()),
              onClearSearch: _clearSearch,
              onClearRoute: _clearRoute,
              onSwapStartAndDestination: _swapStartAndDestination,
              onFromTap: _openFromSearch,
              onFromChanged: _openFromSearch,
              onFromSubmitted: _fromFocusNode.unfocus,
              onUseCurrentLocationAsStart: _resetStartToCurrentLocation,
              onUseCurrentLocationAsDestination:
                  _setDestinationToCurrentLocation,
              onSelectCustomStart: _selectCustomStart,
              onRouteToPlace: (place) => unawaited(_routeTo(place)),
              onToggleFavorite: (place) => unawaited(_toggleFavorite(place)),
              isFavorite: _isFavorite,
              isRecent: _isRecent,
            ),
          ),
          // The three buttons on the bottom right for zooming and centering on location
          Positioned(
            right: 14,
            bottom: (route == null ? 24 : 190) + bottomPadding,
            child: MapControls(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onCenterLocation: _centerOnLocation,
            ),
          ),
          // The route panel that appears when a route is ready
          if (route != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 18 + bottomPadding,
              child: MapRoutePanel(
                route: route,
                statusMessage: _statusMessage,
                usingFallbackLocation: _usingFallbackLocation,
                routeOptionsLabel: _routeOptionsLabel,
                onRouteOptions: () => unawaited(_showRouteOptionsSheet()),
                onClearRoute: _clearRoute,
              ),
            ),
          if (_loading) const MapLoadingOverlay(),
        ],
      ),
    );
  }

  // Loads the campus graph and user data, then starts location updates.
  Future<void> _bootstrap() async {
    try {
      final graph = await _graphLoader.loadGraph();
      final preferences = await _userStore.loadPreferences();
      final recents = await _userStore.loadRecentPlaces();
      final favorites = await _userStore.loadFavoritePlaces();
      final profileName = widget.accountMode == AccountMode.signedIn
          ? _authService.currentDisplayName()
          : await _userStore.loadProfileName();

      // If this screen no longer exists on screen, don’t update state.
      if (!mounted) {
        return;
      }

      setState(() {
        _graph = graph;
        _preferences = preferences;
        _recentPlaces = recents;
        _favoritePlaces = favorites;
        _profileName = profileName;
        _loading = false;
        _statusMessage = 'Local campus map loaded';
      });

      unawaited(_startLocationUpdates());
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _statusMessage = 'Map data could not be loaded';
      });
    }
  }

  // Shows the route options sheet.
  Future<void> _showRouteOptionsSheet() async {
    await showMapRouteOptionsSheet(
      context: context,
      preferences: _preferences,
      onPreferencesChanged: _updatePreferences,
    );
  }

  // Shows the profile sheet.
  Future<void> _showProfileSheet() async {
    final result = await showMapProfileSheet(
      context: context,
      signedIn: widget.accountMode == AccountMode.signedIn,
      profileName: _profileName,
      accountEmail: widget.accountMode == AccountMode.signedIn
          ? _authService.currentUser?.email
          : null,
      signingOut: _signingOut,
      canSignOut: widget.onSignOut != null,
      favoritePlaces: _favoritePlaces,
      onSaveProfile: (name) async {
        if (widget.accountMode == AccountMode.signedIn) {
          await _authService.updateDisplayName(name);
        } else {
          await _userStore.saveProfileName(name);
        }
      },
    );

    // If this screen no longer exists on screen, or the user dismissed the sheet without saving, do nothing.
    if (!mounted || result == null) {
      return;
    }

    // Handle the different actions that can come from the profile sheet
    switch (result.action) {
      case ProfileSheetAction.signOut:
        await _handleSignOut();
      case ProfileSheetAction.saved:
        final savedName = result.profileName;
        if (savedName == null) {
          return;
        }
        setState(() {
          _profileName = savedName;
          _statusMessage = widget.accountMode == AccountMode.signedIn
              ? 'Account profile saved'
              : 'Profile saved locally';
        });
    }
  }

  // Computes the list of suggestions to show in the search panel based on the current query and user data.
  List<CampusPlace> get _visibleSuggestions {
    final graph = _graph;
    if (graph == null) {
      return const [];
    }

    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      return graph.searchPlaces(query);
    }

    final combined = <CampusPlace>[];
    final seen = <String>{};
    for (final place in [..._favoritePlaces, ..._recentPlaces]) {
      if (seen.add(place.key)) {
        combined.add(place);
      }
    }
    return combined.take(6).toList();
  }

  // Computes the list of suggestions for the "from" field based on the current query.
  List<CampusPlace> get _fromSuggestions {
    final query = _fromController.text.trim();
    if (query.isEmpty) {
      return const [];
    }
    return _graph?.searchPlaces(query) ?? const [];
  }

  String get _startLabel {
    final customStart = _customStart;
    if (customStart != null) {
      return customStart.name;
    }
    return _usingFallbackLocation
        ? 'Main Library fallback'
        : 'Current location';
  }

  // Inform the user how many route options they have enabled when they are not viewing the route options panel.
  String get _routeOptionsLabel {
    final count = _activePreferenceCount;
    return count == 0 ? 'Options' : 'Options · $count on';
  }

  int get _activePreferenceCount {
    var count = 0;

    if (_preferences.avoidStairs) count++;
    if (_preferences.preferIndoors) count++;

    return count;
  }

  // Starts listening for location updates and updates the current location on the map.
  // If location unavailable, falls back to default location.
  Future<void> _startLocationUpdates() async {
    _setLocation(_fallbackLocation, fallback: true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3));
      if (!serviceEnabled) {
        _setStatus('Using campus fallback location');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setStatus('Location permission unavailable; using fallback');
        return;
      }

      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        timeLimit: Duration(seconds: 8),
      );
      // This is where the user's current location is first obtained.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
      _setLocation(_latLngFromPosition(position), fallback: false);

      // Listen for location updates and update the map and route.
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((position) {
            _setLocation(_latLngFromPosition(position), fallback: false);
          });
    } catch (error) {
      _setStatus('Using campus fallback location');
    }
  }

  // Routes to the first suggestion in the search results if there is one.
  Future<void> _routeToFirstSuggestion() async {
    final suggestions = _visibleSuggestions;
    if (suggestions.isEmpty) {
      setState(() {
        _statusMessage = 'No matching destination';
      });
      return;
    }
    await _routeTo(suggestions.first);
  }

  // Routes to the given place
  Future<void> _routeTo(CampusPlace place, {bool persistRecent = true}) async {
    final graph = _graph;
    if (graph == null || _routing) {
      return;
    }

    setState(() {
      _routing = true;
      _statusMessage = 'Calculating route';
    });

    final route = graph.findRoute(
      start: _customStart?.position ?? _currentLocation,
      destination: place,
      preferences: _preferences,
    );

    if (!mounted) {
      return;
    }

    if (route == null) {
      setState(() {
        _routing = false;
        _statusMessage = 'No route found';
      });
      return;
    }

    if (persistRecent) {
      await _userStore.addRecentPlace(place);
      _recentPlaces = await _userStore.loadRecentPlaces();
      if (!mounted) {
        return;
      }
    }

    setState(() {
      _selectedPlace = place;
      _route = route;
      _routing = false;
      _searchController.text = place.name;
      _searchExpanded = false;
      _statusMessage = 'Route ready';
      _lastRoutedLocation = _customStart?.position ?? _currentLocation;
      _lastRoutedStartNodeId = route.startNodeId;
      if (persistRecent) {
        _destinationIsCurrentLocation = false;
      }
    });
    _searchFocusNode.unfocus();

    _fitRoute(route);
  }

  void _selectCustomStart(CampusPlace place) {
    setState(() {
      _customStart = place;
      _fromController.text = place.name;
      _lastRoutedLocation = null;
      _lastRoutedStartNodeId = null;
      _editingStart = false;
      _searchExpanded = false;
    });
    _fromFocusNode.unfocus();
    final dest = _selectedPlace;
    if (dest != null) {
      unawaited(_routeTo(dest, persistRecent: false));
    }
  }

  void _resetStartToCurrentLocation() {
    setState(() {
      _customStart = null;
      _fromController.clear();
      _lastRoutedLocation = null;
      _lastRoutedStartNodeId = null;
      _editingStart = false;
      _searchExpanded = false;
    });
    _fromFocusNode.unfocus();
    final dest = _selectedPlace;
    if (dest != null) {
      unawaited(_routeTo(dest, persistRecent: false));
    } else if (_destinationIsCurrentLocation) {
      _setDestinationToCurrentLocation();
    }
  }

  void _setDestinationToCurrentLocation() {
    final locPlace = CampusPlace(
      name: _usingFallbackLocation
          ? 'Main Library (fallback)'
          : 'Current location',
      latitude: _currentLocation.latitude,
      longitude: _currentLocation.longitude,
    );
    setState(() {
      _selectedPlace = locPlace;
      _destinationIsCurrentLocation = true;
      _searchController.text = locPlace.name;
      _editingStart = false;
      _searchExpanded = false;
    });
    _searchFocusNode.unfocus();
    unawaited(_routeTo(locPlace, persistRecent: false));
  }

  void _swapStartAndDestination() {
    final oldDestination = _selectedPlace;
    if (oldDestination == null) {
      setState(() => _statusMessage = 'Choose a destination');
      return;
    }

    final oldStart = _customStart;
    _searchFocusNode.unfocus();
    _fromFocusNode.unfocus();

    if (_destinationIsCurrentLocation) {
      setState(() {
        _customStart = null;
        _fromController.clear();
        _selectedPlace = oldStart;
        _searchController.text = oldStart?.name ?? '';
        _destinationIsCurrentLocation = false;
        _lastRoutedLocation = null;
        _lastRoutedStartNodeId = null;
        _editingStart = false;
        _searchExpanded = false;
      });

      if (oldStart != null) {
        unawaited(_routeTo(oldStart, persistRecent: false));
      } else {
        setState(() {
          _route = null;
          _statusMessage = 'Choose a destination';
        });
      }
      return;
    }

    if (oldStart != null) {
      setState(() {
        _customStart = oldDestination;
        _fromController.text = oldDestination.name;
        _selectedPlace = oldStart;
        _searchController.text = oldStart.name;
        _destinationIsCurrentLocation = false;
        _lastRoutedLocation = null;
        _lastRoutedStartNodeId = null;
        _editingStart = false;
        _searchExpanded = false;
      });
      unawaited(_routeTo(oldStart, persistRecent: false));
      return;
    }

    setState(() {
      _customStart = oldDestination;
      _fromController.text = oldDestination.name;
      _selectedPlace = null;
      _searchController.clear();
      _destinationIsCurrentLocation = false;
      _lastRoutedLocation = null;
      _lastRoutedStartNodeId = null;
      _editingStart = false;
      _searchExpanded = false;
    });
    _setDestinationToCurrentLocation();
  }

  Future<void> _updatePreferences(RoutePreferences preferences) async {
    setState(() {
      _preferences = preferences;
      _statusMessage = 'Routing preferences updated';
      _lastRoutedLocation = null;
      _lastRoutedStartNodeId = null;
    });
    await _userStore.savePreferences(preferences);

    final place = _selectedPlace;
    if (place != null) {
      unawaited(_routeTo(place, persistRecent: false));
    }
  }

  Future<void> _toggleFavorite(CampusPlace place) async {
    final wasFavorite = _isFavorite(place);
    await _userStore.toggleFavorite(place);
    final favorites = await _userStore.loadFavoritePlaces();
    if (!mounted) {
      return;
    }

    setState(() {
      _favoritePlaces = favorites;
      _statusMessage = wasFavorite ? 'Favorite removed' : 'Favorite saved';
    });
  }

  Future<void> _handleSignOut() async {
    final onSignOut = widget.onSignOut;
    if (onSignOut == null || _signingOut) {
      return;
    }

    setState(() {
      _signingOut = true;
      _statusMessage = widget.accountMode == AccountMode.signedIn
          ? 'Signing out'
          : 'Leaving guest mode';
    });

    try {
      await onSignOut();
    } finally {
      if (mounted) {
        setState(() => _signingOut = false);
      }
    }
  }

  void _setLocation(LatLng location, {required bool fallback}) {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentLocation = location;
      _usingFallbackLocation = fallback;
    });

    if (fallback ||
        _customStart != null ||
        !_shouldRerouteFromLocation(location)) {
      return;
    }

    final place = _selectedPlace;
    if (place != null) {
      unawaited(_routeTo(place, persistRecent: false));
    }
  }

  // Determines whether the app should attempt to recalculate the route based on the user's new location.
  bool _shouldRerouteFromLocation(LatLng location) {
    final graph = _graph;
    if (graph == null || _selectedPlace == null) {
      return false;
    }

    final lastLocation = _lastRoutedLocation;
    if (lastLocation != null &&
        graph.haversineMeters(lastLocation, location) <
            _rerouteDistanceThresholdMeters) {
      return false;
    }

    try {
      final currentStartNodeId = graph.nearestNode(location).id;
      return currentStartNodeId != _lastRoutedStartNodeId;
    } catch (error) {
      // If an error occurs while finding the nearest node, do not reroute.
      return false;
    }
  }

  void _setStatus(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _statusMessage = message);
  }

  void _fitRoute(CampusRoute route) {
    final coordinates = <LatLng>[
      _customStart?.position ?? _currentLocation,
      ...route.points,
      route.destination.position,
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: coordinates,
          padding: const EdgeInsets.fromLTRB(42, 120, 42, 220),
          maxZoom: 18,
        ),
      );
    });
  }

  void _centerOnLocation() {
    _mapController.move(_currentLocation, 17);
  }

  void _collapseSearch() {
    if (!_searchExpanded &&
        !_searchFocusNode.hasFocus &&
        !_fromFocusNode.hasFocus) {
      return;
    }
    _searchFocusNode.unfocus();
    _fromFocusNode.unfocus();
    setState(() => _searchExpanded = false);
  }

  void _openDestinationSearch() {
    setState(() {
      _searchExpanded = true;
      _editingStart = false;
    });
  }

  void _openFromSearch() {
    setState(() {
      _searchExpanded = true;
      _editingStart = true;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchExpanded = true);
    _searchFocusNode.requestFocus();
  }

  void _clearRoute() {
    _searchController.clear();
    _fromController.clear();
    _searchFocusNode.unfocus();
    _fromFocusNode.unfocus();
    setState(() {
      _route = null;
      _selectedPlace = null;
      _customStart = null;
      _destinationIsCurrentLocation = false;
      _lastRoutedLocation = null;
      _lastRoutedStartNodeId = null;
      _editingStart = false;
      _searchExpanded = false;
      _statusMessage = 'Route cleared';
    });
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom < _maxZoom) {
      _mapController.move(_mapController.camera.center, currentZoom + 1);
    }
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom > _minZoom) {
      _mapController.move(_mapController.camera.center, currentZoom - 1);
    }
  }

  bool _isFavorite(CampusPlace place) {
    return _favoritePlaces.any((favorite) => favorite.key == place.key);
  }

  bool _isRecent(CampusPlace place) {
    return _recentPlaces.any((recent) => recent.key == place.key);
  }

  LatLng _latLngFromPosition(Position position) {
    return LatLng(position.latitude, position.longitude);
  }
}
