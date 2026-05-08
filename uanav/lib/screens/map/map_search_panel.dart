import 'package:flutter/material.dart';
import '../../models/campus_graph.dart';

class MapSearchPanel extends StatelessWidget {
  const MapSearchPanel({
    required this.route,
    required this.searchExpanded,
    required this.editingStart,
    required this.searchController,
    required this.searchFocusNode,
    required this.fromController,
    required this.fromFocusNode,
    required this.suggestions,
    required this.fromSuggestions,
    required this.favoritePlaces,
    required this.recentPlaces,
    required this.startLabel,
    required this.onShowProfile,
    required this.onSearchTap,
    required this.onSearchChanged,
    required this.onRouteToFirstSuggestion,
    required this.onClearSearch,
    required this.onClearRoute,
    required this.onSwapStartAndDestination,
    required this.onFromTap,
    required this.onFromChanged,
    required this.onFromSubmitted,
    required this.onUseCurrentLocationAsStart,
    required this.onUseCurrentLocationAsDestination,
    required this.onSelectCustomStart,
    required this.onRouteToPlace,
    required this.onToggleFavorite,
    required this.isFavorite,
    required this.isRecent,
    super.key,
  });

  final CampusRoute? route;
  final bool searchExpanded;
  final bool editingStart;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final TextEditingController fromController;
  final FocusNode fromFocusNode;
  final List<CampusPlace> suggestions;
  final List<CampusPlace> fromSuggestions;
  final List<CampusPlace> favoritePlaces;
  final List<CampusPlace> recentPlaces;
  final String startLabel;
  final VoidCallback onShowProfile;
  final VoidCallback onSearchTap;
  final VoidCallback onSearchChanged;
  final VoidCallback onRouteToFirstSuggestion;
  final VoidCallback onClearSearch;
  final VoidCallback onClearRoute;
  final VoidCallback onSwapStartAndDestination;
  final VoidCallback onFromTap;
  final VoidCallback onFromChanged;
  final VoidCallback onFromSubmitted;
  final VoidCallback onUseCurrentLocationAsStart;
  final VoidCallback onUseCurrentLocationAsDestination;
  final ValueChanged<CampusPlace> onSelectCustomStart;
  final ValueChanged<CampusPlace> onRouteToPlace;
  final ValueChanged<CampusPlace> onToggleFavorite;
  final bool Function(CampusPlace place) isFavorite;
  final bool Function(CampusPlace place) isRecent;

  // The main search panel widget
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 7,
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      shadowColor: Colors.black26,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (route == null)
            _DestinationSearchBar(panel: this)
          else
            _RouteSearchHeader(panel: this),
          if (searchExpanded) _SearchDropdown(panel: this),
        ],
      ),
    );
  }

  String placeSubtitle({required bool favorite, required bool recent}) {
    if (favorite && recent) {
      return 'Saved · Recent';
    }
    if (favorite) {
      return 'Saved';
    }
    if (recent) {
      return 'Recent';
    }
    return 'Campus place';
  }
}

// The search bar when no route is active
class _DestinationSearchBar extends StatelessWidget {
  const _DestinationSearchBar({required this.panel});

  final MapSearchPanel panel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: panel.onShowProfile,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(ualbanyPurple),
                shape: BoxShape.circle,
              ),
              child: const Text(
                'UA',
                style: TextStyle(
                  color: Color(ualbanyGold),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DestinationField(panel: panel, hintText: 'Search UAlbany'),
          ),
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            color: const Color(ualbanyPurple),
            onPressed: panel.onRouteToFirstSuggestion,
          ),
          if (panel.searchController.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.close),
              onPressed: panel.onClearSearch,
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// The search panel header when a route is active
// The tiny search bar that had "From" and "To" fields, and the swap button
class _RouteSearchHeader extends StatelessWidget {
  const _RouteSearchHeader({required this.panel});

  final MapSearchPanel panel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Clear route',
            icon: const Icon(Icons.arrow_back),
            color: const Color(ualbanyPurple),
            onPressed: panel.onClearRoute,
          ),
          SizedBox(
            width: 20,
            height: 92,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                const Positioned(
                  top: 18,
                  child: Icon(
                    Icons.radio_button_checked,
                    color: Color(ualbanyPurple),
                    size: 14,
                  ),
                ),
                Positioned(
                  top: 31,
                  bottom: 31,
                  child: Center(
                    child: Container(width: 2, color: Colors.grey[300]),
                  ),
                ),
                const Positioned(
                  bottom: 18,
                  child: Icon(
                    Icons.location_pin,
                    color: Color(ualbanyPurple),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RouteLine(
                  label: 'From',
                  icon: Icons.my_location,
                  child: _FromField(panel: panel, hintText: panel.startLabel),
                ),
                Divider(height: 1, color: Colors.grey[300]),
                _RouteLine(
                  label: 'To',
                  icon: Icons.search,
                  child: _DestinationField(
                    panel: panel,
                    hintText: 'Choose destination',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            height: 100,
            child: Center(
              child: IconButton(
                tooltip: 'Swap start and destination',
                icon: const Icon(Icons.swap_vert),
                color: const Color(ualbanyPurple),
                onPressed: panel.onSwapStartAndDestination,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// That horizontal line with the "From" and "To" fields in the route search header
class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            child: Icon(icon, color: Colors.grey[600], size: 22),
          ),
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// The destination field in the route search header with UI and logic
class _DestinationField extends StatelessWidget {
  const _DestinationField({required this.panel, required this.hintText});

  final MapSearchPanel panel;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: panel.searchFocusNode,
      controller: panel.searchController,
      textInputAction: TextInputAction.search,
      onTap: panel.onSearchTap,
      onChanged: (_) => panel.onSearchChanged(),
      onSubmitted: (_) => panel.onRouteToFirstSuggestion(),
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        hintText: hintText,
      ),
    );
  }
}

// The from field in the route search header with UI and logic
class _FromField extends StatelessWidget {
  const _FromField({required this.panel, required this.hintText});

  final MapSearchPanel panel;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: panel.fromFocusNode,
      controller: panel.fromController,
      textInputAction: TextInputAction.search,
      onTap: panel.onFromTap,
      onChanged: (_) => panel.onFromChanged(),
      onSubmitted: (_) => panel.onFromSubmitted(),
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        hintText: hintText,
      ),
    );
  }
}

// The dropdown that appears when the search bar is expanded,
// showing suggestions, favorites, recents, and the option to use current location
class _SearchDropdown extends StatelessWidget {
  const _SearchDropdown({required this.panel});

  final MapSearchPanel panel;

  @override
  Widget build(BuildContext context) {
    late final Widget dropdownContent;

    final isEditingStart = panel.editingStart;
    final query = isEditingStart
        ? panel.fromController.text.trim()
        : panel.searchController.text.trim();

    if (isEditingStart || query.isNotEmpty) {
      dropdownContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.my_location, color: Color(ualbanyPurple)),
            title: const Text(
              'Use my current location',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            onTap: isEditingStart
                ? panel.onUseCurrentLocationAsStart
                : panel.onUseCurrentLocationAsDestination,
          ),
          if (query.isNotEmpty)
            Flexible(
              child: _PlaceList(
                panel: panel,
                places: isEditingStart
                    ? panel.fromSuggestions
                    : panel.suggestions,
                emptyMessage: isEditingStart
                    ? 'No matching place'
                    : 'No matching destination',
                onTap: isEditingStart ? panel.onSelectCustomStart : null,
              ),
            ),
        ],
      );
    } else {
      // When saved and recent is empty
      dropdownContent = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: true,
              leading: const Icon(
                Icons.my_location,
                color: Color(ualbanyPurple),
              ),
              title: const Text(
                'Use my current location',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: panel.onUseCurrentLocationAsDestination,
            ),
            _PlaceSection(
              panel: panel,
              title: 'Saved',
              icon: Icons.star_border,
              places: panel.favoritePlaces,
              emptyMessage: 'Star places to save them here',
            ),
            const SizedBox(height: 6),
            _PlaceSection(
              panel: panel,
              title: 'Recent',
              icon: Icons.history,
              places: panel.recentPlaces,
              emptyMessage: 'Recent routes will appear here',
            ),
          ],
        ),
      );
    }
    // helper
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: dropdownContent,
    );
  }
}

// A section in the search dropdown for showing up to 4 places due to space constraints.
class _PlaceSection extends StatelessWidget {
  const _PlaceSection({
    required this.panel,
    required this.title,
    required this.icon,
    required this.places,
    required this.emptyMessage,
  });

  final MapSearchPanel panel;
  final String title;
  final IconData icon;
  final List<CampusPlace> places;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 18, 2),
          child: Row(
            children: [
              Icon(icon, size: 14, color: const Color(ualbanyPurple)),
              const SizedBox(width: 6),
              _SectionTitle(title: title),
            ],
          ),
        ),
        if (places.isEmpty)
          ListTile(
            dense: true,
            leading: Icon(icon, color: Colors.grey[350], size: 22),
            title: Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          )
        else
          ...places
              .take(5)
              .map((place) => _PlaceTile(panel: panel, place: place)),
      ],
    );
  }
}

// The title widget for each section in the search dropdown, like "Saved" and "Recent"
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(ualbanyPurple),
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

// The list of places that appears in the search dropdown when there is a query in the search bar or when editing the "From" field. Shows an empty message when there are no results.
class _PlaceList extends StatelessWidget {
  const _PlaceList({
    required this.panel,
    required this.places,
    required this.emptyMessage,
    this.onTap,
  });

  final MapSearchPanel panel;
  final List<CampusPlace> places;
  final String emptyMessage;
  final ValueChanged<CampusPlace>? onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: places.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Text(
                emptyMessage,
                style: TextStyle(color: Colors.grey[700]),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 8),
              shrinkWrap: true,
              itemCount: places.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _PlaceTile(panel: panel, place: places[index], onTap: onTap),
            ),
    );
  }
}

// A tile representing a single place in the search dropdown.
class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.panel, required this.place, this.onTap});

  final MapSearchPanel panel;
  final CampusPlace place;
  final ValueChanged<CampusPlace>? onTap;

  @override
  Widget build(BuildContext context) {
    final favorite = panel.isFavorite(place);
    final recent = panel.isRecent(place);

    return ListTile(
      dense: true,
      leading: Icon(
        recent && !favorite ? Icons.history : Icons.place_outlined,
        color: const Color(ualbanyPurple),
      ),
      title: Text(
        place.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        panel.placeSubtitle(favorite: favorite, recent: recent),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: onTap == null
          ? IconButton(
              tooltip: favorite ? 'Remove favorite' : 'Favorite',
              icon: Icon(favorite ? Icons.star : Icons.star_border),
              color: favorite ? const Color(ualbanyGold) : Colors.grey[600],
              onPressed: () => panel.onToggleFavorite(place),
            )
          : null,
      onTap: () => onTap != null ? onTap!(place) : panel.onRouteToPlace(place),
    );
  }
}
