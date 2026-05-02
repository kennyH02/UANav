import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:uanav/models/campus_graph.dart';

void main() {
  test('A* routes through the lowest-cost campus edges', () {
    final graph = CampusGraph.fromJson(
      nodeJson: const [
        {'id': 'A', 'latitue': 42.6860, 'longitude': -73.8240},
        {'id': 'B', 'latitue': 42.6861, 'longitude': -73.8240},
        {'id': 'D', 'latitue': 42.6862, 'longitude': -73.8240},
      ],
      edgeJson: const [
        {'source': 'A', 'target': 'B', 'length': 10.0},
        {'source': 'B', 'target': 'D', 'length': 10.0},
        {'source': 'A', 'target': 'D', 'length': 100.0},
      ],
      placeJson: const [
        {'name': 'Destination Hall', 'lat': 42.6862, 'lon': -73.8240},
      ],
    );

    final route = graph.findRoute(
      start: const LatLng(42.6860, -73.8240),
      destination: graph.places.single,
      preferences: const RoutePreferences(),
    );

    expect(route, isNotNull);
    expect(route!.distanceMeters, 20);
    expect(route.points, hasLength(3));
    expect(route.estimatedMinutes, 1);
  });
}
