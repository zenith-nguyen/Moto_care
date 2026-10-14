import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/home/data/demo_home_weather.dart';
import 'package:moto_care/features/home/models/home_weather.dart';
import 'package:moto_care/features/home/models/rescue_location.dart';
import 'package:moto_care/features/home/providers/home_provider.dart';
import 'package:moto_care/features/home/providers/home_weather_provider.dart';
import 'package:moto_care/features/home/services/home_weather_service.dart';

class _WeatherService implements HomeWeatherService {
  final requests = <(RescueLocation?, Completer<HomeWeather>)>[];
  @override
  Future<HomeWeather> fetchWeather(RescueLocation? location) {
    final result = Completer<HomeWeather>();
    requests.add((location, result));
    return result.future;
  }
}

void main() {
  const evaluator = WeatherRescueService();
  test(
    'The default service identifies its 32-degree weather as demo data',
    () async {
      final weather = await const MockHomeWeatherService().fetchWeather(null);
      expect(weather.isDemo, isTrue);
      expect(weather.temperatureCelsius, 32);
      expect(evaluator.evaluate(weather).riskAlert, 'Nắng nóng • Dễ nổ lốp');
    },
  );

  test('Rain and storm alerts take precedence over heat; mild weather has no heat warning', () {
    for (final condition in [
      HomeWeatherCondition.rainy,
      HomeWeatherCondition.stormy,
    ]) {
      final risk = evaluator
          .evaluate(
            HomeWeather(
              temperatureCelsius: 35,
              condition: condition,
              description: 'Mưa',
            ),
          )
          .riskAlert;
      expect(risk, contains('ngập nước'));
      expect(risk, isNot(contains('Nắng nóng')));
    }
    expect(
      evaluator
          .evaluate(
            const HomeWeather(
              temperatureCelsius: 26,
              condition: HomeWeatherCondition.cloudy,
              description: 'Nhiều mây',
            ),
          )
          .riskAlert,
      isNot(contains('Nắng nóng')),
    );
  });

  test('A confirmed location refreshes weather and old responses cannot replace it', () async {
    final service = _WeatherService();
    final container = ProviderContainer(
      overrides: [homeWeatherServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    container.listen(homeWeatherProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(service.requests.single.$1, isNull);
    const location = RescueLocation(
      address: '273 An Dương Vương, Quận 5',
      latitude: 10.757,
      longitude: 106.668,
    );
    container.read(rescueLocationProvider.notifier).confirmLocation(location);
    await Future<void>.delayed(Duration.zero);
    expect(service.requests.last.$1!.latitude, location.latitude);
    const rainy = HomeWeather(
      temperatureCelsius: 27,
      condition: HomeWeatherCondition.rainy,
      description: 'Mưa',
    );
    service.requests.last.$2.complete(rainy);
    await container.read(homeWeatherProvider.future);
    service.requests.first.$2.complete(demoHomeWeather);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(homeWeatherProvider).asData!.value.weather,
      same(rainy),
    );
  });

  test('Weather failures are exposed and invalidation can retry', () async {
    final service = _WeatherService();
    final container = ProviderContainer(
      overrides: [homeWeatherServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    container.listen(homeWeatherProvider, (_, _) {});
    final result = container.read(homeWeatherProvider.future);
    final failure = expectLater(result, throwsStateError);
    service.requests.single.$2.completeError(StateError('Weather unavailable'));
    await failure;
    expect(container.read(homeWeatherProvider).hasError, isTrue);
    container.invalidate(homeWeatherProvider);
    final retry = container.read(homeWeatherProvider.future);
    service.requests.last.$2.complete(demoHomeWeather);
    expect((await retry).weather, same(demoHomeWeather));
  });
}
