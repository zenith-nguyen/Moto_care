import '../models/home_discovery.dart';

// Real service-station photos (supplied in the project assets). They are used
// for the offline-demo directory below and spread deterministically across live
// stations so each card shows a distinct, professional-looking building.
const stationPhotoAssets = [
  'assets/images/Tiemsua1.png',
  'assets/images/Tiemsua2.png',
  'assets/images/Tiemsua3.png',
  'assets/images/Tiemsua4.png',
];

// Station photos and sample review/response data for the offline demo
// directory (used when the live service-locations API is not connected).
// Real stations from /service-locations resolve their photo through
// [homeStationDetailsFor] and never show the sample review counts (their
// hasStatistics is false).
const homeStationDetails = {
  'station-mobile': HomeStationDetails(
    imageAsset: 'assets/images/Tiemsua1.png',
    area: 'Đa Kao, Q.1',
    reviewCount: 214,
    responseMinutes: 5,
  ),
  'station-tuan': HomeStationDetails(
    imageAsset: 'assets/images/Tiemsua2.png',
    area: 'Phường 14, Q.3',
    reviewCount: 128,
    responseMinutes: 10,
  ),
  'station-dealer': HomeStationDetails(
    imageAsset: 'assets/images/Tiemsua3.png',
    area: 'Nguyễn Trãi, Q.5',
    reviewCount: 96,
    responseMinutes: 15,
  ),
  'station-thanh': HomeStationDetails(
    imageAsset: 'assets/images/Tiemsua4.png',
    area: 'Cách Mạng Tháng Tám',
    reviewCount: 32,
  ),
};

/// Resolves the display details for a station. A known demo station keeps its
/// curated entry; a live station gets a stable photo chosen from
/// [stationPhotoAssets] by its id, so cards look varied and real instead of all
/// sharing one image.
HomeStationDetails homeStationDetailsFor(
  String stationId,
  Map<String, HomeStationDetails> overrides,
) {
  final override = overrides[stationId];
  if (override != null) return override;
  final index = stationId.hashCode.abs() % stationPhotoAssets.length;
  return HomeStationDetails(imageAsset: stationPhotoAssets[index]);
}
