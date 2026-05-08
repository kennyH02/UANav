import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

const ualbanyPurple = 0xFF46166B;
const ualbanyGold = 0xFFEAAA00;

class CampusNode {
  const CampusNode({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.name,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String type;
  final String? name;

  LatLng get position => LatLng(latitude, longitude);

  //constructor to handle JSON formats for nodes, with some basic validation and normalization
  factory CampusNode.fromJson(Map<String, dynamic> json) {
    return CampusNode(
      id: _readString(json, ['id', 'node_id']),
      latitude: _readDouble(json, [
        'latitue',
        'latitude',
        'lat',
        'node_latitude',
      ]),
      longitude: _readDouble(json, [
        'longitude',
        'lon',
        'lng',
        'node_longitude',
      ]),
      type: _readOptionalString(json, ['type', 'node_type']) ?? 'outdoor',
      name: _readOptionalString(json, ['name', 'node_name']),
    );
  }

  // Convert the CampusNode back to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      if (name != null) 'name': name,
    };
  }
}

class CampusEdge {
  const CampusEdge({
    required this.id,
    required this.source,
    required this.target,
    required this.length,
    required this.type,
    this.name,
  });

  final String id;
  final String source;
  final String target;
  final double length;
  final String type;
  final String? name;

  // Constructor to handle JSON formats for edges, with some basic validation and normalization
  factory CampusEdge.fromJson(Map<String, dynamic> json, int index) {
    final source = _readString(json, ['source', 'edge_source']);
    final target = _readString(json, ['target', 'edge_target']);

    return CampusEdge(
      id:
          _readOptionalString(json, ['id', 'edge_id']) ??
          '${source}_${target}_$index',
      source: source,
      target: target,
      length: _readDouble(json, ['length', 'edge_length']),
      type: _readOptionalString(json, ['type', 'edge_type']) ?? 'walkway',
      name: _readOptionalString(json, ['name', 'edge_name']),
    );
  }

  // Convert the CampusEdge back to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'target': target,
      'length': length,
      'type': type,
      if (name != null) 'name': name,
    };
  }
}

class CampusPlace {
  const CampusPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.nodeId,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? nodeId;

  LatLng get position => LatLng(latitude, longitude);

  // A unique key for this place based on its name and location, used for deduplication
  // Should be O(1) to compute and compare
  String get key =>
      '${name.toLowerCase().trim()}|${latitude.toStringAsFixed(6)}|${longitude.toStringAsFixed(6)}';

  factory CampusPlace.fromJson(Map<String, dynamic> json) {
    return CampusPlace(
      name: _readString(json, ['name', 'node_name']),
      latitude: _readDouble(json, ['lat', 'latitude', 'node_latitude']),
      longitude: _readDouble(json, [
        'lon',
        'lng',
        'longitude',
        'node_longitude',
      ]),
      nodeId: _readOptionalString(json, ['node_id', 'nodeId', 'node id']),
    );
  }

  // Convert the CampusPlace back to JSON format
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lat': latitude,
      'lon': longitude,
      if (nodeId != null) 'node_id': nodeId,
    };
  }
}

// User preferences that can influence route selection
// Note that this is only enabling the UI as of now as we are not calculating weight for routes due to lack of metadata
class RoutePreferences {
  const RoutePreferences({
    this.avoidStairs = false,
    this.preferIndoors = false,
  });

  final bool avoidStairs;
  final bool preferIndoors;

  RoutePreferences copyWith({bool? avoidStairs, bool? preferIndoors}) {
    return RoutePreferences(
      avoidStairs: avoidStairs ?? this.avoidStairs,
      preferIndoors: preferIndoors ?? this.preferIndoors,
    );
  }

  Map<String, dynamic> toJson() {
    return {'avoidStairs': avoidStairs, 'preferIndoors': preferIndoors};
  }

  factory RoutePreferences.fromJson(Map<String, dynamic> json) {
    return RoutePreferences(
      avoidStairs: json['avoidStairs'] == true,
      preferIndoors: json['preferIndoors'] == true,
    );
  }
}

class CampusRoute {
  const CampusRoute({
    required this.destination,
    required this.points,
    required this.distanceMeters,
    required this.estimatedMinutes,
    required this.startNodeId,
    required this.endNodeId,
  });

  final CampusPlace destination;
  final List<LatLng> points;
  final double distanceMeters;
  final int estimatedMinutes;
  final String startNodeId;
  final String endNodeId;
}

// CampusGraph is the in-memory map used for routing.
// If edge.json has A -> B with length 20 and B -> C with length 30, then
// the route A -> B -> C has a display distance of 50 meters.
class CampusGraph {
  CampusGraph._({
    required this.nodesById,
    required this.edges,
    required this.places,
    required this.adjacency,
  });

  final Map<String, CampusNode> nodesById;
  final List<CampusEdge> edges;
  final List<CampusPlace> places;
  final Map<String, List<CampusEdge>> adjacency;

  // Constructor to create a CampusGraph from JSON data
  factory CampusGraph.fromJson({
    required List<dynamic> nodeJson,
    required List<dynamic> edgeJson,
    required List<dynamic> placeJson,
  }) {
    // O(1) lookup for nodes by ID
    final nodes = <String, CampusNode>{};

    for (final value in nodeJson) {
      final node = CampusNode.fromJson(Map<String, dynamic>.from(value as Map));
      nodes[node.id] = node;
    }

    final edges = <CampusEdge>[];

    // adjacency[sourceNodeId] gives every outgoing edge from that node.
    final adjacency = <String, List<CampusEdge>>{
      for (final node in nodes.values) node.id: <CampusEdge>[],
    };

    // For each edge, verify that both source and target nodes exist.
    for (var i = 0; i < edgeJson.length; i++) {
      final edge = CampusEdge.fromJson(
        Map<String, dynamic>.from(edgeJson[i] as Map),
        i,
      );
      // If either node is missing, skip this edge since it can't be used for routing.
      if (!nodes.containsKey(edge.source) || !nodes.containsKey(edge.target)) {
        continue;
      }
      // If so, add to edges list and adjacency map.
      edges.add(edge);
      adjacency.putIfAbsent(edge.source, () => <CampusEdge>[]).add(edge);
    }

    final rawPlaces = <CampusPlace>[];
    for (final value in placeJson) {
      try {
        final place = CampusPlace.fromJson(
          Map<String, dynamic>.from(value as Map),
        );
        if (place.name.trim().isEmpty || place.name.toLowerCase() == 'nan') {
          continue;
        }
        rawPlaces.add(place);
      } catch (error) {
        continue;
      }
    }

    // Create a temporary graph so _cleanPlaces can use nearestNode()
    final graph = CampusGraph._(
      nodesById: nodes,
      edges: edges,
      places: const [],
      adjacency: adjacency,
    );

    final places = graph._cleanPlaces(rawPlaces);

    return CampusGraph._(
      nodesById: nodes,
      edges: edges,
      places: places,
      adjacency: adjacency,
    );
  }

  // From user's search text, find the place that match.
  List<CampusPlace> searchPlaces(String query, {int limit = 10}) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }

    final matches =
        places.where((place) {
          final name = place.name.toLowerCase();
          return name.contains(normalized);
        }).toList()..sort((a, b) {
          final aName = a.name.toLowerCase();
          final bName = b.name.toLowerCase();
          final aStarts = aName.startsWith(normalized);
          final bStarts = bName.startsWith(normalized);
          if (aStarts != bStarts) {
            // Places that start with the query should come first
            return aStarts ? -1 : 1;
          }
          return a.name.compareTo(b.name);
        });

    return matches.take(limit).toList();
  }

  // Find the graph node closest to a GPS point or place coordinate.
  CampusNode nearestNode(LatLng point) {
    CampusNode? nearest;
    var bestDistance = double.infinity;

    for (final node in nodesById.values) {
      final distance = haversineMeters(point, node.position);
      if (distance < bestDistance) {
        nearest = node;
        bestDistance = distance;
      }
    }

    if (nearest == null) {
      throw StateError('Campus graph has no nodes.');
    }

    return nearest;
  }

  // The heuristic function for A*, creates a straight-line distance between the current node and the destination
  // Haversine formula calculate distance between two lat/lng points in meters
  // If we turn heurstic off by returning 0, A* becomes Dijkstra's algorithm
  // It would be cool if we could compare the two, but we don't have much time.
  double haversineMeters(LatLng a, LatLng b) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLon = _toRadians(b.longitude - a.longitude);
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);

    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);

    return 2 * earthRadiusMeters * math.asin(math.sqrt(h));
  }

  // Helper to convert degrees to radians
  double _toRadians(double degrees) => degrees * math.pi / 180;

  // Find the shortest route from start to destination using A* algorithm.
  CampusRoute? findRoute({
    required LatLng start,
    required CampusPlace destination,
    required RoutePreferences preferences,
  }) {
    final startNode = nearestNode(start);
    // Use the linked node_id if available, otherwise fall back to nearest node
    final endNode =
        (destination.nodeId != null &&
            nodesById.containsKey(destination.nodeId))
        ? nodesById[destination.nodeId]!
        : nearestNode(destination.position);

    final openSet = <String>{startNode.id}; // Node IDs to explore
    final cameFrom = <String, String>{};
    // gScore = known walking distance from the start to a node.
    final gScore = <String, double>{startNode.id: 0};
    // fScore = gScore + heuristic, used to decide which node to explore next.
    final fScore = <String, double>{
      startNode.id: haversineMeters(startNode.position, endNode.position),
    };

    while (openSet.isNotEmpty) {
      // Get the node in openSet with the lowest fScore
      final currentId = _lowestScore(openSet, fScore);
      // If we reached the destination, reconstruct the path
      if (currentId == endNode.id) {
        final nodeIds = _reconstructPath(cameFrom, currentId);
        final points = nodeIds
            .map((id) => nodesById[id]?.position)
            .whereType<LatLng>()
            .toList(growable: false);
        final distance = _pathDistance(nodeIds);

        return CampusRoute(
          destination: destination,
          points: points,
          distanceMeters: distance,
          estimatedMinutes: math.max(
            1,
            (distance / 84).ceil(),
          ), // Average walking speed ~5 km/h = 83.3 m/min
          startNodeId: startNode.id,
          endNodeId: endNode.id,
        );
      }
      // Move current from openSet to closedSet because we've now explored it
      openSet.remove(currentId);

      // Explore neighbors
      for (final edge in adjacency[currentId] ?? const <CampusEdge>[]) {
        final source = nodesById[edge.source];
        final target = nodesById[edge.target];
        if (source == null || target == null) {
          continue;
        }

        // Calculate tentative gScore for this neighbor
        final tentativeScore =
            (gScore[currentId] ?? double.infinity) + _weightedEdgeLength(edge);

        // If this path to neighbor is better, record it and update scores
        if (tentativeScore < (gScore[edge.target] ?? double.infinity)) {
          cameFrom[edge.target] = currentId;
          gScore[edge.target] = tentativeScore;
          fScore[edge.target] =
              tentativeScore +
              haversineMeters(target.position, endNode.position);
          openSet.add(edge.target);
        }
      }
    }

    return null;
  }

  List<CampusPlace> _cleanPlaces(List<CampusPlace> rawPlaces) {
    final uniqueNames = <String>{};
    final filtered = <CampusPlace>[];

    for (final place in rawPlaces) {
      final normalizedName = place.name.toLowerCase().trim();
      if (uniqueNames.contains(normalizedName)) {
        continue;
      }

      final hasValidLinkedNode =
          place.nodeId != null && nodesById.containsKey(place.nodeId);
      if (!hasValidLinkedNode) {
        final nearest = nearestNode(place.position);
        final distance = haversineMeters(place.position, nearest.position);

        if (distance > 500) {
          continue;
        }
      }

      uniqueNames.add(normalizedName);
      filtered.add(place);
    }

    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  // Return raw edge length until edge metadata can support route preferences.
  double _weightedEdgeLength(CampusEdge edge) {
    /*
    Re-enable this preference weighting only after edge.json includes meaningful
    edge metadata such as stairs, steps, indoor, or tunnel values. When restoring
    it, pass RoutePreferences into this method again.

    var weight = edge.length;
    final type = edge.type.toLowerCase();
    final name = (edge.name ?? '').toLowerCase();
    final metadata = '$type $name';

    if (preferences.avoidStairs &&
        (metadata.contains('stair') || metadata.contains('steps'))) {
      weight *= 20;
    }

    if (preferences.preferIndoors) {
      if (metadata.contains('indoor') || metadata.contains('tunnel')) {
        weight *= 0.65;
      } else {
        weight *= 1.12;
      }
    }

    return weight;
    */
    return edge.length;
  }

  double _pathDistance(List<String> nodeIds) {
    var total = 0.0;

    for (var i = 0; i < nodeIds.length - 1; i++) {
      final current = nodeIds[i];
      final next = nodeIds[i + 1];
      final edge = adjacency[current]?.firstWhere(
        (candidate) => candidate.target == next,
        orElse: () {
          final source = nodesById[current]!;
          final target = nodesById[next]!;
          return CampusEdge(
            id: '${current}_$next',
            source: current,
            target: next,
            length: haversineMeters(source.position, target.position),
            type: 'walkway',
          );
        },
      );
      total += edge?.length ?? 0;
    }

    return total;
  }

  // Get the node ID in openSet with the lowest fScore, defaulting to infinity
  static String _lowestScore(Set<String> openSet, Map<String, double> fScore) {
    var bestId = openSet.first;
    var bestScore = fScore[bestId] ?? double.infinity;

    for (final id in openSet.skip(1)) {
      final score = fScore[id] ?? double.infinity;
      if (score < bestScore) {
        bestId = id;
        bestScore = score;
      }
    }

    return bestId;
  }

  // Reconstruct the path from start to end by walking backwards through cameFrom
  static List<String> _reconstructPath(
    Map<String, String> cameFrom,
    String currentId,
  ) {
    final totalPath = <String>[currentId];
    var current = currentId;

    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      totalPath.add(current);
    }

    return totalPath.reversed.toList(growable: false);
  }
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  final value = _readOptionalString(json, keys);
  if (value == null || value.isEmpty) {
    throw FormatException('Missing string value for ${keys.join('/')}');
  }
  return value;
}

String? _readOptionalString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return null;
}

double _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  throw FormatException('Missing number value for ${keys.join('/')}');
}
