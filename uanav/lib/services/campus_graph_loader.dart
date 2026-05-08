import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/campus_graph.dart';

class CampusGraphLoader {
  static const _assetNodePath = 'map_data/node.json';
  static const _assetEdgePath = 'map_data/edge.json';
  static const _assetPlacePath = 'map_data/place.json';

  Future<CampusGraph> loadGraph() async {
    final nodeJson = await rootBundle.loadString(_assetNodePath);
    final edgeJson = await rootBundle.loadString(_assetEdgePath);
    final placeJson = await rootBundle.loadString(_assetPlacePath);

    return CampusGraph.fromJson(
      nodeJson: jsonDecode(nodeJson) as List<dynamic>,
      edgeJson: jsonDecode(edgeJson) as List<dynamic>,
      placeJson: jsonDecode(placeJson) as List<dynamic>,
    );
  }
}
