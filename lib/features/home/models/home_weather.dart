import 'package:flutter/foundation.dart';

enum HomeWeatherCondition { sunny, partlyCloudy, cloudy, rainy, stormy }

@immutable
class HomeWeather {
  const HomeWeather({
    required this.temperatureCelsius,
    required this.condition,
    required this.description,
    this.isDemo = false,
  });

  final double temperatureCelsius;
  final HomeWeatherCondition condition;
  final String description;
  final bool isDemo;
}

@immutable
class WeatherRescueSnapshot {
  const WeatherRescueSnapshot({required this.weather, required this.riskAlert});

  final HomeWeather weather;
  final String riskAlert;
}
