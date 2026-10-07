import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/services/service_actions.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/home/theme/home_theme.dart';
import 'package:moto_care/features/home/widgets/home_bottom_navigation.dart';
import 'package:moto_care/features/home/models/home_destination.dart';
import 'package:moto_care/core/widgets/photo_attachment_field.dart';
import 'package:moto_care/core/widgets/service_scaffold.dart';
import 'package:moto_care/features/activity/models/rescue_order.dart';
import 'package:moto_care/features/activity/providers/activity_provider.dart';
import 'package:moto_care/features/chat/screens/tin_nhan_screen.dart';
import 'package:moto_care/features/home/models/home_user.dart';
import 'package:moto_care/features/membership/screens/tich_diem_screen.dart';
import 'package:moto_care/features/partner/providers/partner_registration_provider.dart';
import 'package:moto_care/features/places/models/service_place.dart';
import 'package:moto_care/features/places/screens/tram_sac_tiem_sua_screen.dart';
import 'package:moto_care/features/policy/providers/compensation_provider.dart';
import 'package:moto_care/features/voucher/providers/voucher_provider.dart';

const _user = HomeUser(displayName: 'Nguyễn Văn An', memberId: 'MC15335206');
const _routes = [
  '/tich-diem',
  '/tram-sac-tiem-sua',
  '/kho-voucher',
  '/bang-gia',
  '/dang-ky-tho',
  '/cam-ket-dich-vu',
  '/faq',
  '/meo-xu-ly',
];

Future<GoRouter> _open(
  WidgetTester tester,
  String path, {
  Future<bool> Function(Uri)? launcher,
  Future<Uint8List?> Function()? picker,
  List<ServicePlace>? places,
  List<RescueOrder>? orders,
}) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        voucherClockProvider.overrideWithValue(() => DateTime(2026, 10, 3)),
        serviceUrlLauncherProvider.overrideWithValue(
          launcher ?? (_) async => false,
        ),
        attachmentPickerProvider.overrideWithValue(
          picker ??
              () async =>
                  (await rootBundle.load('assets/images/logo-motocare.png'))
                      .buffer
                      .asUint8List(),
        ),
        if (places != null) servicePlacesProvider.overrideWithValue(places),
        if (orders != null)
          initialRescueOrdersProvider.overrideWithValue(orders),
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
  router.go(path, extra: _user);
  await tester.pumpAndSettle();
  return router;
}

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
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
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

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(ServiceScaffold)));

void main() {
  testWidgets(
    'Account keeps all former menu destinations and their bottom navigation',
    (tester) async {
      final router = await _open(tester, '/trang-chu');
      await _tap(tester, find.text('Tài khoản'));
      const ids = [
        'membership',
        'places',
        'vouchers',
        'prices',
        'mechanic',
        'commitment',
        'help',
        'tips',
      ];
      for (var index = 0; index < ids.length; index++) {
        final item = find.byKey(ValueKey('account-${ids[index]}'));
        await _tap(tester, item);
        expect(router.state.uri.path, _routes[index]);
        expect(find.byType(ServiceScaffold), findsOneWidget);
        final nav = find.byType(HomeBottomNavigation);
        expect(nav, findsOneWidget);
        for (final destination in HomeDestination.homeNavigationItems) {
          expect(
            find.descendant(
              of: nav,
              matching: find.text(destination.navigationLabel),
            ),
            findsOneWidget,
          );
        }
        await _tap(tester, find.byTooltip('Quay lại'));
        expect(router.state.uri.path, '/tai-khoan');
      }
      await _tap(tester, find.text('Trang chủ'));
      expect(find.text('Chào Nguyễn Văn An'), findsOneWidget);
    },
  );

  testWidgets(
    'Membership receives identity, gold tier and remaining progress',
    (tester) async {
      await _open(tester, '/tich-diem');
      expect(find.byType(TichDiemScreen), findsOneWidget);
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.text('ID: MC15335206'), findsOneWidget);
      expect(find.text('Vàng'), findsOneWidget);
      expect(find.text('350 điểm'), findsOneWidget);
      expect(
        find.text('Tích thêm 150 điểm để lên hạng Bạch Kim.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        .7,
      );
      await tester.scrollUntilVisible(
        find.text('+50 điểm - Đơn SOS #MC8821'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('-100 điểm - Đổi Voucher 20k'), findsOneWidget);
    },
  );

  testWidgets(
    'Place search and combined filters update both map and list with an empty state',
    (tester) async {
      await _open(tester, '/tram-sac-tiem-sua');
      await _tap(tester, find.text('Danh sách'));
      await _tap(tester, find.text('Trạm sạc'));
      await _tap(tester, find.text('Mở 24/7'));
      expect(find.text('1 địa điểm • Khoảng cách minh họa'), findsOneWidget);
      expect(find.text('Trạm sạc MotoCare Nguyễn Trãi'), findsOneWidget);
      expect(find.text('Tiệm sửa xe Minh Tuấn'), findsNothing);
      await tester.enterText(find.byType(TextField), 'nguyen trai');
      await tester.pumpAndSettle();
      expect(find.text('1 địa điểm • Khoảng cách minh họa'), findsOneWidget);
      await _tap(tester, find.text('Bản đồ'));
      expect(find.byTooltip('Trạm sạc MotoCare Nguyễn Trãi'), findsOneWidget);
      await _tap(tester, find.text('Sửa xe xăng'));
      expect(
        find.text(
          'Không tìm thấy địa điểm phù hợp. Hãy thử địa chỉ khác hoặc bỏ bớt bộ lọc.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Directions and calls launch encoded external URLs and handle failure',
    (tester) async {
      final launches = <Uri>[];
      await _open(
        tester,
        '/tram-sac-tiem-sua',
        launcher: (uri) async {
          launches.add(uri);
          return false;
        },
        places: [
          const ServicePlace(
            id: '1',
            name: 'Trạm thử',
            address: '120 Nguyễn Trãi, TP. Hồ Chí Minh',
            distanceKm: 1,
            rating: 4.9,
            isOpen: true,
            isCharging: true,
            is24Hours: true,
            repairsPetrol: false,
            phone: '0900000001',
          ),
        ],
      );
      await _tap(tester, find.text('Chỉ đường'));
      expect(launches.single.host, 'www.google.com');
      expect(
        launches.single.queryParameters['destination'],
        '120 Nguyễn Trãi, TP. Hồ Chí Minh',
      );
      expect(find.textContaining('Không thể mở bản đồ.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Gọi'));
      expect(launches.last.toString(), 'tel:0900000001');
      expect(
        find.textContaining('Không thể mở ứng dụng gọi điện.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Promo codes validate, normalize and prevent duplicates; voucher returns to home',
    (tester) async {
      final router = await _open(tester, '/trang-chu');
      router.push('/kho-voucher');
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Áp dụng'));
      expect(find.text('Vui lòng nhập mã ưu đãi.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'INVALID');
      await _tap(tester, find.text('Áp dụng'));
      expect(find.text('Mã ưu đãi không hợp lệ.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), ' moto20 ');
      await _tap(tester, find.text('Áp dụng'));
      final container = _container(tester);
      expect(
        container.read(voucherProvider).where((v) => v.code == 'MOTO20').length,
        1,
      );
      await tester.enterText(find.byType(TextField), 'MOTO20');
      await _tap(tester, find.text('Áp dụng'));
      expect(
        find.text('Mã này đã có trong kho voucher của bạn.'),
        findsOneWidget,
      );
      await _tap(tester, find.text('Lịch sử sử dụng'));
      expect(find.text('Đã sử dụng: 28/09/2026'), findsOneWidget);
      expect(find.text('Dùng ngay'), findsNothing);
      await _tap(tester, find.text('Voucher sẵn có'));
      await _tap(tester, find.text('Dùng ngay').first);
      expect(router.state.uri.path, '/trang-chu');
      expect(find.text('Chào Nguyễn Văn An'), findsOneWidget);
    },
  );

  testWidgets(
    'Pricing search finds accented services with plain text and expands results',
    (tester) async {
      await _open(tester, '/bang-gia');
      await _tap(tester, find.text('Cứu hộ cơ bản'));
      expect(find.text('Vá xe'), findsOneWidget);
      expect(find.text('30k - 50k'), findsOneWidget);
      await _reveal(tester, find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'ac quy');
      await tester.pumpAndSettle();
      expect(find.text('Thay bình ắc quy GS'), findsOneWidget);
      expect(find.text('380k'), findsOneWidget);
      expect(find.text('Cứu hộ cơ bản'), findsNothing);
      await _reveal(tester, find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'khong ton tai');
      await tester.pumpAndSettle();
      expect(
        find.text('Không tìm thấy phụ tùng hoặc dịch vụ phù hợp.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Partner cannot skip identity validation and cancelled photo selection stays empty',
    (tester) async {
      await _open(tester, '/dang-ky-tho', picker: () async => null);
      await _tap(tester, find.text('Tiếp tục'));
      expect(find.text('Vui lòng nhập họ tên đầy đủ.'), findsOneWidget);
      expect(find.text('Số CCCD phải gồm 12 chữ số.'), findsOneWidget);
      expect(find.text('Vui lòng chọn ảnh cccd mặt trước.'), findsOneWidget);
      await _tap(tester, find.text('Ảnh CCCD mặt trước'));
      expect(find.byType(Image), findsNothing);
      expect(_container(tester).read(partnerApplicationsProvider), isEmpty);
    },
  );

  testWidgets(
    'Partner form preserves previous steps and stores complete application once',
    (tester) async {
      await _open(tester, '/dang-ky-tho');
      await tester.enterText(
        find.byType(TextFormField).first,
        'Nguyễn Minh Tuấn',
      );
      await tester.enterText(find.byType(TextFormField).last, '012345678901');
      await _tap(tester, find.text('Ảnh CCCD mặt trước'));
      await _tap(tester, find.text('Ảnh CCCD mặt sau'));
      await _tap(tester, find.text('Tiếp tục'));
      await _tap(tester, find.text('Tiếp tục'));
      expect(find.text('Vui lòng chọn ít nhất một dụng cụ.'), findsOneWidget);
      await _tap(tester, find.byType(DropdownButtonFormField<String>));
      await _tap(tester, find.text('3 - 5 năm').last);
      await _tap(tester, find.text('Bơm điện'));
      await _tap(tester, find.text('Quay lại bước trước'));
      expect(find.text('Nguyễn Minh Tuấn'), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
      await _tap(tester, find.text('Tiếp tục'));
      await _tap(tester, find.text('Tiếp tục'));
      await _tap(tester, find.text('Gửi hồ sơ đăng ký'));
      expect(find.text('Vui lòng chọn khu vực hoạt động.'), findsOneWidget);
      await _tap(tester, find.byType(DropdownButtonFormField<String>));
      await _tap(tester, find.text('Quận 3').last);
      await _tap(tester, find.text('Gửi hồ sơ đăng ký'));
      expect(find.text('Đăng ký thành công'), findsOneWidget);
      final applications = _container(tester).read(partnerApplicationsProvider);
      expect(applications, hasLength(1));
      expect(applications.single.citizenId, '012345678901');
      expect(applications.single.tools, {'Bơm điện'});
      expect(applications.single.district, 'Quận 3');
      expect(applications.single.frontPhoto, isNotEmpty);
      await _tap(tester, find.text('Đã hiểu'));
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Đã ghi nhận hồ sơ'),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'Compensation validates order and incident, then saves evidence without duplicate submission',
    (tester) async {
      await _open(tester, '/cam-ket-dich-vu');
      await _tap(tester, find.text('Gửi báo cáo bồi thường'));
      await tester.scrollUntilVisible(
        find.text('Vui lòng chọn mã đơn cần báo cáo.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Vui lòng mô tả sự cố ít nhất 10 ký tự.'),
        findsOneWidget,
      );
      await _tap(tester, find.byType(DropdownButtonFormField<String>));
      await _tap(tester, find.text('MC-260930-012').last);
      await tester.enterText(
        find.byType(TextFormField),
        'Lốp xe vẫn bị xì hơi sau khi sửa.',
      );
      await _tap(tester, find.text('Tải ảnh hóa đơn/bằng chứng'));
      await _tap(tester, find.text('Gửi báo cáo bồi thường'));
      expect(find.text('Đã ghi nhận báo cáo'), findsWidgets);
      final reports = _container(tester).read(compensationReportsProvider);
      expect(reports, hasLength(1));
      expect(reports.single.orderId, 'completed-001');
      expect(reports.single.evidence, isNotEmpty);
      await _tap(tester, find.text('Đã hiểu'));
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Đã ghi nhận báo cáo'),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('Compensation disables submission when there are no orders', (
    tester,
  ) async {
    await _open(tester, '/cam-ket-dich-vu', orders: []);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Gửi báo cáo bồi thường'),
          )
          .onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.text('Chưa có đơn cứu hộ gần đây để gửi yêu cầu.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(_container(tester).read(compensationReportsProvider), isEmpty);
  });

  testWidgets(
    'FAQ searches, filters topics, calls configured hotline and opens chat',
    (tester) async {
      final calls = <Uri>[];
      final router = await _open(
        tester,
        '/faq',
        launcher: (uri) async {
          calls.add(uri);
          return true;
        },
      );
      await tester.enterText(find.byType(TextField), 'huy don');
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Tôi có thể hủy đơn cứu hộ không?'));
      expect(find.textContaining('Bạn có thể mở Hoạt động'), findsOneWidget);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'huy don',
      );
      await tester.enterText(find.byType(TextField), '');
      await _tap(tester, find.text('Voucher'));
      await _tap(tester, find.text('Làm thế nào để sử dụng voucher?'));
      expect(find.text('Làm thế nào để sử dụng voucher?'), findsOneWidget);
      expect(find.text('Tôi có thể hủy đơn cứu hộ không?'), findsNothing);
      await _tap(tester, find.text('Gọi Hotline 24/7'));
      expect(calls.single.toString(), 'tel:1130');
      await _tap(tester, find.text('Chat với CSKH'));
      expect(router.state.uri.path, '/tin-nhan');
      expect(find.byType(TinNhanScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Input screens stay scrollable above the keyboard on a small device',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final path in [
        '/kho-voucher',
        '/dang-ky-tho',
        '/faq',
        '/bang-gia',
        '/tram-sac-tiem-sua',
      ]) {
        tester.view.resetViewInsets();
        await _open(tester, path);
        await _tap(tester, find.byType(TextField).first);
        tester.view.viewInsets = const FakeViewPadding(bottom: 250);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
      }
    },
  );

  testWidgets('Tip cards open four illustrated steps and close the sheet', (
    tester,
  ) async {
    await _open(tester, '/meo-xu-ly');
    await _tap(tester, find.text('Cách xử lý khi xe bị ngập nước chết máy'));
    expect(find.text('Bước 1'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Bước 4'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Bước 4'), findsOneWidget);
    expect(
      find.textContaining('Gọi cứu hộ đưa xe đi kiểm tra'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byTooltip('Đóng bài viết'),
      -200,
      scrollable: find.byType(Scrollable).last,
    );
    await _tap(tester, find.byTooltip('Đóng bài viết'));
    expect(find.text('Bước 1'), findsNothing);
  });

  testWidgets(
    'Every new route fits small screens with large text and direct back navigation',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final path in _routes) {
        final router = await _open(tester, path);
        expect(tester.takeException(), isNull, reason: path);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.backgroundColor, HomeColors.background);
        expect(find.byType(HomeBottomNavigation), findsOneWidget);
        await _tap(tester, find.byTooltip('Quay lại'));
        expect(router.state.uri.path, '/trang-chu');
        expect(tester.takeException(), isNull, reason: path);
      }
    },
  );
}
