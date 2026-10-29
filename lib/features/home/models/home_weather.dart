import 'package:flutter/foundation.dart';

enum HomeWeatherCondition { sunny, partlyCloudy, cloudy, rainy, stormy }

@immutable
class HomeWeather {
  const HomeWeather({
    required this.temperatureCelsius,
    required this.condition,
    required this.description,
    this.isDemo = false,
    this.isNight = false,
  });

  final double temperatureCelsius;
  final HomeWeatherCondition condition;
  final String description;
  final bool isDemo;

  /// True when the observation is at night (Open-Meteo `is_day == 0`), so the
  /// sun illustration is swapped for a moon.
  final bool isNight;
}

@immutable
class WeatherRescueSnapshot {
  const WeatherRescueSnapshot({required this.weather, required this.riskAlert});

  final HomeWeather weather;
  final String riskAlert;
}
