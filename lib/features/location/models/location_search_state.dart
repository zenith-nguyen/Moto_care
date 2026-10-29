import '../../home/models/rescue_location.dart';
import 'place_suggestion.dart';

class LocationSearchState {
  LocationSearchState({
    required this.source,
    this.query = '',
    this.openingMap = false,
    this.searching = false,
    this.resolving = false,
    this.error,
    List<PlaceSuggestion> suggestions = const [],
  }) : suggestions = List.unmodifiable(suggestions);
  final RescueLocation source;
  final String query;
  final bool openingMap, searching, resolving;
  final String? error;
  final List<PlaceSuggestion> suggestions;
}
