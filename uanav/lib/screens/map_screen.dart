import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // UAlbany Uptown Campus center latitude and longitude
  static const _initialCenter = LatLng(42.6866, -73.8241);
  // Zoom levels
  static const _initialZoom = 16.0;
  static const _minZoom = 3.0;
  static const _maxZoom = 19.0;

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
              icon: const Icon(Icons.menu, color: Colors.grey),
              onPressed: () {},
              tooltip: 'Sandwich Menu',
            ),
            const Expanded(
              child: Text(
                'Search UAlbany',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.grey),
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
