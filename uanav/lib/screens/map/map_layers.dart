import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/campus_graph.dart';

// Renders different layers on the map
class CampusRouteLayer extends StatelessWidget {
  const CampusRouteLayer({required this.route, super.key});

  final CampusRoute route;

  @override
  Widget build(BuildContext context) {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: route.points,
          strokeWidth: 8,
          color: const Color(ualbanyPurple),
          borderStrokeWidth: 3,
          borderColor: Colors.white,
        ),
        Polyline(
          points: route.points,
          strokeWidth: 4,
          color: const Color(ualbanyGold),
        ),
      ],
    );
  }
}

// Renders the user's current location, destination marker, and custom start marker if there is one.
class CampusMarkerLayer extends StatelessWidget {
  const CampusMarkerLayer({
    required this.currentLocation,
    required this.usingFallbackLocation,
    required this.customStart,
    required this.route,
    super.key,
  });

  final LatLng currentLocation;
  final bool usingFallbackLocation;
  final CampusPlace? customStart;
  final CampusRoute? route;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    if (!usingFallbackLocation) {
      markers.add(
        Marker(
          point: currentLocation,
          width: 46,
          height: 46,
          child: const LocationDot(),
        ),
      );
    }

    final start = customStart;
    if (start != null) {
      markers.add(
        Marker(
          point: start.position,
          width: 20,
          height: 20,
          child: const StartDot(),
        ),
      );
    }

    final activeRoute = route;
    if (activeRoute != null) {
      markers.add(
        Marker(
          point: activeRoute.destination.position,
          width: 46,
          height: 52,
          alignment: Alignment.topCenter,
          child: const Icon(
            Icons.location_pin,
            color: Color(ualbanyPurple),
            size: 46,
          ),
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }
}

// Just loading screen
class MapLoadingOverlay extends StatelessWidget {
  const MapLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.82),
      child: const Center(
        child: CircularProgressIndicator(color: Color(ualbanyPurple)),
      ),
    );
  }
}

// Renders the start marker on the map.
class StartDot extends StatelessWidget {
  const StartDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 2,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(ualbanyPurple), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

// Renders the user's current GPS location.
class LocationDot extends StatelessWidget {
  const LocationDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(ualbanyPurple).withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 0, 132, 255),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
