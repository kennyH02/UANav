import 'package:flutter/material.dart';

import '../../models/campus_graph.dart';

// The option button on the bottom of the map screen widget
Future<void> showMapRouteOptionsSheet({
  required BuildContext context,
  required RoutePreferences preferences,
  required Future<void> Function(RoutePreferences preferences)
  onPreferencesChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      var sheetPreferences = preferences;

      return SafeArea(
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> update(RoutePreferences preferences) async {
              setSheetState(() => sheetPreferences = preferences);
              await onPreferencesChanged(preferences);
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Route Options',
                    style: TextStyle(
                      color: Color(ualbanyPurple),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'These preferences recalculate the active route.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Avoid stairs'),
                    secondary: const Icon(
                      Icons.stairs,
                      color: Color(ualbanyPurple),
                    ),
                    value: sheetPreferences.avoidStairs,
                    onChanged: (value) =>
                        update(sheetPreferences.copyWith(avoidStairs: value)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Prefer indoors'),
                    secondary: const Icon(
                      Icons.meeting_room,
                      color: Color(ualbanyPurple),
                    ),
                    value: sheetPreferences.preferIndoors,
                    onChanged: (value) =>
                        update(sheetPreferences.copyWith(preferIndoors: value)),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
