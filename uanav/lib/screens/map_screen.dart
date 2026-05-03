import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/auth_service.dart';
import '../services/local_user_store.dart';

enum AccountMode { guest, signedIn }

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
  static const _purple = Color(0xFF46166B);
  static const _gold = Color(0xFFEAAA00);

  final MapController _mapController = MapController();
  final _authService = AuthService();
  final _userStore = LocalUserStore();

  // UAlbany Uptown Campus center latitude and longitude
  static const _initialCenter = LatLng(42.6866, -73.8241);
  // Zoom levels
  static const _initialZoom = 16.0;
  static const _minZoom = 3.0;
  static const _maxZoom = 19.0;

  String _profileName = AuthService.defaultDisplayName;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountMode == widget.accountMode) {
      return;
    }
    if (widget.accountMode == AccountMode.guest) {
      setState(() => _profileName = AuthService.defaultDisplayName);
      return;
    }
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    if (widget.accountMode == AccountMode.guest) {
      if (!mounted) return;
      setState(() => _profileName = AuthService.defaultDisplayName);
      return;
    }

    final name = await _userStore.loadProfileName();
    if (!mounted || widget.accountMode == AccountMode.guest) return;
    setState(() => _profileName = name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- Map ---
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
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.uanav',
                maxZoom: 19,
              ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // --- Floating Search Bar ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),

          // --- Zoom & Layer Controls (bottom-right) ---
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildControlButton(
                  icon: Icons.add,
                  onPressed: _zoomIn,
                  tooltip: 'Zoom in',
                ),
                const SizedBox(height: 8),
                _buildControlButton(
                  icon: Icons.remove,
                  onPressed: _zoomOut,
                  tooltip: 'Zoom out',
                ),
                const SizedBox(height: 16),
                _buildControlButton(
                  icon: Icons.my_location,
                  onPressed: _resetView,
                  tooltip: 'Reset to campus',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Search bar widget (Top) ----
  Widget _buildSearchBar() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(28),
      shadowColor: Colors.black26,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: _showProfileSheet,
              tooltip: 'Menu',
            ),
            const Expanded(
              child: Text(
                'Search UAlbany',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              // Note from Kenny: Implement search functionality
              onPressed: () {},
              tooltip: 'Search Icon',
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  // ---- Profile / account bottom sheet ----
  Future<void> _showProfileSheet() async {
    final isGuest = widget.accountMode == AccountMode.guest;
    final nameController = TextEditingController(
      text: isGuest ? AuthService.defaultDisplayName : _profileName,
    );

    // https://api.flutter.dev/flutter/material/showModalBottomSheet.html
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'UA',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'UANav',
                        style: TextStyle(
                          color: _purple,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        widget.accountMode == AccountMode.signedIn
                            ? (_authService.currentUser?.email ?? 'Signed in')
                            : 'Guest',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Profile name field
              TextField(
                controller: nameController,
                readOnly: isGuest,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
              ),
              if (!isGuest) ...[
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    await _userStore.saveProfileName(newName);
                    if (!context.mounted) return;
                    setState(() {
                      _profileName = newName.isEmpty
                          ? AuthService.defaultDisplayName
                          : newName;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
              if (widget.onSignOut != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _purple,
                    side: const BorderSide(color: _purple),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await widget.onSignOut!();
                  },
                  child: Text(
                    widget.accountMode == AccountMode.signedIn
                        ? 'Sign out'
                        : 'Back to login',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );

    nameController.dispose();
  }

  // ---- Circular control button (Bottom right)----
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Material(
      elevation: 3,
      shape: const CircleBorder(),
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: Colors.grey[700], size: 22),
          ),
        ),
      ),
    );
  }

  // ---- Map actions ----
  // Sets current zoom to 1 level higher, up to max zoom
  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom < _maxZoom) {
      _mapController.move(_mapController.camera.center, currentZoom + 1);
    }
  }

  // Sets current zoom to 1 level lower, down to min zoom
  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom > _minZoom) {
      _mapController.move(_mapController.camera.center, currentZoom - 1);
    }
  }

  // Resets the map view to the initial center and zoom level (UAlbany campus)
  void _resetView() {
    _mapController.move(_initialCenter, _initialZoom);
  }
}
