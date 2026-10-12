import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/home/models/home_destination.dart';
import 'package:moto_care/features/home/models/home_user.dart';
import 'package:moto_care/features/home/providers/home_discovery_provider.dart';
import 'package:moto_care/features/home/providers/home_provider.dart';
import 'package:moto_care/features/home/screens/home_screen.dart';
import 'package:moto_care/features/home/screens/trang_chu.dart';
import 'package:moto_care/features/home/widgets/home_bottom_navigation.dart';
import 'package:moto_care/features/home/widgets/home_station_grid_card.dart';
import 'package:moto_care/features/home/widgets/revo_home_header.dart';
import 'package:moto_care/features/home/widgets/smart_weather_rescue_card.dart';
import 'package:moto_care/features/home/models/home_rescue_quick_action.dart';
import 'package:moto_care/features/partner/screens/partner_list_screen.dart';
import 'package:moto_care/features/partner/screens/partner_detail_screen.dart';
import 'package:moto_care/features/rescue_station/widgets/rescue_station_mock_map.dart';

import 'fixtures/marketplace_router_fixture.dart';
import 'fixtures/home_scroll_helpers.dart';

const _user = HomeUser(displayName: 'Nguyễn Văn An', memberId: '15335206');

Future<void> _openHome(
  WidgetTester tester, {
  HomeUser? user = _user,
  ValueChanged<HomeDestination>? onSelected,
}) async {
  final router = marketplaceTestRouter(
    TrangChu(user: user, onDestinationSelected: onSelected),
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

ProviderContainer _state(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
Finder get _search => find.byKey(const ValueKey('home-search'));

void main() {
  testWidgets('Home uses two-column station cards and a monochrome surface', (
    tester,
  ) async {
    await _openHome(tester);
    expect(find.byType(PageView), findsNothing);
    expect(find.byType(SmartWeatherRescueCard), findsOneWidget);
    expect(find.text('32°'), findsOneWidget);
    await scrollHomeToStations(tester);
    final cards = find.byType(HomeStationGridCard);
    expect(cards, findsAtLeastNWidgets(2));
    expect(find.text('4 trạm'), findsOneWidget);
    expect(
      tester.getTopLeft(cards.at(0)).dy,
      tester.getTopLeft(cards.at(1)).dy,
    );
    expect(
      tester.getTopLeft(cards.at(0)).dx,
      lessThan(tester.getTopLeft(cards.at(1)).dx),
    );
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.white,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home route receives account data without membership or offers', (
    tester,
  ) async {
    await _openHome(
      tester,
      user: const HomeUser(
        displayName: 'Nguyễn Văn An',
        memberId: '15335206',
        membershipLabel: 'Thành viên Vàng',
        rewardPoints: 350,
      ),
    );
    expect(find.byType(TrangChu), findsOneWidget);
    expect(find.byTooltip('Tài khoản Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Thành viên Vàng'), findsNothing);
    expect(find.text('MotoCare Club'), findsNothing);
    expect(find.text('350 xu'), findsNothing);
  });

  testWidgets(
    'Default browsing area does not invent a confirmed GPS location',
    (tester) async {
      await _openHome(tester, user: null);
      expect(find.text('Quận 1, TP.HCM'), findsOneWidget);
      expect(_state(tester).read(rescueLocationProvider), isNull);
      expect(find.byTooltip('Tài khoản của bạn'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('home-services')));
      expect(find.text('Chọn xe cần cứu hộ'), findsOneWidget);
    },
  );

  testWidgets(
    'Search finds Vietnamese names and services and reset restores results',
    (tester) async {
      await _openHome(tester);
      expect(find.byTooltip('Mở menu'), findsNothing);
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).endDrawer, isNull);
      await tester.enterText(_search, 'MINH TUAN');
      await tester.pumpAndSettle();
      await scrollHomeToStations(tester);
      expect(find.byType(HomeStationGridCard), findsOneWidget);
      expect(find.text('Cứu hộ Minh Tuấn'), findsOneWidget);
      await scrollHomeToSearch(tester);
      await tester.enterText(_search, 'khong co tram nay');
      await tester.pumpAndSettle();
      await scrollHomeToStations(tester);
      expect(find.text('Không tìm thấy trạm phù hợp'), findsOneWidget);
      await _tap(tester, find.text('Xóa tìm kiếm và bộ lọc'));
      expect(find.byType(HomeStationGridCard), findsNWidgets(4));
      expect(_state(tester).read(homeDiscoveryProvider).query, isEmpty);
    },
  );

  testWidgets('Floating bar has four requested tabs and keeps home active', (
    tester,
  ) async {
    final selections = <HomeDestination>[];
    await _openHome(tester, onSelected: selections.add);
    final nav = find.byType(HomeBottomNavigation);
    expect(HomeDestination.homeNavigationItems, [
      HomeDestination.home,
      HomeDestination.rescueStations,
      HomeDestination.activity,
      HomeDestination.account,
    ]);
    expect(find.text('Kho ưu đãi'), findsNothing);
    for (final destination in HomeDestination.homeNavigationItems) {
      await _tap(
        tester,
        find.descendant(
          of: nav,
          matching: find.text(destination.navigationLabel),
        ),
      );
    }
    expect(selections, [
      HomeDestination.rescueStations,
      HomeDestination.activity,
      HomeDestination.account,
    ]);
  });

  testWidgets(
    'Charging remains available through the emergency service sheet',
    (tester) async {
      await _openHome(tester);
      expect(find.text('Mẹo hay & Ưu đãi hôm nay ›'), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('home-services')));
      await _tap(tester, find.byKey(const ValueKey('home-service-charging')));
      expect(find.byType(PartnerListScreen), findsOneWidget);
      expect(find.text('Trạm sạc gần nhất'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Service action opens rescue services without placing an order', (
    tester,
  ) async {
    await _openHome(tester);
    await _tap(tester, find.byKey(const ValueKey('home-services')));
    expect(find.text('Cứu hộ khẩn cấp'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-service-tire')), findsOneWidget);
    expect(find.byType(PartnerDetailScreen), findsNothing);
  });

  testWidgets('Header account avatar forwards the account destination', (
    tester,
  ) async {
    final selections = <HomeDestination>[];
    await _openHome(tester, onSelected: selections.add);
    await _tap(tester, find.byKey(const ValueKey('home-avatar')));
    expect(selections, [HomeDestination.account]);
    expect(find.byKey(const ValueKey('home-avatar')), findsOneWidget);
  });

  testWidgets(
    'Blank avatar, My Location and notifications share the header above weather',
    (tester) async {
      tester.view.padding = FakeViewPadding(
        top: 24 * tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.resetPadding);
      await _openHome(tester);
      expect(
        find.descendant(
          of: find.byType(RevoHomeHeader),
          matching: find.byIcon(Icons.star_rounded),
        ),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('home-avatar')), findsOneWidget);
      expect(find.byTooltip('Thông báo'), findsOneWidget);
      final location = tester.getRect(
        find.byKey(const ValueKey('home-location')),
      );
      final notifications = tester.getRect(find.byTooltip('Thông báo'));
      final avatar = tester.getRect(find.byKey(const ValueKey('home-avatar')));
      final header = tester.getRect(find.byType(RevoHomeHeader));
      final hero = tester.getRect(find.byType(SmartWeatherRescueCard));
      expect(header.top, greaterThanOrEqualTo(36));
      expect(location.center.dy, notifications.center.dy);
      expect(avatar.center.dy, notifications.center.dy);
      expect(avatar.right, lessThan(location.left));
      expect(location.right, lessThan(notifications.left));
      expect(header.bottom, lessThan(hero.top));
      expect(find.text('My Location'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('home-avatar')),
          matching: find.byType(Image),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('home-avatar')),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('home-menu')), findsNothing);
      expect(
        find.descendant(
          of: find.byType(SmartWeatherRescueCard),
          matching: find.byKey(const ValueKey('home-avatar')),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Quick service chips fill search, filter capabilities and reset',
    (tester) async {
      await _openHome(tester);
      final container = _state(tester);
      await _tap(tester, find.byKey(const ValueKey('weather-action-battery')));
      expect(tester.widget<TextField>(_search).controller!.text, 'Kích bình');
      expect(
        container.read(homeDiscoveryProvider).quickAction,
        HomeRescueQuickAction.battery,
      );
      final stations = container.read(homeDiscoveryStationsProvider);
      expect(stations, isNotEmpty);
      expect(
        stations.every(
          (listing) => listing.services.contains(
            HomeRescueQuickAction.battery.serviceType,
          ),
        ),
        isTrue,
      );
      await tester.enterText(_search, 'MINH TUAN');
      await tester.pumpAndSettle();
      expect(
        container.read(homeDiscoveryProvider).quickAction,
        HomeRescueQuickAction.all,
      );
      await _tap(tester, find.byKey(const ValueKey('weather-action-all')));
      expect(tester.widget<TextField>(_search).controller!.text, isEmpty);
      expect(container.read(homeDiscoveryStationsProvider), hasLength(4));
    },
  );

  testWidgets(
    'Filters are applied together and dismissing a draft preserves results',
    (tester) async {
      await _openHome(tester);
      await _tap(tester, find.byTooltip('Bộ lọc'));
      await _tap(tester, find.byKey(const ValueKey('home-filter-open24h')));
      await _tap(tester, find.byTooltip('Đóng'));
      expect(find.byType(HomeStationGridCard), findsNWidgets(4));
      await _tap(tester, find.byTooltip('Bộ lọc'));
      await _tap(tester, find.byKey(const ValueKey('home-filter-open24h')));
      await _tap(tester, find.byKey(const ValueKey('home-filter-verified')));
      await _tap(tester, find.text('Áp dụng bộ lọc'));
      expect(find.byType(HomeStationGridCard), findsNWidgets(2));
      expect(_state(tester).read(homeDiscoveryProvider).filters.activeCount, 2);
      expect(find.text('Đóng cửa'), findsNothing);
    },
  );

  testWidgets('Map tab opens the map and returning preserves the home search', (
    tester,
  ) async {
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    router.go('/trang-chu', extra: _user);
    await tester.pumpAndSettle();
    await tester.enterText(_search, 'revo');
    await tester.pumpAndSettle();
    final nav = find.byType(HomeBottomNavigation);
    await _tap(
      tester,
      find.descendant(of: nav, matching: find.text('Bản đồ trạm')),
    );
    expect(router.state.uri.path, '/tram-cuu-ho');
    expect(router.state.uri.queryParameters['view'], 'map');
    expect(find.byType(RescueStationMockMap), findsOneWidget);
    await _tap(
      tester,
      find.descendant(of: nav, matching: find.text('Trang chủ')),
    );
    expect(router.state.uri.path, '/trang-chu');
    await scrollHomeToStations(tester);
    expect(find.byType(HomeStationGridCard), findsOneWidget);
    expect(_state(tester).read(homeDiscoveryProvider).query, 'revo');
  });

  testWidgets(
    'Towing card opens the selected station with its service packages',
    (tester) async {
      await _openHome(tester);
      await _tap(tester, find.byKey(const ValueKey('home-category-towing')));
      final firstCard = find.byType(HomeStationGridCard).first;
      final stationId = tester
          .widget<HomeStationGridCard>(firstCard)
          .listing
          .station
          .id;
      await _tap(tester, firstCard);
      await _tap(tester, find.byKey(const ValueKey('station-book')));
      final detail = tester.widget<PartnerDetailScreen>(
        find.byType(PartnerDetailScreen),
      );
      expect(detail.partnerId, stationId);
      expect(detail.serviceType, 'Xe cẩu kéo');
      expect(find.text('Tiệm chưa có gói dịch vụ phù hợp.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Small screens support search, large text, cards and service selection',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _openHome(tester);
      expect(tester.takeException(), isNull);
      await _tap(tester, find.byKey(const ValueKey('home-services')));
      await _tap(
        tester,
        find.byKey(const ValueKey('home-service-maintenance')),
      );
      expect(find.byType(PartnerListScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Notification bell opens the notification tab', (tester) async {
    await _openHome(tester);
    await _tap(tester, find.byTooltip('Thông báo'));
    final tabs = tester.element(find.byType(TabBar));
    expect(DefaultTabController.of(tabs).index, 2);
    expect(tester.takeException(), isNull);
  });
}
