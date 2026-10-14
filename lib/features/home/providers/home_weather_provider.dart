import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/home_weather.dart';
import '../services/home_weather_service.dart';
import 'home_provider.dart';

final homeWeatherServiceProvider = Provider<HomeWeatherService>(
  (ref) => const MockHomeWeatherService(),
);

final weatherRescueServiceProvider = Provider<WeatherRescueService>(
  (ref) => const WeatherRescueService(),
);

final homeWeatherProvider = FutureProvider.autoDispose<WeatherRescueSnapshot>((
  ref,
) async {
  final service = ref.watch(homeWeatherServiceProvider);
  final location = ref.watch(rescueLocationProvider);
  final evaluator = ref.watch(weatherRescueServiceProvider);
  return evaluator.evaluate(await service.fetchWeather(location));
});
