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
import 'package:moto_care/features/home/widgets/home_service_grid.dart';
import 'package:moto_care/features/services/screens/services_screen.dart';

const _user = HomeUser(displayName: 'Nguyễn Văn An', memberId: '15335206');

Future<void> _openHome(
  WidgetTester tester, {
  HomeUser? user = _user,
  ValueChanged<HomeDestination>? onSelected,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: TrangChu(user: user, onDestinationSelected: onSelected),
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
    expect(find.text('Thành viên Vàng'), findsOneWidget);
    await _tap(tester, find.text('MotoCare Club'));
    expect(router.state.uri.path, '/tich-diem');
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Missing identity, vehicle and location stay neutral', (
    tester,
  ) async {
    await _openHome(tester, user: null);
    expect(find.text('Chào bạn'), findsOneWidget);
    expect(find.text('Chưa có hạng'), findsOneWidget);
    expect(find.text('Chọn xe cần cứu hộ'), findsOneWidget);
    expect(find.text('Vị trí sự cố: Chưa chọn vị trí'), findsOneWidget);
    await tester.ensureVisible(find.text('0 xu'));
    expect(find.text('0 xu'), findsOneWidget);
  });

  testWidgets('Home removes the menu button and drawer', (tester) async {
    await _openHome(tester);
    expect(find.byTooltip('Mở menu'), findsNothing);
    expect(find.byIcon(Icons.menu_rounded), findsNothing);
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).endDrawer, isNull);
  });

  testWidgets(
    'Bottom navigation has the five requested tabs and keeps home active',
    (tester) async {
      final selections = <HomeDestination>[];
      await _openHome(tester, onSelected: selections.add);
      final nav = find.byType(HomeBottomNavigation);
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
        HomeDestination.vouchers,
        HomeDestination.account,
      ]);
      expect(find.text('Chào Nguyễn Văn An'), findsOneWidget);
    },
  );

  testWidgets(
    'Club, offers, tips and charging dispatch their existing features',
    (tester) async {
      final selections = <HomeDestination>[];
      await _openHome(tester, onSelected: selections.add);
      await _tap(tester, find.text('MotoCare Club'));
      await _tap(tester, find.text('Giảm 30k\ncứu hộ đêm'));
      await _tap(tester, find.text('Xe chết máy\nmùa mưa?'));
      await _tap(tester, find.byKey(const ValueKey('home-service-charging')));
      expect(selections, [
        HomeDestination.membership,
        HomeDestination.vouchers,
        HomeDestination.emergencyTips,
        HomeDestination.nearbyServices,
      ]);
    },
  );

  testWidgets(
    'Search starts empty and only finds services, including unaccented input',
    (tester) async {
      final selections = <HomeDestination>[];
      await _openHome(tester, onSelected: selections.add);
      await _tap(tester, find.byTooltip('Tìm kiếm'));
      expect(find.text('Nhập tên dịch vụ bạn cần tìm.'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
      await tester.enterText(find.byType(TextField), 'tram sac');
      await tester.pumpAndSettle();
      expect(find.text('Trạm sạc gần nhất'), findsOneWidget);
      expect(find.text('Thông tin cá nhân'), findsNothing);
      expect(find.text('Tích điểm & Hạng thành viên'), findsNothing);
      expect(find.text('Kho ưu đãi'), findsNothing);
      await _tap(tester, find.text('Trạm sạc gần nhất'));
      expect(selections, [HomeDestination.nearbyServices]);
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets('Search shows an empty result and resets after clearing', (
    tester,
  ) async {
    await _openHome(tester);
    await _tap(tester, find.byTooltip('Tìm kiếm'));
    await tester.enterText(find.byType(TextField), 'thông tin cá nhân');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy dịch vụ phù hợp.'), findsOneWidget);
    await _tap(tester, find.byTooltip('Xóa tìm kiếm'));
    expect(find.text('Nhập tên dịch vụ bạn cần tìm.'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
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
    'Small screen supports large text, services, carousel and search',
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
      await tester.ensureVisible(find.text('Mẹo hay & Ưu đãi hôm nay ›'));
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
      await _tap(tester, find.byTooltip('Tìm kiếm'));
      await tester.enterText(find.byType(TextField), 'bao duong');
      await tester.pumpAndSettle();
      expect(find.text('Đặt lịch bảo dưỡng'), findsOneWidget);
      await _tap(tester, find.byTooltip('Quay lại'));
      expect(tester.takeException(), isNull);
    },
  );
}
