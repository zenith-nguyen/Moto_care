const maximumLocationFixAge = Duration(minutes: 2);

bool isRecentLocationFix(DateTime timestamp, DateTime now) {
  final age = now.difference(timestamp);
  return age >= const Duration(seconds: -30) && age <= maximumLocationFixAge;
}

bool isInHoChiMinhCity(double latitude, double longitude) =>
    latitude >= 10.30 &&
    latitude <= 11.25 &&
    longitude >= 106.30 &&
    longitude <= 107.15;
