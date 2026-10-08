import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/services/service_actions.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/home/theme/home_theme.dart';
import 'package:moto_care/features/home/models/home_destination.dart';
import 'package:moto_care/features/home/models/home_user.dart';
import 'package:moto_care/features/home/widgets/home_bottom_navigation.dart';
import 'package:moto_care/features/rescue_station/models/rescue_station.dart';
import 'package:moto_care/features/rescue_station/providers/rescue_station_provider.dart';
import 'package:moto_care/features/rescue_station/widgets/rescue_station_card.dart';
import 'package:moto_care/features/vehicle/models/vehicle.dart';
import 'package:moto_care/features/vehicle/providers/vehicle_provider.dart';
import 'package:moto_care/features/vehicle/widgets/them_sua_xe_bottom_sheet.dart';
import 'package:moto_care/features/vehicle/widgets/vehicle_card.dart';

const _wave = Vehicle(
  id: 'wave',
  name: 'Wave đi làm',
  brand: 'Honda',
  licensePlate: '59-X1 123.45',
  tireType: TireType.tubed,
  engineType: EngineType.gas,
  isDefault: true,
  color: 'Đỏ',
);
const _feliz = Vehicle(
  id: 'feliz',
  name: 'Feliz cuối tuần',
  brand: 'VinFast',
  licensePlate: '59-MD1 222.22',
  tireType: TireType.tubeless,
  engineType: EngineType.electric,
);

Future<GoRouter> _open(
  WidgetTester tester, {
  String path = '/xe-cua-toi',
  List<Vehicle> vehicles = const [],
  List<RescueStation>? stations,
  Future<bool> Function(Uri)? launcher,
}) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        initialVehiclesProvider.overrideWithValue(vehicles),
        if (stations != null)
          rescueStationsProvider.overrideWithValue(stations),
        serviceUrlLauncherProvider.overrideWithValue(
          launcher ?? (_) async => true,
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
      ),
    ),
  );
  router.go(
    path,
    extra: const HomeUser(displayName: 'Nguyễn Văn An', memberId: '15335206'),
  );
  await tester.pumpAndSettle();
  return router;
}

ProviderContainer _state(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

Future<void> _reveal(WidgetTester tester, Finder target) async {
  await tester.pumpAndSettle();
  if (target.evaluate().isEmpty) {
    final scrollable = find
        .byElementPredicate((element) {
          if (element.widget is! Scrollable) return false;
          final state = (element as StatefulElement).state as ScrollableState;
          return state.widget.axisDirection == AxisDirection.down &&
              state.position.maxScrollExtent > 0;
        })
        .hitTestable()
        .last;
    await tester.scrollUntilVisible(target, 150, scrollable: scrollable);
  }
  await Scrollable.ensureVisible(target.evaluate().first, alignment: .5);
  await tester.pumpAndSettle();
  for (
    var attempt = 0;
    target.hitTestable().evaluate().isEmpty && attempt < 10;
    attempt++
  ) {
    final scrollable = find
        .byElementPredicate((element) {
          if (element.widget is! Scrollable) return false;
          final state = (element as StatefulElement).state as ScrollableState;
          return state.widget.axisDirection == AxisDirection.down &&
              state.position.maxScrollExtent > 0;
        })
        .hitTestable()
        .last;
    final y = tester.getCenter(target.first).dy;
    await tester.drag(scrollable, Offset(0, y < 100 ? 140 : -140));
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsWidgets);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _reveal(tester, target);
  await tester.tap(target.hitTestable().first);
  await tester.pumpAndSettle();
}

Finder _bottom(String label) => find.descendant(
  of: find.byType(HomeBottomNavigation),
  matching: find.text(label),
);

Future<void> _fill(
  WidgetTester tester, {
  String name = 'Vision đi làm',
  String plate = '59-X2 333.33',
  String brand = 'Honda',
}) async {
  await _reveal(tester, find.byKey(const ValueKey('vehicle-name')));
  await tester.enterText(find.byKey(const ValueKey('vehicle-name')), name);
  await _reveal(tester, find.byKey(const ValueKey('vehicle-plate')));
  await tester.enterText(find.byKey(const ValueKey('vehicle-plate')), plate);
  await _tap(tester, find.byKey(const ValueKey('vehicle-brand')));
  await _tap(tester, find.text(brand).last);
}

Future<void> _menu(
  WidgetTester tester,
  String vehicleName,
  String action,
) async {
  await _tap(tester, find.byTooltip('Tùy chọn xe $vehicleName'));
  await _tap(tester, find.text(action));
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'Light tabs route from home, activity, services and account and preserve the home account',
    (tester) async {
      final router = await _open(tester, path: '/trang-chu');
      for (final (label, path, selected) in [
        ('Hoạt động', '/hoat-dong', HomeDestination.activity),
        ('Dịch vụ', '/dich-vu', HomeDestination.services),
        ('Tài khoản', '/tai-khoan', HomeDestination.account),
        ('Hoạt động', '/hoat-dong', HomeDestination.activity),
      ]) {
        await _tap(tester, _bottom(label));
        expect(router.state.uri.path, path);
        expect(
          tester
              .widget<HomeBottomNavigation>(find.byType(HomeBottomNavigation))
              .selectedDestination,
          selected,
        );
        await _tap(tester, _bottom(label));
        expect(router.state.uri.path, path);
      }
      await _tap(tester, _bottom('Trang chủ'));
      expect(find.text('Chào Nguyễn Văn An'), findsOneWidget);
      expect(router.canPop(), isFalse);
    },
  );

  testWidgets(
    'Empty garage validates required fields, then saves a complete default vehicle',
    (tester) async {
      await _open(tester);
      expect(
        find.text('Bạn chưa thêm xe nào. Thêm xe ngay để cứu hộ nhanh hơn.'),
        findsOneWidget,
      );
      await _tap(tester, find.byTooltip('Thêm xe mới'));
      await _tap(tester, find.text('Lưu thông tin xe'));
      expect(find.text('Vui lòng nhập tên xe.'), findsOneWidget);
      expect(find.text('Vui lòng nhập biển số xe.'), findsOneWidget);
      expect(find.text('Vui lòng chọn hãng xe.'), findsOneWidget);
      await _fill(tester);
      await _tap(tester, find.text('Không ruột'));
      await _tap(tester, find.text('Xe điện'));
      await tester.enterText(
        find.byKey(const ValueKey('vehicle-color')),
        'Xanh',
      );
      await _tap(tester, find.text('Lưu thông tin xe'));
      expect(find.byType(ThemSuaXeBottomSheet), findsNothing);
      final vehicle = _state(tester).read(defaultVehicleProvider)!;
      expect(vehicle.name, 'Vision đi làm');
      expect(vehicle.licensePlate, '59-X2 333.33');
      expect(vehicle.tireType, TireType.tubeless);
      expect(vehicle.engineType, EngineType.electric);
      expect(vehicle.color, 'Xanh');
      expect(find.text('Mặc định cứu hộ'), findsOneWidget);
      expect(find.byType(VehicleCard), findsOneWidget);
    },
  );

  testWidgets(
    'Default and edit actions retain ID and preserve saved vehicles when switching tabs',
    (tester) async {
      final router = await _open(tester, vehicles: [_wave, _feliz]);
      await _menu(tester, _feliz.name, 'Đặt làm mặc định');
      expect(_state(tester).read(defaultVehicleProvider)!.id, _feliz.id);
      await _menu(tester, _feliz.name, 'Chỉnh sửa');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('vehicle-name')))
            .controller!
            .text,
        _feliz.name,
      );
      await tester.enterText(
        find.byKey(const ValueKey('vehicle-name')),
        'Feliz gia đình',
      );
      await _tap(tester, find.text('Lưu thông tin xe'));
      final state = _state(tester);
      expect(state.read(vehicleProvider), hasLength(2));
      expect(state.read(defaultVehicleProvider)!.id, 'feliz');
      expect(state.read(defaultVehicleProvider)!.name, 'Feliz gia đình');
      expect(
        state.read(defaultVehicleProvider)!.engineType,
        EngineType.electric,
      );
      await _tap(tester, _bottom('Dịch vụ'));
      await _tap(tester, find.text('Tìm trạm cứu hộ'));
      await _tap(tester, _bottom('Tài khoản'));
      await _tap(tester, find.byKey(const ValueKey('account-vehicles')));
      expect(router.state.uri.path, '/xe-cua-toi');
      await _reveal(tester, find.text('Feliz gia đình'));
      expect(find.text('Feliz gia đình'), findsOneWidget);
    },
  );

  testWidgets(
    'Delete requires confirmation, promotes another default and restores empty state',
    (tester) async {
      await _open(tester, vehicles: [_wave, _feliz]);
      await _menu(tester, _wave.name, 'Xóa');
      await _tap(tester, find.text('Giữ lại'));
      expect(_state(tester).read(vehicleProvider), hasLength(2));
      await _menu(tester, _wave.name, 'Xóa');
      await _tap(tester, find.text('Xóa xe'));
      expect(_state(tester).read(defaultVehicleProvider)!.id, 'feliz');
      await _menu(tester, _feliz.name, 'Xóa');
      await _tap(tester, find.text('Xóa xe'));
      expect(_state(tester).read(vehicleProvider), isEmpty);
      expect(
        find.text('Bạn chưa thêm xe nào. Thêm xe ngay để cứu hộ nhanh hơn.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Duplicate plates cannot be saved and closing a draft changes no vehicles',
    (tester) async {
      await _open(tester, vehicles: [_wave]);
      await _tap(tester, find.byTooltip('Thêm xe mới'));
      await _fill(tester, plate: '59x112345');
      await _tap(tester, find.text('Lưu thông tin xe'));
      expect(
        find.text('Biển số này đã có trong danh sách xe.'),
        findsOneWidget,
      );
      expect(_state(tester).read(vehicleProvider), hasLength(1));
      await _tap(tester, find.byTooltip('Đóng thông tin xe'));
      expect(_state(tester).read(vehicleProvider).single.id, _wave.id);
      await _tap(tester, find.byTooltip('Thêm xe mới'));
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('vehicle-name')))
            .controller!
            .text,
        isEmpty,
      );
    },
  );

  testWidgets(
    'Station filters combine, nearest sorts, and map selection reveals its station',
    (tester) async {
      await _open(tester, path: '/tram-cuu-ho');
      expect(
        tester
            .widget<RescueStationCard>(find.byType(RescueStationCard).first)
            .station
            .id,
        'station-tuan',
      );
      await _tap(tester, find.text('Gần nhất'));
      expect(
        tester
            .widget<RescueStationCard>(find.byType(RescueStationCard).first)
            .station
            .id,
        'station-mobile',
      );
      await _tap(tester, find.text('Đã xác thực'));
      await _tap(tester, find.text('Chính hãng'));
      expect(find.text('1 trạm • Gần nhất trước'), findsOneWidget);
      await _tap(tester, find.text('Mở 24/7'));
      expect(
        find.text(
          'Không tìm thấy trạm phù hợp. Hãy thử từ khóa khác hoặc bỏ bớt bộ lọc.',
        ),
        findsOneWidget,
      );
      await _tap(tester, find.text('Mở 24/7'));
      await _tap(tester, find.text('Chính hãng'));
      await _tap(tester, find.text('Bản đồ'));
      await _tap(tester, find.byTooltip('Cứu hộ Minh Tuấn'));
      await _reveal(tester, find.text('Cứu hộ Minh Tuấn'));
      expect(
        tester
            .widget<RescueStationCard>(find.byType(RescueStationCard))
            .station
            .id,
        'station-tuan',
      );
    },
  );

  testWidgets(
    'Station address search works without accents and shows closed shops',
    (tester) async {
      await _open(tester, path: '/tram-cuu-ho');
      await tester.enterText(find.byType(TextField), 'thanh cong');
      await tester.pumpAndSettle();
      expect(find.text('1 trạm • Đánh giá cao trước'), findsOneWidget);
      await _reveal(tester, find.text('Đóng cửa'));
      expect(find.text('Đóng cửa'), findsOneWidget);
      expect(find.text('Xác thực MotoCare'), findsNothing);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'khong co tram');
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Không tìm thấy trạm phù hợp. Hãy thử từ khóa khác hoặc bỏ bớt bộ lọc.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Call and directions launch station contact/coordinates and provide fallback feedback',
    (tester) async {
      final launched = <Uri>[];
      await _open(
        tester,
        path: '/tram-cuu-ho',
        launcher: (uri) async {
          launched.add(uri);
          return false;
        },
      );
      await _tap(tester, find.text('Gọi ngay').first);
      expect(launched.single.toString(), 'tel:0900000001');
      expect(
        find.text('Không thể mở ứng dụng gọi điện. Số trạm: 0900000001'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      await _tap(tester, find.text('Chỉ đường').first);
      expect(launched.last.host, 'www.google.com');
      expect(launched.last.queryParameters['destination'], '10.7884,106.6819');
      expect(find.textContaining('Không thể mở Google Maps.'), findsOneWidget);
    },
  );

  testWidgets(
    'Empty station data works in both viewing modes and deep routes return to home',
    (tester) async {
      final router = await _open(tester, path: '/tram-cuu-ho', stations: []);
      await _tap(tester, find.text('Bản đồ'));
      expect(
        find.text(
          'Không tìm thấy trạm phù hợp. Hãy thử từ khóa khác hoặc bỏ bớt bộ lọc.',
        ),
        findsOneWidget,
      );
      await _tap(tester, find.byTooltip('Quay lại'));
      expect(router.state.uri.path, '/trang-chu');
    },
  );

  testWidgets(
    'Vehicle form, station list/map and bottom navigation fit 320px with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(tester, vehicles: [_wave, _feliz]);
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
        HomeColors.background,
      );
      await _tap(tester, find.byTooltip('Thêm xe mới'));
      await _reveal(tester, find.byKey(const ValueKey('vehicle-name')));
      await tester.enterText(
        find.byKey(const ValueKey('vehicle-name')),
        'Xe đi làm',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      await _reveal(tester, find.text('Lưu thông tin xe'));
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await _tap(tester, find.byTooltip('Đóng thông tin xe'));
      await _tap(tester, _bottom('Dịch vụ'));
      await _tap(tester, find.text('Tìm trạm cứu hộ'));
      await _reveal(tester, find.text('Gọi ngay'));
      expect(tester.takeException(), isNull);
      final outer = find.byType(Scrollable).first;
      tester.state<ScrollableState>(outer).position.jumpTo(0);
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Bản đồ'));
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
        HomeColors.background,
      );
    },
  );
}
