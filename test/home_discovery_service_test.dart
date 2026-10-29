import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/activity/models/rescue_order.dart';
import 'package:moto_care/features/home/data/home_station_details.dart';
import 'package:moto_care/features/home/models/home_discovery.dart';
import 'package:moto_care/features/home/models/home_rescue_quick_action.dart';
import 'package:moto_care/features/home/services/home_discovery_service.dart';
import 'package:moto_care/features/rescue_station/data/mock_rescue_stations.dart';

HomeStationListing _listing(
  int index,
  List<RescueServiceType> services, {
  double? distance,
}) {
  final station = mockRescueStations[index];
  return HomeStationListing(
    station: station,
    services: services,
    details: homeStationDetails[station.id]!,
    distanceKm: distance ?? station.distanceKm,
  );
}

void main() {
  const service = HomeDiscoveryService();
  final listings = [
    _listing(0, [RescueServiceType.flatTire]),
    _listing(1, [RescueServiceType.towing]),
    _listing(2, [RescueServiceType.towing, RescueServiceType.flatTire]),
    _listing(3, [RescueServiceType.flatTire]),
  ];
  test('Search recognizes accents, station addresses and service aliases', () {
    expect(
      service
          .filter(listings, const HomeDiscoveryState(query: 'MINH TUAN'))
          .single
          .station
          .id,
      'station-tuan',
    );
    expect(
      service
          .filter(listings, const HomeDiscoveryState(query: 'Nguyễn Trãi'))
          .single
          .station
          .id,
      'station-dealer',
    );
    expect(
      service
          .filter(listings, const HomeDiscoveryState(query: 'va xe'))
          .map((l) => l.station.id),
      ['station-mobile', 'station-tuan', 'station-thanh'],
    );
  });
  test('Service categories use capabilities and tire category requires 24-hour service', () {
    expect(
      service
          .filter(
            listings,
            const HomeDiscoveryState(category: HomeStationCategory.towing),
          )
          .map((l) => l.station.id),
      ['station-mobile', 'station-dealer'],
    );
    expect(
      service
          .filter(
            listings,
            const HomeDiscoveryState(category: HomeStationCategory.tire24h),
          )
          .map((l) => l.station.id),
      ['station-mobile', 'station-tuan'],
    );
  });

  test(
    'Hero hint aliases match only stations offering the requested service',
    () {
      final offers = [
        _listing(0, [RescueServiceType.flatTire]),
        _listing(1, [RescueServiceType.batteryJump]),
        _listing(2, [RescueServiceType.towing]),
      ];
      expect(
        service
            .filter(offers, const HomeDiscoveryState(query: 'Vá lốp'))
            .single
            .station
            .id,
        'station-tuan',
      );
      expect(
        service
            .filter(offers, const HomeDiscoveryState(query: 'het binh'))
            .single
            .station
            .id,
        'station-dealer',
      );
      expect(
        service
            .filter(offers, const HomeDiscoveryState(query: 'thung lop'))
            .single
            .station
            .id,
        'station-tuan',
      );
      expect(
        service
            .filter(offers, const HomeDiscoveryState(query: 'xe keo'))
            .single
            .station
            .id,
        'station-mobile',
      );
    },
  );
  test('Quick actions use actual service capabilities, including on-site engine repair', () {
    final offers = [
      _listing(0, [
        RescueServiceType.batteryJump,
        RescueServiceType.engineFailure,
      ]),
      _listing(1, [RescueServiceType.flatTire]),
      _listing(2, [RescueServiceType.engineFailure]),
    ];
    expect(
      service
          .filter(
            offers,
            const HomeDiscoveryState(
              quickAction: HomeRescueQuickAction.battery,
            ),
          )
          .single
          .station
          .id,
      'station-tuan',
    );
    expect(
      service
          .filter(
            offers,
            const HomeDiscoveryState(quickAction: HomeRescueQuickAction.repair),
          )
          .map((listing) => listing.station.id),
      ['station-mobile', 'station-tuan'],
    );
  });
  test('Fastest, rating and default distance order differ and do not mutate source', () {
    expect(
      service
          .filter(
            listings,
            const HomeDiscoveryState(category: HomeStationCategory.fastest),
          )
          .first
          .station
          .id,
      'station-mobile',
    );
    expect(
      service
          .filter(
            listings,
            const HomeDiscoveryState(category: HomeStationCategory.topRated),
          )
          .first
          .station
          .id,
      'station-tuan',
    );
    final differentDistance = [
      _listing(0, [], distance: .2),
      _listing(2, [], distance: 2),
    ];
    expect(
      service
          .filter(differentDistance, const HomeDiscoveryState())
          .first
          .station
          .id,
      'station-tuan',
    );
    expect(
      service
          .filter(
            differentDistance,
            const HomeDiscoveryState(category: HomeStationCategory.fastest),
          )
          .first
          .station
          .id,
      'station-mobile',
    );
    expect(listings.first.station.id, 'station-tuan');
    expect(
      () => service.filter(listings, const HomeDiscoveryState()).clear(),
      throwsUnsupportedError,
    );
  });
  test('Distance, verification and opening filters intersect and can yield no results', () {
    expect(
      service
          .filter(
            listings,
            const HomeDiscoveryState(
              filters: HomeDiscoveryFilters(
                open24h: true,
                verified: true,
                maxDistanceKm: 1,
              ),
            ),
          )
          .single
          .station
          .id,
      'station-mobile',
    );
    expect(
      service.filter(
        listings,
        const HomeDiscoveryState(
          query: 'An Phát',
          filters: HomeDiscoveryFilters(open24h: true),
        ),
      ),
      isEmpty,
    );
    expect(listings.last.responseLabel, 'Đóng cửa');
  });
}
