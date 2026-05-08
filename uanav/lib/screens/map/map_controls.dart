import 'package:flutter/material.dart';

import '../../models/campus_graph.dart';

class MapControls extends StatelessWidget {
  const MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenterLocation,
    super.key,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenterLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MapControlButton(
          icon: Icons.add,
          tooltip: 'Zoom in',
          onPressed: onZoomIn,
        ),
        const SizedBox(height: 8),
        MapControlButton(
          icon: Icons.remove,
          tooltip: 'Zoom out',
          onPressed: onZoomOut,
        ),
        const SizedBox(height: 8),
        MapControlButton(
          icon: Icons.my_location,
          tooltip: 'My location',
          onPressed: onCenterLocation,
        ),
      ],
    );
  }
}

// Reusable circular button used for the zoom in, zoom out, and center location buttons on the map.
class MapControlButton extends StatelessWidget {
  const MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: Colors.white,
      shadowColor: Colors.black26,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon),
        color: const Color(ualbanyPurple),
        disabledColor: Colors.grey,
        onPressed: onPressed,
      ),
    );
  }
}
