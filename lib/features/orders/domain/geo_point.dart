import '../../../core/network/json_reader.dart';

class GeoPoint {
  const GeoPoint._({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory GeoPoint({required double latitude, required double longitude}) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw const FormatException('Coordinates are out of range.');
    }
    return GeoPoint._(latitude: latitude, longitude: longitude);
  }

  factory GeoPoint.fromGeoJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    if (reader.string('type') != 'Point') {
      throw const FormatException('Only GeoJSON Point is supported.');
    }
    final coordinates = reader.list('coordinates');
    if (coordinates.length != 2 ||
        coordinates[0] is! num ||
        coordinates[1] is! num) {
      throw const FormatException('Invalid GeoJSON coordinates.');
    }
    final longitude = (coordinates[0] as num).toDouble();
    final latitude = (coordinates[1] as num).toDouble();
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw const FormatException('GeoJSON coordinates are out of range.');
    }
    return GeoPoint._(latitude: latitude, longitude: longitude);
  }

  Map<String, double> toRequestJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}
