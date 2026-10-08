import '../models/service_place.dart';

// Demonstration data: distances and opening status are not live location data.
const demoServicePlaces = [
  ServicePlace(
    id: '1',
    name: 'Trạm sạc MotoCare Nguyễn Trãi',
    address: '120 Nguyễn Trãi, TP. Hồ Chí Minh',
    distanceKm: 0.8,
    rating: 4.8,
    isOpen: true,
    isCharging: true,
    is24Hours: true,
    repairsPetrol: false,
  ),
  ServicePlace(
    id: '2',
    name: 'Tiệm sửa xe Minh Tuấn',
    address: '45 Lê Văn Sỹ, TP. Hồ Chí Minh',
    distanceKm: 1.2,
    rating: 4.9,
    isOpen: true,
    isCharging: false,
    is24Hours: true,
    repairsPetrol: true,
  ),
  ServicePlace(
    id: '3',
    name: 'Trạm sạc & Sửa xe An Phát',
    address: '86 Cách Mạng Tháng Tám, TP. Hồ Chí Minh',
    distanceKm: 2.1,
    rating: 4.6,
    isOpen: true,
    isCharging: true,
    is24Hours: false,
    repairsPetrol: true,
  ),
  ServicePlace(
    id: '4',
    name: 'Tiệm sửa xe Thành Công',
    address: '210 Nguyễn Đình Chiểu, TP. Hồ Chí Minh',
    distanceKm: 3.4,
    rating: 4.5,
    isOpen: false,
    isCharging: false,
    is24Hours: false,
    repairsPetrol: true,
  ),
];
