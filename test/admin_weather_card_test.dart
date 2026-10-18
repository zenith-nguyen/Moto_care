import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revo/features/admin/models/admin_models.dart';
import 'package:revo/features/admin/providers/admin_account_provider.dart';
import 'package:revo/features/admin/providers/admin_providers.dart';
import 'package:revo/features/admin/theme/admin_theme.dart';
import 'package:revo/features/admin/widgets/admin_weather_card.dart';
import 'package:revo/features/home/models/home_weather.dart';
import 'package:revo/features/home/models/rescue_location.dart';
import 'package:revo/features/home/providers/home_weather_provider.dart';
import 'package:revo/features/home/services/home_weather_service.dart';
import 'package:revo/features/home/widgets/weather_condition_icon.dart';

class _ForecastService implements HomeWeatherService {
  _ForecastService(this.fetch);

  final Future<HomeWeather> Function() fetch;
  int calls = 0;

  @override
  Future<HomeWeather> fetchWeather(RescueLocation? location) {
    calls++;
    return fetch();
  }
}

Future<ProviderContainer> _open(
  WidgetTester tester, {
  HomeWeatherService? service,
  bool largeText = false,
}) async {
  tester.view.physicalSize = largeText
      ? const Size(320, 568)
      : const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = largeText ? 1.5 : 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminSessionProvider.overrideWith(
          () => AdminSessionController(
            initialSession: const AdminSession(
              id: 'weather-admin',
              name: 'Admin',
              email: 'admin@example.test',
              role: 'ADMIN',
              canManageAdmins: true,
            ),
          ),
        ),
        if (service != null)
          homeWeatherServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        theme: AdminTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: AdminWeatherCard(),
            ),
          ),
        ),
      ),
    ),
  );
  return ProviderScope.containerOf(
    tester.element(find.byType(AdminWeatherCard)),
  );
}

void main() {
  testWidgets(
    'Loading invents no temperature; the shared forecast drives the risk and icon',
    (tester) async {
      final forecast = Completer<HomeWeather>();
      await _open(
        tester,
        service: _ForecastService(() => forecast.future),
        largeText: true,
      );
      expect(
        find.byKey(const ValueKey('admin-weather-temperature')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('admin-weather-risk')), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Áp dụng phụ phí x1.2'), findsOneWidget);

      forecast.complete(
        const HomeWeather(
          temperatureCelsius: 26,
          condition: HomeWeatherCondition.rainy,
          description: 'Trời mưa',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('26°'), findsOneWidget);
      expect(find.text('Trời mưa · Đường trơn, dễ ngập nước'), findsOneWidget);
      expect(
        tester
            .widget<WeatherConditionIcon>(find.byType(WeatherConditionIcon))
            .condition,
        HomeWeatherCondition.rainy,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('A failed forecast keeps the factor visible and can be retried', (
    tester,
  ) async {
    var attempts = 0;
    final service = _ForecastService(() async {
      if (attempts++ == 0) throw StateError('Offline');
      return const HomeWeather(
        temperatureCelsius: 32,
        condition: HomeWeatherCondition.partlyCloudy,
        description: 'Ít mây',
      );
    });
    await _open(tester, service: service);
    await tester.pumpAndSettle();
    expect(find.text('Chưa tải được thời tiết'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('admin-weather-temperature')),
      findsNothing,
    );
    expect(find.text('Áp dụng phụ phí x1.2'), findsOneWidget);
    await tester.tap(find.byTooltip('Tải lại thời tiết'));
    await tester.pumpAndSettle();
    expect(find.text('32°'), findsOneWidget);
    expect(service.calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'The factor badge follows saved settings without rounding away precision',
    (tester) async {
      final container = await _open(tester);
      await tester.pumpAndSettle();
      expect(find.text('Áp dụng phụ phí x1.2'), findsOneWidget);
      final controller = container.read(adminAccountProvider.notifier);
      var saved = controller.updateSettings(
        container
            .read(adminAccountProvider)
            .settings
            .copyWith(weatherFactor: 1),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await saved;
      await tester.pumpAndSettle();
      expect(find.text('Hệ số giá: x1.0 (Bình thường)'), findsOneWidget);
      saved = controller.updateSettings(
        container
            .read(adminAccountProvider)
            .settings
            .copyWith(weatherFactor: 1.35),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await saved;
      await tester.pumpAndSettle();
      expect(find.text('Áp dụng phụ phí x1.35'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
