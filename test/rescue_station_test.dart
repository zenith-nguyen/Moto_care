import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/rescue_station/data/mock_rescue_stations.dart';
import 'package:moto_care/features/rescue_station/models/rescue_station.dart';
import 'package:moto_care/features/rescue_station/providers/rescue_station_provider.dart';

void main() {
  test(
    'Station JSON round trips coordinates, contact, type and opening status',
    () {
      for (final station in mockRescueStations) {
        final json = station.toJson();
        expect(RescueStation.fromJson(json).toJson(), json);
      }
      expect(mockRescueStations[1].toJson()['stationType'], 'official_dealer');
      expect(mockRescueStations[2].toJson()['stationType'], 'mobile_team');
      expect(mockRescueStations.last.isOpen, isFalse);
    },
  );

  test(
    'Invalid station metrics, coordinates and types fail before rendering',
    () {
      final json = mockRescueStations.first.toJson();
      for (final change in [
        {'rating': 6},
        {'distanceKm': -1},
        {'completedRescues': -1},
        {'latitude': 91},
        {'longitude': double.nan},
        {'isOpen': false},
      ]) {
        expect(
          () => RescueStation.fromJson({...json, ...change}),
          throwsArgumentError,
        );
      }
      expect(
        () => RescueStation.fromJson({...json, 'stationType': 'unknown'}),
        throwsFormatException,
      );
    },
  );

  test('Vietnamese search and combined filters work without mutating source stations', () {
    final byName = filterRescueStations(mockRescueStations, query: 'minh tuan');
    expect(byName.single.id, 'station-tuan');
    final byAddress = filterRescueStations(
      mockRescueStations,
      query: 'NGUYEN TRAI',
    );
    expect(byAddress.single.id, 'station-dealer');
    final verified = filterRescueStations(
      mockRescueStations,
      filters: {StationFilter.verified, StationFilter.open24h},
    );
    expect(verified.map((s) => s.id), ['station-tuan', 'station-mobile']);
    expect(
      filterRescueStations(
        mockRescueStations,
        filters: {StationFilter.official, StationFilter.open24h},
      ),
      isEmpty,
    );
    final nearest = filterRescueStations(
      mockRescueStations,
      filters: {StationFilter.nearest},
    );
    expect(nearest.first.id, 'station-mobile');
    expect(nearest.last.id, 'station-thanh');
    expect(mockRescueStations.first.id, 'station-tuan');
    expect(() => nearest.clear(), throwsUnsupportedError);
  });
}
