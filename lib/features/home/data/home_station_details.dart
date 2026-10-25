import '../models/home_discovery.dart';

// Station photos and sample review/response data for the offline demo
// directory (used when the live service-locations API is not connected).
// Real stations from /service-locations fall back to [defaultHomeStationDetails]
// and never show the sample review counts (their hasStatistics is false).
const homeStationDetails = {
  'station-mobile': HomeStationDetails(
    imageAsset: 'assets/images/rescue-team.png',
    area: 'Đa Kao, Q.1',
    reviewCount: 214,
    responseMinutes: 5,
  ),
  'station-tuan': HomeStationDetails(
    imageAsset: 'assets/images/rescue-garage.png',
    area: 'Phường 14, Q.3',
    reviewCount: 128,
    responseMinutes: 10,
  ),
  'station-dealer': HomeStationDetails(
    imageAsset: 'assets/images/rescue-garage.png',
    area: 'Nguyễn Trãi, Q.5',
    reviewCount: 96,
    responseMinutes: 15,
  ),
  'station-thanh': HomeStationDetails(
    imageAsset: 'assets/images/rescue-garage.png',
    area: 'Cách Mạng Tháng Tám',
    reviewCount: 32,
  ),
};

// Default photo for live stations and any station without a sample entry.
const defaultHomeStationDetails = HomeStationDetails(
  imageAsset: 'assets/images/rescue-garage.png',
);
