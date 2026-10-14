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
}
