import '../models/home_discovery.dart';

// Station photos and sample review/response data for the demo directory.
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

const defaultHomeStationDetails = HomeStationDetails(
  imageAsset: 'assets/images/Tiemsua1.png',
);
