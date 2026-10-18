import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/home/models/home_weather.dart';
import 'package:moto_care/features/home/models/rescue_location.dart';
import 'package:moto_care/features/home/services/home_weather_service.dart';

import '../../support/recording_json_api.dart';

void main() {
  test('loads live weather for the confirmed customer coordinates', () async {
    final api = RecordingJsonApi()
      ..objectResponse = {
        'source': 'OPEN_METEO',
        'weatherCode': 61,
        'temperatureCelsius': 27.5,
      };
    final weather = await HttpHomeWeatherService(api).fetchWeather(
      const RescueLocation(
        address: 'Quận 5, TP.HCM',
        latitude: 10.757,
        longitude: 106.668,
      ),
    );

    expect(api.lastPath, '/weather/current');
    expect(api.lastQueryParameters, {'latitude': 10.757, 'longitude': 106.668});
    expect(weather.temperatureCelsius, 27.5);
    expect(weather.condition, HomeWeatherCondition.rainy);
    expect(weather.isDemo, isFalse);
  });

  test('does not present a fallback response as live weather', () async {
    final api = RecordingJsonApi()
      ..objectResponse = {
        'source': 'FALLBACK',
        'weatherCode': null,
        'temperatureCelsius': null,
      };

    await expectLater(
      HttpHomeWeatherService(api).fetchWeather(null),
      throwsStateError,
    );
  });
}
