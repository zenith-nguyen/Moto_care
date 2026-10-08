import 'package:flutter/foundation.dart';

@immutable
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.id,
    required this.title,
    required this.address,
  });
  final String id;
  final String title;
  final String address;
}
