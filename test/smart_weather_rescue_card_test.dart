import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/home/data/demo_home_weather.dart';
import 'package:moto_care/features/home/models/home_rescue_quick_action.dart';
import 'package:moto_care/features/home/services/home_weather_service.dart';
import 'package:moto_care/features/home/widgets/smart_weather_rescue_card.dart';
import 'package:moto_care/features/home/widgets/weather_condition_icon.dart';

void main() {
  Widget card({
    VoidCallback? onSearch,
    ValueChanged<HomeRescueQuickAction>? onAction,
    VoidCallback? onFilter,
    VoidCallback? onRetry,
    bool error = false,
    bool loading = false,
  }) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SmartWeatherRescueCard(
            weather: error || loading
                ? null
                : const WeatherRescueService().evaluate(demoHomeWeather),
            isLoading: loading,
            hasWeatherError: error,
            onSearch: onSearch ?? () {},
            onFilter: onFilter ?? () {},
            onQuickAction: onAction ?? (_) {},
            onRetryWeather: onRetry ?? () {},
          ),
        ),
      ),
    ),
  );

  testWidgets('Weather stays above search with its subtitle left of the icon', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(card());

    final temperature = tester.getRect(find.text('32°'));
    final subtitle = tester.getRect(find.text('Nắng nóng • Dễ nổ lốp'));
    final illustration = tester.getRect(find.byType(WeatherConditionIcon));
    final searchBar = tester.getRect(find.byKey(const ValueKey('home-search')));
    final chips = tester.getRect(
      find.byKey(const ValueKey('weather-quick-actions')),
    );
    expect(subtitle.left, temperature.left);
    expect(subtitle.top, greaterThan(temperature.bottom));
    expect(subtitle.right, lessThan(illustration.left));
    expect(searchBar.top, greaterThan(illustration.bottom));
    expect(chips.top, greaterThan(searchBar.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Search, filter and quick services remain usable when weather fails',
    (tester) async {
      var filters = 0;
      var retries = 0;
      var searches = 0;
      HomeRescueQuickAction? action;
      await tester.pumpWidget(
        card(
          error: true,
          onFilter: () => filters++,
          onRetry: () => retries++,
          onSearch: () => searches++,
          onAction: (value) => action = value,
        ),
      );
      expect(find.byKey(const ValueKey('weather-temperature')), findsNothing);
      expect(find.text('Chưa tải được thời tiết'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('home-search')));
      expect(searches, 1);
      await tester.tap(find.byTooltip('Bộ lọc'));
      await tester.tap(find.byTooltip('Tải lại thời tiết'));
      await tester.tap(find.byKey(const ValueKey('weather-action-battery')));
      expect(searches, 1);
      expect(filters, 1);
      expect(retries, 1);
      expect(action, HomeRescueQuickAction.battery);
    },
  );

  testWidgets('Loading weather does not invent a temperature or risk', (
    tester,
  ) async {
    await tester.pumpWidget(card(loading: true));
    expect(find.byKey(const ValueKey('weather-temperature')), findsNothing);
    expect(find.byKey(const ValueKey('weather-risk-alert')), findsNothing);
    expect(find.byKey(const ValueKey('home-search')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets(
    '320px, larger text and a keyboard retain search, filters and scrollable quick services',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      HomeRescueQuickAction? action;
      await tester.pumpWidget(card(onAction: (value) => action = value));
      await tester.pumpAndSettle();
      expect(find.text('32°'), findsOneWidget);
      expect(
        tester.getBottomRight(find.text('Nắng nóng • Dễ nổ lốp')).dx,
        lessThan(tester.getTopLeft(find.byType(WeatherConditionIcon)).dx),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('home-search')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Bộ lọc').hitTestable(), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('weather-quick-actions')),
        const Offset(-700, 0),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('weather-action-repair')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('weather-action-repair')));
      expect(action, HomeRescueQuickAction.repair);
      expect(tester.takeException(), isNull);
    },
  );
}
