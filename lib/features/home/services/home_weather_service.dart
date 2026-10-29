import '../data/demo_home_weather.dart';
import '../../../core/network/json_api.dart';
import '../models/home_weather.dart';
import '../models/rescue_location.dart';

/// Implement with the approved HTTP client when a weather API is connected.
/// Only request local weather when the confirmed location has coordinates.
abstract interface class HomeWeatherService {
  Future<HomeWeather> fetchWeather(RescueLocation? location);
}

class MockHomeWeatherService implements HomeWeatherService {
  const MockHomeWeatherService({this.weather = demoHomeWeather});

  final HomeWeather weather;

  @override
  Future<HomeWeather> fetchWeather(RescueLocation? location) async => weather;
}

class HttpHomeWeatherService implements HomeWeatherService {
  const HttpHomeWeatherService(this._api);

  final JsonApi _api;

  @override
  Future<HomeWeather> fetchWeather(RescueLocation? location) async {
    final json = await _api.getObject(
      '/weather/current',
      queryParameters: {
        // Before the customer confirms a GPS point, show real city-centre
        // weather rather than fabricated demo data.
        'latitude': location?.latitude ?? 10.7769,
        'longitude': location?.longitude ?? 106.7009,
      },
    );
    final temperature = (json['temperatureCelsius'] as num?)?.toDouble();
    final code = (json['weatherCode'] as num?)?.toInt();
    if (json['source'] != 'OPEN_METEO' || temperature == null || code == null) {
      throw StateError('Live weather is currently unavailable');
    }
    final isDay = json['isDay'];
    return HomeWeather(
      temperatureCelsius: temperature,
      condition: _condition(code),
      description: _description(code),
      isNight: isDay == false || isDay == 0,
    );
  }

  HomeWeatherCondition _condition(int code) {
    if ({95, 96, 99}.contains(code)) return HomeWeatherCondition.stormy;
    if ((code >= 51 && code <= 82) || (code >= 85 && code <= 86)) {
      return HomeWeatherCondition.rainy;
    }
    if (code == 0) return HomeWeatherCondition.sunny;
    if (code <= 2) return HomeWeatherCondition.partlyCloudy;
    return HomeWeatherCondition.cloudy;
  }

  String _description(int code) => switch (_condition(code)) {
    HomeWeatherCondition.sunny => 'Trời quang',
    HomeWeatherCondition.partlyCloudy => 'Ít mây',
    HomeWeatherCondition.cloudy => 'Nhiều mây hoặc sương mù',
    HomeWeatherCondition.rainy => 'Có mưa',
    HomeWeatherCondition.stormy => 'Có giông',
  };
}

class WeatherRescueService {
  const WeatherRescueService();

  WeatherRescueSnapshot evaluate(HomeWeather weather) {
    final risk = switch (weather.condition) {
      HomeWeatherCondition.stormy => 'Mưa giông • Đường trơn, dễ ngập nước',
      HomeWeatherCondition.rainy => 'Trời mưa • Đường trơn, dễ ngập nước',
      _ when weather.temperatureCelsius >= 32 => 'Nắng nóng • Dễ nổ lốp',
      _ => 'Di chuyển an toàn • Kiểm tra xe',
    };
    return WeatherRescueSnapshot(weather: weather, riskAlert: risk);
  }
}
