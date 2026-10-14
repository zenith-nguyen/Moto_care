import '../data/demo_home_weather.dart';
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
