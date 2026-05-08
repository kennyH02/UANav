import 'package:flutter/material.dart';
import '../../models/campus_graph.dart';

class MapRoutePanel extends StatelessWidget {
  const MapRoutePanel({
    required this.route,
    required this.statusMessage,
    required this.usingFallbackLocation,
    required this.routeOptionsLabel,
    required this.onRouteOptions,
    required this.onClearRoute,
    super.key,
  });

  final CampusRoute route;
  final String? statusMessage;
  final bool usingFallbackLocation;
  final String routeOptionsLabel;
  final VoidCallback onRouteOptions;
  final VoidCallback onClearRoute;

  // The panel that appears at the bottom of the map when a route is active
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RouteSummary(
              route: route,
              usingFallbackLocation: usingFallbackLocation,
              routeOptionsLabel: routeOptionsLabel,
              onRouteOptions: onRouteOptions,
              onClearRoute: onClearRoute,
            ),
            if (statusMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                statusMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({
    required this.route,
    required this.usingFallbackLocation,
    required this.routeOptionsLabel,
    required this.onRouteOptions,
    required this.onClearRoute,
  });

  final CampusRoute route;
  final bool usingFallbackLocation;
  final String routeOptionsLabel;
  final VoidCallback onRouteOptions;
  final VoidCallback onClearRoute;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(ualbanyGold).withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.route, color: Color(ualbanyPurple)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route.destination.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                '${route.estimatedMinutes} min walk · ${_formatDistance(route.distanceMeters)}',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                usingFallbackLocation
                    ? 'Starting near Main Library'
                    : 'Starting from your GPS location',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.tune, size: 18),
                    label: Text(routeOptionsLabel),
                    side: BorderSide(color: Colors.grey.shade300),
                    onPressed: onRouteOptions,
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Clear route',
          icon: const Icon(Icons.close),
          onPressed: onClearRoute,
        ),
      ],
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }
}
