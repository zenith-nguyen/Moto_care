import '../../home/models/rescue_location.dart';

typedef IncidentPlace = ({String name, RescueLocation location});

const mockCurrentIncidentLocation = RescueLocation(
  address: '180/9a Bùi Văn Ba, Tân Thuận, Q.7',
);

const mockRecentIncidentPlaces = <IncidentPlace>[
  (name: '180/9a Bùi Văn Ba', location: mockCurrentIncidentLocation),
  (
    name: 'Đại học Kinh tế UEH – Cổng Đào Duy Từ',
    location: RescueLocation(
      address: '36 Đào Duy Từ, Diên Hồng, TP. Hồ Chí Minh',
    ),
  ),
  (
    name: 'Đại học Kinh tế UEH – Cơ sở Võ Thị Sáu',
    location: RescueLocation(
      address: '232/6 Võ Thị Sáu, Xuân Hòa, TP. Hồ Chí Minh',
    ),
  ),
  (
    name: 'Đường Huỳnh Tấn Phát',
    location: RescueLocation(address: '120 Huỳnh Tấn Phát, Tân Thuận, Q.7'),
  ),
];

const mockNearbyIncidentLocations = [
  mockCurrentIncidentLocation,
  RescueLocation(address: '118 Bùi Văn Ba, Tân Thuận, Q.7'),
  RescueLocation(address: '120 Huỳnh Tấn Phát, Tân Thuận, Q.7'),
];

const mockHomeIncidentLocation = RescueLocation(
  address: '45 Lê Văn Sỹ, TP. Hồ Chí Minh',
);
const mockWorkIncidentLocation = RescueLocation(
  address: '273 An Dương Vương, TP. Hồ Chí Minh',
);
