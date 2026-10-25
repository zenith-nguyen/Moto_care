class ServicePlace {
  const ServicePlace({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.rating,
    required this.isOpen,
    required this.isCharging,
    required this.is24Hours,
    required this.repairsPetrol,
    this.phone,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final double distanceKm;
  final double rating;
  final bool isOpen;
  final bool isCharging;
  final bool is24Hours;
  final bool repairsPetrol;
  final String? phone;
  final double? latitude;
  final double? longitude;

  /// True when the place has a usable rating to show (live service locations
  /// have none yet, so the UI hides the stars instead of showing 0).
  bool get hasRating => rating > 0;

  /// True when a real GPS-derived distance is available to show.
  bool get hasDistance => distanceKm > 0;

  bool get hasCoordinates => latitude != null && longitude != null;
}
