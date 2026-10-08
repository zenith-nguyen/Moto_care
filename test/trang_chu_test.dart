import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/home/models/home_destination.dart';
import 'package:moto_care/features/home/models/home_user.dart';
import 'package:moto_care/features/home/screens/home_screen.dart';
import 'package:moto_care/features/home/screens/trang_chu.dart';
import 'package:moto_care/features/home/widgets/home_bottom_navigation.dart';
import 'package:moto_care/features/home/widgets/home_header.dart';
import 'package:moto_care/features/home/widgets/home_service_grid.dart';
import 'package:moto_care/features/home/widgets/promo_banner_slider.dart';
import 'package:moto_care/features/services/screens/services_screen.dart';
import 'package:moto_care/features/partner/screens/partner_list_screen.dart';

import 'fixtures/marketplace_router_fixture.dart';

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

void main() {
  testWidgets('Home promo banners only display and swipe without navigation', (
    tester,
  ) async {
    final selections = <HomeDestination>[];
    await _openHome(tester, onSelected: selections.add);
    final slider = find.byType(PromoBannerSlider);
    await tester.ensureVisible(slider);
    await tester.tap(find.image(const AssetImage('assets/images/Banner1.png')));
    await tester.pumpAndSettle();
    await tester.drag(slider, const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.image(const AssetImage('assets/images/Banner2.png')));
    await tester.pumpAndSettle();

    expect(selections, isEmpty);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home route uses the new screen and receives account data', (
    tester,
  ) async {
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    router.go(
      '/trang-chu',
      extra: const HomeUser(
        displayName: 'Nguyễn Văn An',
        memberId: '15335206',
        membershipLabel: 'Thành viên Vàng',
        rewardPoints: 350,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TrangChu), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Chào Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Thành viên Vàng'), findsNothing);
    expect(find.text('MotoCare Club'), findsNothing);
    expect(router.state.uri.path, '/trang-chu');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Missing identity, vehicle and location stay neutral', (
    tester,
  ) async {
    await _openHome(tester, user: null);
    expect(find.text('Chào bạn'), findsOneWidget);
    expect(find.text('Chưa có hạng'), findsNothing);
    expect(find.text('Chọn xe cần cứu hộ'), findsOneWidget);
    expect(find.text('Vị trí sự cố: Chưa chọn vị trí'), findsOneWidget);
    expect(find.text('0 xu'), findsNothing);
  });

  testWidgets('Home removes menu, drawer and search actions', (tester) async {
    await _openHome(tester);
    expect(find.byTooltip('Mở menu'), findsNothing);
    expect(find.byIcon(Icons.menu_rounded), findsNothing);
    expect(find.byTooltip('Tìm kiếm'), findsNothing);
    expect(find.byIcon(Icons.search_rounded), findsNothing);
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).endDrawer, isNull);
  });

  testWidgets(
    'Bottom navigation has four tabs without offers and keeps home active',
    (tester) async {
      final selections = <HomeDestination>[];
      await _openHome(tester, onSelected: selections.add);
      final nav = find.byType(HomeBottomNavigation);
      expect(HomeDestination.homeNavigationItems, hasLength(4));
      expect(find.text('Kho ưu đãi'), findsNothing);
      await _tap(
        tester,
        find.descendant(of: nav, matching: find.text('Trang chủ')),
      );
      expect(selections, isEmpty);
      for (final destination in HomeDestination.homeNavigationItems.skip(1)) {
        await _tap(
          tester,
          find.descendant(
            of: nav,
            matching: find.text(destination.navigationLabel),
          ),
        );
      }
      expect(selections, [
        HomeDestination.activity,
        HomeDestination.services,
        HomeDestination.account,
      ]);
      expect(find.text('Chào Nguyễn Văn An'), findsOneWidget);
    },
  );

  testWidgets(
    'Home has no club or offer cards while charging opens the partner list',
    (tester) async {
      final selections = <HomeDestination>[];
      await _openHome(tester, onSelected: selections.add);
      expect(find.text('MotoCare Club'), findsNothing);
      expect(find.text('Mẹo hay & Ưu đãi hôm nay ›'), findsNothing);
      expect(find.text('Giảm 30k\ncứu hộ đêm'), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('home-service-charging')));
      expect(selections, isEmpty);
      expect(find.text('Trạm sạc gần nhất'), findsOneWidget);
      expect(find.byType(PartnerListScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Home hides the placeholder membership badge', (tester) async {
    await _openHome(tester);
    expect(find.text('Chưa có hạng'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(HomeHeader),
        matching: find.byIcon(Icons.star_rounded),
      ),
      findsNothing,
    );
    expect(find.text('Chào Nguyễn Văn An'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Legacy membership data does not display a badge', (
    tester,
  ) async {
    await _openHome(
      tester,
      user: const HomeUser(
        displayName: 'Nguyễn An',
        membershipLabel: 'Thành viên Vàng',
        rewardPoints: 350,
      ),
    );
    expect(
      find.descendant(
        of: find.byType(HomeHeader),
        matching: find.byIcon(Icons.star_rounded),
      ),
      findsNothing,
    );
    expect(find.text('Chào Nguyễn An'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Services tab opens the service catalog', (tester) async {
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    router.go('/trang-chu', extra: _user);
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Dịch vụ'));
    expect(router.state.uri.path, '/dich-vu');
    expect(find.byType(ServicesScreen), findsOneWidget);
  });

  testWidgets(
    'Small screen supports large text, services and carousel without search',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _openHome(
        tester,
        user: const HomeUser(
          displayName: 'Nguyễn Hoàng Minh Anh',
          membershipLabel: 'Thành viên Bạch Kim',
        ),
      );
      expect(tester.takeException(), isNull);
      for (final service in HomeService.homeItems) {
        await tester.ensureVisible(
          find.byKey(ValueKey('home-service-${service.name}')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.ensureVisible(find.text('Cứu hộ nhanh gần đây'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('home-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Tìm kiếm'), findsNothing);
      await _tap(
        tester,
        find.byKey(const ValueKey('home-service-maintenance')),
      );
      expect(find.text('Đặt lịch bảo dưỡng'), findsOneWidget);
      expect(find.byType(PartnerListScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
